use super::PromptConfig;
use anyhow::{Result, Context};
use std::path::{Path, PathBuf};
use std::collections::HashMap;
use std::sync::RwLock;

/// Loads and manages prompt configurations from YAML files
pub struct PromptLoader {
    prompts_dir: PathBuf,
    cache: RwLock<HashMap<String, PromptConfig>>,
    hot_reload: bool,
}

impl PromptLoader {
    pub fn new(prompts_dir: impl AsRef<Path>, hot_reload: bool) -> Self {
        Self {
            prompts_dir: prompts_dir.as_ref().to_path_buf(),
            cache: RwLock::new(HashMap::new()),
            hot_reload,
        }
    }
    
    /// Load a prompt configuration by name
    pub fn load_prompt(&self, name: &str) -> Result<PromptConfig> {
        // Check cache first if hot reload is disabled
        if !self.hot_reload {
            if let Some(cached) = self.cache.read().unwrap().get(name) {
                return Ok(cached.clone());
            }
        }
        
        // Load from file
        let path = self.build_prompt_path(name);
        let content = std::fs::read_to_string(&path)
            .with_context(|| format!("Failed to read prompt file: {:?}", path))?;
        
        let config: PromptConfig = serde_yaml::from_str(&content)
            .with_context(|| format!("Failed to parse prompt YAML: {:?}", path))?;
        
        // Cache the loaded prompt
        if !self.hot_reload {
            self.cache.write().unwrap().insert(name.to_string(), config.clone());
        }
        
        Ok(config)
    }
    
    /// Load all prompts from a directory
    pub fn load_all_prompts(&self) -> Result<HashMap<String, PromptConfig>> {
        let mut prompts = HashMap::new();
        
        let prompt_files = std::fs::read_dir(&self.prompts_dir)?;
        
        for entry in prompt_files {
            let entry = entry?;
            let path = entry.path();
            
            if path.extension().and_then(|s| s.to_str()) == Some("yaml") {
                if let Some(name) = path.file_stem().and_then(|s| s.to_str()) {
                    match self.load_prompt(name) {
                        Ok(config) => {
                            prompts.insert(name.to_string(), config);
                        }
                        Err(e) => {
                            tracing::warn!("Failed to load prompt {}: {}", name, e);
                        }
                    }
                }
            }
        }
        
        Ok(prompts)
    }
    
    /// Build a full prompt with context injection
    pub fn build_prompt_with_context(
        &self,
        config: &PromptConfig,
        context: &HashMap<String, String>
    ) -> String {
        let mut prompt = format!("{}\n\n{}", config.system_prompt, config.task_description);
        
        // Inject context values
        for (key, _value) in &config.context_injection {
            if let Some(replacement) = context.get(key) {
                prompt = prompt.replace(&format!("{{{{{}}}}}", key), replacement);
            }
        }
        
        prompt
    }
    
    /// Validate a prompt configuration
    pub fn validate_prompt(&self, config: &PromptConfig) -> Result<()> {
        if config.version.is_empty() {
            anyhow::bail!("Prompt version is required");
        }
        
        if config.temperature < 0.0 || config.temperature > 2.0 {
            anyhow::bail!("Temperature must be between 0.0 and 2.0");
        }
        
        if config.categories.is_empty() {
            anyhow::bail!("At least one category must be defined");
        }
        
        Ok(())
    }
    
    fn build_prompt_path(&self, name: &str) -> PathBuf {
        // Handle nested paths like "gemini/intent_classifier"
        let parts: Vec<&str> = name.split('/').collect();
        let mut path = self.prompts_dir.clone();
        
        for part in parts {
            path = path.join(part);
        }
        
        path.with_extension("yaml")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::CategoryDefinition;
    use tempfile::TempDir;
    use std::fs;
    
    #[test]
    fn test_load_prompt() {
        let temp_dir = TempDir::new().unwrap();
        let prompts_dir = temp_dir.path().join("prompts");
        fs::create_dir(&prompts_dir).unwrap();
        
        // Create a test prompt file
        let test_prompt = r#"
version: "1.0"
model: "test-model"
temperature: 0.5
system_prompt: "You are a test assistant"
task_description: "Test task"
categories:
  - name: test
    description: "Test category"
    required_params: ["param1"]
    optional_params: ["param2"]
"#;
        
        fs::write(prompts_dir.join("test.yaml"), test_prompt).unwrap();
        
        let loader = PromptLoader::new(&prompts_dir, false);
        let config = loader.load_prompt("test").unwrap();
        
        assert_eq!(config.version, "1.0");
        assert_eq!(config.model, "test-model");
        assert_eq!(config.temperature, 0.5);
        assert_eq!(config.categories.len(), 1);
    }
    
    #[test]
    fn test_validate_prompt() {
        let loader = PromptLoader::new(".", false);
        
        let valid_config = PromptConfig {
            version: "1.0".to_string(),
            model: "test".to_string(),
            temperature: 0.5,
            system_prompt: "test".to_string(),
            task_description: "test".to_string(),
            categories: vec![
                CategoryDefinition {
                    name: "test".to_string(),
                    description: "test".to_string(),
                    required_params: vec![],
                    optional_params: vec![],
                }
            ],
            context_injection: HashMap::new(),
        };
        
        assert!(loader.validate_prompt(&valid_config).is_ok());
        
        let invalid_config = PromptConfig {
            temperature: 3.0, // Invalid temperature
            ..valid_config
        };
        
        assert!(loader.validate_prompt(&invalid_config).is_err());
    }
}