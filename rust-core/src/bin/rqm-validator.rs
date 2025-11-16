//! RQM Validator CLI
//!
//! Standalone binary for validating requirements YAML files.
//! Designed to be called by the Go CLI and other language bindings.

use rqm_core::types::RequirementReference;
use rqm_core::{Parser, RequirementGraph, Validator};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::env;
use std::process;

#[derive(Debug, Serialize, Deserialize)]
struct ValidationResult {
    valid: bool,
    errors: Vec<String>,
    warnings: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct CycleCheckResult {
    has_cycles: bool,
    cycles: Vec<Vec<String>>,
    graph: HashMap<String, Vec<String>>,
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: {} <requirements.yml> [--format json-full | --check-cycles | --graph]", args[0]);
        process::exit(1);
    }
    
    let file_path = &args[1];
    
    // Check for flags
    let output_full = args.len() > 3 && args[2] == "--format" && args[3] == "json-full";
    let check_cycles = args.len() > 2 && args[2] == "--check-cycles";
    let output_graph = args.len() > 2 && args[2] == "--graph";
    
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
    
    // If --format json-full, output the parsed config and exit
    if output_full {
        println!("{}", serde_json::to_string_pretty(&config).unwrap());
        return;
    }
    
    // If --check-cycles or --graph, build graph and check for cycles
    if check_cycles || output_graph {
        let graph = match RequirementGraph::from_config(&config) {
            Ok(g) => g,
            Err(e) => {
                let result = CycleCheckResult {
                    has_cycles: false,
                    cycles: vec![],
                    graph: HashMap::new(),
                };
                println!("{}", serde_json::to_string_pretty(&result).unwrap());
                eprintln!("Error building graph: {}", e);
                process::exit(1);
            }
        };
        
        let cycles = graph.find_cycles();
        let has_cycles = !cycles.is_empty();
        
        // Build adjacency map for graph output
        let mut adj_map: HashMap<String, Vec<String>> = HashMap::new();
        for req in &config.requirements {
            collect_graph_edges(req, &mut adj_map);
        }
        
        let result = CycleCheckResult {
            has_cycles,
            cycles,
            graph: adj_map,
        };
        
        println!("{}", serde_json::to_string_pretty(&result).unwrap());
        
        if has_cycles && check_cycles {
            process::exit(1);
        }
        return;
    }
    
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

// Helper function to collect graph edges from requirements
fn collect_graph_edges(req: &rqm_core::Requirement, adj_map: &mut HashMap<String, Vec<String>>) {
    let mut deps = Vec::new();
    
    for child in &req.requirements {
        match child {
            RequirementReference::Full(full_req) => {
                deps.push(full_req.summary.clone());
                collect_graph_edges(full_req, adj_map);
            }
            RequirementReference::Reference(summary) => {
                deps.push(summary.clone());
            }
        }
    }
    
    adj_map.insert(req.summary.clone(), deps);
}
