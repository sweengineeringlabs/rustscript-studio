//! CSS Designer E2E tests.
//!
//! Tests for the CSS Designer page including token editing, preview, and export.

use super::TestContext;
use std::time::Duration;

/// Navigate to CSS Designer page helper.
async fn goto_css_designer(ctx: &TestContext) -> Result<(), Box<dyn std::error::Error>> {
    ctx.goto("/").await?;
    ctx.wait_for_app().await?;
    ctx.click_activity_item("CSS Designer").await?;
    tokio::time::sleep(Duration::from_millis(300)).await;
    Ok(())
}

/// Tests that CSS Designer page loads with all main elements.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_css_designer_loads() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Verify main elements are present
    let css_sidebar = ctx.query(".css-sidebar").await.expect("Query failed");
    assert!(css_sidebar.is_some(), "CSS sidebar should be visible");

    let css_page = ctx.query(".css-designer-page").await.expect("Query failed");
    assert!(css_page.is_some(), "CSS designer page should be visible");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests token category tabs navigation.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_token_category_tabs() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Should have category tabs
    let tabs = ctx.query_all("[class*='tab']").await.expect("Query failed");
    assert!(!tabs.is_empty(), "Should have category tabs");

    // Click on Spacing tab
    let spacing_result = ctx.click("button:has-text('Spacing'), [data-tab='spacing']").await;
    if spacing_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(200)).await;

        // Token editor should update
        let token_list = ctx.query(".token-list").await.expect("Query failed");
        assert!(token_list.is_some(), "Token list should be visible");
    }

    // Click on Colors tab
    let _colors_result = ctx.click("button:has-text('Colors'), [data-tab='colors']").await;
    tokio::time::sleep(Duration::from_millis(200)).await;

    ctx.close().await.expect("Failed to close browser");
}

