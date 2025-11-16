//! Metadata management for requirements
//!
//! This module handles the persistent metadata storage for requirements,
//! including UUID generation, ID assignment, and tracking changes.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use uuid::Uuid;

use crate::error::Error;
use crate::types::Requirement;

/// Metadata for a single requirement
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RequirementMetadata {
    /// Stable UUID for tracking across refactors
    pub uuid: Uuid,
    
    /// Auto-generated ID (e.g., "RQM-001")
    pub generated_id: String,
    
    /// Hash of the summary for change detection
    pub summary_hash: String,
    
    /// When this requirement was first created
    pub created_at: DateTime<Utc>,
    
    /// When this requirement was last updated
    pub updated_at: DateTime<Utc>,
    
    /// Original summary text
    pub summary: String,
}

/// Configuration for a project's ID generation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectConfig {
    /// Prefix for generated IDs (e.g., "RQM")
    pub project_prefix: String,
    
    /// Next sequential ID number
    pub next_id: u32,
}

impl ProjectConfig {
    /// Create a new project configuration
    pub fn new(prefix: String) -> Self {
        Self {
            project_prefix: prefix,
            next_id: 1,
        }
    }
    
    /// Generate the next ID and increment the counter
    pub fn next_id(&mut self) -> String {
        let id = format!("{}-{:03}", self.project_prefix, self.next_id);
        self.next_id += 1;
        id
    }
}

/// Metadata store for managing requirement metadata
pub struct MetadataStore {
    metadata_dir: PathBuf,
    config_path: PathBuf,
    metadata_cache: HashMap<String, RequirementMetadata>,
    project_config: ProjectConfig,
}

impl MetadataStore {
    /// Create a new metadata store
    pub fn new<P: AsRef<Path>>(rqm_dir: P) -> Result<Self, Error> {
        let rqm_path = rqm_dir.as_ref();
        let metadata_dir = rqm_path.join(".metadata");
        let config_path = rqm_path.join("config.yml");
        
        // Load or create project config
        let project_config = if config_path.exists() {
            let content = fs::read_to_string(&config_path)?;
            serde_yaml::from_str(&content)
                .map_err(|e| Error::SchemaValidation(e.to_string()))?
        } else {
            ProjectConfig::new("REQ".to_string())
        };
        
        // Create metadata directory if it doesn't exist
        if !metadata_dir.exists() {
            fs::create_dir_all(&metadata_dir)?;
        }
        
        Ok(Self {
            metadata_dir,
            config_path,
            metadata_cache: HashMap::new(),
            project_config,
        })
    }
    
    /// Initialize a new project with the given prefix
    pub fn init<P: AsRef<Path>>(rqm_dir: P, prefix: String) -> Result<Self, Error> {
        let rqm_path = rqm_dir.as_ref();
        
        // Create .rqm directory if needed
        if !rqm_path.exists() {
            fs::create_dir_all(rqm_path)?;
        }
        
        let config_path = rqm_path.join("config.yml");
        let config = ProjectConfig::new(prefix);
        
        // Write config
        let yaml = serde_yaml::to_string(&config)
            .map_err(|e| Error::SchemaValidation(e.to_string()))?;
        fs::write(&config_path, yaml)?;
        
        Self::new(rqm_dir)
    }
    
    /// Save the project configuration
    pub fn save_config(&self) -> Result<(), Error> {
        let yaml = serde_yaml::to_string(&self.project_config)
            .map_err(|e| Error::SchemaValidation(e.to_string()))?;
        fs::write(&self.config_path, yaml)?;
        Ok(())
    }
    
