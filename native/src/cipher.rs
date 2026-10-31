use regex::Regex;
use std::collections::HashMap;

/// Decodes YouTube signature cipher query string
pub fn decode_signature_cipher(cipher_str: &str) -> Option<String> {
    let mut params = HashMap::new();
    for pair in cipher_str.split('&') {
        let mut parts = pair.splitn(2, '=');
        if let (Some(k), Some(v)) = (parts.next(), parts.next()) {
            params.insert(k, urlencoding_decode(v));
        }
    }

    let url = params.get("url")?;
    let sig = params.get("s");
    let sp = params.get("sp").map(|s| s.as_str()).unwrap_or("signature");

    if let Some(s) = sig {
        // If signature manipulation is needed, here we append or transform signature
        // In most standard InnerTube Android/iOS clients, direct URL or sp=sig is used
        let separator = if url.contains('?') { "&" } else { "?" };
        Some(format!("{}{}{}={}", url, separator, sp, s))
    } else {
        Some(url.clone())
    }
}

fn urlencoding_decode(s: &str) -> String {
    let mut result = String::new();
    let mut chars = s.chars();
    while let Some(ch) = chars.next() {
        if ch == '%' {
            let hex: String = chars.by_ref().take(2).collect();
            if let Ok(byte) = u8::from_str_radix(&hex, 16) {
                result.push(byte as char);
            }
        } else if ch == '+' {
            result.push(' ');
        } else {
            result.push(ch);
        }
    }
    result
}
