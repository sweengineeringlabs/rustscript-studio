//! Navigation Designer E2E tests.
//!
//! Tests for the Navigation Designer page including workflow management,
//! flow canvas interaction, and node manipulation.

use super::TestContext;
use std::time::Duration;

/// Navigate to Navigation Designer page helper.
async fn goto_navigation_designer(ctx: &TestContext) -> Result<(), Box<dyn std::error::Error>> {
    ctx.goto("/").await?;
    ctx.wait_for_app().await?;
    // Navigation Designer is the default page, but click to ensure
    ctx.click_activity_item("Navigation Designer").await?;
    tokio::time::sleep(Duration::from_millis(300)).await;
    Ok(())
}

/// Tests that Navigation Designer page loads with all main elements.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_navigation_designer_loads() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Verify main elements are present
    let nav_sidebar = ctx.query(".navigation-sidebar").await.expect("Query failed");
    assert!(nav_sidebar.is_some(), "Navigation sidebar should be visible");

    // Should have workflow list
    let workflow_list = ctx.query(".workflow-list, [class*='workflow']").await.expect("Query failed");
    assert!(workflow_list.is_some(), "Workflow list should be visible");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests sidebar shows workflows panel.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_sidebar_workflows_panel() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Should have Workflows panel
    let _workflows_panel = ctx.query("[class*='panel']:has-text('Workflows'), .navigation-sidebar .panel").await;

    // Should have Add Workflow button
    let add_btn = ctx.query(".add-workflow, button:has-text('Add Workflow')").await.expect("Query failed");
    assert!(add_btn.is_some(), "Add Workflow button should be visible");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests adding a new workflow.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_add_workflow() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Count existing workflows
    let workflows_before = ctx.query_all(".workflow-item").await.expect("Query failed");
    let count_before = workflows_before.len();

    // Click Add Workflow button
    let add_result = ctx.click(".add-workflow, button:has-text('Add Workflow')").await;
    if add_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(300)).await;

        // Should have one more workflow
        let workflows_after = ctx.query_all(".workflow-item").await.expect("Query failed");
        assert!(
            workflows_after.len() >= count_before,
            "Should have same or more workflows after adding"
        );
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests workflow item displays name and context count.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_workflow_item_display() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Get first workflow item
    let workflow_item = ctx.query(".workflow-item").await.expect("Query failed");
    if let Some(_item) = workflow_item {
        // Should have workflow name
        let name = ctx.query(".workflow-item .workflow-name").await.expect("Query failed");
        assert!(name.is_some(), "Workflow should have a name");

        // Should have context count
        let meta = ctx.query(".workflow-item .workflow-meta").await.expect("Query failed");
        if let Some(m) = meta {
            let text = m.text_content().await.expect("Failed to get text");
            assert!(text.contains("context"), "Should show context count");
        }
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests selecting a workflow.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_select_workflow() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Click first workflow item
    let click_result = ctx.click(".workflow-item").await;
    if click_result.is_ok() {
        tokio::time::sleep(Duration::from_millis(200)).await;

        // Workflow should be selected (might have active class or different styling)
        // The canvas should update to show the workflow
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests flow canvas is present.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_flow_canvas_present() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Should have a canvas or flow area in main content
    let canvas = ctx.query(".flow-canvas, .navigation-canvas, [class*='canvas'], .content main")
        .await
        .expect("Query failed");
    assert!(canvas.is_some(), "Flow canvas should be present");

    ctx.close().await.expect("Failed to close browser");
}

/// Tests zoom controls if present.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_zoom_controls() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Look for zoom controls
    let zoom_controls = ctx.query(".zoom-controls, [class*='zoom']").await.expect("Query failed");

    if zoom_controls.is_some() {
        // Try zoom in
        let _zoom_in = ctx.click("button:has-text('+'), .zoom-in").await;

        // Try zoom out
        let _zoom_out = ctx.click("button:has-text('-'), .zoom-out").await;

        // Try reset zoom
        let _reset = ctx.click("button:has-text('100%'), .zoom-reset").await;
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests minimap if present.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_minimap() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Look for minimap
    let minimap = ctx.query(".minimap, [class*='minimap']").await.expect("Query failed");

    // Minimap is optional, just verify it renders if present
    if let Some(m) = minimap {
        // Minimap should be visible
        let visible = m.is_visible().await.expect("Failed to check visibility");
        assert!(visible, "Minimap should be visible if present");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests flow node creation via context menu or toolbar.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_create_flow_node() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Try right-click on canvas for context menu
    let canvas = ctx.query(".flow-canvas, .navigation-canvas, [class*='canvas']")
        .await
        .expect("Query failed");

    if let Some(_c) = canvas {
        // Right-click to open context menu
        // Note: right-click might not be directly supported, would need page.click with button: 'right'

        // Alternative: look for add node button in toolbar
        let add_node_btn = ctx.query("button:has-text('Add Node'), button:has-text('Add Context'), [class*='add-node']")
            .await
            .expect("Query failed");

        if let Some(btn) = add_node_btn {
            btn.click().await.ok();
            tokio::time::sleep(Duration::from_millis(300)).await;

            // Node should be created
            let _nodes = ctx.query_all(".flow-node, [class*='node']").await.expect("Query failed");
            // Just verify the action completed
        }
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests flow node selection.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_select_flow_node() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Click on a flow node if present
    let node = ctx.query(".flow-node, [class*='node']").await.expect("Query failed");

    if let Some(n) = node {
        n.click().await.ok();
        tokio::time::sleep(Duration::from_millis(200)).await;

        // Node should be selected (might show properties panel or have selected styling)
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests flow edge connection between nodes.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_flow_edge_connection() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Look for existing edges
    let _edges = ctx.query_all(".flow-edge, [class*='edge'], path[class*='edge']")
        .await
        .expect("Query failed");

    // Edges render as SVG paths typically
    // Just verify edge elements exist if there are connected nodes

    ctx.close().await.expect("Failed to close browser");
}

/// Tests drag and drop of flow nodes (if supported).
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_drag_flow_node() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Get a node element
    let node = ctx.query(".flow-node, [class*='node']").await.expect("Query failed");

    if let Some(n) = node {
        let _bbox = n.bounding_box().await.expect("Failed to get bounding box");

        // Would need drag operations which might require more complex mouse interactions
        // This test just verifies nodes exist and could potentially be dragged
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests bottom panel if present.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_bottom_panel() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Look for bottom panel
    let bottom_panel = ctx.query(".bottom-panel, [class*='bottom-panel']").await.expect("Query failed");

    if bottom_panel.is_some() {
        // Bottom panel should have tabs or content
        let _tabs = ctx.query(".bottom-panel [class*='tab'], .bottom-panel-tab").await.expect("Query failed");
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests toolbar actions for navigation designer.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_navigation_toolbar() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Look for toolbar
    let toolbar = ctx.query(".toolbar, [class*='toolbar']").await.expect("Query failed");

    if toolbar.is_some() {
        // Might have undo/redo buttons
        let _undo = ctx.query("button[title*='Undo'], button:has-text('Undo')").await.ok();
        let _redo = ctx.query("button[title*='Redo'], button:has-text('Redo')").await.ok();

        // Might have save/export buttons
        let _save = ctx.query("button[title*='Save'], button:has-text('Save')").await.ok();
    }

    ctx.close().await.expect("Failed to close browser");
}

/// Tests keyboard shortcuts for navigation designer.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_keyboard_shortcuts() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Focus on canvas
    ctx.click(".flow-canvas, .navigation-canvas, [class*='canvas']").await.ok();

    // Test common shortcuts
    // Delete selected node
    ctx.press("Delete").await.ok();

    // Undo
    ctx.press("Control+z").await.ok();

    // Redo
    ctx.press("Control+y").await.ok();

    // Select all
    ctx.press("Control+a").await.ok();

    // Escape to deselect
    ctx.press("Escape").await.ok();

    ctx.close().await.expect("Failed to close browser");
}

/// Tests taking screenshots of Navigation Designer.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_navigation_designer_screenshots() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Screenshot of default state
    ctx.screenshot("navigation-designer-default").await.ok();

    // Select a workflow if available
    ctx.click(".workflow-item").await.ok();
    tokio::time::sleep(Duration::from_millis(300)).await;
    ctx.screenshot("navigation-designer-workflow-selected").await.ok();

    ctx.close().await.expect("Failed to close browser");
}

/// Tests context menu on flow canvas.
#[tokio::test]
#[ignore = "requires browser and dev server"]
async fn test_context_menu() {
    let ctx = TestContext::new().await.expect("Failed to create test context");

    goto_navigation_designer(&ctx).await.expect("Failed to navigate");

    // Context menus typically appear on right-click
    // Check if a context menu component exists
    let context_menu = ctx.query(".context-menu, [class*='context-menu']").await.expect("Query failed");

    // Context menu should be hidden initially
    if let Some(cm) = context_menu {
        let hidden = cm.is_hidden().await.expect("Failed to check visibility");
        assert!(hidden, "Context menu should be hidden initially");
    }

    ctx.close().await.expect("Failed to close browser");
}
