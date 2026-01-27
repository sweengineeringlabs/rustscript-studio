//! RustScript Studio - Visual IDE for RustScript
//!
//! Full interactive UI with signals, event handlers, and conditional rendering.

use rsc::prelude::*;

component App {
    // Core navigation state
    let active_designer = signal("navigation");
    let sidebar_visible = signal(true);
    let show_modal = signal(false);
    let selected_workflow = signal("");
    let canvas_zoom = signal(100);
    let selected_category = signal("colors");

    render {
        <div class="app" data-testid="app-root">
            // Activity Bar
            <div class="activity-bar" data-testid="activity-bar">
                <button
                    class="activity-item"
                    class:active={active_designer.get() == "navigation"}
                    title="Navigation Designer"
                    data-testid="activity-item-navigation"
                    on:click={active_designer.set("navigation")}
                >
                    "Nav"
                </button>
                <button
                    class="activity-item"
                    class:active={active_designer.get() == "css"}
                    title="CSS Designer"
                    data-testid="activity-item-css"
                    on:click={active_designer.set("css")}
                >
                    "CSS"
                </button>
                <button
                    class="activity-item"
                    class:active={active_designer.get() == "settings"}
                    title="Settings"
                    data-testid="activity-item-settings"
                    on:click={active_designer.set("settings")}
                >
                    "Set"
                </button>
                <button
                    title="Toggle Sidebar"
                    data-testid="toggle-sidebar"
                    on:click={sidebar_visible.set(!sidebar_visible.get())}
                >
                    "Toggle"
                </button>
            </div>

            // Sidebar - conditionally rendered
            if sidebar_visible.get() {
                <div class="sidebar" data-testid="sidebar">
                    if active_designer.get() == "navigation" {
                        <div class="navigation-sidebar" data-testid="navigation-sidebar">
                            <h3>"Workflows"</h3>
                            <button
                                data-testid="add-workflow"
                                on:click={show_modal.set(true)}
                            >
                                "+ Add Workflow"
                            </button>
                            <div data-testid="workflow-list" class="workflow-list">
                                <div
                                    class="workflow-item"
                                    class:selected={selected_workflow.get() == "main"}
                                    data-testid="workflow-item"
                                    on:click={selected_workflow.set("main")}
                                >
                                    <span class="workflow-name">"Main Flow"</span>
                                    <span class="workflow-meta">"2 contexts"</span>
                                </div>
                                <div
                                    class="workflow-item"
                                    class:selected={selected_workflow.get() == "auth"}
                                    data-testid="workflow-item"
                                    on:click={selected_workflow.set("auth")}
                                >
                                    <span class="workflow-name">"Auth Flow"</span>
                                    <span class="workflow-meta">"1 context"</span>
                                </div>
                            </div>
                        </div>
                    }
                    if active_designer.get() == "css" {
                        <div class="css-sidebar" data-testid="css-sidebar">
                            <h3>"Categories"</h3>
                            <button
                                class:active={selected_category.get() == "colors"}
                                data-testid="category-colors"
                                on:click={selected_category.set("colors")}
                            >
                                "Colors"
                            </button>
                            <button
                                class:active={selected_category.get() == "spacing"}
                                data-testid="category-spacing"
                                on:click={selected_category.set("spacing")}
                            >
                                "Spacing"
                            </button>
                        </div>
                    }
                    if active_designer.get() == "settings" {
                        <div class="settings-sidebar" data-testid="settings-sidebar">
                            <h3>"Settings"</h3>
                            <div class="settings-menu">
                                <button class="settings-item">"General"</button>
                                <button class="settings-item">"Appearance"</button>
                            </div>
                        </div>
                    }
                </div>
            }

            // Main Area
            <div class="main-area" data-testid="main-area">
                if active_designer.get() == "navigation" {
                    <h1 data-testid="page-title">"Navigation Designer"</h1>
                    <div class="navigation-designer-page">
                        <div data-testid="toolbar" class="toolbar">
                            <button data-testid="add-node">"+ Add Node"</button>
                            <div data-testid="zoom-controls" class="zoom-controls">
                                <button
                                    class="zoom-out"
                                    on:click={canvas_zoom.set(canvas_zoom.get() - 10)}
                                >
                                    "-"
                                </button>
                                <button class="zoom-reset" on:click={canvas_zoom.set(100)}>
                                    {canvas_zoom.get()}"%"
                                </button>
                                <button
                                    class="zoom-in"
                                    on:click={canvas_zoom.set(canvas_zoom.get() + 10)}
                                >
                                    "+"
                                </button>
                            </div>
                        </div>
                        <div data-testid="flow-canvas" class="flow-canvas">
                            <div class="flow-node flow-node-workflow" data-testid="flow-node">
                                "Main Flow"
                            </div>
                        </div>
                    </div>
                }
                if active_designer.get() == "css" {
                    <h1 data-testid="page-title">"CSS Designer"</h1>
                    <div class="css-designer-page" data-testid="css-designer-page">
                        <div data-testid="token-panel" class="token-panel">
                            <h3>"Design Tokens"</h3>
                        </div>
                    </div>
                }
                if active_designer.get() == "settings" {
                    <h1 data-testid="page-title">"Settings"</h1>
                    <div class="settings-page">
                        <h2>"Settings"</h2>
                    </div>
                }
            </div>

            // Add Workflow Modal
            if show_modal.get() {
                <div
                    class="modal-overlay"
                    data-testid="add-workflow-modal"
                    on:click={show_modal.set(false)}
                >
                    <div class="modal-content">
                        <h2>"Add Workflow"</h2>
                        <div class="form-group">
                            <label>"Name"</label>
                            <input
                                type="text"
                                placeholder="Workflow name"
                                data-testid="workflow-name-input"
                            />
                        </div>
                        <div class="modal-actions">
                            <button
                                class="button-secondary"
                                on:click={show_modal.set(false)}
                            >
                                "Cancel"
                            </button>
                            <button
                                class="button-primary"
                                data-testid="submit-workflow"
                                on:click={show_modal.set(false)}
                            >
                                "Add"
                            </button>
                        </div>
                    </div>
                </div>
            }
        </div>
    }
}
