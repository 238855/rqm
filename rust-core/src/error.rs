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
