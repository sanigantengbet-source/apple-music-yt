use crate::cipher::decode_signature_cipher;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::time::Duration;

const INNERTUBE_API_KEY: &str = "";
const USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

#[derive(Debug, Serialize, Deserialize)]
pub struct SongItem {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: Option<String>,
    pub duration: Option<String>,
    pub thumbnail_url: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StreamInfo {
    pub url: String,
    pub bitrate: u64,
    pub mime_type: String,
    pub duration_seconds: u64,
}

pub struct YtMusicClient {
    agent: ureq::Agent,
}

impl YtMusicClient {
    pub fn new() -> Self {
        let agent = ureq::AgentBuilder::new()
            .timeout_connect(Duration::from_secs(10))
            .timeout_read(Duration::from_secs(15))
            .user_agent(USER_AGENT)
            .build();
        Self { agent }
    }

    fn create_innertube_context(&self) -> Value {
        json!({
            "client": {
                "clientName": "WEB_REMIX",
                "clientVersion": "1.20240101.01.00",
                "hl": "en",
                "gl": "US"
            }
        })
    }

    /// Search for songs, albums, or artists
    pub fn search(&self, query: &str, filter: &str) -> Result<Vec<SongItem>, String> {
        let mut params = None;
        if filter == "songs" {
            params = Some("EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D");
        } else if filter == "albums" {
            params = Some("EgWKAQIYAWoKEAkQBRAKEAMQBA%3D%3D");
        }

        let mut body_map = json!({
            "context": self.create_innertube_context(),
            "query": query,
        });

        if let Some(p) = params {
            body_map["params"] = json!(p);
        }

        let resp = self.agent
            .post("https://music.youtube.com/youtubei/v1/search?prettyPrint=false")
            .set("Content-Type", "application/json")
            .set("Referer", "https://music.youtube.com/")
            .send_json(body_map)
            .map_err(|e| format!("Search request failed: {}", e))?;

        let json_val: Value = resp.into_json()
            .map_err(|e| format!("Failed to parse response JSON: {}", e))?;

        let mut songs = Vec::new();
        self.extract_search_results(&json_val, &mut songs);
        Ok(songs)
    }

    fn extract_search_results(&self, root: &Value, out: &mut Vec<SongItem>) {
        let contents = &root["contents"]["tabbedSearchResultsRenderer"]["tabs"][0]
            ["tabRenderer"]["content"]["sectionListRenderer"]["contents"];

        if let Some(sections) = contents.as_array() {
            for section in sections {
                let items = &section["musicShelfRenderer"]["contents"];
                if let Some(shelf_items) = items.as_array() {
                    for item in shelf_items {
                        if let Some(song) = self.parse_music_responsive_list_item(item) {
                            out.push(song);
                        }
                    }
                }
            }
        }
    }

    fn parse_music_responsive_list_item(&self, item: &Value) -> Option<SongItem> {
        let renderer = &item["musicResponsiveListItemRenderer"];
        if renderer.is_null() {
            return None;
        }

        let flex_columns = renderer["flexColumns"].as_array()?;
        if flex_columns.is_empty() {
            return None;
        }

        // Title
        let title = flex_columns[0]["musicResponsiveListItemFlexColumnRenderer"]
            ["text"]["runs"][0]["text"].as_str()?.to_string();

        // Video ID
        let mut video_id = String::new();
        if let Some(nav_endpoint) = renderer["playlistItemData"]["videoId"].as_str() {
            video_id = nav_endpoint.to_string();
        } else if let Some(play_nav) = renderer["overlay"]["musicItemThumbnailOverlayRenderer"]
            ["content"]["musicPlayButtonRenderer"]["playNavigationEndpoint"]["watchEndpoint"]["videoId"].as_str() {
            video_id = play_nav.to_string();
        }

        if video_id.is_empty() {
            return None;
        }

        // Artist & Album
        let mut artist = "Unknown Artist".to_string();
        let mut album = None;
        let mut duration = None;

        if flex_columns.len() > 1 {
            let runs = flex_columns[1]["musicResponsiveListItemFlexColumnRenderer"]
                ["text"]["runs"].as_array();
            if let Some(r) = runs {
                if !r.is_empty() {
                    artist = r[0]["text"].as_str().unwrap_or("Unknown Artist").to_string();
                }
                if r.len() >= 3 {
                    album = r[2]["text"].as_str().map(|s| s.to_string());
                }
                if r.len() >= 5 {
                    duration = r[4]["text"].as_str().map(|s| s.to_string());
                }
            }
        }

        // Thumbnail
        let mut thumbnail_url = String::new();
        if let Some(thumbs) = renderer["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"].as_array() {
            if let Some(last) = thumbs.last() {
                thumbnail_url = last["url"].as_str().unwrap_or("").to_string();
            }
        }

        Some(SongItem {
            id: video_id,
            title,
            artist,
            album,
            duration,
            thumbnail_url,
        })
    }

    /// Extract stream URL for playback with high audio quality
    pub fn get_stream_url(&self, video_id: &str) -> Result<StreamInfo, String> {
        // Use Android client context for direct audio playback URLs (often un-throttled & un-ciphered)
        let body = json!({
            "context": {
                "client": {
                    "clientName": "ANDROID_MUSIC",
                    "clientVersion": "6.31.55",
                    "androidSdkVersion": 33,
                    "hl": "en",
                    "gl": "US"
                }
            },
            "videoId": video_id,
            "playbackContext": {
                "contentPlaybackContext": {
                    "html5Preference": "HTML5_PREF_WANTS"
                }
            }
        });

        let resp = self.agent
            .post("https://music.youtube.com/youtubei/v1/player?prettyPrint=false")
            .set("Content-Type", "application/json")
            .set("User-Agent", "com.google.android.apps.youtube.music/6.31.55 (Linux; U; Android 13)")
            .send_json(body)
            .map_err(|e| format!("Player API request failed: {}", e))?;

        let json_val: Value = resp.into_json()
            .map_err(|e| format!("Failed to parse player JSON: {}", e))?;

        let streaming_data = &json_val["streamingData"];
        let adaptive_formats = streaming_data["adaptiveFormats"].as_array()
            .ok_or_else(|| "No adaptive formats in streamingData".to_string())?;

        let mut best_format: Option<&Value> = None;
        let mut best_bitrate = 0u64;

        for fmt in adaptive_formats {
            let mime = fmt["mimeType"].as_str().unwrap_or("");
            if mime.starts_with("audio/") {
                let bitrate = fmt["bitrate"].as_u64().unwrap_or(0);
                if bitrate > best_bitrate {
                    best_bitrate = bitrate;
                    best_format = Some(fmt);
                }
            }
        }

        let chosen = best_format.ok_or_else(|| "No suitable audio format found".to_string())?;
        let mime_type = chosen["mimeType"].as_str().unwrap_or("audio/mp4").to_string();
        let duration_seconds = chosen["approxDurationMs"]
            .as_str()
            .and_then(|s| s.parse::<u64>().ok())
            .map(|ms| ms / 1000)
            .unwrap_or(0);

        let stream_url = if let Some(direct_url) = chosen["url"].as_str() {
            direct_url.to_string()
        } else if let Some(cipher) = chosen["signatureCipher"].as_str() {
            decode_signature_cipher(cipher).ok_or_else(|| "Failed to decipher signature".to_string())?
        } else {
            return Err("Neither direct url nor signatureCipher found in format".to_string());
        };

        Ok(StreamInfo {
            url: stream_url,
            bitrate: best_bitrate,
            mime_type,
            duration_seconds,
        })
    }
}
