use anyhow::Result;
use regex::Regex;
use std::collections::HashMap;

/// Simple template engine for prompt variable substitution
pub struct TemplateEngine {
    variable_pattern: Regex,
}

impl TemplateEngine {
    pub fn new() -> Self {
        Self {
            // Matches {{VARIABLE_NAME}} patterns
            variable_pattern: Regex::new(r"\{\{([A-Z0-9_]+)\}\}").unwrap(),
        }
    }
    
    /// Replace template variables with actual values
    pub fn render(&self, template: &str, context: &HashMap<String, String>) -> String {
        let mut result = template.to_string();
        
        for capture in self.variable_pattern.captures_iter(template) {
            if let Some(var_name) = capture.get(1) {
                let var_name_str = var_name.as_str();
                if let Some(value) = context.get(var_name_str) {
                    let pattern = format!("{{{{{}}}}}", var_name_str);
                    result = result.replace(&pattern, value);
                }
            }
        }
        
        result
    }
    
    /// Extract all variable names from a template
    pub fn extract_variables(&self, template: &str) -> Vec<String> {
        self.variable_pattern
            .captures_iter(template)
            .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
            .collect()
    }
    
    /// Validate that all required variables are present in context
    pub fn validate_context(&self, template: &str, context: &HashMap<String, String>) -> Result<()> {
        let required_vars = self.extract_variables(template);
        
        for var in required_vars {
            if !context.contains_key(&var) {
                anyhow::bail!("Missing required template variable: {}", var);
            }
        }
        
        Ok(())
    }
}

impl Default for TemplateEngine {
    fn default() -> Self {
        Self::new()
    }
}

/// Builder for creating context with common DeFi variables
pub struct ContextBuilder {
    context: HashMap<String, String>,
}

impl Default for ContextBuilder {
    fn default() -> Self {
        Self {
            context: HashMap::new(),
        }
    }
}

impl ContextBuilder {
    pub fn new() -> Self {
        Self::default()
    }
    
    pub fn with_chain_id(mut self, chain_id: u32) -> Self {
        self.context.insert("CHAIN_ID".to_string(), chain_id.to_string());
        self
    }
    
    pub fn with_user_address(mut self, address: &str) -> Self {
        self.context.insert("USER_ADDRESS".to_string(), address.to_string());
        self
    }
    
    pub fn with_gas_price(mut self, gas_price: u64) -> Self {
        self.context.insert("GAS_PRICE".to_string(), gas_price.to_string());
        self
    }
    
    pub fn with_protocols(mut self, protocols: &[String]) -> Self {
        self.context.insert(
            "AVAILABLE_PROTOCOLS".to_string(), 
            serde_json::to_string(protocols).unwrap_or_default()
        );
        self
    }
    
    pub fn with_custom(mut self, key: &str, value: &str) -> Self {
        self.context.insert(key.to_uppercase(), value.to_string());
        self
    }
    
    pub fn build(self) -> HashMap<String, String> {
        self.context
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_template_rendering() {
        let engine = TemplateEngine::new();
        let mut context = HashMap::new();
        context.insert("USER_ADDRESS".to_string(), "0x123...".to_string());
        context.insert("CHAIN_ID".to_string(), "1".to_string());
        
        let template = "User {{USER_ADDRESS}} on chain {{CHAIN_ID}}";
        let result = engine.render(template, &context);
        
        assert_eq!(result, "User 0x123... on chain 1");
    }
    
    #[test]
    fn test_extract_variables() {
        let engine = TemplateEngine::new();
        let template = "{{VAR1}} and {{VAR2}} and {{VAR1}} again";
        let vars = engine.extract_variables(template);
        
        assert_eq!(vars.len(), 3); // Including duplicates
        assert!(vars.contains(&"VAR1".to_string()));
        assert!(vars.contains(&"VAR2".to_string()));
    }
    
    #[test]
    fn test_context_builder() {
        let context = ContextBuilder::new()
            .with_chain_id(1)
            .with_user_address("0xabc")
            .with_gas_price(30000000000)
            .build();
        
        assert_eq!(context.get("CHAIN_ID"), Some(&"1".to_string()));
        assert_eq!(context.get("USER_ADDRESS"), Some(&"0xabc".to_string()));
        assert_eq!(context.get("GAS_PRICE"), Some(&"30000000000".to_string()));
    }
}