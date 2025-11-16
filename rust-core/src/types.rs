// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Top-level configuration for a requirements file
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RequirementConfig {
    /// Schema version
    pub version: String,

    /// Person aliases for ownership
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub aliases: Vec<PersonAlias>,

    /// Top-level requirements
    pub requirements: Vec<Requirement>,
}

impl RequirementConfig {
    /// Get a map of aliases for quick lookup
    pub fn alias_map(&self) -> HashMap<String, &PersonAlias> {
        self.aliases
            .iter()
            .map(|alias| (alias.alias.clone(), alias))
            .collect()
    }

    /// Flatten all requirements into a single list
    pub fn all_requirements(&self) -> Vec<&Requirement> {
        let mut all = Vec::new();
        for req in &self.requirements {
            all.extend(req.flatten());
        }
        all
    }
}

/// Person alias for requirement ownership
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PersonAlias {
    /// Short alias identifier
    pub alias: String,

    /// Full name of the person
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,

    /// Email address
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,

    /// GitHub username
    #[serde(skip_serializing_if = "Option::is_none")]
    pub github: Option<String>,
}

/// Owner reference (email, GitHub username, or alias)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(untagged)]
pub enum OwnerReference {
    String(String),
}

impl OwnerReference {
    /// Check if this is an email reference
    pub fn is_email(&self) -> bool {
        match self {
            OwnerReference::String(s) => s.contains('@') && !s.starts_with('@'),
        }
    }

    /// Check if this is a GitHub username reference
    pub fn is_github(&self) -> bool {
        match self {
            OwnerReference::String(s) => s.starts_with('@'),
        }
    }

    /// Get the string value
    pub fn as_str(&self) -> &str {
        match self {
            OwnerReference::String(s) => s,
        }
    }
}

/// Priority level for requirements
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Priority {
    Critical,
    High,
    Medium,
    Low,
}

/// Status of a requirement
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Draft,
    Proposed,
    Approved,
    Implemented,
    Verified,
    Deprecated,
}

/// A single requirement or reference to a requirement
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(untagged)]
pub enum RequirementReference {
    /// Full requirement definition
    Full(Box<Requirement>),

    /// Reference by summary
    Reference(String),
}

/// A single requirement
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Requirement {
    /// Short, unique identifier (required)
    pub summary: String,

    /// Optional human-friendly name or ID
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,

    /// Detailed description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// Rationale for the requirement
    #[serde(skip_serializing_if = "Option::is_none")]
    pub justification: Option<String>,

    /// Acceptance criteria text
    #[serde(skip_serializing_if = "Option::is_none")]
    pub acceptance_test: Option<String>,

    /// URL to acceptance test documentation
    #[serde(skip_serializing_if = "Option::is_none")]
    pub acceptance_test_link: Option<String>,

    /// Owner reference
    #[serde(skip_serializing_if = "Option::is_none")]
    pub owner: Option<OwnerReference>,

    /// Child requirements
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub requirements: Vec<RequirementReference>,

    /// Additional information
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub further_information: Vec<String>,

    /// Tags for categorization
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<String>,

    /// Priority level
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<Priority>,

    /// Current status
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status: Option<Status>,

    /// Creation timestamp
    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<String>,

    /// Last update timestamp
    #[serde(skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<String>,
}

impl Requirement {
    /// Create a new requirement with just a summary
    pub fn new(summary: impl Into<String>) -> Self {
        Self {
            summary: summary.into(),
            name: None,
            description: None,
            justification: None,
            acceptance_test: None,
            acceptance_test_link: None,
            owner: None,
            requirements: Vec::new(),
            further_information: Vec::new(),
            tags: Vec::new(),
            priority: None,
            status: None,
            created_at: None,
            updated_at: None,
        }
    }

    /// Flatten this requirement and all children into a list
    pub fn flatten(&self) -> Vec<&Requirement> {
        let mut result = vec![self];
        for child in &self.requirements {
            if let RequirementReference::Full(req) = child {
                result.extend(req.flatten());
            }
        }
        result
    }

    /// Get the ID (name or summary)
    pub fn id(&self) -> &str {
        self.name.as_deref().unwrap_or(&self.summary)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_requirement_new() {
        let req = Requirement::new("Test Requirement");
        assert_eq!(req.summary, "Test Requirement");
        assert!(req.description.is_none());
    }

    #[test]
    fn test_owner_reference_email() {
        let owner = OwnerReference::String("test@example.com".to_string());
        assert!(owner.is_email());
        assert!(!owner.is_github());
    }

    #[test]
    fn test_owner_reference_github() {
        let owner = OwnerReference::String("@username".to_string());
        assert!(!owner.is_email());
        assert!(owner.is_github());
    }

    #[test]
    fn test_requirement_flatten() {
        let child = Requirement::new("Child");
        let mut parent = Requirement::new("Parent");
        parent
            .requirements
            .push(RequirementReference::Full(Box::new(child)));

        let flattened = parent.flatten();
        assert_eq!(flattened.len(), 2);
        assert_eq!(flattened[0].summary, "Parent");
        assert_eq!(flattened[1].summary, "Child");
    }

    #[test]
    fn test_config_alias_map() {
        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![PersonAlias {
                alias: "john".to_string(),
                name: Some("John Doe".to_string()),
                email: Some("john@example.com".to_string()),
                github: None,
            }],
            requirements: vec![],
        };

        let map = config.alias_map();
        assert!(map.contains_key("john"));
        assert_eq!(
            map.get("john").unwrap().email,
            Some("john@example.com".to_string())
        );
    }
}
