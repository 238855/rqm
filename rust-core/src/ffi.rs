// FFI (Foreign Function Interface) for Go integration
// Provides C-compatible functions that Go can call via CGO

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use crate::validator::Validator;
use crate::parser::Parser;

/// Validate a YAML file and return JSON result
/// 
/// # Safety
/// - `yaml_content` must be a valid null-terminated C string
/// - Caller must free the returned string with `free_string`
#[no_mangle]
pub unsafe extern "C" fn validate_yaml(yaml_content: *const c_char) -> *mut c_char {
    if yaml_content.is_null() {
        return error_json("Input is null");
    }

    let c_str = unsafe { CStr::from_ptr(yaml_content) };
    let yaml_str = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return error_json("Invalid UTF-8"),
    };

    let validator = match Validator::new() {
        Ok(v) => v,
        Err(e) => return error_json(&format!("Failed to create validator: {}", e)),
    };

    let result = match Parser::parse_str(yaml_str) {
        Ok(config) => {
            match validator.validate(&config) {
                Ok(_) => {
                    serde_json::json!({
                        "valid": true,
                        "errors": [],
                        "warnings": []
                    })
                }
                Err(e) => {
                    serde_json::json!({
                        "valid": false,
                        "errors": [e.to_string()],
                        "warnings": []
                    })
                }
            }
        }
        Err(e) => {
            serde_json::json!({
                "valid": false,
                "errors": [e.to_string()],
                "warnings": []
            })
        }
    };

    let json_str = result.to_string();
    match CString::new(json_str) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => error_json("Failed to create result string"),
    }
}

/// Free a string allocated by Rust
///
/// # Safety
/// - `s` must be a string previously returned by a Rust FFI function
/// - `s` must not be used after this call
#[no_mangle]
pub unsafe extern "C" fn free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

/// Helper to create error JSON
fn error_json(message: &str) -> *mut c_char {
    let json = serde_json::json!({
        "valid": false,
        "errors": [message],
        "warnings": []
    });
    let json_str = json.to_string();
    CString::new(json_str)
        .unwrap_or_else(|_| CString::new("Internal error").unwrap())
        .into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_validate_yaml_ffi() {
        let yaml = r#"
version: "1.0"
requirements:
  - summary: Test Requirement
    name: TEST-001
    description: A test
    owner: test@example.com
"#;
        let c_yaml = CString::new(yaml).unwrap();
        let result_ptr = unsafe { validate_yaml(c_yaml.as_ptr()) };
        assert!(!result_ptr.is_null());
        
        let result_str = unsafe { CStr::from_ptr(result_ptr) };
        let result_json: serde_json::Value = serde_json::from_str(result_str.to_str().unwrap()).unwrap();
        
        assert_eq!(result_json["valid"], true);
        
        unsafe { free_string(result_ptr) };
    }

    #[test]
    fn test_validate_invalid_yaml() {
        let yaml = "invalid: [yaml";
        let c_yaml = CString::new(yaml).unwrap();
        let result_ptr = unsafe { validate_yaml(c_yaml.as_ptr()) };
        assert!(!result_ptr.is_null());
        
        let result_str = unsafe { CStr::from_ptr(result_ptr) };
        let result_json: serde_json::Value = serde_json::from_str(result_str.to_str().unwrap()).unwrap();
        
        assert_eq!(result_json["valid"], false);
        
        unsafe { free_string(result_ptr) };
    }
}
