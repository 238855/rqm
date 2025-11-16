// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

use crate::{RequirementConfig, Result};
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
        let config: RequirementConfig = serde_yaml::from_str(content)?;
        Ok(config)
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
}
