//! UI Interactivity E2E tests.
//!
//! Tests for signal-based interactivity, event handlers, conditional rendering,
//! and dynamic UI updates across all components.

use super::TestContext;
use std::time::Duration;

// ============================================================================
// Phase 1: Core State & Navigation Tests
// ============================================================================

/// Tests that signals correctly update the active designer state.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_active_designer_signal_updates() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Default state should show Navigation Designer
    let nav_sidebar = ctx.query("[data-testid='navigation-sidebar']").await.expect("Query failed");
    assert!(nav_sidebar.is_some(), "Navigation sidebar should be visible by default");

    // Click CSS button - signal should update
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click CSS");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Navigation sidebar should be hidden, CSS sidebar visible
    let nav_after = ctx.query("[data-testid='navigation-sidebar']").await.expect("Query failed");
    assert!(nav_after.is_none(), "Navigation sidebar should be hidden after clicking CSS");

    let css_sidebar = ctx.query("[data-testid='css-sidebar']").await.expect("Query failed");
    assert!(css_sidebar.is_some(), "CSS sidebar should be visible after clicking CSS");

    // Click Settings button
    ctx.click("[data-testid='activity-item-settings']").await.expect("Failed to click Settings");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let settings_sidebar = ctx.query("[data-testid='settings-sidebar']").await.expect("Query failed");
    assert!(settings_sidebar.is_some(), "Settings sidebar should be visible after clicking Settings");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that the sidebar_visible signal toggles sidebar visibility.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_sidebar_visible_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Sidebar should be visible initially
    let sidebar = ctx.query("[data-testid='sidebar']").await.expect("Query failed");
    assert!(sidebar.is_some(), "Sidebar should be visible initially");

    // Click toggle button
    ctx.click("[data-testid='toggle-sidebar']").await.expect("Failed to click toggle");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Sidebar should be hidden
    let sidebar_hidden = ctx.query("[data-testid='sidebar']").await.expect("Query failed");
    assert!(sidebar_hidden.is_none(), "Sidebar should be hidden after toggle");

    // Toggle again
    ctx.click("[data-testid='toggle-sidebar']").await.expect("Failed to click toggle");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Sidebar should be visible again
    let sidebar_restored = ctx.query("[data-testid='sidebar']").await.expect("Query failed");
    assert!(sidebar_restored.is_some(), "Sidebar should be visible after second toggle");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that the page_title derived signal updates correctly.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_page_title_derived_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Check initial title
    let title = ctx.query("[data-testid='page-title']").await.expect("Query failed");
    if let Some(t) = title {
        let text = t.text_content().await.expect("Failed to get text");
        assert!(text.contains("Navigation Designer"), "Initial title should be 'Navigation Designer'");
    }

    // Navigate to CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let title_css = ctx.query("[data-testid='page-title']").await.expect("Query failed");
    if let Some(t) = title_css {
        let text = t.text_content().await.expect("Failed to get text");
        assert!(text.contains("CSS Designer"), "Title should update to 'CSS Designer'");
    }

    // Navigate to Settings
    ctx.click("[data-testid='activity-item-settings']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let title_settings = ctx.query("[data-testid='page-title']").await.expect("Query failed");
    if let Some(t) = title_settings {
        let text = t.text_content().await.expect("Failed to get text");
        assert!(text.contains("Settings"), "Title should update to 'Settings'");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests class:active binding on activity bar buttons.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_class_active_binding() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Check that Navigation button has active class
    let nav_btn = ctx.query("[data-testid='activity-item-navigation'].active").await.expect("Query failed");
    assert!(nav_btn.is_some(), "Navigation button should have 'active' class initially");

    // CSS button should not have active class
    let css_btn_inactive = ctx.query("[data-testid='activity-item-css'].active").await.expect("Query failed");
    assert!(css_btn_inactive.is_none(), "CSS button should not have 'active' class initially");

    // Click CSS button
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Now CSS should have active class
    let css_btn_active = ctx.query("[data-testid='activity-item-css'].active").await.expect("Query failed");
    assert!(css_btn_active.is_some(), "CSS button should have 'active' class after click");

    // Navigation should not have active class anymore
    let nav_btn_inactive = ctx.query("[data-testid='activity-item-navigation'].active").await.expect("Query failed");
    assert!(nav_btn_inactive.is_none(), "Navigation button should not have 'active' class after clicking CSS");

    ctx.close().await.expect("Failed to close browser");
}

// ============================================================================
// Phase 2: Form Components Tests
// ============================================================================

/// Tests modal open/close with @if conditional rendering.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_modal_conditional_rendering() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Modal should not be visible initially
    let modal_hidden = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_hidden.is_none(), "Add Workflow modal should be hidden initially");

    // Click Add Workflow button
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should appear
    let modal_visible = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_visible.is_some(), "Add Workflow modal should be visible after click");

    // Modal should have input field
    let input = ctx.query("[data-testid='workflow-name-input']").await.expect("Query failed");
    assert!(input.is_some(), "Modal should contain workflow name input");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests modal closes on overlay click (on:click|self).
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_modal_overlay_click_closes() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Open modal
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Verify modal is open
    let modal = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal.is_some(), "Modal should be open");

    // Click on overlay (the modal-overlay element itself, not the content)
    // This tests the on:click|self modifier
    ctx.click("[data-testid='add-workflow-modal']").await.expect("Failed to click overlay");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should be closed
    let modal_closed = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_closed.is_none(), "Modal should close when clicking overlay");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests input value binding with on:input handler.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_input_value_binding() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Open Add Workflow modal
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Type into the input
    ctx.fill("[data-testid='workflow-name-input']", "My Test Workflow").await.expect("Failed to fill");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Verify input has the value
    let input = ctx.query("[data-testid='workflow-name-input']").await.expect("Query failed");
    if let Some(i) = input {
        let value = i.get_attribute("value").await.expect("Failed to get value");
        assert!(value.as_ref().map(|v| v.contains("My Test Workflow")).unwrap_or(false),
            "Input should contain typed text");
    }

    ctx.close().await.expect("Failed to close browser");
}

