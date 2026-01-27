//! RustScript Studio - Visual IDE for RustScript
//!
//! Full interactive UI with signals, event handlers, and conditional rendering.
//! Implements Navigation Designer, CSS Designer, and Settings pages.

use rsc::prelude::*;

// ============================================================================
// Data Models
// ============================================================================

struct Workflow {
    id: String,
    name: String,
    contexts: i32,
}

struct FlowNode {
    id: String,
    name: String,
    node_type: String,
    x: i32,
    y: i32,
}

struct Token {
    id: String,
    category: String,
    name: String,
    value: String,
}

// ============================================================================
// Helper Functions
// ============================================================================

fn get_initial_workflows() -> Vec<Workflow> {
    vec![
        Workflow { id: "main".to_string(), name: "Main Flow".to_string(), contexts: 2 },
        Workflow { id: "auth".to_string(), name: "Auth Flow".to_string(), contexts: 1 },
    ]
}

fn get_initial_nodes() -> Vec<FlowNode> {
    vec![
        FlowNode { id: "node-1".to_string(), name: "Main Flow".to_string(), node_type: "workflow".to_string(), x: 100, y: 100 },
        FlowNode { id: "node-2".to_string(), name: "Login Context".to_string(), node_type: "context".to_string(), x: 300, y: 100 },
    ]
}

fn get_initial_tokens() -> Vec<Token> {
    vec![
        // Colors
        Token { id: "color-primary".to_string(), category: "colors".to_string(), name: "Primary".to_string(), value: "#3b82f6".to_string() },
        Token { id: "color-secondary".to_string(), category: "colors".to_string(), name: "Secondary".to_string(), value: "#64748b".to_string() },
        Token { id: "color-success".to_string(), category: "colors".to_string(), name: "Success".to_string(), value: "#22c55e".to_string() },
        Token { id: "color-warning".to_string(), category: "colors".to_string(), name: "Warning".to_string(), value: "#f59e0b".to_string() },
        Token { id: "color-error".to_string(), category: "colors".to_string(), name: "Error".to_string(), value: "#ef4444".to_string() },
        Token { id: "color-bg".to_string(), category: "colors".to_string(), name: "Background".to_string(), value: "#ffffff".to_string() },
        // Spacing
        Token { id: "spacing-xs".to_string(), category: "spacing".to_string(), name: "Extra Small".to_string(), value: "0.25rem".to_string() },
        Token { id: "spacing-sm".to_string(), category: "spacing".to_string(), name: "Small".to_string(), value: "0.5rem".to_string() },
        Token { id: "spacing-md".to_string(), category: "spacing".to_string(), name: "Medium".to_string(), value: "1rem".to_string() },
        Token { id: "spacing-lg".to_string(), category: "spacing".to_string(), name: "Large".to_string(), value: "1.5rem".to_string() },
        Token { id: "spacing-xl".to_string(), category: "spacing".to_string(), name: "Extra Large".to_string(), value: "2rem".to_string() },
        // Radius
        Token { id: "radius-sm".to_string(), category: "radius".to_string(), name: "Small".to_string(), value: "0.25rem".to_string() },
        Token { id: "radius-md".to_string(), category: "radius".to_string(), name: "Medium".to_string(), value: "0.375rem".to_string() },
        Token { id: "radius-lg".to_string(), category: "radius".to_string(), name: "Large".to_string(), value: "0.5rem".to_string() },
        Token { id: "radius-full".to_string(), category: "radius".to_string(), name: "Full".to_string(), value: "9999px".to_string() },
        // Shadows
        Token { id: "shadow-sm".to_string(), category: "shadows".to_string(), name: "Small".to_string(), value: "0 1px 2px rgba(0,0,0,0.05)".to_string() },
        Token { id: "shadow-md".to_string(), category: "shadows".to_string(), name: "Medium".to_string(), value: "0 4px 6px rgba(0,0,0,0.1)".to_string() },
        Token { id: "shadow-lg".to_string(), category: "shadows".to_string(), name: "Large".to_string(), value: "0 10px 15px rgba(0,0,0,0.1)".to_string() },
    ]
}

fn generate_css_output(tokens: &Vec<Token>) -> String {
    let mut css = ":root {\n".to_string();
    for token in tokens {
        let var_name = format!("--{}-{}", token.category, token.name.to_lowercase().replace(" ", "-"));
        css.push_str(&format!("  {}: {};\n", var_name, token.value));
    }
    css.push_str("}\n");
    css
}

