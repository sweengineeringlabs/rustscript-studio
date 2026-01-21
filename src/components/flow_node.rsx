//! Flow node component - draggable node in the flow canvas with snap-to-grid and connection support.

use rsc::prelude::*;

use rsc_flow::prelude::{Node, Position, NodeType};
use super::Icon;
use super::flow_canvas::StudioNode;

/// Snap a value to the nearest grid line.
fn snap_to_grid_value(value: f64, grid_size: f64) -> f64 {
    (value / grid_size).round() * grid_size
}

/// Flow node component with drag support, snap-to-grid, and edge connection.
///
/// ## Features
/// - Left click to select
/// - Drag to move (accounts for canvas zoom)
/// - Optional snap-to-grid when `snap_to_grid` is enabled
/// - Drag from handles to create connections
/// - Visual feedback when node is a valid connection target
component FlowNode(
    node: StudioNode,
    /// Current viewport zoom level (for scaling drag deltas)
    zoom?: f64,
    /// Whether snap-to-grid is enabled
    snap_to_grid?: bool,
    /// Grid size in pixels for snapping
    grid_size?: f64,
    on_select?: Callback<String>,
    on_move?: Callback<(String, Position)>,
    /// Callback when connection drag starts from this node (node_id, from_top, position)
    on_connection_start?: Callback<(String, bool, Position)>,
    /// Callback when connection ends on this node (node_id)
    on_connection_end?: Callback<String>,
    /// Whether this node is a valid connection target (while another node is being connected)
    is_connection_target?: bool,
) {
    let zoom = zoom.unwrap_or(1.0);
    let snap_to_grid = snap_to_grid.unwrap_or(false);
    let grid_size = grid_size.unwrap_or(20.0);
    let is_connection_target = is_connection_target.unwrap_or(false);

    let is_dragging = signal(false);
    let drag_start = signal(Position::zero());
    let node_start = signal(Position::zero());
    let is_handle_hovered = signal(false);

    let node_type = if let NodeType::Custom(t) = &node.node_type {
        t.as_str()
    } else {
        "default"
    };

    render {
        <div
            class={format!("flow-node flow-node-{}", node_type)}
            style={styles::node(
                &node.position,
                node_type,
                node.selected,
                is_dragging.get(),
                is_connection_target,
            )}
            on:mousedown={|e: MouseEvent| {
                if e.button() == 0 && node.draggable {
                    e.stop_propagation();
                    is_dragging.set(true);
                    drag_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
                    node_start.set(node.position);

                    if let Some(ref on_select) = on_select {
                        on_select.call(node.id.clone());
                    }
                }
            }}
            on:mousemove={|e: MouseEvent| {
                if is_dragging.get() {
                    let dx = (e.client_x() as f64 - drag_start.get().x) / zoom;
                    let dy = (e.client_y() as f64 - drag_start.get().y) / zoom;

                    let mut new_x = node_start.get().x + dx;
                    let mut new_y = node_start.get().y + dy;

                    if snap_to_grid {
                        new_x = snap_to_grid_value(new_x, grid_size);
                        new_y = snap_to_grid_value(new_y, grid_size);
                    }

                    let new_pos = Position::new(new_x, new_y);

                    if let Some(ref on_move) = on_move {
                        on_move.call((node.id.clone(), new_pos));
                    }
                }
            }}
            on:mouseup={|_: MouseEvent| {
                is_dragging.set(false);
            }}
        >
            // Header
            <div class="flow-node-header" style={styles::header(node_type)}>
                <Icon name={get_node_icon(node_type).to_string()} size={16} />
                <span style={styles::label()}>
                    {node.id.clone()}
                </span>
            </div>

            // Top connection handle (input)
            <div
                class="flow-node-handle flow-node-handle-top"
                style={styles::handle_top(is_connection_target, is_handle_hovered.get())}
                on:mousedown={|e: MouseEvent| {
                    if e.button() == 0 && node.connectable {
                        e.stop_propagation();
                        e.prevent_default();
                        if let Some(ref callback) = on_connection_start {
                            // Top handle position
                            let handle_pos = Position::new(node.position.x + 80.0, node.position.y);
                            callback.call((node.id.clone(), true, handle_pos));
                        }
                    }
                }}
                on:mouseup={|e: MouseEvent| {
                    if is_connection_target {
                        e.stop_propagation();
                        if let Some(ref callback) = on_connection_end {
                            callback.call(node.id.clone());
                        }
                    }
                }}
                on:mouseenter={|_: MouseEvent| {
                    is_handle_hovered.set(true);
                }}
                on:mouseleave={|_: MouseEvent| {
                    is_handle_hovered.set(false);
                }}
            />

            // Bottom connection handle (output)
            <div
                class="flow-node-handle flow-node-handle-bottom"
                style={styles::handle_bottom(is_connection_target, is_handle_hovered.get())}
                on:mousedown={|e: MouseEvent| {
                    if e.button() == 0 && node.connectable {
                        e.stop_propagation();
                        e.prevent_default();
                        if let Some(ref callback) = on_connection_start {
                            // Bottom handle position (approximate)
                            let handle_pos = Position::new(node.position.x + 80.0, node.position.y + 50.0);
                            callback.call((node.id.clone(), false, handle_pos));
                        }
                    }
                }}
                on:mouseup={|e: MouseEvent| {
                    if is_connection_target {
                        e.stop_propagation();
                        if let Some(ref callback) = on_connection_end {
                            callback.call(node.id.clone());
                        }
                    }
                }}
                on:mouseenter={|_: MouseEvent| {
                    is_handle_hovered.set(true);
                }}
                on:mouseleave={|_: MouseEvent| {
                    is_handle_hovered.set(false);
                }}
            />
        </div>
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

    pub fn node(
        pos: &Position,
        node_type: &str,
        selected: bool,
        is_dragging: bool,
        is_connection_target: bool,
    ) -> String {
        let border_color = match node_type {
            "workflow" => "var(--color-node-workflow)",
            "context" => "var(--color-node-context)",
            "preset" => "var(--color-node-preset)",
            _ => "var(--color-border)",
        };

        let selected_style = if selected {
            "box-shadow: 0 0 0 2px var(--color-primary);"
        } else if is_connection_target {
            "box-shadow: 0 0 0 2px var(--color-success);"
        } else {
            ""
        };

        let cursor = if is_dragging { "grabbing" } else { "grab" };
        let opacity = if is_dragging { "0.9" } else { "1" };
        let scale = if is_connection_target { "transform: scale(1.02);" } else { "" };

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
                transition: box-shadow 0.15s ease, transform 0.15s ease;
                {selected_style}
                {scale}
            "#,
            x = pos.x,
            y = pos.y,
            border_color = border_color,
            cursor = cursor,
            opacity = opacity,
            selected_style = selected_style,
            scale = scale,
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

    pub fn handle_top(is_connection_target: bool, is_hovered: bool) -> String {
        let (bg, border, scale) = if is_connection_target && is_hovered {
            ("var(--color-success)", "var(--color-success)", "scale(1.3)")
        } else if is_connection_target {
            ("var(--color-surface)", "var(--color-success)", "scale(1.1)")
        } else if is_hovered {
            ("var(--color-primary)", "var(--color-primary)", "scale(1.2)")
        } else {
            ("var(--color-surface)", "var(--color-border)", "scale(1)")
        };

        format!(
            r#"
                position: absolute;
                top: -6px;
                left: 50%;
                transform: translateX(-50%) {scale};
                width: 12px;
                height: 12px;
                background: {bg};
                border: 2px solid {border};
                border-radius: 50%;
                cursor: crosshair;
                transition: all 0.15s ease;
                z-index: 10;
            "#,
            bg = bg,
            border = border,
            scale = scale,
        )
    }

    pub fn handle_bottom(is_connection_target: bool, is_hovered: bool) -> String {
        let (bg, border, scale) = if is_connection_target && is_hovered {
            ("var(--color-success)", "var(--color-success)", "scale(1.3)")
        } else if is_connection_target {
            ("var(--color-surface)", "var(--color-success)", "scale(1.1)")
        } else if is_hovered {
            ("var(--color-primary)", "var(--color-primary)", "scale(1.2)")
        } else {
            ("var(--color-surface)", "var(--color-border)", "scale(1)")
        };

        format!(
            r#"
                position: absolute;
                bottom: -6px;
                left: 50%;
                transform: translateX(-50%) {scale};
                width: 12px;
                height: 12px;
                background: {bg};
                border: 2px solid {border};
                border-radius: 50%;
                cursor: crosshair;
                transition: all 0.15s ease;
                z-index: 10;
            "#,
            bg = bg,
            border = border,
            scale = scale,
        )
    }
}
