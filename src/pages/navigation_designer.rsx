//! Navigation designer page - visual workflow/context/preset editor.

use rsc::prelude::*;

use rsc_flow::prelude::{FlowCanvas as RscFlowCanvas, LayoutConfig, LayoutDirection};
use rsc_studio::designer::navigation::{NavigationDesigner, NavigationNodeData, EntityType};

use crate::components::{FlowCanvasView, Toolbar, ToolbarGroup, ToolbarButton, ToolbarDivider, Button, ButtonVariant, ButtonSize, Icon};
use crate::hooks::StudioStore;

/// Navigation designer page.
#[component]
pub fn NavigationDesignerPage(store: StudioStore) -> Element {
    let canvas = use_signal(|| {
        let mut designer = NavigationDesigner::new();
        let workflows = store.workflows();
        let workflow_refs: Vec<_> = workflows.iter().collect();
        designer.load_workflows(&workflow_refs);
        designer.canvas
    });

    let selected_node = use_signal::<Option<String>>(|| None);
    let zoom_level = use_signal(|| 100);

    // Toolbar actions
    let on_add_workflow = move |_| {
        store.add_workflow("New Workflow");
        // Reload canvas
        let workflows = store.workflows();
        let workflow_refs: Vec<_> = workflows.iter().collect();
        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&workflow_refs);
        canvas.set(designer.canvas);
    };

    let on_zoom_in = move |_| {
        zoom_level.update(|z| *z = (*z + 10).min(200));
        canvas.update(|c| {
            c.viewport.zoom = zoom_level.get() as f64 / 100.0;
        });
    };

    let on_zoom_out = move |_| {
        zoom_level.update(|z| *z = (*z - 10).max(25));
        canvas.update(|c| {
            c.viewport.zoom = zoom_level.get() as f64 / 100.0;
        });
    };

    let on_fit_view = move |_| {
        canvas.update(|c| {
            c.fit_view(50.0, rsc_flow::prelude::Dimensions::new(800.0, 600.0));
        });
        zoom_level.set(100);
    };

    let on_auto_layout = move |_| {
        canvas.update(|c| {
            c.auto_layout(LayoutConfig {
                direction: LayoutDirection::TopToBottom,
                node_sep: 80.0,
                rank_sep: 120.0,
                ..Default::default()
            });
        });
    };

    rsx! {
        div(class: "navigation-designer-page", style: styles::container()) {
            // Toolbar
            Toolbar {
                ToolbarGroup {
                    ToolbarButton {
                        icon: "plus".to_string(),
                        label: Some("Add Workflow".to_string()),
                        onclick: on_add_workflow,
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "zoom-in".to_string(),
                        onclick: on_zoom_in,
                    }

                    span(style: styles::zoom_label()) {
                        { format!("{}%", zoom_level.get()) }
                    }

                    ToolbarButton {
                        icon: "zoom-out".to_string(),
                        onclick: on_zoom_out,
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "maximize".to_string(),
                        label: Some("Fit".to_string()),
                        onclick: on_fit_view,
                    }

                    ToolbarButton {
                        icon: "layout".to_string(),
                        label: Some("Auto Layout".to_string()),
                        onclick: on_auto_layout,
                    }
                }
            }

            // Canvas area
            div(class: "canvas-container", style: styles::canvas_container()) {
                FlowCanvasView {
                    canvas: canvas.clone(),
                    on_node_select: Some(Callback::new(move |id: String| {
                        selected_node.set(Some(id));
                    })),
                    on_node_move: Some(Callback::new(move |(id, pos): (String, rsc_flow::prelude::Position)| {
                        canvas.update(|c| {
                            if let Some(node) = c.nodes.get_mut(&id) {
                                node.position = pos;
                            }
                        });
                    })),
                }

                // Empty state
                if store.workflows().is_empty() {
                    EmptyState {
                        on_add: on_add_workflow,
                        on_load_sample: move |_| {
                            store.load_sample_data();
                            // Reload canvas
                            let workflows = store.workflows();
                            let workflow_refs: Vec<_> = workflows.iter().collect();
                            let mut designer = NavigationDesigner::new();
                            designer.load_workflows(&workflow_refs);
                            canvas.set(designer.canvas);
                        },
                    }
                }
            }

            // Selection details panel (if a node is selected)
            if let Some(node_id) = selected_node.get() {
                NodeDetailsPanel {
                    canvas: canvas.clone(),
                    node_id: node_id,
                    on_close: move |_| selected_node.set(None),
                }
            }
        }
    }
}