    /// Get or create metadata for a requirement
    pub fn get_or_create_metadata(&mut self, req: &Requirement) -> Result<RequirementMetadata, Error> {
        let kebab_id = kebab_case(&req.summary);
        
        // Check cache first
        if let Some(meta) = self.metadata_cache.get(&kebab_id) {
            return Ok(meta.clone());
        }
        
        // Try to load from disk
        let meta_path = self.metadata_dir.join(format!("{}.json", kebab_id));
        
        if meta_path.exists() {
            let content = fs::read_to_string(&meta_path)?;
            let mut meta: RequirementMetadata = serde_json::from_str(&content)
                .map_err(|e| Error::SchemaValidation(e.to_string()))?;
            
            // Check if summary changed
            let current_hash = hash_string(&req.summary);
            if meta.summary_hash != current_hash {
                meta.summary = req.summary.clone();
                meta.summary_hash = current_hash;
                meta.updated_at = Utc::now();
            }
            
            self.metadata_cache.insert(kebab_id, meta.clone());
            Ok(meta)
        } else {
            // Create new metadata
            let generated_id = self.project_config.next_id();
            let meta = RequirementMetadata {
                uuid: Uuid::new_v4(),
                generated_id,
                summary_hash: hash_string(&req.summary),
                created_at: Utc::now(),
                updated_at: Utc::now(),
                summary: req.summary.clone(),
            };
            
            // Save to disk
            let json = serde_json::to_string_pretty(&meta)
                .map_err(|e| Error::SchemaValidation(e.to_string()))?;
            fs::write(&meta_path, json)?;
            
            // Update config with new next_id
            self.save_config()?;
            
            self.metadata_cache.insert(kebab_id, meta.clone());
            Ok(meta)
        }
    }
    
    /// Get the generated ID for a requirement
    pub fn get_generated_id(&mut self, req: &Requirement) -> Result<String, Error> {
        let meta = self.get_or_create_metadata(req)?;
        Ok(meta.generated_id)
    }
}

/// Convert a string to kebab-case
pub fn kebab_case(s: &str) -> String {
    s.to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .split('-')
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("-")
}

/// Simple hash function for change detection
fn hash_string(s: &str) -> String {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    
    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    format!("{:x}", hasher.finish())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_kebab_case() {
        assert_eq!(kebab_case("Hello World"), "hello-world");
        assert_eq!(kebab_case("Automatic ID Generation"), "automatic-id-generation");
        assert_eq!(kebab_case("Test-Case"), "test-case");
        assert_eq!(kebab_case("Multiple   Spaces"), "multiple-spaces");
    }

    #[test]
    fn test_project_config_next_id() {
        let mut config = ProjectConfig::new("TEST".to_string());
        assert_eq!(config.next_id(), "TEST-001");
        assert_eq!(config.next_id(), "TEST-002");
        assert_eq!(config.next_id(), "TEST-003");
    }

    #[test]
    fn test_metadata_store_init() {
        let temp = TempDir::new().unwrap();
        let rqm_dir = temp.path().join(".rqm");
        
        let store = MetadataStore::init(&rqm_dir, "PROJ".to_string()).unwrap();
        assert_eq!(store.project_config.project_prefix, "PROJ");
        assert_eq!(store.project_config.next_id, 1);
        
        // Verify config file was created
        assert!(rqm_dir.join("config.yml").exists());
    }

    #[test]
    fn test_metadata_creation() {
        let temp = TempDir::new().unwrap();
        let rqm_dir = temp.path().join(".rqm");
        let mut store = MetadataStore::init(&rqm_dir, "TEST".to_string()).unwrap();
        
        let req = Requirement::new("Test Requirement");
        
        let meta = store.get_or_create_metadata(&req).unwrap();
        assert_eq!(meta.generated_id, "TEST-001");
        assert_eq!(meta.summary, "Test Requirement");
        
        // Verify metadata file exists
        let meta_path = rqm_dir.join(".metadata/test-requirement.json");
        assert!(meta_path.exists());
    }

    #[test]
    fn test_metadata_persistence() {
        let temp = TempDir::new().unwrap();
        let rqm_dir = temp.path().join(".rqm");
        
        let req = Requirement::new("Persistent Requirement");
        
        // Create metadata in first store
        let uuid = {
            let mut store = MetadataStore::init(&rqm_dir, "PERS".to_string()).unwrap();
            let meta = store.get_or_create_metadata(&req).unwrap();
            meta.uuid
        };
        
        // Load metadata in second store
        {
            let mut store = MetadataStore::new(&rqm_dir).unwrap();
            let meta = store.get_or_create_metadata(&req).unwrap();
            assert_eq!(meta.uuid, uuid);
            assert_eq!(meta.generated_id, "PERS-001");
        }
    }
}
