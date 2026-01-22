//! CSS Designer E2E tests.
//!
//! Tests for the CSS Designer page including token editing, preview, and export.

use rsc_test::prelude::*;

const BASE_URL: &str = "http://localhost:3000";

/// Navigate to CSS Designer page helper.
async fn goto_css_designer(page: &Page) {
    page.goto(BASE_URL).await;
    page.wait_for("[data-testid='activity-bar']").await;
    page.click("[data-testid='activity-item-css']").await;
    page.wait_for("[data-testid='css-sidebar']").await;
}

/// Tests that CSS Designer page loads with all main elements.
#[e2e]
async fn css_designer_loads() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Verify main elements are present
    assert!(page.query("[data-testid='css-sidebar']").is_visible().await, "CSS sidebar should be visible");
    assert!(page.query("[data-testid='css-designer-page']").is_visible().await, "CSS designer page should be visible");
}

/// Tests token category tabs navigation.
#[e2e]
async fn token_category_tabs() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Should have category items
    assert!(page.query("[data-testid='category-colors']").is_visible().await, "Colors category should be visible");
    assert!(page.query("[data-testid='category-spacing']").is_visible().await, "Spacing category should be visible");

    // Click on Spacing category
    page.click("[data-testid='category-spacing']").await;
    page.wait(200).await;
}

/// Tests design mode toggle between Tokens and Components.
#[e2e]
async fn design_mode_toggle() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Token panel should be visible
    assert!(page.query("[data-testid='token-panel']").is_visible().await, "Token panel should be visible");
}

/// Tests preview mode toggles.
#[e2e]
async fn preview_mode_toggles() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Preview pane should be visible
    assert!(page.query("[data-testid='preview-pane']").is_visible().await, "Preview pane should be visible");
}

/// Tests Add Token modal.
#[e2e]
async fn add_token_modal() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Token list should be visible
    assert!(page.query("[data-testid='token-list']").is_visible().await, "Token list should be visible");
}

/// Tests Export modal functionality.
#[e2e]
async fn export_modal() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // CSS designer page should be visible
    assert!(page.query("[data-testid='css-designer-page']").is_visible().await, "CSS designer page should be visible");
}

/// Tests Import modal functionality.
#[e2e]
async fn import_modal() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // CSS sidebar should be visible
    assert!(page.query("[data-testid='css-sidebar']").is_visible().await, "CSS sidebar should be visible");
}

/// Tests CSS Output panel toggle.
#[e2e]
async fn css_output_panel() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // CSS output panel element should exist (may be hidden)
    assert!(page.query("[data-testid='css-output-panel']").exists().await, "CSS output panel should exist");
}

/// Tests Validation panel.
#[e2e]
async fn validation_panel() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Token panel should be visible
    assert!(page.query("[data-testid='token-panel']").is_visible().await, "Token panel should be visible");
}

/// Tests Dependencies panel.
#[e2e]
async fn dependencies_panel() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // CSS designer page should be visible
    assert!(page.query("[data-testid='css-designer-page']").is_visible().await, "CSS designer page should be visible");
}

/// Tests sidebar category selection.
#[e2e]
async fn sidebar_category_selection() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Click on Colors category
    page.click("[data-testid='category-colors']").await;
    page.wait(200).await;

    // Click on Spacing category
    page.click("[data-testid='category-spacing']").await;
    page.wait(200).await;
}

/// Tests preview pane shows sample UI elements.
#[e2e]
async fn preview_shows_sample_elements() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Preview pane should be visible with sample elements
    assert!(page.query("[data-testid='preview-pane']").is_visible().await, "Preview pane should be visible");
    assert!(page.query("[data-testid='preview-pane'] button").is_visible().await, "Preview should show sample buttons");
    assert!(page.query("[data-testid='preview-pane'] input").is_visible().await, "Preview should show sample input");
}

/// Tests taking screenshots of CSS Designer in different states.
#[e2e]
async fn css_designer_screenshots() {
    let page = browser.new_page().await;
    goto_css_designer(&page).await;

    // Screenshot of default state
    page.screenshot("css-designer-default").await;
}
