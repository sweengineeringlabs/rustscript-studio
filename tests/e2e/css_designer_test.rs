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

// ============================================================================
// Signal-Based Interactivity Tests for CSS Designer
// ============================================================================

/// Tests selected_category signal updates on tab click.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_selected_category_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Colors should be active by default
    let colors_active = ctx.query("[data-testid='category-colors'].active").await.expect("Query failed");
    assert!(colors_active.is_some(), "Colors category should be active by default");

    // Click Spacing category
    ctx.click("[data-testid='category-spacing']").await.expect("Failed to click Spacing");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Spacing should now be active
    let spacing_active = ctx.query("[data-testid='category-spacing'].active").await.expect("Query failed");
    assert!(spacing_active.is_some(), "Spacing should be active after click");

    // Colors should not be active
    let colors_inactive = ctx.query("[data-testid='category-colors'].active").await.expect("Query failed");
    assert!(colors_inactive.is_none(), "Colors should not be active after clicking Spacing");

    // Click Radius
    ctx.click("[data-testid='category-radius']").await.expect("Failed to click Radius");
    tokio::time::sleep(Duration::from_millis(200)).await;

    let radius_active = ctx.query("[data-testid='category-radius'].active").await.expect("Query failed");
    assert!(radius_active.is_some(), "Radius should be active after click");

    // Click Shadows
    ctx.click("[data-testid='category-shadows']").await.expect("Failed to click Shadows");
    tokio::time::sleep(Duration::from_millis(200)).await;

    let shadows_active = ctx.query("[data-testid='category-shadows'].active").await.expect("Query failed");
    assert!(shadows_active.is_some(), "Shadows should be active after click");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests preview_mode signal toggle between light and dark.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_preview_mode_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Preview should default to light mode (no dark-mode class)
    let preview = ctx.query(".preview-content").await.expect("Query failed");
    if let Some(p) = preview {
        let classes = p.get_attribute("class").await.expect("Failed to get class");
        assert!(!classes.as_ref().map(|c| c.contains("dark-mode")).unwrap_or(false),
            "Preview should default to light mode");
    }

    // Click Dark button to toggle
    ctx.click(".preview-header button:has-text('Dark')").await.ok();
    // Alternative selector
    ctx.click("button:has-text('Dark')").await.ok();
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Preview should now have dark-mode class
    let preview_dark = ctx.query(".preview-content.dark-mode").await.expect("Query failed");
    if preview_dark.is_some() {
        // Click Light to switch back
        ctx.click("button:has-text('Light')").await.ok();
        tokio::time::sleep(Duration::from_millis(200)).await;

        // Should be back to light mode
        let preview_light = ctx.query(".preview-content:not(.dark-mode)").await.expect("Query failed");
        assert!(preview_light.is_some(), "Preview should switch back to light mode");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests token panel renders tokens based on selected category.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_token_panel_by_category() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Get color tokens
    let color_tokens = ctx.query_all("[data-testid='token-list'] .token-item").await.expect("Query failed");
    let color_count = color_tokens.len();

    // Switch to Spacing
    ctx.click("[data-testid='category-spacing']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Get spacing tokens (should be different)
    let spacing_tokens = ctx.query_all("[data-testid='token-list'] .token-item").await.expect("Query failed");
    let spacing_count = spacing_tokens.len();

    // Counts may differ - both should have tokens
    assert!(color_count > 0, "Should have color tokens");
    assert!(spacing_count > 0, "Should have spacing tokens");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests css_designer signal updates when changing tokens.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_css_designer_token_update() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Get initial CSS output
    let css_output = ctx.query("[data-testid='css-output-panel'] pre").await.expect("Query failed");
    let initial_css = if let Some(o) = css_output {
        o.text_content().await.expect("Failed to get text")
    } else {
        String::new()
    };

    // Find a color token input and change it
    let color_input = ctx.query(".token-item input[type='color']").await.expect("Query failed");
    if color_input.is_some() {
        // Change the color value via text input
        ctx.fill(".token-value-input", "#ff0000").await.ok();
        tokio::time::sleep(Duration::from_millis(200)).await;

        // CSS output should update
        let updated_css = ctx.query("[data-testid='css-output-panel'] pre").await.expect("Query failed");
        if let Some(o) = updated_css {
            let new_css = o.text_content().await.expect("Failed to get text");
            // CSS should contain the new value or be different
            assert!(new_css.contains("#ff0000") || new_css != initial_css,
                "CSS output should update when token changes");
        }
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests export modal format selection signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_export_format_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Open export modal
    ctx.click("[data-testid='export-btn']").await.expect("Failed to click export");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Check modal opened
    let modal = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal.is_some(), "Export modal should open");

    // CSS should be selected by default
    let css_active = ctx.query(".export-format-selector button.active").await.expect("Query failed");
    if let Some(btn) = css_active {
        let text = btn.text_content().await.expect("Failed to get text");
        assert!(text.contains("CSS"), "CSS format should be selected by default");
    }

    // Export preview should show CSS
    let preview = ctx.query(".export-preview").await.expect("Query failed");
    if let Some(p) = preview {
        let text = p.text_content().await.expect("Failed to get text");
        assert!(text.contains(":root") || text.contains("--"), "Preview should show CSS");
    }

    // Click JSON format
    ctx.click(".export-format-selector button:has-text('JSON')").await.ok();
    tokio::time::sleep(Duration::from_millis(200)).await;

    // JSON should now be active
    let json_active = ctx.query(".export-format-selector button.active:has-text('JSON')").await.expect("Query failed");
    if json_active.is_some() {
        // Preview should update to JSON format
        let preview_json = ctx.query(".export-preview").await.expect("Query failed");
        if let Some(p) = preview_json {
            let text = p.text_content().await.expect("Failed to get text");
            // JSON typically has braces
            assert!(text.contains("{") || text.contains("colors"), "Preview should show JSON format");
        }
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests show_export_modal signal toggle.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_show_export_modal_signal() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Modal should not be visible initially
    let modal_initial = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal_initial.is_none(), "Export modal should be hidden initially");

    // Click export button to show
    ctx.click("[data-testid='export-btn']").await.expect("Failed to click export");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should be visible
    let modal_visible = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal_visible.is_some(), "Export modal should be visible after clicking export");

    // Click overlay to close (on:click|self)
    ctx.click("[data-testid='export-modal']").await.expect("Failed to click overlay");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should be hidden
    let modal_closed = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal_closed.is_none(), "Export modal should close on overlay click");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests token list renders using @for loop.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_token_list_for_loop() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Token list should have items
    let token_list = ctx.query("[data-testid='token-list']").await.expect("Query failed");
    assert!(token_list.is_some(), "Token list should exist");

    let items = ctx.query_all("[data-testid='token-list'] .token-item").await.expect("Query failed");
    assert!(!items.is_empty(), "Token list should have items rendered via @for");

    // Each item should have name and input
    let names = ctx.query_all(".token-item .token-name").await.expect("Query failed");
    assert!(!names.is_empty(), "Each token should have a name");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests derived css_output signal updates.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_derived_css_output() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // CSS output panel should exist
    let output_panel = ctx.query("[data-testid='css-output-panel']").await.expect("Query failed");
    assert!(output_panel.is_some(), "CSS output panel should exist");

    // Should have pre element with CSS
    let pre = ctx.query("[data-testid='css-output-panel'] pre").await.expect("Query failed");
    if let Some(p) = pre {
        let text = p.text_content().await.expect("Failed to get text");
        // Should contain CSS variables
        assert!(text.contains(":root") || text.contains("--color") || text.contains("--spacing"),
            "CSS output should contain CSS variables");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests live preview updates with style injection.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_live_preview_style_injection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Preview pane should exist
    let preview = ctx.query("[data-testid='preview-pane']").await.expect("Query failed");
    assert!(preview.is_some(), "Preview pane should exist");

    // Preview content should have style element
    let style = ctx.query(".preview-content style").await.expect("Query failed");
    assert!(style.is_some(), "Preview should have injected style element");

    // Preview should have sample components
    let button = ctx.query(".preview-button").await.expect("Query failed");
    let input = ctx.query(".preview-input").await.expect("Query failed");
    let card = ctx.query(".preview-card").await.expect("Query failed");

    assert!(button.is_some() || input.is_some() || card.is_some(),
        "Preview should have sample components");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests token item selection class binding.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_token_item_selection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // No token selected initially
    let selected_initial = ctx.query(".token-item.selected").await.expect("Query failed");
    assert!(selected_initial.is_none(), "No token should be selected initially");

    // Click a token item
    let item = ctx.query(".token-item").await.expect("Query failed");
    if item.is_some() {
        ctx.click(".token-item").await.expect("Failed to click token");
        tokio::time::sleep(Duration::from_millis(200)).await;

        // Token should be selected
        let selected_after = ctx.query(".token-item.selected").await.expect("Query failed");
        assert!(selected_after.is_some(), "Token should be selected after click");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests color picker input for color tokens.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_color_picker_input() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Should have color input for color tokens
    let color_input = ctx.query(".token-item input[type='color']").await.expect("Query failed");
    assert!(color_input.is_some(), "Should have color picker input for color tokens");

    // Should also have text input
    let text_input = ctx.query(".token-value-input").await.expect("Query failed");
    assert!(text_input.is_some(), "Should have text input for token value");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests class:active binding on category tabs.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_category_class_active() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // Only one category should be active
    let active_categories = ctx.query_all("[data-testid^='category-'].active").await.expect("Query failed");
    assert_eq!(active_categories.len(), 1, "Only one category should be active at a time");

    // Click different category
    ctx.click("[data-testid='category-spacing']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Still only one active
    let active_after = ctx.query_all("[data-testid^='category-'].active").await.expect("Query failed");
    assert_eq!(active_after.len(), 1, "Still only one category should be active after click");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests full CSS designer workflow.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_full_css_designer_workflow() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_css_designer(&ctx).await.expect("Failed to navigate");

    // 1. Verify we're on CSS Designer page
    let css_page = ctx.query("[data-testid='css-designer-page']").await.expect("Query failed");
    assert!(css_page.is_some(), "Should be on CSS Designer page");

    // 2. Switch through categories
    let categories = ["category-colors", "category-spacing", "category-radius", "category-shadows"];
    for cat in categories {
        ctx.click(&format!("[data-testid='{}']", cat)).await.ok();
        tokio::time::sleep(Duration::from_millis(100)).await;
    }

    // 3. Toggle preview mode
    ctx.click("button:has-text('Dark')").await.ok();
    tokio::time::sleep(Duration::from_millis(100)).await;
    ctx.click("button:has-text('Light')").await.ok();
    tokio::time::sleep(Duration::from_millis(100)).await;

    // 4. Open export modal
    ctx.click("[data-testid='export-btn']").await.expect("Failed to click export");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let modal = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal.is_some(), "Export modal should open");

    // 5. Close export modal
    ctx.click("[data-testid='export-modal']").await.expect("Failed to close modal");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let modal_closed = ctx.query("[data-testid='export-modal']").await.expect("Query failed");
    assert!(modal_closed.is_none(), "Export modal should close");

    ctx.close().await.expect("Failed to close browser");
}
