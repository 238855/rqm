// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

//! # RQM Core Library
//!
//! This library provides the core functionality for RQM (Requirements Management in Code).
//! It handles YAML parsing, validation, and graph traversal of requirement hierarchies.
//!
//! ## Features
//!
//! - Parse YAML requirement files with full validation
//! - Build requirement graphs with circular reference detection
//! - Query and traverse requirement trees
//! - Export to various formats
//! - Automatic ID generation with metadata management

pub mod error;
pub mod graph;
pub mod metadata;
pub mod parser;
pub mod types;
pub mod validator;

pub use error::{Error, Result};
pub use graph::RequirementGraph;
pub use metadata::{kebab_case, MetadataStore, ProjectConfig, RequirementMetadata};
pub use parser::Parser;
pub use types::{OwnerReference, PersonAlias, Requirement, RequirementConfig};
pub use validator::Validator;

/// Version of the library
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert_eq!(VERSION, "0.1.0");
    }
}
