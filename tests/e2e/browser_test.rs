//! Browser tests using rsc-test e2e framework.
//!
//! These tests demonstrate the rsc-test e2e testing capabilities including:
//! - Page navigation and history
//! - Element interactions (click, fill, type, hover, etc.)
//! - Keyboard and touch input
//! - Screenshots and PDF generation
//! - Storage (localStorage, sessionStorage, cookies, IndexedDB)
//! - HAR recording and network idle
//! - Dialogs, Geolocation, Timezone
//! - Frames, Service Workers, Web Workers
//!
//! # Running Tests
//!
//! ```bash
//! # Start the dev server first
//! rsc dev --port 3000
//!
//! # Run browser tests
//! cargo test --test e2e browser_test -- --ignored --test-threads=1
//! ```

use rsc_test::e2e::{
    BrowserTestContext, BrowserTestConfig, BrowserTestError,
    PageAssertions, ElementAssertions,
    BrowserType, Viewport, LoadState,
    NetworkConditions, Permission, TracingOptions, VideoRecordingOptions,
};
use std::time::Duration;

/// Gets the base URL from environment or defaults to localhost.
fn base_url() -> String {
    std::env::var("RSC_TEST_&base_url()")
        .or_else(|_| std::env::var("RSC_TEST_PORT").map(|p| format!("http://localhost:{}", p)))
        .unwrap_or_else(|_| "http://localhost".to_string())
}

/// Creates a configured browser test context.
async fn create_context() -> Result<BrowserTestContext, BrowserTestError> {
    // Check if we should run headless (default true unless RSC_TEST_HEADLESS=false)
    let headless = std::env::var("RSC_TEST_HEADLESS")
        .map(|v| v != "false" && v != "0")
        .unwrap_or(true);

    let config = BrowserTestConfig::new()
        .browser(BrowserType::Chrome)
        .headless(headless)
        .viewport(Viewport::desktop())
        .timeout(Duration::from_secs(30))
        .base_url(&base_url());

    BrowserTestContext::new(config).await
}

