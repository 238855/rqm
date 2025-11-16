// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

use crate::{Error, RequirementConfig, Result};
use jsonschema::JSONSchema;
use serde_json::Value;
use std::collections::HashSet;

/// Validator for requirement files
pub struct Validator {
    schema: JSONSchema,
}

impl Validator {
    /// Create a new validator with the embedded schema
    pub fn new() -> Result<Self> {
        let schema_json = include_str!("../../docs/schema.json");
        let schema: Value = serde_json::from_str(schema_json)
            .map_err(|e| Error::custom(format!("Failed to parse schema: {}", e)))?;

        let compiled = JSONSchema::compile(&schema)
            .map_err(|e| Error::custom(format!("Failed to compile schema: {}", e)))?;

        Ok(Self { schema: compiled })
    }

    /// Validate a RequirementConfig against the schema
    pub fn validate(&self, config: &RequirementConfig) -> Result<()> {
        // Convert to JSON for validation
        let json = serde_json::to_value(config)
            .map_err(|e| Error::custom(format!("Failed to convert to JSON: {}", e)))?;

        // Validate against schema
        if let Err(errors) = self.schema.validate(&json) {
            let error_messages: Vec<String> = errors.map(|e| format!("{}", e)).collect();
            return Err(Error::SchemaValidation(error_messages.join("; ")));
        }

        // Additional validation
        self.validate_unique_summaries(config)?;
        self.validate_owner_references(config)?;

        Ok(())
    }

    /// Ensure all summaries are unique
    fn validate_unique_summaries(&self, config: &RequirementConfig) -> Result<()> {
        let mut seen = HashSet::new();

        for req in config.all_requirements() {
            if !seen.insert(&req.summary) {
                return Err(Error::DuplicateSummary(req.summary.clone()));
            }
        }

        Ok(())
    }

    /// Validate owner references point to valid aliases or are valid formats
    fn validate_owner_references(&self, config: &RequirementConfig) -> Result<()> {
        let alias_map = config.alias_map();

        for req in config.all_requirements() {
            if let Some(owner) = &req.owner {
                let owner_str = owner.as_str();

                // Check if it's an email, GitHub username, or valid alias
                if !owner.is_email() && !owner.is_github() && !alias_map.contains_key(owner_str) {
                    return Err(Error::InvalidOwner(format!(
                        "'{}' is not a valid email, GitHub username, or defined alias",
                        owner_str
                    )));
                }
            }
        }

        Ok(())
    }
}

impl Default for Validator {
    fn default() -> Self {
        Self::new().expect("Failed to create default validator")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{OwnerReference, PersonAlias, Requirement};

    #[test]
    fn test_validate_simple_config() {
        let validator = Validator::new().unwrap();
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![Requirement::new("Test")],
        };

        assert!(validator.validate(&config).is_ok());
    }

    #[test]
    fn test_duplicate_summary() {
        let validator = Validator::new().unwrap();
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![Requirement::new("Test"), Requirement::new("Test")],
        };

        let result = validator.validate(&config);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), Error::DuplicateSummary(_)));
    }

    #[test]
    fn test_valid_alias_owner() {
        let validator = Validator::new().unwrap();
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![PersonAlias {
                alias: "john".to_string(),
                name: None,
                email: None,
                github: None,
            }],
            requirements: vec![{
                let mut req = Requirement::new("Test");
                req.owner = Some(OwnerReference::String("john".to_string()));
                req
            }],
        };

        assert!(validator.validate(&config).is_ok());
    }

    #[test]
    fn test_invalid_alias_owner() {
        let validator = Validator::new().unwrap();
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![{
                let mut req = Requirement::new("Test");
                req.owner = Some(OwnerReference::String("nonexistent".to_string()));
                req
            }],
        };

        let result = validator.validate(&config);
        assert!(result.is_err());
    }

    #[test]
    fn test_email_owner() {
        let validator = Validator::new().unwrap();
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![{
                let mut req = Requirement::new("Test");
                req.owner = Some(OwnerReference::String("test@example.com".to_string()));
                req
            }],
        };

        assert!(validator.validate(&config).is_ok());
    }
}
