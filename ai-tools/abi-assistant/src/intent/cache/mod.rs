use crate::intent::Intent;
use lru::LruCache;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, RwLock};
use std::time::{Duration, Instant};
use std::num::NonZeroUsize;

/// Cached intent entry
#[derive(Debug, Clone)]
pub struct CachedIntent {
    pub intent: Intent,
    pub timestamp: Instant,
    pub hit_count: u32,
}

/// Intent cache with LRU eviction and TTL
pub struct IntentCache {
    store: Arc<RwLock<LruCache<String, CachedIntent>>>,
    ttl: Duration,
    normalizer: QueryNormalizer,
}

impl IntentCache {
    pub fn new(max_entries: usize, ttl_seconds: u64) -> Self {
        let cache_size = NonZeroUsize::new(max_entries).unwrap_or(NonZeroUsize::new(1000).unwrap());
        
        Self {
            store: Arc::new(RwLock::new(LruCache::new(cache_size))),
            ttl: Duration::from_secs(ttl_seconds),
            normalizer: QueryNormalizer::new(),
        }
    }
    
    /// Get an intent from cache if it exists and is not expired
    pub fn get(&self, query: &str) -> Option<Intent> {
        let normalized = self.normalizer.normalize(query);
        let mut cache = self.store.write().unwrap();
        
        if let Some(entry) = cache.get_mut(&normalized) {
            if entry.timestamp.elapsed() < self.ttl {
                entry.hit_count += 1;
                return Some(entry.intent.clone());
            } else {
                // Entry expired, remove it
                cache.pop(&normalized);
            }
        }
        
        None
    }
    
    /// Store an intent in the cache
    pub fn put(&self, query: &str, intent: Intent) {
        let normalized = self.normalizer.normalize(query);
        let entry = CachedIntent {
            intent,
            timestamp: Instant::now(),
            hit_count: 0,
        };
        
        let mut cache = self.store.write().unwrap();
        cache.put(normalized, entry);
    }
    
    /// Clear all entries from the cache
    pub fn clear(&self) {
        let mut cache = self.store.write().unwrap();
        cache.clear();
    }
    
    /// Get cache statistics
    pub fn stats(&self) -> CacheStats {
        let cache = self.store.read().unwrap();
        let mut total_hits = 0;
        let mut expired_count = 0;
        
        for (_, entry) in cache.iter() {
            total_hits += entry.hit_count;
            if entry.timestamp.elapsed() >= self.ttl {
                expired_count += 1;
            }
        }
        
        CacheStats {
            total_entries: cache.len(),
            total_hits,
            expired_entries: expired_count,
            capacity: cache.cap().get(),
        }
    }
}

/// Query normalizer for consistent cache keys
pub struct QueryNormalizer {
    stop_words: Vec<String>,
}

impl Default for QueryNormalizer {
    fn default() -> Self {
        Self {
            stop_words: vec![
                "i".to_string(),
                "want".to_string(),
                "to".to_string(),
                "for".to_string(),
                "please".to_string(),
                "can".to_string(),
                "you".to_string(),
                "would".to_string(),
                "like".to_string(),
            ],
        }
    }
}

impl QueryNormalizer {
    pub fn new() -> Self {
        Self::default()
    }
    
    /// Normalize a query for use as a cache key
    pub fn normalize(&self, query: &str) -> String {
        let mut normalized = query.to_lowercase();
        
        // Remove punctuation
        normalized = normalized
            .chars()
            .map(|c| if c.is_alphanumeric() || c.is_whitespace() { c } else { ' ' })
            .collect();
        
        // Remove stop words and normalize whitespace
        let words: Vec<String> = normalized
            .split_whitespace()
            .filter(|word| !self.stop_words.contains(&word.to_string()))
            .map(|word| self.normalize_token(word))
            .collect();
        
        words.join(" ")
    }
    
    fn normalize_token(&self, token: &str) -> String {
        // Normalize common token variations
        match token {
            "ethereum" | "ether" => "eth".to_string(),
            "bitcoin" => "btc".to_string(),
            "dollars" | "dollar" | "usd" => "usdc".to_string(),
            _ => token.to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheStats {
    pub total_entries: usize,
    pub total_hits: u32,
    pub expired_entries: usize,
    pub capacity: usize,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::intent::IntentCategory;
    use std::collections::HashMap;
    use std::thread;
    
    #[test]
    fn test_cache_basic_operations() {
        let cache = IntentCache::new(100, 60);
        
        let intent = Intent {
            raw_text: "swap 100 USDC for ETH".to_string(),
            category: IntentCategory::Swap,
            confidence: 0.9,
            parameters: HashMap::new(),
            suggested_protocols: vec![],
        };
        
        // Store intent
        cache.put("swap 100 USDC for ETH", intent.clone());
        
        // Retrieve intent
        let cached = cache.get("swap 100 USDC for ETH");
        assert!(cached.is_some());
        assert_eq!(cached.unwrap().category, IntentCategory::Swap);
        
        // Test normalization - should still find it
        let cached_normalized = cache.get("I want to swap 100 USDC for ETH");
        assert!(cached_normalized.is_some());
    }
    
    #[test]
    fn test_cache_expiration() {
        let cache = IntentCache::new(100, 1); // 1 second TTL
        
        let intent = Intent {
            raw_text: "test".to_string(),
            category: IntentCategory::Query,
            confidence: 1.0,
            parameters: HashMap::new(),
            suggested_protocols: vec![],
        };
        
        cache.put("test", intent);
        assert!(cache.get("test").is_some());
        
        // Wait for expiration
        thread::sleep(Duration::from_secs(2));
        assert!(cache.get("test").is_none());
    }
    
    #[test]
    fn test_query_normalizer() {
        let normalizer = QueryNormalizer::new();
        
        assert_eq!(
            normalizer.normalize("I want to swap 100 USDC for ETH"),
            "swap 100 usdc eth"
        );
        
        assert_eq!(
            normalizer.normalize("Can you please swap 100 dollars for Ethereum?"),
            "swap 100 usdc eth"
        );
        
        assert_eq!(
            normalizer.normalize("SWAP 100 USDC FOR ETH!!!"),
            "swap 100 usdc eth"
        );
    }
}