/// Empty state when no workflows exist.
#[component]
fn EmptyState(on_add: Callback<()>, on_load_sample: Callback<()>) -> Element {
    rsx! {
        div(class: "empty-state", style: styles::empty_state()) {
            Icon { name: "git-branch".to_string(), size: 48 }
            h2(style: styles::empty_title()) { "No Workflows Yet" }
            p(style: styles::empty_description()) {
                "Create your first workflow to start designing navigation flows."
            }
            div(class: "empty-actions", style: styles::empty_actions()) {
                Button {
                    variant: ButtonVariant::Primary,
                    onclick: on_add.clone(),
                } {
                    Icon { name: "plus".to_string() }
                    "Create Workflow"
                }
                Button {
                    variant: ButtonVariant::Secondary,
                    onclick: on_load_sample.clone(),
                } {
                    Icon { name: "download".to_string() }
                    "Load Sample Data"
                }
            }
        }
    }
}

/// Node details panel.
#[component]
fn NodeDetailsPanel(
    canvas: Signal<RscFlowCanvas<NavigationNodeData, ()>>,
    node_id: String,
    on_close: Callback<()>,
) -> Element {
    let canvas_value = canvas.get();
    let node = canvas_value.nodes.get(&node_id);

    let Some(node) = node else {
        return rsx! {};
    };

    let data = node.data.as_ref();

    rsx! {
        div(class: "node-details-panel", style: styles::details_panel()) {
            div(class: "panel-header", style: styles::panel_header()) {
                h3(style: styles::panel_title()) {
                    { data.map(|d| d.label.clone()).unwrap_or_else(|| node_id.clone()) }
                }
                Button {
                    variant: ButtonVariant::Ghost,
                    size: ButtonSize::Sm,
                    onclick: on_close.clone(),
                } {
                    Icon { name: "x".to_string() }
                }
            }

            div(class: "panel-content", style: styles::panel_content()) {
                if let Some(data) = data {
                    div(class: "detail-row") {
                        span(class: "detail-label") { "Type" }
                        span(class: "detail-value") {
                            { format!("{:?}", data.entity_type) }
                        }
                    }

                    if let Some(ref desc) = data.description {
                        div(class: "detail-row") {
                            span(class: "detail-label") { "Description" }
                            span(class: "detail-value") { { desc.clone() } }
                        }
                    }

                    div(class: "detail-row") {
                        span(class: "detail-label") { "Position" }
                        span(class: "detail-value") {
                            { format!("({:.0}, {:.0})", node.position.x, node.position.y) }
                        }
                    }
                }
            }
        }
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            height: 100%;
        "#
    }

    pub fn canvas_container() -> &'static str {
        r#"
            flex: 1;
            position: relative;
            overflow: hidden;
        "#
    }

    pub fn zoom_label() -> &'static str {
        r#"
            min-width: 48px;
            text-align: center;
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn empty_state() -> &'static str {
        r#"
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            color: var(--color-text-secondary);
        "#
    }

    pub fn empty_title() -> &'static str {
        r#"
            margin: var(--spacing-md) 0 var(--spacing-sm);
            font-size: var(--font-size-xl);
            color: var(--color-text-primary);
        "#
    }

    pub fn empty_description() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-lg);
            max-width: 300px;
        "#
    }

    pub fn empty_actions() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-md);
        "#
    }

    pub fn details_panel() -> &'static str {
        r#"
            position: absolute;
            top: var(--spacing-md);
            right: var(--spacing-md);
            width: 300px;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-lg);
            overflow: hidden;
        "#
    }

    pub fn panel_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: var(--spacing-sm) var(--spacing-md);
            border-bottom: 1px solid var(--color-border);
            background: var(--color-bg-secondary);
        "#
    }

    pub fn panel_title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-base);
            font-weight: var(--font-weight-semibold);
        "#
    }

    pub fn panel_content() -> &'static str {
        r#"
            padding: var(--spacing-md);
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }
}
