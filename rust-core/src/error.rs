// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

use thiserror::Error;

/// Result type for RQM operations
pub type Result<T> = std::result::Result<T, Error>;

/// Error types for RQM operations
#[derive(Error, Debug)]
pub enum Error {
    #[error("YAML parsing error: {0}")]
    YamlError(#[from] serde_yaml::Error),

    #[error("JSON schema validation error: {0}")]
    SchemaValidation(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Requirement not found: {0}")]
    RequirementNotFound(String),

    #[error("Circular reference detected: {0}")]
    CircularReference(String),

    #[error("Invalid reference: {0}")]
    InvalidReference(String),

    #[error("Duplicate summary: {0}")]
    DuplicateSummary(String),

    #[error("Invalid owner reference: {0}")]
    InvalidOwner(String),

    #[error("Graph error: {0}")]
    GraphError(String),

    #[error("{0}")]
    Custom(String),
}

impl Error {
    /// Create a custom error
    pub fn custom(msg: impl Into<String>) -> Self {
        Error::Custom(msg.into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_custom_error() {
        let err = Error::custom("test error");
        assert_eq!(err.to_string(), "test error");
    }

    #[test]
    fn test_schema_validation_error() {
        let err = Error::SchemaValidation("invalid schema".to_string());
        assert!(err.to_string().contains("schema validation"));
    }

    #[test]
    fn test_requirement_not_found() {
        let err = Error::RequirementNotFound("REQ-001".to_string());
        assert!(err.to_string().contains("REQ-001"));
        assert!(err.to_string().contains("not found"));
    }

    #[test]
    fn test_circular_reference_error() {
        let err = Error::CircularReference("A -> B -> A".to_string());
        assert!(err.to_string().contains("Circular reference"));
        assert!(err.to_string().contains("A -> B -> A"));
    }

    #[test]
    fn test_invalid_reference_error() {
        let err = Error::InvalidReference("unknown ref".to_string());
        assert!(err.to_string().contains("Invalid reference"));
    }

    #[test]
    fn test_duplicate_summary_error() {
        let err = Error::DuplicateSummary("Test Summary".to_string());
        assert!(err.to_string().contains("Duplicate"));
        assert!(err.to_string().contains("Test Summary"));
    }

    #[test]
    fn test_invalid_owner_error() {
        let err = Error::InvalidOwner("@unknown".to_string());
        assert!(err.to_string().contains("Invalid owner"));
    }

    #[test]
    fn test_graph_error() {
        let err = Error::GraphError("cycle detected".to_string());
        assert!(err.to_string().contains("Graph error"));
    }

    #[test]
    fn test_yaml_error_from() {
        let yaml_err = serde_yaml::from_str::<String>("invalid: yaml: syntax");
        match yaml_err {
            Err(e) => {
                let err: Error = e.into();
                assert!(err.to_string().contains("YAML parsing"));
            }
            Ok(_) => panic!("Expected YAML error"),
        }
    }

    #[test]
    fn test_io_error_from() {
        let io_err = std::io::Error::new(std::io::ErrorKind::NotFound, "file not found");
        let err: Error = io_err.into();
        assert!(err.to_string().contains("IO error"));
    }
}
