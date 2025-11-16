//! RQM Validator CLI
//!
//! Standalone binary for validating requirements YAML files.
//! Designed to be called by the Go CLI and other language bindings.

use rqm_core::{Parser, Validator};
use serde::{Deserialize, Serialize};
use std::env;
use std::process;

#[derive(Debug, Serialize, Deserialize)]
struct ValidationResult {
    valid: bool,
    errors: Vec<String>,
    warnings: Vec<String>,
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: {} <requirements.yml>", args[0]);
        process::exit(1);
    }
    
    let file_path = &args[1];
    
    // Parse the file
    let config = match Parser::parse_file(file_path) {
        Ok(cfg) => cfg,
        Err(e) => {
            let result = ValidationResult {
                valid: false,
                errors: vec![format!("Parse error: {}", e)],
                warnings: vec![],
            };
            println!("{}", serde_json::to_string_pretty(&result).unwrap());
            process::exit(1);
        }
    };
    
    // Create validator
    let validator = match Validator::new() {
        Ok(v) => v,
        Err(e) => {
            let result = ValidationResult {
                valid: false,
                errors: vec![format!("Validator initialization error: {}", e)],
                warnings: vec![],
            };
            println!("{}", serde_json::to_string_pretty(&result).unwrap());
            process::exit(1);
        }
    };
    
    // Validate
    let result = match validator.validate(&config) {
        Ok(_) => ValidationResult {
            valid: true,
            errors: vec![],
            warnings: vec![],
        },
        Err(e) => ValidationResult {
            valid: false,
            errors: vec![format!("{}", e)],
            warnings: vec![],
        },
    };
    
    // Output JSON result
    println!("{}", serde_json::to_string_pretty(&result).unwrap());
    
    if !result.valid {
        process::exit(1);
    }
}
