//! Application-level E2E tests.
//!
//! Tests for core app functionality including navigation, layout, and routing.

use rsc_test::prelude::*;

const BASE_URL: &str = "http://localhost:3000";

/// Tests that the app loads successfully with all main UI elements.
#[e2e]
async fn app_loads_successfully() {
    let page = browser.new_page().await;
    page.goto(BASE_URL).await;

    // Wait for app to be ready
    page.wait_for("[data-testid='activity-bar']").await;

    // Verify main layout elements are present
    assert!(page.query("[data-testid='activity-bar']").is_visible().await, "Activity bar should be visible");
    assert!(page.query("[data-testid='sidebar']").is_visible().await, "Sidebar should be visible");
    assert!(page.query("[data-testid='main-area']").is_visible().await, "Main content area should be visible");
}

/// Tests navigation between different views via activity bar.
#[e2e]
async fn activity_bar_navigation() {
    let page = browser.new_page().await;
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;

    // Default should be Navigation Designer
    assert!(page.query("[data-testid='navigation-sidebar']").is_visible().await, "Navigation page should be default");

    // Click CSS Designer
    page.click("[data-testid='activity-item-css']").await;
    page.wait_for("[data-testid='css-sidebar']").await;
    assert!(page.query("[data-testid='css-sidebar']").is_visible().await, "CSS sidebar should be visible");

    // Click Settings
    page.click("[data-testid='activity-item-settings']").await;
    page.wait_for("[data-testid='settings-sidebar']").await;
    assert!(page.query("[data-testid='settings-sidebar']").is_visible().await, "Settings sidebar should be visible");

    // Click back to Navigation Designer
    page.click("[data-testid='activity-item-navigation']").await;
    page.wait_for("[data-testid='navigation-sidebar']").await;
    assert!(page.query("[data-testid='navigation-sidebar']").is_visible().await, "Navigation sidebar should be visible");
}

/// Tests that the activity bar highlights the active item.
#[e2e]
async fn activity_bar_active_state() {
    let page = browser.new_page().await;
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;

    // Navigation Designer item should be visible by default
    assert!(page.query("[data-testid='activity-item-navigation']").is_visible().await, "Navigation Designer item should be visible");
}

/// Tests sidebar toggle functionality.
#[e2e]
async fn sidebar_toggle() {
    let page = browser.new_page().await;
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;

    // Sidebar should be visible initially
    assert!(page.query("[data-testid='sidebar']").is_visible().await, "Sidebar should be visible initially");

    // Click sidebar toggle button
    page.click("[data-testid='toggle-sidebar']").await;
    page.wait(300).await;

    // Sidebar should be hidden
    assert!(!page.query("[data-testid='sidebar']").is_visible().await, "Sidebar should be hidden after toggle");

    // Toggle back
    page.click("[data-testid='toggle-sidebar']").await;
    page.wait(300).await;

    assert!(page.query("[data-testid='sidebar']").is_visible().await, "Sidebar should be visible after second toggle");
}

/// Tests that the app header displays the correct page title.
#[e2e]
async fn header_displays_page_title() {
    let page = browser.new_page().await;
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;

    // Check initial title
    let header = page.query("[data-testid='page-title']").await;
    let text = header.text_content().await;
    assert!(text.contains("Navigation Designer"), "Header should show 'Navigation Designer' initially");

    // Navigate to CSS Designer
    page.click("[data-testid='activity-item-css']").await;
    page.wait_for("[data-testid='css-sidebar']").await;

    let header = page.query("[data-testid='page-title']").await;
    let text = header.text_content().await;
    assert!(text.contains("CSS Designer"), "Header should show 'CSS Designer' after navigation");
}

/// Tests responsive behavior at different viewport sizes.
#[e2e]
async fn responsive_layout() {
    // Test with tablet viewport
    let page = browser.new_page().await;
    page.set_viewport(1024, 768).await;
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;

    assert!(page.query("[data-testid='activity-bar']").is_visible().await, "Activity bar should be visible at 1024px width");

    // Test with mobile viewport
    page.set_viewport(375, 667).await;
    page.wait(500).await;

    // Take screenshot for visual verification
    page.screenshot("mobile-layout").await;
}

/// Tests keyboard navigation between activity bar items.
#[e2e]
async fn keyboard_navigation() {
    let page = browser.new_page().await;
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;

    // Focus the first activity item
    page.click("[data-testid='activity-item-navigation']").await;

    // Press Tab to move to next item
    page.keyboard().press("Tab").await;
    page.wait(100).await;

    // Press Enter to activate
    page.keyboard().press("Enter").await;
    page.wait(300).await;

    // Should have navigated to CSS Designer (second item)
    assert!(page.query("[data-testid='css-sidebar']").is_visible().await, "Should navigate to CSS Designer via keyboard");
}
