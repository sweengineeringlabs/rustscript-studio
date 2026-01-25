//! E2E test harness with browser pooling, sharding, and multi-port support.
//!
//! This module provides efficient test execution through:
//! - Browser reuse (pages/contexts instead of new browsers)
//! - CI sharding (split tests across workers)
//! - Multi-port configuration (parallel dev servers)
//!
//! # Usage
//!
//! ```rust
//! use crate::harness::{TestHarness, test_context};
//!
//! #[tokio::test]
//! async fn test_example() {
//!     let ctx = test_context!();
//!     ctx.goto("/").await.unwrap();
//!     // ...
//! }
//! ```
//!
//! # Environment Variables
//!
//! - `RSC_TEST_PORT`: Port number (default: 3000)
//! - `RSC_TEST_SHARD_INDEX`: Current shard (0-based)
//! - `RSC_TEST_SHARD_TOTAL`: Total shards
//! - `RSC_TEST_HEADLESS`: Run headless (default: true)
//! - `RSC_TEST_REUSE_BROWSER`: Reuse browsers (default: true)

use std::sync::{Arc, OnceLock};

use rsc_test::e2e::{
    BrowserTestContext, BrowserTestConfig, BrowserTestError,
    ShardConfig, TestEnvConfig, E2eConfig,
};

/// Global test harness instance.
static HARNESS: OnceLock<Arc<TestHarness>> = OnceLock::new();

fn get_harness() -> Arc<TestHarness> {
    HARNESS.get_or_init(|| Arc::new(TestHarness::load())).clone()
}

/// Test harness for e2e tests.
pub struct TestHarness {
    /// Environment configuration (from env vars).
    pub env_config: TestEnvConfig,
    /// File configuration (from rsc-test.toml).
    pub file_config: E2eConfig,
}

impl TestHarness {
    /// Loads configuration from file and environment.
    pub fn load() -> Self {
        Self {
            env_config: TestEnvConfig::from_env(),
            file_config: E2eConfig::load(),
        }
    }

    /// Creates a harness from environment configuration only.
    pub fn from_env() -> Self {
        Self {
            env_config: TestEnvConfig::from_env(),
            file_config: E2eConfig::default(),
        }
    }

    /// Gets the global harness instance.
    pub fn global() -> Arc<TestHarness> {
        get_harness()
    }

    /// Gets the base URL for tests.
    pub fn base_url(&self) -> &str {
        &self.file_config.base_url
    }

    /// Gets the shard configuration.
    pub fn shard_config(&self) -> ShardConfig {
        self.file_config.to_shard_config()
    }

    /// Checks if a test should run on this shard.
    pub fn should_run(&self, test_name: &str) -> bool {
        self.shard_config().should_run(test_name)
    }

    /// Creates a new browser test context.
    pub async fn new_context(&self) -> Result<BrowserTestContext, BrowserTestError> {
        BrowserTestContext::new(self.file_config.to_browser_config()).await
    }

    /// Creates a context for a specific port.
    pub async fn context_for_port(&self, port: u16) -> Result<BrowserTestContext, BrowserTestError> {
        let base_url = format!("http://localhost:{}", port);

        let browser_config = self.file_config.to_browser_config()
            .base_url(&base_url);

        BrowserTestContext::new(browser_config).await
    }
}

/// Gets the default base URL from environment.
pub fn base_url() -> String {
    std::env::var("RSC_TEST_BASE_URL")
        .or_else(|_| std::env::var("RSC_TEST_PORT").map(|p| format!("http://localhost:{}", p)))
        .unwrap_or_else(|_| "http://localhost:3000".to_string())
}

/// Gets the port from environment.
pub fn port() -> u16 {
    std::env::var("RSC_TEST_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(3000)
}

/// Creates a test context using the global harness.
pub async fn create_context() -> Result<BrowserTestContext, BrowserTestError> {
    TestHarness::global().new_context().await
}

/// Creates a test context for a specific port.
pub async fn create_context_for_port(port: u16) -> Result<BrowserTestContext, BrowserTestError> {
    TestHarness::global().context_for_port(port).await
}

/// Checks if current test should run based on sharding.
pub fn should_run_test(test_name: &str) -> bool {
    TestHarness::global().should_run(test_name)
}

/// Macro to create a test context with automatic configuration.
#[macro_export]
macro_rules! test_context {
    () => {{
        $crate::harness::create_context().await.expect("Failed to create test context")
    }};
    ($port:expr) => {{
        $crate::harness::create_context_for_port($port).await.expect("Failed to create test context")
    }};
}

/// Macro to skip test if not in current shard.
#[macro_export]
macro_rules! skip_if_sharded_out {
    () => {{
        let test_name = module_path!();
        if !$crate::harness::should_run_test(test_name) {
            println!("Skipping {} (not in this shard)", test_name);
            return;
        }
    }};
    ($name:expr) => {{
        if !$crate::harness::should_run_test($name) {
            println!("Skipping {} (not in this shard)", $name);
            return;
        }
    }};
}

pub use test_context;
pub use skip_if_sharded_out;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base_url_default() {
        // This test checks the default when env vars are not set
        // In actual test runs, env vars may be set
        let url = base_url();
        assert!(url.starts_with("http://localhost:"));
    }

    #[test]
    fn test_harness_creation() {
        let harness = TestHarness::from_env();
        assert!(!harness.base_url().is_empty());
    }
}
