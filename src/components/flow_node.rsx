//! Flow node component - draggable node in the flow canvas with snap-to-grid support.

use rsc::prelude::*;

use rsc_flow::prelude::{Node, Position};
use super::Icon;

/// Flow node component props.
#[derive(Props)]
pub struct FlowNodeProps<T: Clone + 'static> {
    pub node: Node<T>,
    /// Current viewport zoom level (for scaling drag deltas)
    #[prop(default = 1.0)]
    pub zoom: f64,
    /// Whether snap-to-grid is enabled
    #[prop(default = false)]
    pub snap_to_grid: bool,
    /// Grid size in pixels for snapping
    #[prop(default = 20.0)]
    pub grid_size: f64,
    #[prop(default)]
    pub on_select: Option<Callback<String>>,
    #[prop(default)]
    pub on_move: Option<Callback<(String, Position)>>,
}

/// Snap a value to the nearest grid line.
fn snap_to_grid_value(value: f64, grid_size: f64) -> f64 {
    (value / grid_size).round() * grid_size
}

/// Flow node component with drag support and optional snap-to-grid.
///
/// ## Features
/// - Left click to select
/// - Drag to move (accounts for canvas zoom)
/// - Optional snap-to-grid when `snap_to_grid` is enabled
/// - Visual cursor feedback during drag
#[component]
pub fn FlowNode<T: Clone + 'static>(props: FlowNodeProps<T>) -> Element {
    let is_dragging = use_signal(|| false);
    let drag_start = use_signal(|| Position::zero());
    let node_start = use_signal(|| Position::zero());

    let node_type = match &props.node.node_type {
        rsc_flow::prelude::NodeType::Custom(t) => t.as_str(),
        _ => "default",
    };

    let on_mouse_down = {
        let id = props.node.id.clone();
        let pos = props.node.position;
        let draggable = props.node.draggable;
        move |e: MouseEvent| {
            if e.button() == 0 && draggable {
                // Left click and node is draggable
                e.stop_propagation(); // Prevent canvas pan
                is_dragging.set(true);
                drag_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
                node_start.set(pos);

                if let Some(ref on_select) = props.on_select {
                    on_select.call(id.clone());
                }
            }
        }
    };

    let on_mouse_move = {
        let id = props.node.id.clone();
        let zoom = props.zoom;
        let snap_enabled = props.snap_to_grid;
        let grid_size = props.grid_size;
        move |e: MouseEvent| {
            if is_dragging.get() {
                // Calculate delta in screen space, then convert to canvas space
                let dx = (e.client_x() as f64 - drag_start.get().x) / zoom;
                let dy = (e.client_y() as f64 - drag_start.get().y) / zoom;

                let mut new_x = node_start.get().x + dx;
                let mut new_y = node_start.get().y + dy;

                // Apply snap-to-grid if enabled
                if snap_enabled {
                    new_x = snap_to_grid_value(new_x, grid_size);
                    new_y = snap_to_grid_value(new_y, grid_size);
                }

                let new_pos = Position::new(new_x, new_y);

                if let Some(ref on_move) = props.on_move {
                    on_move.call((id.clone(), new_pos));
                }
            }
        }
    };

    let on_mouse_up = move |_: MouseEvent| {
        is_dragging.set(false);
    };

    // Handle mouse leaving the node during drag (continue tracking via window)
    let on_mouse_leave = {
        let id = props.node.id.clone();
        let zoom = props.zoom;
        let snap_enabled = props.snap_to_grid;
        let grid_size = props.grid_size;
        move |e: MouseEvent| {
            // If dragging and leaving node, we need to finalize position
            if is_dragging.get() {
                let dx = (e.client_x() as f64 - drag_start.get().x) / zoom;
                let dy = (e.client_y() as f64 - drag_start.get().y) / zoom;

                let mut new_x = node_start.get().x + dx;
                let mut new_y = node_start.get().y + dy;

                if snap_enabled {
                    new_x = snap_to_grid_value(new_x, grid_size);
                    new_y = snap_to_grid_value(new_y, grid_size);
                }

                let new_pos = Position::new(new_x, new_y);

                if let Some(ref on_move) = props.on_move {
                    on_move.call((id.clone(), new_pos));
                }
            }
        }
    };

    rsx! {
        div(
            class=format!("flow-node flow-node-{}", node_type),
            style=styles::node(&props.node.position, node_type, props.node.selected, is_dragging.get()),
            on:mousedown=on_mouse_down,
            on:mousemove=on_mouse_move,
            on:mouseup=on_mouse_up,
            on:mouseleave=on_mouse_leave,
        ) {
            // Header
            div(class="flow-node-header", style=styles::header(node_type)) {
                Icon { name: get_node_icon(node_type).to_string(), size: 16 }
                span(style=styles::label()) {
                    { props.node.id.clone() }
                }
            }

            // Connection handles
            div(class="flow-node-handle flow-node-handle-top", style=styles::handle_top())
            div(class="flow-node-handle flow-node-handle-bottom", style=styles::handle_bottom())
        }
    }
}