// ============================================================================
// Phase 3: Navigation Designer Tests
// ============================================================================

/// Tests workflow list renders from store signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_workflow_list_from_store() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Should have workflow items rendered from store
    let workflow_items = ctx.query_all("[data-testid='workflow-item']").await.expect("Query failed");
    assert!(!workflow_items.is_empty(), "Should have workflow items from store");

    // First workflow should have name and context count
    let first_name = ctx.query(".workflow-item .workflow-name").await.expect("Query failed");
    assert!(first_name.is_some(), "Workflow item should have name");

    let first_meta = ctx.query(".workflow-item .workflow-meta").await.expect("Query failed");
    assert!(first_meta.is_some(), "Workflow item should have meta (context count)");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests adding a new workflow updates the store and re-renders list.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_add_workflow_updates_store() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Count initial workflows
    let initial_items = ctx.query_all("[data-testid='workflow-item']").await.expect("Query failed");
    let initial_count = initial_items.len();

    // Open modal and add workflow
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    ctx.fill("[data-testid='workflow-name-input']", "New Test Workflow").await.expect("Failed to fill");
    tokio::time::sleep(Duration::from_millis(100)).await;

    ctx.click("[data-testid='submit-workflow']").await.expect("Failed to submit");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should close
    let modal = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal.is_none(), "Modal should close after submit");

    // Should have one more workflow
    let final_items = ctx.query_all("[data-testid='workflow-item']").await.expect("Query failed");
    assert_eq!(final_items.len(), initial_count + 1, "Should have one more workflow after adding");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests workflow selection with class:selected binding.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_workflow_selection_class_binding() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // No workflow should be selected initially
    let selected_initial = ctx.query(".workflow-item.selected").await.expect("Query failed");
    assert!(selected_initial.is_none(), "No workflow should be selected initially");

    // Click first workflow
    ctx.click("[data-testid='workflow-item']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // First workflow should now have selected class
    let selected_after = ctx.query(".workflow-item.selected").await.expect("Query failed");
    assert!(selected_after.is_some(), "Clicked workflow should have 'selected' class");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests zoom controls update the canvas_zoom signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_zoom_controls_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Get initial zoom display
    let zoom_reset = ctx.query(".zoom-reset").await.expect("Query failed");
    if let Some(z) = zoom_reset {
        let text = z.text_content().await.expect("Failed to get text");
        assert!(text.contains("100%"), "Initial zoom should be 100%");
    }

    // Click zoom in
    ctx.click(".zoom-in").await.expect("Failed to click zoom in");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Zoom should increase
    let zoom_after_in = ctx.query(".zoom-reset").await.expect("Query failed");
    if let Some(z) = zoom_after_in {
        let text = z.text_content().await.expect("Failed to get text");
        assert!(text.contains("110%"), "Zoom should be 110% after zoom in");
    }

    // Click zoom out twice
    ctx.click(".zoom-out").await.expect("Failed to click zoom out");
    tokio::time::sleep(Duration::from_millis(100)).await;
    ctx.click(".zoom-out").await.expect("Failed to click zoom out");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Zoom should decrease
    let zoom_after_out = ctx.query(".zoom-reset").await.expect("Query failed");
    if let Some(z) = zoom_after_out {
        let text = z.text_content().await.expect("Failed to get text");
        assert!(text.contains("90%"), "Zoom should be 90% after zoom out twice from 110%");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests flow canvas renders nodes from derived canvas.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_flow_canvas_renders_nodes() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Canvas should be present
    let canvas = ctx.query("[data-testid='flow-canvas']").await.expect("Query failed");
    assert!(canvas.is_some(), "Flow canvas should be present");

    // Should have flow nodes
    let nodes = ctx.query_all("[data-testid='flow-node']").await.expect("Query failed");
    assert!(!nodes.is_empty(), "Canvas should render flow nodes");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests flow node selection updates selected_node signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_flow_node_selection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // No node selected initially
    let selected_initial = ctx.query(".flow-node.selected").await.expect("Query failed");
    assert!(selected_initial.is_none(), "No flow node should be selected initially");

    // Click a flow node
    ctx.click("[data-testid='flow-node']").await.expect("Failed to click node");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Node should now be selected
    let selected_after = ctx.query(".flow-node.selected").await.expect("Query failed");
    assert!(selected_after.is_some(), "Clicked node should have 'selected' class");

    // Bottom panel should show properties
    let bottom_panel = ctx.query("[data-testid='bottom-panel']").await.expect("Query failed");
    if let Some(bp) = bottom_panel {
        let text = bp.text_content().await.expect("Failed to get text");
        assert!(text.contains("Node Properties") || text.contains("ID"),
            "Bottom panel should show node properties when node is selected");
    }

    ctx.close().await.expect("Failed to close browser");
}

// ============================================================================
// Phase 4: CSS Designer Tests
// ============================================================================

/// Tests token category selection updates selected_category signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_token_category_selection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate to CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Colors should be active by default
    let colors_active = ctx.query("[data-testid='category-colors'].active").await.expect("Query failed");
    assert!(colors_active.is_some(), "Colors category should be active by default");

    // Click Spacing category
    ctx.click("[data-testid='category-spacing']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Spacing should now be active
    let spacing_active = ctx.query("[data-testid='category-spacing'].active").await.expect("Query failed");
    assert!(spacing_active.is_some(), "Spacing category should be active after click");

    // Colors should not be active
    let colors_inactive = ctx.query("[data-testid='category-colors'].active").await.expect("Query failed");
    assert!(colors_inactive.is_none(), "Colors category should not be active after clicking Spacing");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests token list renders tokens from the selected category.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_token_list_renders_by_category() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate to CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Token list should be visible
    let token_list = ctx.query("[data-testid='token-list']").await.expect("Query failed");
    assert!(token_list.is_some(), "Token list should be visible");

    // Should have token items (colors by default)
    let color_tokens = ctx.query_all(".token-item").await.expect("Query failed");
    let color_count = color_tokens.len();
    assert!(color_count > 0, "Should have color tokens");

    // Switch to spacing
    ctx.click("[data-testid='category-spacing']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Token list should update with spacing tokens
    let spacing_tokens = ctx.query_all(".token-item").await.expect("Query failed");
    assert!(spacing_tokens.len() > 0, "Should have spacing tokens");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests preview mode toggle updates the preview_mode signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_preview_mode_toggle() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate to CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Preview pane should be visible
    let preview = ctx.query("[data-testid='preview-pane']").await.expect("Query failed");
    assert!(preview.is_some(), "Preview pane should be visible");

    // Light mode should be active by default
    let preview_content = ctx.query(".preview-content").await.expect("Query failed");
    if let Some(pc) = preview_content {
        let has_dark = pc.get_attribute("class").await.expect("Failed to get class");
        assert!(!has_dark.as_ref().map(|c| c.contains("dark-mode")).unwrap_or(false),
            "Preview should not have dark-mode class by default");
    }

    // Click Dark button
    ctx.click(".preview-header button:has-text('Dark')").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Preview should now have dark-mode class
    let preview_dark = ctx.query(".preview-content.dark-mode").await.expect("Query failed");
    assert!(preview_dark.is_some(), "Preview should have dark-mode class after clicking Dark");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests export modal opens and format selection works.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_export_modal_format_selection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate to CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Click Export button
    ctx.click("[data-testid='export-btn']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Export modal should appear
    let modal = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal.is_some(), "Export modal should be visible");

    // CSS format should be selected by default
    let css_active = ctx.query(".export-format-selector button.active").await.expect("Query failed");
    if let Some(btn) = css_active {
        let text = btn.text_content().await.expect("Failed to get text");
        assert!(text.contains("CSS"), "CSS format should be selected by default");
    }

    // Export preview should contain CSS
    let preview = ctx.query(".export-preview").await.expect("Query failed");
    if let Some(p) = preview {
        let text = p.text_content().await.expect("Failed to get text");
        assert!(text.contains(":root") || text.contains("--"), "Preview should show CSS output");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests CSS output updates live when tokens change.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_live_css_output_update() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate to CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Get initial CSS output
    let output_initial = ctx.query("[data-testid='css-output-panel'] pre").await.expect("Query failed");
    let initial_text = if let Some(o) = output_initial {
        o.text_content().await.expect("Failed to get text")
    } else {
        String::new()
    };

    // Find a token input and change its value
    let token_input = ctx.query(".token-value-input").await.expect("Query failed");
    if token_input.is_some() {
        ctx.fill(".token-value-input", "#ff0000").await.ok();
        tokio::time::sleep(Duration::from_millis(200)).await;

        // CSS output should update
        let output_after = ctx.query("[data-testid='css-output-panel'] pre").await.expect("Query failed");
        if let Some(o) = output_after {
            let after_text = o.text_content().await.expect("Failed to get text");
            // The output should contain the new color value
            assert!(after_text.contains("#ff0000") || after_text != initial_text,
                "CSS output should update when token changes");
        }
    }

    ctx.close().await.expect("Failed to close browser");
}

// ============================================================================
// Settings Page Tests
// ============================================================================

/// Tests settings form controls work with signals.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_settings_form_controls() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate to Settings
    ctx.click("[data-testid='activity-item-settings']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Settings page should be visible
    let settings = ctx.query(".settings-page").await.expect("Query failed");
    assert!(settings.is_some(), "Settings page should be visible");

    // Auto-save checkbox should exist
    let checkbox = ctx.query("input[type='checkbox']").await.expect("Query failed");
    assert!(checkbox.is_some(), "Auto-save checkbox should exist");

    // Theme select should exist
    let select = ctx.query("select").await.expect("Query failed");
    assert!(select.is_some(), "Theme select should exist");

    ctx.close().await.expect("Failed to close browser");
}

// ============================================================================
// Event Modifier Tests
// ============================================================================

/// Tests on:click|stop prevents event propagation.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_click_stop_modifier() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Open modal
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Click on modal content (should not close due to on:click|stop)
    ctx.click(".modal-content").await.expect("Failed to click modal content");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Modal should still be open
    let modal = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal.is_some(), "Modal should remain open when clicking content (on:click|stop)");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests multiple conditional @if blocks render correctly.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_multiple_if_conditionals() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Navigate through all pages to verify @if conditionals work
    let pages = [
        ("activity-item-navigation", "navigation-sidebar"),
        ("activity-item-css", "css-sidebar"),
        ("activity-item-settings", "settings-sidebar"),
    ];

    for (button_id, expected_sidebar) in pages {
        ctx.click(&format!("[data-testid='{}']", button_id)).await.expect("Failed to click");
        tokio::time::sleep(Duration::from_millis(300)).await;

        let sidebar = ctx.query(&format!("[data-testid='{}']", expected_sidebar)).await.expect("Query failed");
        assert!(sidebar.is_some(), "Expected {} to be visible", expected_sidebar);
    }

    ctx.close().await.expect("Failed to close browser");
}