fn generate_json_output(tokens: &Vec<Token>) -> String {
    let mut json = "{\n".to_string();
    let mut categories: std::collections::HashMap<String, Vec<String>> = std::collections::HashMap::new();

    for token in tokens {
        let entry = format!("    \"{}\": \"{}\"", token.name.to_lowercase().replace(" ", "-"), token.value);
        categories.entry(token.category.clone()).or_insert(vec![]).push(entry);
    }

    let cat_strings: Vec<String> = categories.iter().map(|(cat, entries)| {
        format!("  \"{}\": {{\n{}\n  }}", cat, entries.join(",\n"))
    }).collect();

    json.push_str(&cat_strings.join(",\n"));
    json.push_str("\n}\n");
    json
}

// ============================================================================
// Main App Component
// ============================================================================

component App {
    // Core navigation state
    let active_designer = signal("navigation");
    let sidebar_visible = signal(true);
    let show_modal = signal(false);

    // Navigation Designer state
    let workflows = signal(get_initial_workflows());
    let selected_workflow = signal("");
    let flow_nodes = signal(get_initial_nodes());
    let selected_node = signal("");
    let canvas_zoom = signal(100);
    let workflow_name_input = signal("");

    // CSS Designer state
    let tokens = signal(get_initial_tokens());
    let selected_category = signal("colors");
    let selected_token = signal("");
    let preview_mode = signal("light");
    let show_export_modal = signal(false);
    let export_format = signal("css");
    let show_css_output = signal(true);

    // Settings state
    let auto_save = signal(true);
    let theme = signal("system");

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
                    // Navigation Designer Sidebar
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
                                @for workflow in workflows.get() {
                                    <div
                                        class="workflow-item"
                                        class:selected={selected_workflow.get() == workflow.id}
                                        data-testid="workflow-item"
                                        on:click={selected_workflow.set(workflow.id.clone())}
                                    >
                                        <span class="workflow-name">{workflow.name}</span>
                                        <span class="workflow-meta">{workflow.contexts}" contexts"</span>
                                    </div>
                                }
                            </div>
                        </div>
                    }

                    // CSS Designer Sidebar
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
                            <button
                                class:active={selected_category.get() == "radius"}
                                data-testid="category-radius"
                                on:click={selected_category.set("radius")}
                            >
                                "Radius"
                            </button>
                            <button
                                class:active={selected_category.get() == "shadows"}
                                data-testid="category-shadows"
                                on:click={selected_category.set("shadows")}
                            >
                                "Shadows"
                            </button>
                        </div>
                    }

                    // Settings Sidebar
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
                // Navigation Designer Page
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
                        <div data-testid="flow-canvas" class="flow-canvas" on:click={selected_node.set("")}>
                            @for node in flow_nodes.get() {
                                <div
                                    class="flow-node"
                                    class:selected={selected_node.get() == node.id}
                                    class:flow-node-workflow={node.node_type == "workflow"}
                                    class:flow-node-context={node.node_type == "context"}
                                    data-testid="flow-node"
                                    on:click|stop={selected_node.set(node.id.clone())}
                                >
                                    {node.name}
                                </div>
                            }
                        </div>
                        <div data-testid="bottom-panel" class="bottom-panel">
                            if selected_node.get() != "" {
                                <div class="node-properties">
                                    <h3>"Node Properties"</h3>
                                    <p>"ID: "{selected_node.get()}</p>
                                </div>
                            } else {
                                <p>"Select a node to view properties"</p>
                            }
                        </div>
                    </div>
                }

                // CSS Designer Page
                if active_designer.get() == "css" {
                    <h1 data-testid="page-title">"CSS Designer"</h1>
                    <div class="css-designer-page" data-testid="css-designer-page">
                        <div class="css-designer-content">
                            // Token Panel
                            <div data-testid="token-panel" class="token-panel">
                                <div class="token-panel-header">
                                    <h3>"Design Tokens"</h3>
                                    <div class="token-actions">
                                        <button>"Add Token"</button>
                                        <button>"Import"</button>
                                        <button data-testid="export-btn" on:click={show_export_modal.set(true)}>
                                            "Export"
                                        </button>
                                    </div>
                                </div>
                                <div data-testid="token-list" class="token-list">
                                    @for token in tokens.get().iter().filter(|t| t.category == selected_category.get()) {
                                        <div
                                            class="token-item"
                                            class:selected={selected_token.get() == token.id}
                                            on:click={selected_token.set(token.id.clone())}
                                        >
                                            <span class="token-name">{token.name.clone()}</span>
                                            if token.category == "colors" {
                                                <input
                                                    type="color"
                                                    value={token.value.clone()}
                                                    class="token-color-input"
                                                />
                                            }
                                            <input
                                                type="text"
                                                value={token.value.clone()}
                                                class="token-value-input"
                                            />
                                        </div>
                                    }
                                </div>
                            </div>

                            // Preview Pane
                            <div data-testid="preview-pane" class="preview-pane">
                                <div class="preview-header">
                                    <button
                                        class:active={preview_mode.get() == "light"}
                                        on:click={preview_mode.set("light")}
                                    >
                                        "Light"
                                    </button>
                                    <button
                                        class:active={preview_mode.get() == "dark"}
                                        on:click={preview_mode.set("dark")}
                                    >
                                        "Dark"
                                    </button>
                                    <button
                                        class:active={preview_mode.get() == "both"}
                                        on:click={preview_mode.set("both")}
                                    >
                                        "Both"
                                    </button>
                                    <button
                                        class:active={preview_mode.get() == "system"}
                                        on:click={preview_mode.set("system")}
                                    >
                                        "System"
                                    </button>
                                </div>
                                <div
                                    class="preview-content"
                                    class:dark-mode={preview_mode.get() == "dark"}
                                >
                                    <style>{generate_css_output(&tokens.get())}</style>
                                    <div class="preview-components">
                                        <button class="preview-button">"Sample Button"</button>
                                        <div class="preview-card">"Sample Card"</div>
                                        <input class="preview-input" placeholder="Sample Input" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        // CSS Output Panel
                        if show_css_output.get() {
                            <div data-testid="css-output-panel" class="css-output-panel">
                                <div class="css-output-header">
                                    <h4>"CSS Output"</h4>
                                    <button on:click={show_css_output.set(false)}>"Close"</button>
                                </div>
                                <pre><code>{generate_css_output(&tokens.get())}</code></pre>
                            </div>
                        }
                    </div>
                }

                // Settings Page
                if active_designer.get() == "settings" {
                    <h1 data-testid="page-title">"Settings"</h1>
                    <div class="settings-page">
                        <div class="settings-section">
                            <h2>"General"</h2>
                            <div class="setting-item">
                                <label>
                                    <input
                                        type="checkbox"
                                        checked={auto_save.get()}
                                        on:change={auto_save.set(!auto_save.get())}
                                    />
                                    "Auto-save"
                                </label>
                            </div>
                            <div class="setting-item">
                                <label>"Theme"</label>
                                <select on:change={|e| theme.set(e.target.value)}>
                                    <option value="light" selected={theme.get() == "light"}>"Light"</option>
                                    <option value="dark" selected={theme.get() == "dark"}>"Dark"</option>
                                    <option value="system" selected={theme.get() == "system"}>"System"</option>
                                </select>
                            </div>
                        </div>
                    </div>
                }
            </div>

            // Add Workflow Modal
            if show_modal.get() {
                <div
                    class="modal-overlay"
                    data-testid="add-workflow-modal"
                    on:click|self={show_modal.set(false)}
                >
                    <div class="modal-content" on:click|stop={}>
                        <h2>"Add Workflow"</h2>
                        <div class="form-group">
                            <label>"Name"</label>
                            <input
                                type="text"
                                placeholder="Workflow name"
                                data-testid="workflow-name-input"
                                value={workflow_name_input.get()}
                                on:input={|e| workflow_name_input.set(e.target.value)}
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
                                on:click={
                                    let name = workflow_name_input.get();
                                    if name != "" {
                                        let mut wfs = workflows.get();
                                        let new_id = format!("workflow-{}", wfs.len() + 1);
                                        wfs.push(Workflow {
                                            id: new_id,
                                            name: name,
                                            contexts: 0,
                                        });
                                        workflows.set(wfs);
                                        workflow_name_input.set("");
                                    }
                                    show_modal.set(false);
                                }
                            >
                                "Add"
                            </button>
                        </div>
                    </div>
                </div>
            }

            // Export Modal
            if show_export_modal.get() {
                <div
                    class="modal-overlay"
                    data-testid="export-modal"
                    on:click|self={show_export_modal.set(false)}
                >
                    <div class="modal-content" on:click|stop={}>
                        <h2>"Export Tokens"</h2>
                        <div class="export-format-selector">
                            <button
                                class:active={export_format.get() == "css"}
                                on:click={export_format.set("css")}
                            >
                                "CSS"
                            </button>
                            <button
                                class:active={export_format.get() == "json"}
                                on:click={export_format.set("json")}
                            >
                                "JSON"
                            </button>
                            <button
                                class:active={export_format.get() == "sass"}
                                on:click={export_format.set("sass")}
                            >
                                "Sass"
                            </button>
                        </div>
                        <div class="export-preview">
                            <pre><code>
                                if export_format.get() == "css" {
                                    {generate_css_output(&tokens.get())}
                                }
                                if export_format.get() == "json" {
                                    {generate_json_output(&tokens.get())}
                                }
                                if export_format.get() == "sass" {
                                    {generate_css_output(&tokens.get())}
                                }
                            </code></pre>
                        </div>
                        <div class="modal-actions">
                            <button on:click={show_export_modal.set(false)}>"Close"</button>
                            <button class="button-primary">"Copy to Clipboard"</button>
                        </div>
                    </div>
                </div>
            }
        </div>
    }
}