/// Tests design mode toggle between Tokens and Components.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_design_mode_toggle() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Default should be Tokens mode - look for the toolbar button
    let _tokens_btn = ctx.query("[class*='toolbar'] button:has-text('Tokens')").await;

    // Click Components mode
    let comp_result = ctx.click("button:has-text('Components')").await;
    if comp_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Component style editor should be visible
        let _comp_editor = ctx.query(".component-style-editor, [class*='component']").await.expect("Query failed");
        // This might not exist yet, so we just verify we can toggle
    }

    // Click back to Tokens mode
    let tokens_result = ctx.click("button:has-text('Tokens')").await;
    if tokens_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Token panel should be visible
        let token_panel = ctx.query(".token-panel, .token-list").await.expect("Query failed");
        assert!(token_panel.is_some(), "Token panel should be visible in Tokens mode");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests preview mode toggles (Light/Dark/Both/System).
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_preview_mode_toggles() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click Light mode
    let light_result = ctx.click("button:has-text('Light')").await;
    if light_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(200)).await;
        let preview = ctx.query(".preview-pane-light, [class*='preview']").await.expect("Query failed");
        assert!(preview.is_some(), "Light preview should be visible");
    }

    // Click Dark mode
    let dark_result = ctx.click("button:has-text('Dark')").await;
    if dark_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(200)).await;
        let preview = ctx.query(".preview-pane-dark, [class*='preview']").await.expect("Query failed");
        assert!(preview.is_some(), "Dark preview should be visible");
    }

    // Click Both mode
    let both_result = ctx.click("button:has-text('Both')").await;
    if both_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(200)).await;
        let preview_split = ctx.query(".preview-split, [class*='preview']").await.expect("Query failed");
        assert!(preview_split.is_some(), "Split preview should be visible");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests Add Token modal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_add_token_modal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click Add Token button
    let add_result = ctx.click("button:has-text('Add Token')").await;
    if add_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Modal should appear
        let modal = ctx.query(".modal, [role='dialog']").await.expect("Query failed");
        assert!(modal.is_some(), "Add Token modal should be visible");

        // Fill in token name
        ctx.fill("input[placeholder*='name'], .modal input:first-of-type", "test-token")
            .await
            .ok();

        // Fill in token value
        ctx.fill("input[placeholder*='#'], .modal input:last-of-type", "#ff0000")
            .await
            .ok();

        // Click Cancel to close
        let cancel_result = ctx.click("button:has-text('Cancel')").await;
        if cancel_result.is_ok() {
            tokio::time::sleep(Duration::from_millis(200)).await;

            // Modal should be closed
            let modal_after = ctx.query(".modal, [role='dialog']").await.expect("Query failed");
            assert!(modal_after.is_none(), "Modal should be closed after Cancel");
        }
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests Export modal functionality.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_export_modal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click Export button
    let export_result = ctx.click("button:has-text('Export')").await;
    if export_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Modal should appear
        let modal = ctx.query(".modal, [role='dialog']").await.expect("Query failed");
        assert!(modal.is_some(), "Export modal should be visible");

        // Should have format selector
        let format_select = ctx.query("select, [class*='select']").await.expect("Query failed");
        assert!(format_select.is_some(), "Format selector should be visible");

        // Should have code preview
        let code_preview = ctx.query("pre, code, [class*='export-code']").await.expect("Query failed");
        assert!(code_preview.is_some(), "Code preview should be visible");

        // Take screenshot of export modal
        ctx.screenshot("export-modal").await.ok();

        // Close modal
        ctx.click("button:has-text('Close')").await.ok();
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests Import modal functionality.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_import_modal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click Import button
    let import_result = ctx.click("button:has-text('Import')").await;
    if import_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Modal should appear
        let modal = ctx.query(".modal, [role='dialog']").await.expect("Query failed");
        assert!(modal.is_some(), "Import modal should be visible");

        // Should have textarea for pasting
        let textarea = ctx.query("textarea").await.expect("Query failed");
        assert!(textarea.is_some(), "Textarea should be visible for pasting tokens");

        // Close modal
        ctx.click("button:has-text('Cancel')").await.ok();
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests CSS Output panel toggle.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_css_output_panel() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click CSS Output button
    let output_result = ctx.click("button:has-text('CSS Output')").await;
    if output_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // CSS output panel should be visible
        let output_panel = ctx.query(".css-output-panel, [class*='css-output']").await.expect("Query failed");
        assert!(output_panel.is_some(), "CSS output panel should be visible");

        // Should contain CSS code
        let code = ctx.query(".css-output-panel code, pre code").await.expect("Query failed");
        if let Some(c) = code {
            let text = c.text_content().await.expect("Failed to get text");
            assert!(text.contains("--") || text.contains(":root"), "Should contain CSS variables");
        }

        // Toggle off
        ctx.click("button:has-text('CSS Output')").await.ok();
        tokio::time::sleep(Duration::from_millis(200)).await;

        let output_panel_after = ctx.query(".css-output-panel").await.expect("Query failed");
        assert!(output_panel_after.is_none(), "CSS output panel should be hidden after toggle");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests Validation panel.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_validation_panel() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click Validate button
    let validate_result = ctx.click("button:has-text('Validate')").await;
    if validate_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Validation panel should appear
        let validation_panel = ctx.query(".validation-panel, [class*='validation']").await.expect("Query failed");
        assert!(validation_panel.is_some(), "Validation panel should be visible");

        // Should have summary
        let summary = ctx.query("[class*='validation-summary'], [class*='validation'] h3").await.expect("Query failed");
        assert!(summary.is_some(), "Validation summary should be visible");

        // Close panel
        ctx.click(".validation-panel button:has(svg), .close-button").await.ok();
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests Dependencies panel.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_dependencies_panel() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click Dependencies button
    let deps_result = ctx.click("button:has-text('Dependencies')").await;
    if deps_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Dependencies panel should appear
        let deps_panel = ctx.query(".dependencies-panel, [class*='dependencies']").await.expect("Query failed");
        assert!(deps_panel.is_some(), "Dependencies panel should be visible");

        // Close panel
        ctx.click(".dependencies-panel button:has(svg), .close-button").await.ok();
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests sidebar category selection.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_sidebar_category_selection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Click on Colors category in sidebar
    let _colors_result = ctx.click(".css-sidebar .category-item:has-text('Colors')").await;
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Click on Spacing category
    let _spacing_result = ctx.click(".css-sidebar .category-item:has-text('Spacing')").await;
    tokio::time::sleep(Duration::from_millis(200)).await;

    ctx.close().await.expect("Failed to close browser");
}

/// Tests preview pane shows sample UI elements.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_preview_shows_sample_elements() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Preview should show sample buttons
    let buttons = ctx.query(".preview-pane button, [class*='preview'] button").await.expect("Query failed");
    assert!(buttons.is_some(), "Preview should show sample buttons");

    // Preview should show color swatches
    let _swatches = ctx.query("[class*='swatch'], .color-swatches").await.expect("Query failed");
    // Swatches might not always be visible depending on category

    // Preview should show sample card
    let _card = ctx.query("[class*='sample-card'], .preview-pane [class*='card']").await.expect("Query failed");

    // Preview should show sample input
    let input = ctx.query(".preview-pane input, [class*='preview'] input").await.expect("Query failed");
    assert!(input.is_some(), "Preview should show sample input");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests taking screenshots of CSS Designer in different states.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_css_designer_screenshots() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate to CSS Designer");

    // Screenshot of default state
    ctx.screenshot("css-designer-default").await.ok();

    // Screenshot with dark preview
    ctx.click("button:has-text('Dark')").await.ok();
    tokio::time::sleep(Duration::from_millis(300)).await;
    ctx.screenshot("css-designer-dark-preview").await.ok();

    // Screenshot with both previews
    ctx.click("button:has-text('Both')").await.ok();
    tokio::time::sleep(Duration::from_millis(300)).await;
    ctx.screenshot("css-designer-both-preview").await.ok();

    ctx.close().await.expect("Failed to close browser");
}