// ============================================================================
// Navigation Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_app_loads_successfully() {
    let ctx = create_context().await.expect("Failed to create context");

    // Navigate to the app
    ctx.goto("/").await.expect("Failed to navigate");

    // Inject error handlers IMMEDIATELY to catch async errors
    ctx.evaluate(r#"
        window.__errors = [];
        window.onerror = function(msg, src, line, col, err) {
            window.__errors.push('onerror: ' + msg + ' at ' + src + ':' + line);
            return false;
        };
        window.addEventListener('unhandledrejection', function(e) {
            window.__errors.push('unhandled rejection: ' + (e.reason ? e.reason.message || e.reason : 'unknown'));
        });
        // Also intercept console.error
        const origError = console.error;
        console.error = function() {
            window.__errors.push('console.error: ' + Array.from(arguments).join(' '));
            origError.apply(console, arguments);
        };
    "#).await.expect("Failed to inject error handlers");

    // Check immediately before WASM loads
    let app_div_before = ctx.evaluate("!!document.getElementById('app')").await
        .expect("Failed to check app div");
    let body_before = ctx.evaluate("document.body.innerHTML.substring(0, 300)").await
        .expect("Failed to get body");
    println!("BEFORE WASM: app_div={:?}, body={:?}", app_div_before, body_before);

    // Give time for WASM to load and mount
    tokio::time::sleep(Duration::from_secs(3)).await;

    // Debug: check what's in the DOM and any errors
    let app_div = ctx.evaluate("!!document.getElementById('app')").await
        .expect("Failed to check app div");
    let activity_bar = ctx.evaluate("!!document.querySelector('.activity-bar')").await
        .expect("Failed to check activity bar");
    let body_html = ctx.evaluate("document.body ? document.body.innerHTML.substring(0, 500) : 'NO BODY'").await
        .expect("Failed to get body");
    println!("After 3s wait: app_div={:?}, activity_bar={:?}, body={:?}", app_div, activity_bar, body_html);

    // Check for captured errors
    let errors = ctx.evaluate("JSON.stringify(window.__errors || [])").await
        .expect("Failed to get errors");
    println!("Captured errors: {:?}", errors);

    // Try to manually call mount and see the result
    let manual_mount = ctx.evaluate(r#"
        (async function() {
            try {
                // Check if WASM is available
                const resp = await fetch('/__rsc__/wasm');
                if (!resp.ok) return 'WASM fetch failed: ' + resp.status;
                const bytes = await resp.arrayBuffer();

                // Instantiate manually with RustScript imports
                const imports = RustScript.createImports();
                const { instance } = await WebAssembly.instantiate(bytes, imports);

                // Check exports
                const exports = Object.keys(instance.exports).join(', ');

                // Initialize
                RustScript.initialize(instance, instance.exports.memory);

                // Check if app element exists
                const appEl = document.getElementById('app');
                if (!appEl) return 'ERROR: No app element in DOM';

                // Call mount
                const SCRATCH = 65536;
                const encoder = new TextEncoder();
                const rootIdBytes = encoder.encode('app');
                const view = new Uint8Array(instance.exports.memory.buffer, SCRATCH, rootIdBytes.length);
                view.set(rootIdBytes);

                const result = instance.exports.mount(SCRATCH, rootIdBytes.length);

                // Check what's in app element now
                const appInner = appEl.innerHTML;
                const appChildren = appEl.children.length;

                return 'mount returned: ' + result + ', app innerHTML length: ' + appInner.length + ', children: ' + appChildren + ', innerHTML: ' + appInner.substring(0, 200);
            } catch (e) {
                return 'ERROR: ' + e.message + ' at ' + e.stack;
            }
        })()
    "#).await.expect("Failed to manual mount");
    println!("Manual mount test: {:?}", manual_mount);

    // Check if RustScript is defined and if loadApp was called
    let rs_check = ctx.evaluate(r#"
        (function() {
            if (typeof RustScript === 'undefined') return 'RustScript undefined';
            if (typeof RustScript.loadApp !== 'function') return 'loadApp not a function';
            // Check if __rustscript_app was set (from the HTML's module script)
            if (window.__rustscript_app) return 'RustScript available, app already loaded';
            return 'RustScript available but app not loaded';
        })()
    "#).await.expect("Failed to check RustScript");
    println!("RustScript check: {:?}", rs_check);

    // Check for errors from the module script
    let load_error = ctx.evaluate("window.__rustscript_error || 'No error recorded'").await
        .expect("Failed to check error");
    println!("Load error: {:?}", load_error);

    // Get ALL appendChild calls to check for handle 1 being used as child
    let appends = ctx.evaluate(r#"
        (function() {
            if (typeof RustScript !== 'undefined' && RustScript.debug && RustScript.debug.getTimeline) {
                const timeline = RustScript.debug.getTimeline();
                const appends = timeline.filter(e => {
                    const msg = e.args.join(' ');
                    return msg.includes('appendChild');
                });
                // Focus on calls involving handle 1 or 2
                return JSON.stringify(appends.slice(0, 30), null, 2);
            }
            return 'Debug timeline not available';
        })()
    "#).await.expect("Failed to get appendChild calls");
    println!("All appendChild calls:\n{}", appends);

    // Wait for the auto-loaded app (set by the HTML's module script)
    // NOTE: Do NOT call loadApp again - it would cause duplication!
    let wait_result = ctx.evaluate(r#"
        (async function() {
            // Wait up to 5 seconds for the app to be loaded
            for (let i = 0; i < 50; i++) {
                if (window.__rustscript_app) {
                    const app = window.__rustscript_app;
                    return 'Auto-load success: ' + Object.keys(app.instance.exports).length + ' exports';
                }
                await new Promise(r => setTimeout(r, 100));
            }
            return 'Timeout waiting for auto-load';
        })()
    "#).await.expect("Failed to wait for auto-load");
    println!("Auto-load result: {:?}", wait_result);

    // Check DOM - app should already be rendered by auto-load
    tokio::time::sleep(Duration::from_millis(200)).await;
    let activity_bar_after = ctx.evaluate("!!document.querySelector('.activity-bar')").await
        .expect("Failed to check activity bar");
    println!("Activity bar present: {:?}", activity_bar_after);

    // Wait for the activity bar to be visible
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Assert the page title
    let title = ctx.title().await.expect("Failed to get title");
    assert!(!title.is_empty(), "Page should have a title");

    // Assert URL
    ctx.assert_url_contains("localhost").await.expect("URL assertion failed");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_navigation_history() {
    let ctx = create_context().await.expect("Failed to create context");

    // Navigate to home
    ctx.goto("/").await.expect("Failed to navigate to home");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Click on CSS Designer to navigate
    ctx.click(".activity-item[title='CSS Designer']").await.expect("Failed to click CSS Designer");
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Go back in history
    ctx.go_back().await.expect("Failed to go back");
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Go forward in history
    ctx.go_forward().await.expect("Failed to go forward");
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Reload the page
    ctx.reload().await.expect("Failed to reload");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found after reload");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_page_content() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Get page content
    let content = ctx.content().await.expect("Failed to get content");
    assert!(content.contains("<!DOCTYPE html>") || content.contains("<html"), "Should have HTML content");

    // Get current URL
    let url = ctx.url().await.expect("Failed to get URL");
    assert!(url.contains("localhost"), "URL should contain localhost");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Element Interaction Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_click_interactions() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Single click
    ctx.click(".activity-item[title='CSS Designer']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Double click (if applicable element exists)
    if ctx.query(".dblclick-target").await.expect("Query failed").is_some() {
        ctx.dblclick(".dblclick-target").await.expect("Failed to double click");
    }

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_form_interactions() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Navigate to a page with form elements (if available)
    ctx.click(".activity-item[title='CSS Designer']").await.expect("Failed to click");
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Test fill - clears and fills input
    if let Ok(Some(_)) = ctx.query("input[type='text']").await {
        ctx.fill("input[type='text']", "test value").await.expect("Failed to fill");
    }

    // Test type_text - types character by character
    if let Ok(Some(_)) = ctx.query("input.type-target").await {
        ctx.type_text("input.type-target", "typed text").await.expect("Failed to type");
    }

    // Test select dropdown
    if let Ok(Some(_)) = ctx.query("select").await {
        ctx.select("select", "option1").await.expect("Failed to select");
    }

    // Test checkbox
    if let Ok(Some(_)) = ctx.query("input[type='checkbox']").await {
        ctx.check("input[type='checkbox']").await.expect("Failed to check");
        ctx.uncheck("input[type='checkbox']").await.expect("Failed to uncheck");
    }

    // Test focus
    if let Ok(Some(_)) = ctx.query("input").await {
        ctx.focus("input").await.expect("Failed to focus");
    }

    // Test hover
    ctx.hover(".activity-item").await.expect("Failed to hover");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_element_querying() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Query single element
    let element = ctx.query(".activity-bar").await.expect("Query failed");
    assert!(element.is_some(), "Activity bar should exist");

    // Query all elements
    let activity_items = ctx.query_all(".activity-item").await.expect("Failed to query activity items");
    assert!(!activity_items.is_empty(), "Should have activity items");

    // Check element exists
    let exists = ctx.exists(".activity-bar").await.expect("Exists check failed");
    assert!(exists, "Activity bar should exist");

    // Count elements
    let count = ctx.count(".activity-item").await.expect("Count failed");
    assert!(count > 0, "Should have at least one activity item");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_element_assertions() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Get element and use ElementAssertions
    let element = ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Test visibility
    element.assert_visible().await.expect("Should be visible");

    // Test enabled state
    element.assert_enabled().await.expect("Should be enabled");

    // Test text content (if element has text)
    let text = element.text_content().await.expect("Failed to get text");
    if !text.is_empty() {
        element.assert_text_contains(&text[..text.len().min(10)]).await.ok();
    }

    // Test attribute
    if let Ok(Some(class)) = element.get_attribute("class").await {
        element.assert_has_attribute("class").await.expect("Should have class attribute");
        element.assert_class(&class.split_whitespace().next().unwrap_or("")).await.ok();
    }

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Keyboard Input Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_keyboard_input() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Press single key
    ctx.press_key("Escape").await.expect("Failed to press Escape");

    // Press arrow keys
    ctx.press_key("ArrowDown").await.expect("Failed to press ArrowDown");
    ctx.press_key("ArrowUp").await.expect("Failed to press ArrowUp");

    // Press Enter
    ctx.press_key("Enter").await.expect("Failed to press Enter");

    // Press Tab
    ctx.press_key("Tab").await.expect("Failed to press Tab");

    // Keyboard shortcut (Ctrl+A, Cmd+A, etc.)
    ctx.keyboard_shortcut("Control+a").await.expect("Failed to execute shortcut");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Touch Input Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_touch_input() {
    // Create context with mobile viewport for touch testing
    let config = BrowserTestConfig::new()
        .browser(BrowserType::Chrome)
        .headless(true)
        .viewport(Viewport::mobile())
        .timeout(Duration::from_secs(30))
        .base_url(&base_url());

    let ctx = BrowserTestContext::new(config).await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Tap on element
    ctx.tap(".activity-item").await.expect("Failed to tap");

    // Swipe gesture
    ctx.swipe(100.0, 300.0, 100.0, 100.0, Some(300)).await.expect("Failed to swipe");

    // Pinch gesture (zoom out)
    ctx.pinch(200.0, 300.0, 0.5, Some(10)).await.expect("Failed to pinch");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Drag and Drop Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_drag_and_drop() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Test drag and drop if draggable elements exist
    if let (Ok(Some(_)), Ok(Some(_))) = (
        ctx.query(".draggable").await,
        ctx.query(".droppable").await
    ) {
        ctx.drag_and_drop(".draggable", ".droppable").await.expect("Failed to drag and drop");
    }

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Screenshot Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_screenshot_capture() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Capture full page screenshot
    let screenshot = ctx.screenshot().await.expect("Failed to capture screenshot");
    assert!(!screenshot.is_empty(), "Screenshot should not be empty");

    // Save screenshot for manual inspection
    std::fs::create_dir_all("target/e2e-screenshots").ok();
    std::fs::write("target/e2e-screenshots/full-page.png", &screenshot)
        .expect("Failed to save screenshot");

    // Capture element screenshot
    let element_screenshot = ctx.screenshot_element(".activity-bar").await.expect("Failed to capture element screenshot");
    assert!(!element_screenshot.is_empty(), "Element screenshot should not be empty");

    std::fs::write("target/e2e-screenshots/activity-bar.png", &element_screenshot)
        .expect("Failed to save element screenshot");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// PDF Generation Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_pdf_generation() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");
    ctx.wait_for_load_state(LoadState::NetworkIdle).await.expect("Network not idle");

    // Generate PDF
    let pdf = ctx.pdf().await.expect("Failed to generate PDF");
    assert!(!pdf.is_empty(), "PDF should not be empty");

    // Save PDF for manual inspection
    std::fs::create_dir_all("target/e2e-screenshots").ok();
    std::fs::write("target/e2e-screenshots/page.pdf", &pdf)
        .expect("Failed to save PDF");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// JavaScript Evaluation Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_javascript_evaluation() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Evaluate simple expression
    let result = ctx.evaluate("1 + 1").await.expect("Failed to evaluate");
    assert_eq!(result.as_i64(), Some(2));

    // Evaluate to get page info
    let title = ctx.evaluate("document.title").await.expect("Failed to get title");
    assert!(title.is_string(), "Title should be a string");

    // Evaluate to get element count
    let count = ctx.evaluate("document.querySelectorAll('.activity-item').length").await
        .expect("Failed to count elements");
    assert!(count.as_i64().unwrap_or(0) > 0, "Should have activity items");

    // Evaluate to manipulate DOM
    ctx.evaluate("document.body.setAttribute('data-test', 'value')").await
        .expect("Failed to set attribute");
    let attr = ctx.evaluate("document.body.getAttribute('data-test')").await
        .expect("Failed to get attribute");
    assert_eq!(attr.as_str(), Some("value"));

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// localStorage Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_local_storage() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set localStorage value
    ctx.set_local_storage("test_key", "test_value").await.expect("Failed to set localStorage");

    // Get localStorage value
    let value = ctx.get_local_storage("test_key").await.expect("Failed to get localStorage");
    assert_eq!(value, Some("test_value".to_string()), "localStorage value mismatch");

    // Remove localStorage value
    ctx.remove_local_storage("test_key").await.expect("Failed to remove localStorage");
    let removed = ctx.get_local_storage("test_key").await.expect("Failed to check localStorage");
    assert!(removed.is_none(), "localStorage key should be removed");

    // Set multiple values
    ctx.set_local_storage("key1", "value1").await.expect("Failed to set key1");
    ctx.set_local_storage("key2", "value2").await.expect("Failed to set key2");

    // Clear all localStorage
    ctx.clear_local_storage().await.expect("Failed to clear localStorage");
    let cleared1 = ctx.get_local_storage("key1").await.expect("Failed to check key1");
    let cleared2 = ctx.get_local_storage("key2").await.expect("Failed to check key2");
    assert!(cleared1.is_none() && cleared2.is_none(), "localStorage should be cleared");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// sessionStorage Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_session_storage() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set sessionStorage value
    ctx.set_session_storage("session_key", "session_value").await.expect("Failed to set sessionStorage");

    // Get sessionStorage value
    let value = ctx.get_session_storage("session_key").await.expect("Failed to get sessionStorage");
    assert_eq!(value, Some("session_value".to_string()), "sessionStorage value mismatch");

    // Remove sessionStorage value
    ctx.remove_session_storage("session_key").await.expect("Failed to remove sessionStorage");
    let removed = ctx.get_session_storage("session_key").await.expect("Failed to check sessionStorage");
    assert!(removed.is_none(), "sessionStorage key should be removed");

    // Clear all sessionStorage
    ctx.set_session_storage("temp_key", "temp_value").await.expect("Failed to set temp key");
    ctx.clear_session_storage().await.expect("Failed to clear sessionStorage");
    let cleared = ctx.get_session_storage("temp_key").await.expect("Failed to check temp key");
    assert!(cleared.is_none(), "sessionStorage should be cleared");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Cookie Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_cookies() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Get cookies (via JavaScript)
    let cookies = ctx.get_cookies().await.expect("Failed to get cookies");
    let initial_count = cookies.len();

    // Set a cookie via JavaScript evaluation
    ctx.evaluate("document.cookie = 'test_cookie=test_value; path=/'").await
        .expect("Failed to set cookie");

    // Get cookies again
    let cookies_after = ctx.get_cookies().await.expect("Failed to get cookies");
    assert!(cookies_after.iter().any(|c| c.name == "test_cookie"), "Cookie should be set");

    // Delete the cookie
    ctx.evaluate("document.cookie = 'test_cookie=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;'").await
        .expect("Failed to delete cookie");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// IndexedDB Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_indexeddb() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Create a test database via JavaScript
    ctx.evaluate(r#"
        new Promise((resolve, reject) => {
            const request = indexedDB.open('test_db', 1);
            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                request.result.close();
                resolve();
            };
            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                db.createObjectStore('test_store', { keyPath: 'id' });
            };
        })
    "#).await.expect("Failed to create test database");

    // List IndexedDB databases
    let databases = ctx.indexeddb_databases().await.expect("Failed to list databases");
    // Note: databases list may or may not include the test_db depending on browser support

    // Delete the test database
    ctx.indexeddb_delete_database("test_db").await.expect("Failed to delete database");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Network Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_offline_mode() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set offline mode
    ctx.set_offline(true).await.expect("Failed to set offline");

    // Restore online mode
    ctx.set_offline(false).await.expect("Failed to restore online");

    // Test page still loads after restoring
    ctx.reload().await.expect("Failed to reload");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_network_conditions() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set slow 3G conditions
    ctx.set_network_conditions(NetworkConditions::slow_3g()).await
        .expect("Failed to set network conditions");

    // Test page still loads (slowly)
    ctx.reload().await.expect("Failed to reload with slow network");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Restore normal conditions
    ctx.set_network_conditions(NetworkConditions::no_throttle()).await
        .expect("Failed to restore network");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_har_recording() {
    let ctx = create_context().await.expect("Failed to create context");

    // Start HAR recording
    let recorder = ctx.start_har_recording().await.expect("Failed to start HAR recording");

    // Navigate and perform actions
    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");
    ctx.wait_for_load_state(LoadState::NetworkIdle).await.expect("Network not idle");

    // Stop HAR recording and get the HAR data
    let har = recorder.stop().await.expect("Failed to stop HAR recording");

    // HAR should contain entries
    assert!(!har.log.entries.is_empty(), "HAR should have entries");

    // Save HAR for inspection
    std::fs::create_dir_all("target/e2e-screenshots").ok();
    let har_json = serde_json::to_string_pretty(&har).expect("Failed to serialize HAR");
    std::fs::write("target/e2e-screenshots/network.har", har_json)
        .expect("Failed to save HAR");

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_wait_for_network_idle() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");

    // Wait for network idle
    ctx.wait_for_load_state(LoadState::NetworkIdle).await.expect("Network not idle");

    // Page should be fully loaded
    ctx.assert_element_exists(".activity-bar").await.expect("Activity bar should exist");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Dialog Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_dialog_handling() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set up auto-dismiss for dialogs
    ctx.set_default_dialog_handler(false).await.expect("Failed to set dialog handler");

    // Trigger an alert via JavaScript
    ctx.evaluate("setTimeout(() => alert('Test alert'), 100)").await.ok();
    tokio::time::sleep(Duration::from_millis(200)).await;

    // The dialog should be auto-dismissed

    // Set up auto-accept for dialogs
    ctx.set_default_dialog_handler(true).await.expect("Failed to set dialog handler");

    // Trigger a confirm dialog
    let result = ctx.evaluate("setTimeout(() => { window.confirmResult = confirm('Test confirm'); }, 100); true").await;
    tokio::time::sleep(Duration::from_millis(200)).await;

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Geolocation Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_geolocation() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set geolocation to San Francisco
    ctx.set_geolocation(37.7749, -122.4194, Some(100.0)).await
        .expect("Failed to set geolocation");

    // Verify via JavaScript
    let result = ctx.evaluate(r#"
        new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(
                (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
                (err) => reject(err.message),
                { timeout: 5000 }
            );
        })
    "#).await;

    if let Ok(pos) = result {
        if let Some(lat) = pos.get("lat").and_then(|v| v.as_f64()) {
            assert!((lat - 37.7749).abs() < 0.01, "Latitude should be ~37.7749");
        }
    }

    // Clear geolocation
    ctx.clear_geolocation().await.expect("Failed to clear geolocation");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Timezone Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_timezone() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Set timezone to Tokyo
    ctx.set_timezone("Asia/Tokyo").await.expect("Failed to set timezone");

    // Verify via JavaScript
    let tz = ctx.evaluate("Intl.DateTimeFormat().resolvedOptions().timeZone").await
        .expect("Failed to get timezone");
    assert_eq!(tz.as_str(), Some("Asia/Tokyo"));

    // Set timezone to New York
    ctx.set_timezone("America/New_York").await.expect("Failed to set timezone");
    let tz2 = ctx.evaluate("Intl.DateTimeFormat().resolvedOptions().timeZone").await
        .expect("Failed to get timezone");
    assert_eq!(tz2.as_str(), Some("America/New_York"));

    // Clear timezone override
    ctx.clear_timezone().await.expect("Failed to clear timezone");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Permissions Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_permissions() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Grant geolocation permission using abstraction type
    ctx.grant_permissions(&[Permission::Geolocation]).await
        .expect("Failed to grant permissions");

    // Query permission state via JavaScript
    let state = ctx.evaluate("navigator.permissions.query({ name: 'geolocation' }).then(p => p.state)").await
        .expect("Failed to query permission");
    assert_eq!(state.as_str(), Some("granted"));

    // Reset permissions
    ctx.reset_permissions().await.expect("Failed to reset permissions");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Frame Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_frames() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Get main frame
    let main_frame = ctx.main_frame().await.expect("Failed to get main frame");
    assert!(!main_frame.id.is_empty(), "Main frame should have an ID");

    // Get all frames
    let frames = ctx.frames().await.expect("Failed to get frames");
    assert!(!frames.is_empty(), "Should have at least one frame (main)");

    // Try to get frame by name (if any exist)
    let named_frame = ctx.frame("iframe-name").await.expect("Failed to query frame");
    // named_frame may be None if no iframe with that name exists

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Service Worker Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_service_workers() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");
    ctx.wait_for_load_state(LoadState::NetworkIdle).await.expect("Network not idle");

    // Get registered service workers
    let workers = ctx.service_workers().await.expect("Failed to get service workers");
    // May be empty if the app doesn't use service workers

    // If there are service workers, we can test operations
    if !workers.is_empty() {
        // Stop all service workers
        ctx.stop_all_service_workers().await.expect("Failed to stop service workers");
    }

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Web Worker Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_web_workers() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Get web workers
    let workers = ctx.web_workers().await.expect("Failed to get web workers");
    // May be empty if the app doesn't use web workers

    // Create a test worker via JavaScript
    ctx.evaluate(r#"
        window.testWorker = new Worker(URL.createObjectURL(new Blob([
            'self.onmessage = function(e) { self.postMessage(e.data * 2); }'
        ], { type: 'application/javascript' })));
    "#).await.ok();

    tokio::time::sleep(Duration::from_millis(100)).await;

    // Get workers again
    let workers_after = ctx.web_workers().await.expect("Failed to get web workers");

    // Terminate the test worker
    ctx.evaluate("window.testWorker && window.testWorker.terminate()").await.ok();

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Waiting Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_waiting_operations() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");

    // Wait for element
    ctx.wait_for(".activity-bar").await.expect("Failed to wait for activity bar");

    // Wait for load state - DomContentLoaded
    ctx.wait_for_load_state(LoadState::DomContentLoaded).await.expect("DOM not loaded");

    // Wait for load state - Load
    ctx.wait_for_load_state(LoadState::Load).await.expect("Page not loaded");

    // Wait for load state - NetworkIdle
    ctx.wait_for_load_state(LoadState::NetworkIdle).await.expect("Network not idle");

    // Wait for navigation (after click)
    ctx.click(".activity-item[title='CSS Designer']").await.ok();
    // wait_for_navigation would be called here if navigation occurs

    // Wait for URL change
    ctx.wait_for_url("localhost").await.expect("URL should contain localhost");

    // Wait for timeout
    ctx.wait_for_timeout(100).await;

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Page Assertions Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_page_assertions() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // URL assertions
    ctx.assert_url_contains("localhost").await.expect("URL should contain localhost");

    // Title assertions
    let title = ctx.title().await.expect("Failed to get title");
    if !title.is_empty() {
        ctx.assert_title(&title).await.expect("Title should match");
        ctx.assert_title_contains(&title[..title.len().min(5)]).await.expect("Title should contain substring");
    }

    // Element assertions
    ctx.assert_element_exists(".activity-bar").await.expect("Activity bar should exist");
    ctx.assert_element_not_exists(".non-existent-element-12345").await.expect("Non-existent should not exist");

    // Element count
    let count = ctx.count(".activity-item").await.expect("Failed to count");
    ctx.assert_element_count(".activity-item", count).await.expect("Count should match");

    // Text assertions
    ctx.assert_text_present("<!DOCTYPE html>").await.ok(); // HTML doctype
    ctx.assert_text_not_present("THIS_TEXT_SHOULD_NOT_EXIST_12345").await.expect("Text should not be present");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Responsive Viewport Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_responsive_viewports() {
    // Test with mobile viewport
    let mobile_config = BrowserTestConfig::new()
        .browser(BrowserType::Chrome)
        .headless(true)
        .viewport(Viewport::mobile())
        .timeout(Duration::from_secs(30))
        .base_url(&base_url());

    let ctx = BrowserTestContext::new(mobile_config).await.expect("Failed to create mobile context");
    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found on mobile");

    // Capture mobile screenshot
    let mobile_screenshot = ctx.screenshot().await.expect("Failed to capture mobile screenshot");
    std::fs::create_dir_all("target/e2e-screenshots").ok();
    std::fs::write("target/e2e-screenshots/mobile.png", &mobile_screenshot).expect("Failed to save");

    ctx.browser().close().await.expect("Failed to close browser");

    // Test with tablet viewport
    let tablet_config = BrowserTestConfig::new()
        .browser(BrowserType::Chrome)
        .headless(true)
        .viewport(Viewport::tablet())
        .timeout(Duration::from_secs(30))
        .base_url(&base_url());

    let ctx = BrowserTestContext::new(tablet_config).await.expect("Failed to create tablet context");
    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found on tablet");

    let tablet_screenshot = ctx.screenshot().await.expect("Failed to capture tablet screenshot");
    std::fs::write("target/e2e-screenshots/tablet.png", &tablet_screenshot).expect("Failed to save");

    ctx.browser().close().await.expect("Failed to close browser");

    // Test with desktop viewport
    let desktop_config = BrowserTestConfig::new()
        .browser(BrowserType::Chrome)
        .headless(true)
        .viewport(Viewport::desktop())
        .timeout(Duration::from_secs(30))
        .base_url(&base_url());

    let ctx = BrowserTestContext::new(desktop_config).await.expect("Failed to create desktop context");
    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found on desktop");

    let desktop_screenshot = ctx.screenshot().await.expect("Failed to capture desktop screenshot");
    std::fs::write("target/e2e-screenshots/desktop.png", &desktop_screenshot).expect("Failed to save");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Error Handling Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_404_handling() {
    let ctx = create_context().await.expect("Failed to create context");

    // Navigate to non-existent page
    ctx.goto("/non-existent-page-12345").await.expect("Failed to navigate");

    // App should handle 404 gracefully (either show error or redirect)
    tokio::time::sleep(Duration::from_secs(1)).await;

    // Page should still be functional
    let content = ctx.content().await.expect("Failed to get content");
    assert!(!content.is_empty(), "Page should have content");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Performance Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_page_load_performance() {
    let ctx = create_context().await.expect("Failed to create context");

    let start = std::time::Instant::now();

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");
    ctx.wait_for_load_state(LoadState::NetworkIdle).await.expect("Network not idle");

    let load_time = start.elapsed();

    // Page should load within reasonable time (10 seconds)
    assert!(
        load_time < Duration::from_secs(10),
        "Page load took too long: {:?}",
        load_time
    );

    println!("Page load time: {:?}", load_time);

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Multi-Page Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_multiple_pages() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Navigate through different pages
    let pages = [
        ("CSS Designer", ".css-designer-page"),
        ("Navigation Designer", ".navigation-designer-page"),
    ];

    for (title, _selector) in pages {
        let activity_selector = format!(".activity-item[title='{}']", title);
        if ctx.query(&activity_selector).await.expect("Query failed").is_some() {
            ctx.click(&activity_selector).await.expect(&format!("Failed to click {}", title));
            // Give time for page transition
            tokio::time::sleep(Duration::from_millis(500)).await;
        }
    }

    ctx.browser().close().await.expect("Failed to close browser");
}

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_new_page_creation() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Create a new page
    let new_page = ctx.new_page().await.expect("Failed to create new page");

    // Navigate new page to different URL
    new_page.goto(&format!("{}/", &base_url())).await.expect("Failed to navigate new page");

    // Both pages should work independently
    let title1 = ctx.title().await.expect("Failed to get title from first page");
    let title2 = new_page.title().await.expect("Failed to get title from second page");

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Tracing Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_tracing() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Ensure output directory exists
    std::fs::create_dir_all("target/e2e-screenshots").ok();

    // Start tracing with screenshots enabled using abstraction type
    let tracing_options = TracingOptions::new()
        .with_screenshots()
        .with_snapshots();

    let tracing_session = ctx.start_tracing(tracing_options).await
        .expect("Failed to start tracing");

    // Perform some actions to trace
    ctx.click(".activity-item[title='CSS Designer']").await.ok();
    tokio::time::sleep(Duration::from_millis(500)).await;
    ctx.go_back().await.ok();
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Stop tracing and save to specified path
    let trace_path = tracing_session.stop("target/e2e-screenshots/trace.json").await
        .expect("Failed to stop tracing");

    // Verify trace file was created
    assert!(trace_path.exists(), "Trace file should exist at {:?}", trace_path);

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Video Recording Tests
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_video_recording() {
    let ctx = create_context().await.expect("Failed to create context");

    ctx.goto("/").await.expect("Failed to navigate");
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found");

    // Ensure output directory exists
    std::fs::create_dir_all("target/e2e-screenshots").ok();

    // Start video recording using abstraction type
    let video_options = VideoRecordingOptions::new("target/e2e-screenshots/test-video.webm")
        .with_quality(80)
        .with_max_size(1280, 720);

    let video_recorder = ctx.start_video_recording(video_options).await
        .expect("Failed to start video recording");

    // Perform some actions to record
    ctx.click(".activity-item[title='CSS Designer']").await.ok();
    tokio::time::sleep(Duration::from_millis(500)).await;
    ctx.go_back().await.ok();
    tokio::time::sleep(Duration::from_millis(500)).await;
    ctx.reload().await.ok();
    ctx.wait_for(".activity-bar").await.expect("Activity bar not found after reload");

    // Stop video recording
    let video_path = video_recorder.stop().await.expect("Failed to stop video recording");

    // Verify video file was created
    assert!(video_path.exists(), "Video file should exist at {:?}", video_path);

    ctx.browser().close().await.expect("Failed to close browser");
}

// ============================================================================
// Debug Test for @if Conditional Rendering
// ============================================================================

#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_debug_conditional_rendering() {
    let ctx = create_context().await.expect("Failed to create context");

    // Navigate to the app, but check response immediately
    ctx.goto("/").await.expect("Failed to navigate");

    // Get the DOM state IMMEDIATELY after goto returns with a SINGLE evaluate call
    // Also intercept removeChild to capture the stack trace
    let immediate_state = ctx.evaluate(r#"
        (function() {
            const result = {
                bodyStart: document.body ? document.body.outerHTML.substring(0, 300) : 'NO BODY',
                divCount: document.querySelectorAll('div').length,
                appExists: !!document.getElementById('app'),
                timestamp: Date.now()
            };

            // Intercept various ways to remove elements
            window.__removalLog = [];

            // Intercept Node.prototype.removeChild (the base method)
            const originalNodeRemoveChild = Node.prototype.removeChild;
            Node.prototype.removeChild = function(child) {
                const stack = new Error().stack;
                if (child && child.id === 'app') {
                    window.__removalLog.push({
                        method: 'Node.prototype.removeChild',
                        parent: this.nodeName + (this.id ? '#' + this.id : ''),
                        child: child.nodeName + (child.id ? '#' + child.id : ''),
                        timestamp: Date.now(),
                        stack: stack
                    });
                }
                return originalNodeRemoveChild.call(this, child);
            };

            // Intercept Element.prototype.remove
            const originalRemove = Element.prototype.remove;
            Element.prototype.remove = function() {
                const stack = new Error().stack;
                if (this.id === 'app') {
                    window.__removalLog.push({
                        method: 'Element.remove',
                        element: this.nodeName + (this.id ? '#' + this.id : ''),
                        timestamp: Date.now(),
                        stack: stack
                    });
                }
                return originalRemove.call(this);
            };

            // Intercept document.write which could replace the body
            const originalDocWrite = document.write.bind(document);
            document.write = function(html) {
                window.__removalLog.push({
                    method: 'document.write',
                    htmlStart: html.substring(0, 100),
                    timestamp: Date.now(),
                    stack: new Error().stack
                });
                return originalDocWrite(html);
            };

            // Monitor for location changes
            window.__originalLocation = window.location.href;

            // Intercept innerHTML setter on body
            const bodyDescriptor = Object.getOwnPropertyDescriptor(Element.prototype, 'innerHTML');
            if (bodyDescriptor && bodyDescriptor.set) {
                const originalSetter = bodyDescriptor.set;
                Object.defineProperty(document.body, 'innerHTML', {
                    set: function(value) {
                        window.__removalLog.push({
                            method: 'body.innerHTML setter',
                            valueStart: value.substring(0, 100),
                            timestamp: Date.now(),
                            stack: new Error().stack
                        });
                        return originalSetter.call(this, value);
                    },
                    get: bodyDescriptor.get
                });
            }

            // Intercept replaceChildren
            const originalReplaceChildren = Element.prototype.replaceChildren;
            Element.prototype.replaceChildren = function(...nodes) {
                if (this === document.body) {
                    window.__removalLog.push({
                        method: 'body.replaceChildren',
                        nodeCount: nodes.length,
                        timestamp: Date.now(),
                        stack: new Error().stack
                    });
                }
                return originalReplaceChildren.apply(this, nodes);
            };

            // Set up mutation observer in the same call
            window.__mutationLog = [];
            const appDivForObserver = document.getElementById('app');
            if (appDivForObserver) {
                const observer = new MutationObserver((mutations) => {
                    for (const m of mutations) {
                        window.__mutationLog.push({
                            type: m.type,
                            target: m.target.tagName + (m.target.id ? '#' + m.target.id : ''),
                            removed: Array.from(m.removedNodes).map(n => n.nodeName + (n.id ? '#' + n.id : '')),
                            added: Array.from(m.addedNodes).map(n => n.nodeName + (n.id ? '#' + n.id : '')),
                            timestamp: Date.now()
                        });
                    }
                });
                observer.observe(document.body, { childList: true, subtree: true });
                window.__appDivObserver = observer;
            }

            result.observerAttached = !!appDivForObserver;
            return JSON.stringify(result);
        })()
    "#).await.expect("Failed to get immediate state");
    println!("IMMEDIATE state (single call): {:?}", immediate_state);

    // Check the actual URL we navigated to
    let current_url = ctx.url().await.expect("Failed to get URL");
    println!("Current URL: {:?}", current_url);

    // Check SUPER IMMEDIATELY (10ms)
    tokio::time::sleep(Duration::from_millis(10)).await;
    let div_at_10ms = ctx.evaluate("!!document.getElementById('app')").await
        .expect("Failed to check div at 10ms");
    println!("App div exists at 10ms: {:?}", div_at_10ms);

    // Check at 50ms
    tokio::time::sleep(Duration::from_millis(40)).await;
    let div_at_50ms = ctx.evaluate("!!document.getElementById('app')").await
        .expect("Failed to check div at 50ms");
    println!("App div exists at 50ms: {:?}", div_at_50ms);

    // Check at 100ms
    tokio::time::sleep(Duration::from_millis(50)).await;

    // Check the mutation log
    let mutation_log = ctx.evaluate("JSON.stringify(window.__mutationLog || [], null, 2)").await
        .expect("Failed to get mutation log");
    println!("Mutation log:\n{}", mutation_log);

    // Check the removal log with stack traces
    let removal_log = ctx.evaluate("JSON.stringify(window.__removalLog || [], null, 2)").await
        .expect("Failed to get removal log");
    println!("Removal log:\n{}", removal_log);

    // Get the full page source (original HTML from server)
    let page_content = ctx.content().await.expect("Failed to get content");
    let has_app_div_in_source = page_content.contains(r#"id="app""#);
    println!("Page source (ctx.content) contains 'id=\"app\"': {}", has_app_div_in_source);

    // Try fetching the HTML directly via JS to see what the server returns
    let fetch_result = ctx.evaluate(r#"
        (async function() {
            const response = await fetch('/');
            const text = await response.text();
            return text.includes('id="app"') ? 'HAS_APP_DIV' : 'NO_APP_DIV_BODY=' + text.substring(text.indexOf('<body>'), text.indexOf('<body>') + 200);
        })()
    "#).await.expect("Failed to fetch via JS");
    println!("Direct fetch contains 'id=\"app\"': {:?}", fetch_result);

    // Print the first 1000 chars of body content
    if let Some(body_start) = page_content.find("<body>") {
        let body_portion = &page_content[body_start..body_start.saturating_add(800).min(page_content.len())];
        println!("ctx.content() body start:\n{}", body_portion);
    }

    // Get the DOM body
    let initial_body = ctx.evaluate("document.body.outerHTML.substring(0, 500)").await
        .expect("Failed to get initial body");
    println!("INITIAL body (100ms): {:?}", initial_body);

    // Now wait for scripts to execute
    tokio::time::sleep(Duration::from_secs(2)).await;

    // Check if RustScript global exists
    let has_rustscript = ctx.evaluate("typeof RustScript !== 'undefined'").await
        .expect("Failed to check RustScript");
    println!("RustScript global exists: {:?}", has_rustscript);

    // Check what RustScript contains
    let rustscript_keys = ctx.evaluate("typeof RustScript !== 'undefined' ? Object.keys(RustScript) : 'not defined'").await
        .expect("Failed to get RustScript keys");
    println!("RustScript keys: {:?}", rustscript_keys);

    // Check if loadApp function exists
    let has_load_app = ctx.evaluate("typeof RustScript.loadApp === 'function'").await
        .expect("Failed to check loadApp");
    println!("Has loadApp: {:?}", has_load_app);

    // Check what divs exist
    let all_divs = ctx.evaluate("Array.from(document.querySelectorAll('div')).map(d => d.id || d.className || 'no-id-or-class').join(', ')").await
        .expect("Failed to get divs");
    println!("All divs: {:?}", all_divs);

    // Check the full document body children
    let body_children = ctx.evaluate("Array.from(document.body.children).map(c => c.tagName + (c.id ? '#' + c.id : '')).join(', ')").await
        .expect("Failed to get body children");
    println!("Body children: {:?}", body_children);

    // Check if there's an element with ID "app"
    let app_element = ctx.evaluate("document.getElementById('app') !== null").await
        .expect("Failed to check app element");
    println!("App element exists: {:?}", app_element);

    // Try loading the app manually and capture any errors
    let load_error = ctx.evaluate(r#"
        (function() {
            try {
                if (typeof RustScript === 'undefined') {
                    return 'RustScript not defined';
                }
                if (typeof RustScript.loadApp !== 'function') {
                    return 'loadApp not a function: ' + typeof RustScript.loadApp;
                }
                return 'loadApp is available';
            } catch (e) {
                return 'Error: ' + e.message;
            }
        })()
    "#).await.expect("Failed to check loadApp");
    println!("LoadApp check: {:?}", load_error);

    // Wait for the auto-loaded app (set by the HTML's module script)
    // NOTE: Do NOT call loadApp again - it would cause duplication!
    let _ = ctx.evaluate(r#"
        (async function() {
            window.__loadTestResult = 'waiting...';
            // Wait up to 5 seconds for the app to be loaded by the HTML's script
            for (let i = 0; i < 50; i++) {
                if (window.__rustscript_app) {
                    const app = window.__rustscript_app;
                    window.__loadTestResult = 'auto-load success: ' + Object.keys(app.instance.exports).length + ' exports';
                    return;
                }
                await new Promise(r => setTimeout(r, 100));
            }
            // If auto-load didn't happen, check for error
            if (window.__rustscript_error) {
                window.__loadTestResult = 'auto-load error: ' + window.__rustscript_error;
            } else {
                window.__loadTestResult = 'timeout waiting for auto-load';
            }
        })();
    "#).await;

    // Wait for the check to complete
    tokio::time::sleep(Duration::from_secs(3)).await;

    // Check the result
    let load_result = ctx.evaluate("window.__loadTestResult").await
        .expect("Failed to get load result");
    println!("Auto-load result: {:?}", load_result);

    // Wait a bit more after manual load
    tokio::time::sleep(Duration::from_millis(500)).await;

    // Get the body HTML to see what was rendered
    let body_html = ctx.evaluate("document.body.innerHTML").await
        .expect("Failed to get body innerHTML");
    println!("Body HTML length: {}", body_html.to_string().len());
    println!("Body HTML (truncated): {:?}", &body_html.to_string()[..500.min(body_html.to_string().len())]);

    // Get the app div content
    let app_html = ctx.evaluate("document.getElementById('app')?.innerHTML || 'app element not found'").await
        .expect("Failed to get app innerHTML");
    println!("App HTML: {:?}", app_html);

    // Check for any JS errors stored in window
    ctx.evaluate(r#"
        window.__jsErrors = [];
        window.onerror = function(msg, url, line, col, error) {
            window.__jsErrors.push({msg, url, line, col, error: error?.message});
            return false;
        };
    "#).await.ok();

    // Try to get the RustScript app state
    let app_state = ctx.evaluate(r#"
        (function() {
            const app = window.__rustscript_app;
            if (!app) return { error: 'No __rustscript_app found' };
            return {
                hasInstance: !!app.instance,
                hasMemory: !!app.memory,
                exports: app.instance ? Object.keys(app.instance.exports) : [],
            };
        })()
    "#).await.expect("Failed to get app state");
    println!("App state: {:?}", app_state);

    // Check the element count
    let element_count = ctx.evaluate("document.querySelectorAll('*').length").await
        .expect("Failed to count elements");
    println!("Total elements: {:?}", element_count);

    // Check for activity bar
    let has_activity_bar = ctx.evaluate("!!document.querySelector('.activity-bar')").await
        .expect("Failed to check activity bar");
    println!("Has activity bar: {:?}", has_activity_bar);

    // Check for sidebar
    let has_sidebar = ctx.evaluate("!!document.querySelector('.sidebar')").await
        .expect("Failed to check sidebar");
    println!("Has sidebar: {:?}", has_sidebar);

    // Take a screenshot for visual inspection
    std::fs::create_dir_all("target/e2e-screenshots").ok();
    let screenshot = ctx.screenshot().await.expect("Failed to capture screenshot");
    std::fs::write("target/e2e-screenshots/debug-conditional.png", &screenshot)
        .expect("Failed to save screenshot");
    println!("Screenshot saved to target/e2e-screenshots/debug-conditional.png");

    ctx.browser().close().await.expect("Failed to close browser");

    // Assert that rendering happened
    assert!(has_activity_bar.as_bool().unwrap_or(false), "Activity bar should be rendered");
}
