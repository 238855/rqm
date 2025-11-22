// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

use crate::{Error, RequirementConfig, Result};
use std::fs;
use std::path::Path;

/// YAML parser for requirement files
pub struct Parser;

impl Parser {
    /// Parse a YAML file into a RequirementConfig
    pub fn parse_file<P: AsRef<Path>>(path: P) -> Result<RequirementConfig> {
        let content = fs::read_to_string(path)?;
        Self::parse_str(&content)
    }

    /// Parse a YAML string into a RequirementConfig
    pub fn parse_str(content: &str) -> Result<RequirementConfig> {
        serde_yaml::from_str(content).map_err(Error::enhance_yaml_error)
    }

    /// Serialize a RequirementConfig to YAML string
    pub fn to_yaml(config: &RequirementConfig) -> Result<String> {
        let yaml = serde_yaml::to_string(config)?;
        Ok(yaml)
    }

    /// Write a RequirementConfig to a YAML file
    pub fn write_file<P: AsRef<Path>>(path: P, config: &RequirementConfig) -> Result<()> {
        let yaml = Self::to_yaml(config)?;
        fs::write(path, yaml)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Requirement;

    #[test]
    fn test_parse_simple_yaml() {
        let yaml = r#"
version: "1.0"
requirements:
  - summary: Test Requirement
    description: A test requirement
"#;

        let config = Parser::parse_str(yaml).unwrap();
        assert_eq!(config.version, "1.0");
        assert_eq!(config.requirements.len(), 1);
        assert_eq!(config.requirements[0].summary, "Test Requirement");
    }

    #[test]
    fn test_parse_with_aliases() {
        let yaml = r#"
version: "1.0"
aliases:
  - alias: john
    email: john@example.com
requirements:
  - summary: Test
    owner: john
"#;

        let config = Parser::parse_str(yaml).unwrap();
        assert_eq!(config.aliases.len(), 1);
        assert_eq!(config.aliases[0].alias, "john");
    }

    #[test]
    fn test_roundtrip() {
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![Requirement::new("Test")],
        };

        let yaml = Parser::to_yaml(&config).unwrap();
        let parsed = Parser::parse_str(&yaml).unwrap();
        assert_eq!(parsed.version, config.version);
        assert_eq!(parsed.requirements.len(), 1);
    }

    #[test]
    fn test_parse_invalid_yaml() {
        let yaml = "invalid: yaml: [unclosed";
        let result = Parser::parse_str(yaml);
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_empty_string() {
        let yaml = "";
        let result = Parser::parse_str(yaml);
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_with_nested_requirements() {
        let yaml = r#"
version: "1.0"
requirements:
  - summary: Parent
    owner: test@example.com
    requirements:
      - summary: Child
        owner: test@example.com
"#;

        let config = Parser::parse_str(yaml).unwrap();
        assert_eq!(config.requirements.len(), 1);
        assert_eq!(config.requirements[0].requirements.len(), 1);
    }

    #[test]
    fn test_to_yaml() {
        let mut req = Requirement::new("Test Requirement");
        req.owner = Some(crate::types::OwnerReference::String("test@example.com".to_string()));
        req.status = Some(crate::types::Status::Draft);

        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![req],
        };

        let yaml = Parser::to_yaml(&config).unwrap();
        assert!(yaml.contains("Test Requirement"));
        assert!(yaml.contains("test@example.com"));
        assert!(yaml.contains("draft"));
    }

    #[test]
    fn test_parse_file_not_found() {
        let result = Parser::parse_file("nonexistent_file.yml");
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_with_all_fields() {
        let yaml = r#"
version: "1.0"
requirements:
  - summary: Complete Requirement
    name: REQ-001
    description: A complete requirement with all fields
    justification: Testing purposes
    acceptance_test: Should parse correctly
    acceptance_test_link: https://example.com/test
    owner: test@example.com
    priority: high
    status: implemented
    tags:
      - test
      - complete
    further_information:
      - https://example.com/docs
"#;

        let config = Parser::parse_str(yaml).unwrap();
        let req = &config.requirements[0];
        
        assert_eq!(req.summary, "Complete Requirement");
        assert_eq!(req.name, Some("REQ-001".to_string()));
        assert!(req.description.is_some());
        assert!(req.justification.is_some());
        assert!(req.acceptance_test.is_some());
        assert!(req.acceptance_test_link.is_some());
        assert_eq!(req.priority, Some(crate::types::Priority::High));
        assert_eq!(req.status, Some(crate::types::Status::Implemented));
        assert_eq!(req.tags.len(), 2);
        assert_eq!(req.further_information.len(), 1);
    }
}

