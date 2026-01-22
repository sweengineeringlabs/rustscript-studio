//! Application-level E2E tests.
//!
//! Tests for core app functionality including navigation, layout, and routing.

use super::{TestConfig, TestContext};
use std::time::Duration;

/// Tests that the app loads successfully with all main UI elements.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_app_loads_successfully() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    // Navigate to app
    ctx.goto("/").await.expect("Failed to navigate");

    // Wait for app to be ready
    ctx.wait_for_app().await.expect("App did not load");

    // Verify main layout elements are present
    let activity_bar = ctx.query(".activity-bar").await.expect("Query failed");
    assert!(activity_bar.is_some(), "Activity bar should be visible");

    let sidebar = ctx.query(".sidebar").await.expect("Query failed");
    assert!(sidebar.is_some(), "Sidebar should be visible");

    let main_content = ctx.query(".main-area").await.expect("Query failed");
    assert!(main_content.is_some(), "Main content area should be visible");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests navigation between different views via activity bar.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_activity_bar_navigation() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Default should be Navigation Designer
    let nav_page = ctx.query(".navigation-sidebar").await.expect("Query failed");
    assert!(nav_page.is_some(), "Navigation page should be default");

    // Click CSS Designer
    ctx.click_activity_item("CSS Designer").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let css_sidebar = ctx.query(".css-sidebar").await.expect("Query failed");
    assert!(css_sidebar.is_some(), "CSS sidebar should be visible after clicking CSS Designer");

    // Click Settings
    ctx.click_activity_item("Settings").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let settings_sidebar = ctx.query(".settings-sidebar").await.expect("Query failed");
    assert!(settings_sidebar.is_some(), "Settings sidebar should be visible after clicking Settings");

    // Click back to Navigation Designer
    ctx.click_activity_item("Navigation Designer").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let nav_sidebar = ctx.query(".navigation-sidebar").await.expect("Query failed");
    assert!(nav_sidebar.is_some(), "Navigation sidebar should be visible after clicking Navigation Designer");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that the activity bar highlights the active item.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_activity_bar_active_state() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Check that Navigation Designer is active by default
    let active_item = ctx.query(".activity-item[title='Navigation Designer']")
        .await
        .expect("Query failed")
        .expect("Navigation item not found");

    let style = active_item.get_attribute("style").await.expect("Failed to get style");
    assert!(
        style.as_ref().map(|s| s.contains("primary")).unwrap_or(false),
        "Navigation Designer should have active styling"
    );

    ctx.close().await.expect("Failed to close browser");
}

/// Tests sidebar toggle functionality.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_sidebar_toggle() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Sidebar should be visible initially
    let sidebar = ctx.query(".sidebar").await.expect("Query failed");
    assert!(sidebar.is_some(), "Sidebar should be visible initially");

    // Look for sidebar toggle button in header and click it
    let toggle_result = ctx.click("[title='Toggle Sidebar']").await;
    if toggle_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Sidebar should be hidden
        let sidebar_after = ctx.query(".sidebar").await.expect("Query failed");
        assert!(sidebar_after.is_none(), "Sidebar should be hidden after toggle");

        // Toggle back
        ctx.click("[title='Toggle Sidebar']").await.expect("Failed to toggle");
        tokio::time::sleep(Duration::from_millis(300)).await;

        let sidebar_restored = ctx.query(".sidebar").await.expect("Query failed");
        assert!(sidebar_restored.is_some(), "Sidebar should be visible after second toggle");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that the app header displays the correct page title.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_header_displays_page_title() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Check initial title
    let header = ctx.query(".content header, .header").await.expect("Query failed");
    if let Some(h) = header {
        let text = h.text_content().await.expect("Failed to get text");
        assert!(
            text.contains("Navigation Designer"),
            "Header should show 'Navigation Designer' initially"
        );
    }

    // Navigate to CSS Designer
    ctx.click_activity_item("CSS Designer").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let header = ctx.query(".content header, .header").await.expect("Query failed");
    if let Some(h) = header {
        let text = h.text_content().await.expect("Failed to get text");
        assert!(
            text.contains("CSS Designer"),
            "Header should show 'CSS Designer' after navigation"
        );
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests responsive behavior at different viewport sizes.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_responsive_layout() {
    // Test with smaller viewport
    let config = TestConfig::default().viewport(1024, 768);
    let ctx = TestContext::with_config(config).await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // App should still render properly
    let activity_bar = ctx.query(".activity-bar").await.expect("Query failed");
    assert!(activity_bar.is_some(), "Activity bar should be visible at 1024px width");

    ctx.close().await.expect("Failed to close browser");

    // Test with mobile viewport
    let mobile_config = TestConfig::default().viewport(375, 667);
    let mobile_ctx = TestContext::with_config(mobile_config).await.expect("Failed to create test context");

    mobile_ctx.goto("/").await.expect("Failed to navigate");
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Take screenshot for visual verification
    mobile_ctx.screenshot("mobile-layout").await.ok();

    mobile_ctx.close().await.expect("Failed to close browser");
}

/// Tests keyboard navigation between activity bar items.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_keyboard_navigation() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Focus the first activity item
    ctx.click(".activity-item").await.expect("Failed to click");

    // Press Tab to move to next item
    ctx.press("Tab").await.expect("Failed to press Tab");
    tokio::time::sleep(Duration::from_millis(100)).await;

    // Press Enter to activate
    ctx.press("Enter").await.expect("Failed to press Enter");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Should have navigated to CSS Designer (second item)
    let css_sidebar = ctx.query(".css-sidebar").await.expect("Query failed");
    assert!(css_sidebar.is_some(), "Should navigate to CSS Designer via keyboard");

    ctx.close().await.expect("Failed to close browser");
}