fn get_node_icon(node_type: &str) -> &str {
    match node_type {
        "workflow" => "git-branch",
        "context" => "layers",
        "preset" => "layout",
        _ => "circle",
    }
}

mod styles {
    use rsc_flow::prelude::Position;

    pub fn node(pos: &Position, node_type: &str, selected: bool, is_dragging: bool) -> String {
        let border_color = match node_type {
            "workflow" => "var(--color-node-workflow)",
            "context" => "var(--color-node-context)",
            "preset" => "var(--color-node-preset)",
            _ => "var(--color-border)",
        };

        let selected_style = if selected {
            "box-shadow: 0 0 0 2px var(--color-primary);"
        } else {
            ""
        };

        let cursor = if is_dragging { "grabbing" } else { "grab" };
        let opacity = if is_dragging { "0.9" } else { "1" };

        format!(
            r#"
                position: absolute;
                left: {x}px;
                top: {y}px;
                min-width: 160px;
                background: var(--color-surface);
                border: 2px solid {border_color};
                border-radius: var(--radius-lg);
                box-shadow: var(--shadow-md);
                cursor: {cursor};
                user-select: none;
                opacity: {opacity};
                transition: box-shadow 0.15s ease;
                {selected_style}
            "#,
            x = pos.x,
            y = pos.y,
            border_color = border_color,
            cursor = cursor,
            opacity = opacity,
            selected_style = selected_style,
        )
    }

    pub fn header(node_type: &str) -> String {
        let bg_color = match node_type {
            "workflow" => "var(--color-node-workflow)",
            "context" => "var(--color-node-context)",
            "preset" => "var(--color-node-preset)",
            _ => "var(--color-bg-secondary)",
        };

        format!(
            r#"
                display: flex;
                align-items: center;
                gap: var(--spacing-sm);
                padding: var(--spacing-sm) var(--spacing-md);
                background: {bg_color};
                color: var(--color-text-inverse);
                border-radius: var(--radius-md) var(--radius-md) 0 0;
                font-weight: var(--font-weight-medium);
                font-size: var(--font-size-sm);
            "#,
            bg_color = bg_color,
        )
    }

    pub fn label() -> &'static str {
        r#"
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        "#
    }

    pub fn handle_top() -> &'static str {
        r#"
            position: absolute;
            top: -6px;
            left: 50%;
            transform: translateX(-50%);
            width: 12px;
            height: 12px;
            background: var(--color-surface);
            border: 2px solid var(--color-border);
            border-radius: 50%;
            cursor: crosshair;
            transition: border-color 0.15s ease, transform 0.15s ease;
        "#
    }

    pub fn handle_bottom() -> &'static str {
        r#"
            position: absolute;
            bottom: -6px;
            left: 50%;
            transform: translateX(-50%);
            width: 12px;
            height: 12px;
            background: var(--color-surface);
            border: 2px solid var(--color-border);
            border-radius: 50%;
            cursor: crosshair;
            transition: border-color 0.15s ease, transform 0.15s ease;
        "#
    }
}
