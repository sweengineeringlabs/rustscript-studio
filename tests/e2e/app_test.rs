//! Application-level E2E tests.
//!
//! Tests for core app functionality including navigation, layout, and routing.

use super::{TestConfig, TestContext};
use std::time::Duration;

/// Debug test to understand toggle behavior
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_toggle_behavior() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Check sidebar state before
    let sidebar_before = ctx.query(".sidebar").await.expect("Query failed");
    println!("Sidebar before: {:?}", sidebar_before.is_some());

    // Get button HTML
    let btn_html = ctx.evaluate(r#"
        (function() {
            const btn = document.querySelector('[title="Toggle Sidebar"]');
            if (!btn) return 'BUTTON NOT FOUND';
            return btn.outerHTML;
        })()
    "#).await.expect("Failed to get button");
    println!("Toggle button HTML: {:?}", btn_html);

    // Check all event handlers on the button
    let event_info = ctx.evaluate(r#"
        (function() {
            const btn = document.querySelector('[title="Toggle Sidebar"]');
            if (!btn) return 'BUTTON NOT FOUND';
            // Check for listeners
            const hasOnclick = !!btn.onclick;
            const attrs = Array.from(btn.attributes).map(a => a.name + '=' + a.value).join('; ');
            return 'onclick=' + hasOnclick + ', attrs: ' + attrs;
        })()
    "#).await.expect("Failed to get event info");
    println!("Event info: {:?}", event_info);

    // Click the toggle button using JS
    let click_result = ctx.evaluate(r#"
        (function() {
            const btn = document.querySelector('[title="Toggle Sidebar"]');
            if (!btn) return 'BUTTON NOT FOUND';

            // Capture any console output
            const logs = [];
            const oldLog = console.log;
            console.log = function(...args) {
                logs.push(args.join(' '));
                oldLog.apply(console, args);
            };

            // Click the button
            btn.click();

            // Restore console
            console.log = oldLog;

            return 'Clicked. Logs: ' + logs.join(' | ');
        })()
    "#).await.expect("Failed to click");
    println!("Click result: {:?}", click_result);

    // Wait a bit
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Check sidebar state after
    let sidebar_after = ctx.query(".sidebar").await.expect("Query failed");
    println!("Sidebar after: {:?}", sidebar_after.is_some());

    // Get the full DOM for debugging
    let dom_after = ctx.evaluate("document.querySelector('.app').innerHTML.substring(0, 500)").await.expect("Failed to get DOM");
    println!("DOM after click: {:?}", dom_after);

    // Check reactivity state
    let reactivity_debug = ctx.evaluate(r#"
        (function() {
            // Check if createReactive was called
            if (!window.__rsc_conditionals_debug) {
                return 'No debug info (createReactive may not have been called)';
            }
            return JSON.stringify(window.__rsc_conditionals_debug);
        })()
    "#).await.expect("Failed to get reactivity debug");
    println!("Reactivity debug: {:?}", reactivity_debug);

    // Check the conditionals instances
    let conditionals_state = ctx.evaluate(r#"
        (function() {
            if (typeof RustScript === 'undefined') return 'RustScript not available';
            // Try to access internal state
            try {
                const runtime = RustScript;
                // Look for any exposed conditionals state
                return 'RustScript available, checking conditionals...';
            } catch(e) {
                return 'Error: ' + e.message;
            }
        })()
    "#).await.expect("Failed to get conditionals state");
    println!("Conditionals state: {:?}", conditionals_state);

    // Check if there are any console errors during click
    let all_logs = ctx.evaluate(r#"
        (function() {
            const logs = [];
            const oldLog = console.log;
            const oldError = console.error;
            console.log = function(...args) {
                logs.push('LOG: ' + args.join(' '));
                oldLog.apply(console, args);
            };
            console.error = function(...args) {
                logs.push('ERROR: ' + args.join(' '));
                oldError.apply(console, args);
            };

            // Click the toggle button again
            const btn = document.querySelector('[title="Toggle Sidebar"]');
            if (btn) btn.click();

            // Restore console
            setTimeout(() => {
                console.log = oldLog;
                console.error = oldError;
            }, 100);

            return logs.join('\n');
        })()
    "#).await.expect("Failed to get logs");
    println!("Console logs during second click: {:?}", all_logs);

    // Wait and check sidebar again
    tokio::time::sleep(Duration::from_millis(500)).await;
    let sidebar_final = ctx.query(".sidebar").await.expect("Query failed");
    println!("Sidebar final: {:?}", sidebar_final.is_some());

    ctx.close().await.expect("Failed to close browser");
}

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

// ============================================================================
// Signal-Based Interactivity Tests
// ============================================================================

/// Tests that clicking activity items updates the active_designer signal.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_signal_active_designer() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Initially Navigation Designer should be active
    let nav_active = ctx.query("[data-testid='activity-item-navigation'].active").await.expect("Query failed");
    assert!(nav_active.is_some(), "Navigation should be active by default");

    // Click CSS Designer
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click CSS");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // CSS should now be active
    let css_active = ctx.query("[data-testid='activity-item-css'].active").await.expect("Query failed");
    assert!(css_active.is_some(), "CSS should be active after click");

    // Navigation should no longer be active
    let nav_inactive = ctx.query("[data-testid='activity-item-navigation'].active").await.expect("Query failed");
    assert!(nav_inactive.is_none(), "Navigation should not be active after clicking CSS");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that sidebar_visible signal toggles sidebar correctly.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_signal_sidebar_visible() {
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

    // Toggle again to show
    ctx.click("[data-testid='toggle-sidebar']").await.expect("Failed to click toggle");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Sidebar should be visible again
    let sidebar_restored = ctx.query("[data-testid='sidebar']").await.expect("Query failed");
    assert!(sidebar_restored.is_some(), "Sidebar should be visible after second toggle");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that page_title derived signal updates correctly.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_derived_page_title() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Check initial title
    let title = ctx.query("[data-testid='page-title']").await.expect("Query failed");
    if let Some(t) = title {
        let text = t.text_content().await.expect("Failed to get text");
        assert!(text.contains("Navigation"), "Initial title should contain 'Navigation'");
    }

    // Navigate to CSS
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click CSS");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let title_css = ctx.query("[data-testid='page-title']").await.expect("Query failed");
    if let Some(t) = title_css {
        let text = t.text_content().await.expect("Failed to get text");
        assert!(text.contains("CSS"), "Title should contain 'CSS' after navigation");
    }

    // Navigate to Settings
    ctx.click("[data-testid='activity-item-settings']").await.expect("Failed to click Settings");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let title_settings = ctx.query("[data-testid='page-title']").await.expect("Query failed");
    if let Some(t) = title_settings {
        let text = t.text_content().await.expect("Failed to get text");
        assert!(text.contains("Settings"), "Title should contain 'Settings' after navigation");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Debug test to trace conditional rendering issues.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_conditional_trace() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Wait a bit for all rendering to complete
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Get the sidebar HTML to see what's actually rendered
    let sidebar_html = ctx.evaluate(r#"
        const sidebar = document.querySelector('[data-testid="sidebar"]');
        sidebar ? sidebar.outerHTML : 'SIDEBAR NOT FOUND';
    "#).await.expect("Failed to evaluate");
    println!("Sidebar HTML: {:?}", sidebar_html);

    // Check conditional 2's state
    let cond2_info = ctx.evaluate(r#"
        try {
            // Try to trigger an update manually for condition 2
            // to see what happens
            var result = {
                navSidebar: !!document.querySelector('[data-testid="navigation-sidebar"]'),
                cssSidebar: !!document.querySelector('[data-testid="css-sidebar"]'),
                settingsSidebar: !!document.querySelector('[data-testid="settings-sidebar"]'),
                pageTitle: document.querySelector('[data-testid="page-title"]')?.textContent,
                mainAreaHTML: document.querySelector('.main-area')?.innerHTML?.substring(0, 500)
            };
            JSON.stringify(result, null, 2);
        } catch(e) {
            'Error: ' + e.message;
        }
    "#).await.expect("Failed to get cond2 info");
    println!("Conditional 2 info: {:?}", cond2_info);

    // Check if there were any WASM errors
    let errors = ctx.evaluate(r#"
        window.__rustscript_error || 'No error'
    "#).await.expect("Failed to get errors");
    println!("WASM errors: {:?}", errors);

    // Click CSS button and check if sidebar content changes
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click CSS");
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Check sidebar and main area after CSS click
    let after_css = ctx.evaluate(r#"
        try {
            var result = {
                pageTitle: document.querySelector('[data-testid="page-title"]')?.textContent,
                sidebarHTML: document.querySelector('[data-testid="sidebar"]')?.innerHTML?.substring(0, 200),
                mainAreaNav: !!document.querySelector('.navigation-designer-page'),
                mainAreaCSS: !!document.querySelector('.css-designer-page')
            };
            JSON.stringify(result, null, 2);
        } catch(e) {
            'Error: ' + e.message;
        }
    "#).await.expect("Failed to get state after CSS click");
    println!("After CSS click: {:?}", after_css);

    ctx.close().await.expect("Failed to close browser");
}

/// Tests conditional rendering with @if directive.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_conditional_rendering_if() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Initially Navigation sidebar should be visible
    let nav_sidebar = ctx.query("[data-testid='navigation-sidebar']").await.expect("Query failed");
    assert!(nav_sidebar.is_some(), "Navigation sidebar should be visible by default");

    // CSS and Settings sidebars should NOT be visible
    let css_sidebar = ctx.query("[data-testid='css-sidebar']").await.expect("Query failed");
    assert!(css_sidebar.is_none(), "CSS sidebar should not be visible initially");

    let settings_sidebar = ctx.query("[data-testid='settings-sidebar']").await.expect("Query failed");
    assert!(settings_sidebar.is_none(), "Settings sidebar should not be visible initially");

    // Switch to CSS
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click CSS");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Now CSS sidebar should be visible, Navigation should not
    let css_visible = ctx.query("[data-testid='css-sidebar']").await.expect("Query failed");
    assert!(css_visible.is_some(), "CSS sidebar should be visible after switching");

    let nav_hidden = ctx.query("[data-testid='navigation-sidebar']").await.expect("Query failed");
    assert!(nav_hidden.is_none(), "Navigation sidebar should be hidden after switching");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests class:active binding on buttons.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_class_active_binding() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Get all activity items
    let items = ctx.query_all(".activity-item").await.expect("Query failed");
    assert!(items.len() >= 3, "Should have at least 3 activity items");

    // Only one should have active class initially
    let active_items = ctx.query_all(".activity-item.active").await.expect("Query failed");
    assert_eq!(active_items.len(), 1, "Only one item should be active");

    // Click second item
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(200)).await;

    // Still only one active
    let active_after = ctx.query_all(".activity-item.active").await.expect("Query failed");
    assert_eq!(active_after.len(), 1, "Still only one item should be active after click");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests modal conditional rendering.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_modal_conditional_rendering() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Modal should not be visible initially
    let modal_initial = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_initial.is_none(), "Modal should not be visible initially");

    // Click Add Workflow button
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click Add Workflow");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should now be visible
    let modal_visible = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_visible.is_some(), "Modal should be visible after clicking Add Workflow");

    // Modal should have input field
    let input = ctx.query("[data-testid='workflow-name-input']").await.expect("Query failed");
    assert!(input.is_some(), "Modal should have workflow name input");

    // Modal should have submit button
    let submit = ctx.query("[data-testid='submit-workflow']").await.expect("Query failed");
    assert!(submit.is_some(), "Modal should have submit button");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests that modal closes on overlay click (on:click|self modifier).
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_modal_overlay_click_self() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Open modal
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click Add Workflow");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Verify modal is open
    let modal_open = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_open.is_some(), "Modal should be open");

    // Click on overlay (should close due to on:click|self)
    ctx.click("[data-testid='add-workflow-modal']").await.expect("Failed to click overlay");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Modal should be closed
    let modal_closed = ctx.query("[data-testid='add-workflow-modal']").await.expect("Query failed");
    assert!(modal_closed.is_none(), "Modal should be closed after clicking overlay");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests input value binding with on:input handler.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_input_on_input_binding() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Open modal
    ctx.click("[data-testid='add-workflow']").await.expect("Failed to click Add Workflow");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Type into input
    ctx.fill("[data-testid='workflow-name-input']", "Test Workflow").await.expect("Failed to fill input");
    tokio::time::sleep(Duration::from_millis(100)).await;

    // Verify value is bound
    let input = ctx.query("[data-testid='workflow-name-input']").await.expect("Query failed");
    if let Some(i) = input {
        let value = i.get_attribute("value").await.expect("Failed to get value");
        assert!(value.as_ref().map(|v| v.contains("Test Workflow")).unwrap_or(false),
            "Input should contain typed text");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests full navigation workflow.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_full_navigation_workflow() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");

    // Start at Navigation Designer
    let nav_page = ctx.query("[data-testid='navigation-sidebar']").await.expect("Query failed");
    assert!(nav_page.is_some(), "Should start at Navigation Designer");

    // Navigate to CSS
    ctx.click("[data-testid='activity-item-css']").await.expect("Failed to click CSS");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let css_page = ctx.query("[data-testid='css-designer-page']").await.expect("Query failed");
    assert!(css_page.is_some(), "Should be on CSS Designer page");

    // Navigate to Settings
    ctx.click("[data-testid='activity-item-settings']").await.expect("Failed to click Settings");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let settings_page = ctx.query(".settings-page").await.expect("Query failed");
    assert!(settings_page.is_some(), "Should be on Settings page");

    // Navigate back to Navigation
    ctx.click("[data-testid='activity-item-navigation']").await.expect("Failed to click Navigation");
    tokio::time::sleep(Duration::from_millis(300)).await;

    let nav_page_restored = ctx.query("[data-testid='navigation-sidebar']").await.expect("Query failed");
    assert!(nav_page_restored.is_some(), "Should be back at Navigation Designer");

    ctx.close().await.expect("Failed to close browser");
}

/// Debug test to check activity bar DOM structure
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_activity_bar_dom() {
    let ctx = TestContext::new().await.expect("Failed to create test context");
    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for_app().await.expect("App did not load");
    
    // Get activity bar HTML
    let activity_bar_html = ctx.evaluate(
        "document.querySelector('.activity-bar')?.outerHTML || 'NOT FOUND'"
    ).await.expect("Eval failed");
    println!("Activity bar HTML: {:?}", activity_bar_html);
    
    // Get class of navigation button
    let nav_class = ctx.evaluate(
        "document.querySelector('[data-testid=\"activity-item-navigation\"]')?.className || 'NOT FOUND'"
    ).await.expect("Eval failed");
    println!("Navigation button class: {:?}", nav_class);
    
    // Get style of navigation button
    let nav_style = ctx.evaluate(
        "document.querySelector('[data-testid=\"activity-item-navigation\"]')?.getAttribute('style') || 'NO STYLE'"
    ).await.expect("Eval failed");
    println!("Navigation button style: {:?}", nav_style);
    
    ctx.close().await.expect("Failed to close browser");
}

/// Debug test to check JavaScript errors
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_js_errors() {
    let ctx = TestContext::new().await.expect("Failed to create test context");
    ctx.goto("/").await.expect("Failed to navigate");
    
    // Wait a bit for any errors
    tokio::time::sleep(Duration::from_secs(3)).await;
    
    // Get JavaScript errors
    let errors = ctx.evaluate(r#"
        (function() {
            // Try to load WASM and return any errors
            return new Promise(async (resolve) => {
                try {
                    const response = await fetch('/__rsc__/wasm');
                    const buffer = await response.arrayBuffer();
                    const module = await WebAssembly.compile(buffer);
                    
                    // Get imports required by module
                    const imports = WebAssembly.Module.imports(module);
                    const importMap = {};
                    for (const imp of imports) {
                        if (!importMap[imp.module]) importMap[imp.module] = [];
                        importMap[imp.module].push(imp.name);
                    }
                    
                    resolve(JSON.stringify({
                        status: 'compiled',
                        imports: importMap
                    }));
                } catch (e) {
                    resolve(JSON.stringify({ error: e.toString() }));
                }
            });
        })()
    "#).await.expect("Eval failed");
    println!("WASM imports: {:?}", errors);
    
    // Check console errors
    let console_result = ctx.evaluate(r#"
        window.__rsc_errors || 'no errors captured'
    "#).await.expect("Eval failed");
    println!("Console errors: {:?}", console_result);
    
    ctx.close().await.expect("Failed to close browser");
}

/// Debug test to check WASM instantiation
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_wasm_instantiation() {
    let ctx = TestContext::new().await.expect("Failed to create test context");
    ctx.goto("/").await.expect("Failed to navigate");
    
    // Wait for runtime to load
    tokio::time::sleep(Duration::from_secs(2)).await;
    
    // Check if RustScript runtime is available and try to load
    let result = ctx.evaluate(r#"
        (async function() {
            if (typeof RustScript === 'undefined') {
                return { error: 'RustScript not defined' };
            }
            
            try {
                // Try to load the app manually
                await RustScript.loadApp('/__rsc__/wasm', 'app');
                return { status: 'loaded', innerHTML: document.getElementById('app').innerHTML.substring(0, 200) };
            } catch (e) {
                return { error: e.toString(), stack: e.stack ? e.stack.substring(0, 500) : 'no stack' };
            }
        })()
    "#).await.expect("Eval failed");
    println!("Result: {:?}", result);
    
    ctx.close().await.expect("Failed to close browser");
}

/// Debug test to check runtime loading
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_runtime_load() {
    let ctx = TestContext::new().await.expect("Failed to create test context");
    ctx.goto("/").await.expect("Failed to navigate");
    
    // Wait for runtime to load
    tokio::time::sleep(Duration::from_secs(3)).await;
    
    // Check runtime status
    let runtime_check = ctx.evaluate("typeof RustScript").await.expect("Eval failed");
    println!("RustScript type: {:?}", runtime_check);
    
    // Check if loadApp exists
    let load_app_check = ctx.evaluate("typeof RustScript?.loadApp").await.expect("Eval failed");
    println!("loadApp type: {:?}", load_app_check);
    
    // Wait longer
    tokio::time::sleep(Duration::from_secs(3)).await;
    
    // Check app div
    let app_html = ctx.evaluate("document.getElementById('app')?.innerHTML?.length || 0").await.expect("Eval failed");
    println!("App innerHTML length: {:?}", app_html);
    
    // Check for any global errors
    let global_errors = ctx.evaluate(r#"
        window.onerror = function(msg, url, line, col, error) {
            window.__error = msg + ' at ' + line + ':' + col;
            return false;
        };
        window.__error || 'no error'
    "#).await.expect("Eval failed");
    println!("Global errors: {:?}", global_errors);
    
    ctx.close().await.expect("Failed to close browser");
}

/// Debug test to check loadApp call
#[tokio::test]
#[ignore = "requires browser and dev server"]  
async fn test_debug_load_app_call() {
    let ctx = TestContext::new().await.expect("Failed to create test context");
    ctx.goto("/").await.expect("Failed to navigate");
    
    // Wait for runtime
    tokio::time::sleep(Duration::from_secs(2)).await;
    
    // Try to call loadApp manually and capture error
    let result = ctx.evaluate(r#"
        new Promise((resolve) => {
            window.__loadResult = 'pending';
            RustScript.loadApp('/__rsc__/wasm', 'app')
                .then(() => {
                    window.__loadResult = 'success';
                    resolve('success: ' + document.getElementById('app').innerHTML.substring(0, 200));
                })
                .catch(e => {
                    window.__loadResult = 'error';
                    resolve('error: ' + e.toString() + ' | stack: ' + (e.stack || 'none').substring(0, 300));
                });
        })
    "#).await.expect("Eval failed");
    println!("Load result: {:?}", result);
    
    ctx.close().await.expect("Failed to close browser");
}
