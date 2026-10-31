pub mod cipher;
pub mod ytmusic;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use ytmusic::YtMusicClient;

#[no_mangle]
pub extern "C" fn ytmusic_ping() -> i32 {
    42
}

#[no_mangle]
pub extern "C" fn ytmusic_search(query: *const c_char, filter: *const c_char) -> *mut c_char {
    if query.is_null() {
        return std::ptr::null_mut();
    }
    let c_query = unsafe { CStr::from_ptr(query) };
    let query_str = match c_query.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let filter_str = if !filter.is_null() {
        unsafe { CStr::from_ptr(filter).to_str().unwrap_or("songs") }
    } else {
        "songs"
    };

    let client = YtMusicClient::new();
    match client.search(query_str, filter_str) {
        Ok(songs) => {
            let json = serde_json::to_string(&songs).unwrap_or_else(|_| "[]".to_string());
            CString::new(json).unwrap().into_raw()
        }
        Err(err) => {
            let error_json = serde_json::json!({ "error": err }).to_string();
            CString::new(error_json).unwrap().into_raw()
        }
    }
}

#[no_mangle]
pub extern "C" fn ytmusic_get_stream_url(video_id: *const c_char) -> *mut c_char {
    if video_id.is_null() {
        return std::ptr::null_mut();
    }
    let c_id = unsafe { CStr::from_ptr(video_id) };
    let id_str = match c_id.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let client = YtMusicClient::new();
    match client.get_stream_url(id_str) {
        Ok(stream_info) => {
            let json = serde_json::to_string(&stream_info).unwrap_or_else(|_| "{}".to_string());
            CString::new(json).unwrap().into_raw()
        }
        Err(err) => {
            let error_json = serde_json::json!({ "error": err }).to_string();
            CString::new(error_json).unwrap().into_raw()
        }
    }
}

#[no_mangle]
pub extern "C" fn ytmusic_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}
