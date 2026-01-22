//! End-to-end browser tests for RustScript Studio.
//!
//! These tests use the `rsc-test` e2e framework to automate browser interactions
//! and verify the application behaves correctly.
//!
//! # Running Tests
//!
//! ```bash
//! # Start the dev server first
//! rsc dev --port 3000
//!
//! # Run e2e tests (in another terminal)
//! cargo test -p rsc-studio --test e2e -- --ignored
//! ```

pub mod app_test;
pub mod browser_test;
pub mod css_designer_test;
pub mod navigation_designer_test;

use rsc_test::e2e::{
    BrowserTestContext, BrowserTestConfig, BrowserElement, BrowserTestError,
    BrowserType, Viewport,
};
use std::time::Duration;

/// Default test server URL.
pub const BASE_URL: &str = "http://localhost:3000";

/// Default timeout for browser operations.
pub const DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);

/// Test configuration for browser tests.
pub struct TestConfig {
    pub base_url: String,
    pub headless: bool,
    pub viewport: Viewport,
    pub timeout: Duration,
}

impl Default for TestConfig {
    fn default() -> Self {
        TestConfig {
            base_url: BASE_URL.to_string(),
            headless: true,
            viewport: Viewport::desktop(),
            timeout: DEFAULT_TIMEOUT,
        }
    }
}

impl TestConfig {
    pub fn with_base_url(mut self, url: &str) -> Self {
        self.base_url = url.to_string();
        self
    }

    pub fn headless(mut self, headless: bool) -> Self {
        self.headless = headless;
        self
    }

    pub fn viewport(mut self, width: u32, height: u32) -> Self {
        self.viewport = Viewport::new(width, height);
        self
    }
}

/// Test context that provides browser automation utilities.
/// Wraps BrowserTestContext from rsc_test::e2e.
pub struct TestContext {
    ctx: BrowserTestContext,
    pub config: TestConfig,
}

impl TestContext {
    /// Creates a new test context with default configuration.
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        Self::with_config(TestConfig::default()).await
    }

    /// Creates a new test context with custom configuration.
    pub async fn with_config(config: TestConfig) -> Result<Self, Box<dyn std::error::Error>> {
        let browser_config = BrowserTestConfig::new()
            .browser(BrowserType::Chrome)
            .headless(config.headless)
            .viewport(config.viewport.clone())
            .timeout(config.timeout)
            .base_url(&config.base_url);

        let ctx = BrowserTestContext::new(browser_config).await?;

        Ok(TestContext { ctx, config })
    }

    /// Navigates to a path relative to the base URL.
    pub async fn goto(&self, path: &str) -> Result<(), Box<dyn std::error::Error>> {
        self.ctx.goto(path).await?;
        Ok(())
    }

    /// Waits for the app to be ready (activity bar visible).
    pub async fn wait_for_app(&self) -> Result<(), Box<dyn std::error::Error>> {
        self.ctx.wait_for(".activity-bar").await?;
        Ok(())
    }

    /// Clicks an activity bar item by its title.
    pub async fn click_activity_item(&self, title: &str) -> Result<(), Box<dyn std::error::Error>> {
        let selector = format!(".activity-item[title='{}']", title);
        self.ctx.click(&selector).await?;
        Ok(())
    }

    /// Waits for a specific page to be visible.
    pub async fn wait_for_page(&self, class: &str) -> Result<(), Box<dyn std::error::Error>> {
        let selector = format!(".{}", class);
        self.ctx.wait_for(&selector).await?;
        Ok(())
    }

    /// Takes a screenshot and saves it.
    pub async fn screenshot(&self, name: &str) -> Result<(), Box<dyn std::error::Error>> {
        let screenshot = self.ctx.screenshot().await?;
        let path = format!("target/e2e-screenshots/{}.png", name);
        std::fs::create_dir_all("target/e2e-screenshots")?;
        std::fs::write(&path, screenshot)?;
        Ok(())
    }

    /// Closes the browser.
    pub async fn close(self) -> Result<(), Box<dyn std::error::Error>> {
        self.ctx.browser().close().await?;
        Ok(())
    }

    // ========================================================================
    // Page operations - delegating to BrowserTestContext
    // ========================================================================

    /// Queries for a single element.
    pub async fn query(&self, selector: &str) -> Result<Option<BrowserElement>, BrowserTestError> {
        self.ctx.query(selector).await
    }

    /// Queries for all matching elements.
    pub async fn query_all(&self, selector: &str) -> Result<Vec<BrowserElement>, BrowserTestError> {
        self.ctx.query_all(selector).await
    }

    /// Clicks an element.
    pub async fn click(&self, selector: &str) -> Result<(), BrowserTestError> {
        self.ctx.click(selector).await
    }

    /// Fills an input element.
    pub async fn fill(&self, selector: &str, value: &str) -> Result<(), BrowserTestError> {
        self.ctx.fill(selector, value).await
    }

    /// Presses a key.
    pub async fn press(&self, key: &str) -> Result<(), BrowserTestError> {
        self.ctx.press_key(key).await
    }

    /// Waits for an element to appear.
    pub async fn wait_for(&self, selector: &str) -> Result<BrowserElement, BrowserTestError> {
        self.ctx.wait_for(selector).await
    }
}

/// Helper macro for creating browser tests.
#[macro_export]
macro_rules! browser_test {
    ($name:ident, $body:expr) => {
        #[tokio::test]
        #[ignore = "requires browser and dev server"]
        async fn $name() {
            let ctx = $crate::e2e::TestContext::new()
                .await
                .expect("Failed to create test context");

            let result = $body(&ctx).await;

            ctx.close().await.expect("Failed to close browser");

            result.expect("Test failed");
        }
    };
}
