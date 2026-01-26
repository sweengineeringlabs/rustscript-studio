//! RustScript Studio - Visual IDE for RustScript
//!
//! Working version without @if blocks (conditional rendering is broken in runtime).
//! All UI elements are always visible. Once the runtime bug is fixed, we can
//! add conditional rendering back.

use rsc::prelude::*;

component App {
    // Core navigation state (signals work, but @if does not)
    let active_designer = signal("navigation");
    let canvas_zoom = signal(100);

    render {
        <div class="app" data-testid="app-root">
            // Activity Bar
            <div class="activity-bar" data-testid="activity-bar">
                <button
                    class="activity-item"
                    class:active={active_designer.get() == "navigation"}
                    title="Navigation Designer"
                    data-testid="activity-item-navigation"
                    on:click={|_| active_designer.set("navigation")}
                >
                    "Nav"
                </button>
                <button
                    class="activity-item"
                    class:active={active_designer.get() == "css"}
                    title="CSS Designer"
                    data-testid="activity-item-css"
                    on:click={|_| active_designer.set("css")}
                >
                    "CSS"
                </button>
                <button
                    class="activity-item"
                    class:active={active_designer.get() == "settings"}
                    title="Settings"
                    data-testid="activity-item-settings"
                    on:click={|_| active_designer.set("settings")}
                >
                    "Set"
                </button>
            </div>

            // Sidebar - always visible (no @if toggle)
            <div class="sidebar" data-testid="sidebar">
                <div class="navigation-sidebar" data-testid="navigation-sidebar">
                    <h3>"Workflows"</h3>
                    <button data-testid="add-workflow">"+ Add Workflow"</button>
                    <div data-testid="workflow-list" class="workflow-list">
                        <div class="workflow-item" data-testid="workflow-item">
                            <span class="workflow-name">"Main Flow"</span>
                            <span class="workflow-meta">"2 contexts"</span>
                        </div>
                        <div class="workflow-item" data-testid="workflow-item">
                            <span class="workflow-name">"Auth Flow"</span>
                            <span class="workflow-meta">"1 context"</span>
                        </div>
                    </div>
                </div>
            </div>

            // Main Area - always show navigation designer
            <div class="main-area" data-testid="main-area">
                <h1 data-testid="page-title">"Navigation Designer"</h1>
                <div class="navigation-designer-page">
                    <div data-testid="toolbar" class="toolbar">
                        <button data-testid="add-node">"+ Add Node"</button>
                        <div data-testid="zoom-controls" class="zoom-controls">
                            <button
                                class="zoom-out"
                                on:click={|_| {
                                    let z = canvas_zoom.get();
                                    if z > 50 {
                                        canvas_zoom.set(z - 10);
                                    }
                                }}
                            >
                                "-"
                            </button>
                            <button class="zoom-reset" on:click={|_| canvas_zoom.set(100)}>
                                {canvas_zoom.get()}"%"
                            </button>
                            <button
                                class="zoom-in"
                                on:click={|_| {
                                    let z = canvas_zoom.get();
                                    if z < 200 {
                                        canvas_zoom.set(z + 10);
                                    }
                                }}
                            >
                                "+"
                            </button>
                        </div>
                    </div>
                    <div data-testid="flow-canvas" class="flow-canvas">
                        <div class="flow-node flow-node-workflow" data-testid="flow-node">
                            "Main Flow"
                        </div>
                        <div class="flow-node flow-node-context" data-testid="flow-node">
                            "Default Context"
                        </div>
                    </div>
                    <div data-testid="minimap" class="minimap">"Mini"</div>
                    <div data-testid="bottom-panel" class="bottom-panel">
                        <span>"Properties"</span>
                    </div>
                </div>
            </div>
        </div>
    }
}
