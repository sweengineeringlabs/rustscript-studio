//! Flow canvas component - interactive graph visualization with pan/zoom gestures.

use rsc::prelude::*;

use rsc_flow::prelude::*;
use super::{FlowNode, FlowEdge};

/// Connection state for edge creation by dragging.
#[derive(Debug, Clone, Default)]
pub struct ConnectionState {
    /// Source node ID (where the connection started)
    pub source_node: Option<String>,
    /// Whether connecting from top (true) or bottom (false) handle
    pub from_top: bool,
    /// Current mouse position in canvas coordinates
    pub current_pos: Position,
    /// Whether a connection drag is active
    pub is_connecting: bool,
}

/// Flow canvas component props.
#[derive(Props)]
pub struct FlowCanvasProps<N, E>
where
    N: Clone + 'static,
    E: Clone + 'static,
{
    pub canvas: Signal<FlowCanvas<N, E>>,
    #[prop(default)]
    pub on_node_select: Option<Callback<String>>,
    #[prop(default)]
    pub on_node_move: Option<Callback<(String, Position)>>,
    #[prop(default)]
    pub on_edge_select: Option<Callback<String>>,
    /// Callback when a new edge should be created (source_id, target_id)
    #[prop(default)]
    pub on_edge_create: Option<Callback<(String, String)>>,
}

/// Flow canvas component with pan/zoom gesture support and edge creation.
///
/// ## Gestures
/// - **Pan**: Middle mouse button drag
/// - **Zoom**: Mouse wheel (zooms towards cursor position)
/// - **Keyboard**: +/= to zoom in, - to zoom out, 0 to reset view
/// - **Connect**: Drag from node handle to another node to create edge
#[component]
pub fn FlowCanvasView<N, E>(props: FlowCanvasProps<N, E>) -> Element
where
    N: Clone + 'static,
    E: Clone + 'static,
{
    let canvas = props.canvas.get();
    let container_ref = use_node_ref();
    let is_panning = use_signal(|| false);
    let pan_start = use_signal(|| Position::zero());
    let viewport_start = use_signal(|| (0.0f64, 0.0f64));

    // Connection state for edge creation
    let connection = use_signal(|| ConnectionState::default());

    // Handle mouse down for panning (middle mouse button)
    let on_mouse_down = move |e: MouseEvent| {
        if e.button() == 1 {
            // Middle mouse button
            e.prevent_default();
            is_panning.set(true);
            pan_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
            let vp = props.canvas.get().viewport.transform;
            viewport_start.set((vp.x, vp.y));
        }
    };

    let on_mouse_move = {
        let connection = connection.clone();
        move |e: MouseEvent| {
            // Handle panning
            if is_panning.get() {
                let dx = e.client_x() as f64 - pan_start.get().x;
                let dy = e.client_y() as f64 - pan_start.get().y;
                let (start_x, start_y) = viewport_start.get();
                props.canvas.update(|c| {
                    if c.viewport.pan_enabled {
                        c.viewport.transform.x = start_x + dx;
                        c.viewport.transform.y = start_y + dy;
                    }
                });
            }

            // Handle connection dragging - update current position
            if connection.get().is_connecting {
                let canvas_data = props.canvas.get();
                let vp = &canvas_data.viewport.transform;
                // Convert screen position to canvas position
                let canvas_x = (e.offset_x() as f64 - vp.x) / vp.zoom;
                let canvas_y = (e.offset_y() as f64 - vp.y) / vp.zoom;
                connection.update(|c| {
                    c.current_pos = Position::new(canvas_x, canvas_y);
                });
            }
        }
    };

    let on_mouse_up = {
        let connection = connection.clone();
        move |_: MouseEvent| {
            is_panning.set(false);
            // Cancel any active connection if mouse up on canvas (not on a node handle)
            if connection.get().is_connecting {
                connection.update(|c| {
                    c.is_connecting = false;
                    c.source_node = None;
                });
            }
        }
    };

    let on_mouse_leave = {
        let connection = connection.clone();
        move |_: MouseEvent| {
            is_panning.set(false);
            // Cancel connection when leaving canvas
            if connection.get().is_connecting {
                connection.update(|c| {
                    c.is_connecting = false;
                    c.source_node = None;
                });
            }
        }
    };

    // Handle wheel for zooming towards mouse position (focal point zoom)
    let on_wheel = move |e: WheelEvent| {
        e.prevent_default();

        let canvas_data = props.canvas.get();
        if !canvas_data.viewport.zoom_enabled {
            return;
        }

        // Calculate zoom factor with smooth intensity
        let zoom_intensity = 0.08;
        let delta = if e.delta_y() > 0.0 { -zoom_intensity } else { zoom_intensity };
        let current_zoom = canvas_data.viewport.transform.zoom;
        let new_zoom = (current_zoom * (1.0 + delta))
            .clamp(canvas_data.viewport.min_zoom, canvas_data.viewport.max_zoom);

        // Skip if zoom didn't change (at limits)
        if (new_zoom - current_zoom).abs() < 0.0001 {
            return;
        }

        // Get mouse position relative to container for focal point zoom
        let mouse_x = e.offset_x() as f64;
        let mouse_y = e.offset_y() as f64;

        // Calculate the canvas point under the mouse before zoom
        let vp = &canvas_data.viewport.transform;
        let canvas_x = (mouse_x - vp.x) / vp.zoom;
        let canvas_y = (mouse_y - vp.y) / vp.zoom;

        // After zoom, that same canvas point should remain under the mouse
        let new_vp_x = mouse_x - canvas_x * new_zoom;
        let new_vp_y = mouse_y - canvas_y * new_zoom;

        props.canvas.update(|c| {
            c.viewport.transform.x = new_vp_x;
            c.viewport.transform.y = new_vp_y;
            c.viewport.transform.zoom = new_zoom;
        });
    };

    // Handle keyboard shortcuts for zoom control
    let on_key_down = move |e: KeyboardEvent| {
        let key = e.key();
        match key.as_str() {
            "+" | "=" => {
                e.prevent_default();
                props.canvas.update(|c| {
                    if c.viewport.zoom_enabled {
                        c.viewport.zoom_in(1.2);
                    }
                });
            }
            "-" => {
                e.prevent_default();
                props.canvas.update(|c| {
                    if c.viewport.zoom_enabled {
                        c.viewport.zoom_out(1.2);
                    }
                });
            }
            "0" => {
                e.prevent_default();
                props.canvas.update(|c| {
                    c.viewport.reset();
                });
            }
            "Escape" => {
                // Cancel any active connection
                connection.update(|c| {
                    c.is_connecting = false;
                    c.source_node = None;
                });
            }
            _ => {}
        }
    };

    let on_context_menu = move |e: MouseEvent| {
        e.prevent_default();
    };

    // Callbacks for node connection events
    let on_connection_start = {
        let connection = connection.clone();
        Callback::new(move |(node_id, from_top, pos): (String, bool, Position)| {
            connection.update(|c| {
                c.is_connecting = true;
                c.source_node = Some(node_id);
                c.from_top = from_top;
                c.current_pos = pos;
            });
        })
    };

    let on_connection_end = {
        let connection = connection.clone();
        let on_edge_create = props.on_edge_create.clone();
        Callback::new(move |target_node_id: String| {
            let conn = connection.get();
            if conn.is_connecting {
                if let Some(ref source_id) = conn.source_node {
                    // Don't allow self-connections
                    if source_id != &target_node_id {
                        if let Some(ref callback) = on_edge_create {
                            // Direction: bottom handle → top handle (source → target)
                            if conn.from_top {
                                // Started from top, so this is an incoming connection
                                callback.call((target_node_id.clone(), source_id.clone()));
                            } else {
                                // Started from bottom, so this is an outgoing connection
                                callback.call((source_id.clone(), target_node_id.clone()));
                            }
                        }
                    }
                }
            }
            // Reset connection state
            connection.update(|c| {
                c.is_connecting = false;
                c.source_node = None;
            });
        })
    };

    // Get connection line source position
    let conn_state = connection.get();
    let connection_source_pos = if conn_state.is_connecting {
        conn_state.source_node.as_ref().and_then(|id| {
            canvas.get_node_center(id).map(|center| {
                // Adjust for handle position (top or bottom)
                let node = canvas.nodes.get(id);
                let height = node.and_then(|n| n.dimensions.map(|d| d.height)).unwrap_or(50.0);
                if conn_state.from_top {
                    Position::new(center.x, center.y - height / 2.0)
                } else {
                    Position::new(center.x, center.y + height / 2.0)
                }
            })
        })
    } else {
        None
    };

    rsx! {
        div(
            class="flow-canvas",
            style=styles::container(is_panning.get(), conn_state.is_connecting),
            ref=container_ref,
            tabindex="0",
            on:mousedown=on_mouse_down,
            on:mousemove=on_mouse_move,
            on:mouseup=on_mouse_up,
            on:mouseleave=on_mouse_leave,
            on:wheel=on_wheel,
            on:keydown=on_key_down,
            on:contextmenu=on_context_menu,
        ) {
            // Background grid layer
            div(class="flow-grid", style=styles::grid(&canvas.viewport, &canvas.config))

            // SVG layer for edges
            svg(
                class="flow-edges",
                style=styles::edges_layer(&canvas.viewport),
            ) {
                // Existing edges
                for edge in canvas.edges.values() {
                    FlowEdge {
                        edge: edge.clone(),
                        source_pos: canvas.get_node_center(&edge.source),
                        target_pos: canvas.get_node_center(&edge.target),
                        on_select: props.on_edge_select.clone(),
                    }
                }

                // Connection line preview (while dragging)
                if conn_state.is_connecting {
                    if let Some(source_pos) = connection_source_pos {
                        ConnectionLine {
                            source: source_pos,
                            target: conn_state.current_pos,
                        }
                    }
                }
            }

            // Node layer with viewport transform
            div(
                class="flow-nodes",
                style=styles::nodes_layer(&canvas.viewport),
            ) {
                for node in canvas.nodes.values() {
                    FlowNode {
                        node: node.clone(),
                        zoom: canvas.viewport.transform.zoom,
                        snap_to_grid: canvas.config.snap_to_grid,
                        grid_size: canvas.config.grid_size,
                        on_select: props.on_node_select.clone(),
                        on_move: props.on_node_move.clone(),
                        on_connection_start: Some(on_connection_start.clone()),
                        on_connection_end: Some(on_connection_end.clone()),
                        is_connection_target: conn_state.is_connecting && conn_state.source_node.as_ref() != Some(&node.id),
                    }
                }
            }
        }
    }
}

/// Connection line component for showing edge preview while dragging.
#[derive(Props)]
struct ConnectionLineProps {
    source: Position,
    target: Position,
}

#[component]
fn ConnectionLine(props: ConnectionLineProps) -> Element {
    let path = calculate_bezier_path(&props.source, &props.target);

    rsx! {
        path(
            d=path,
            fill="none",
            stroke="var(--color-primary)",
            stroke_width="2",
            stroke_dasharray="5,5",
            style="pointer-events: none; opacity: 0.7;",
        )
    }
}

/// Calculate a smooth bezier curve path between two points.
fn calculate_bezier_path(source: &Position, target: &Position) -> String {
    let dx = target.x - source.x;
    let dy = target.y - source.y;

    // Control point offset based on distance
    let offset = (dx.abs() + dy.abs()).max(50.0) * 0.3;

    let sx = source.x;
    let sy = source.y;
    let tx = target.x;
    let ty = target.y;

    // Determine control points based on vertical direction
    let (c1y, c2y) = if ty > sy {
        (sy + offset, ty - offset)
    } else {
        (sy - offset, ty + offset)
    };

    format!("M {} {} C {} {}, {} {}, {} {}", sx, sy, sx, c1y, tx, c2y, tx, ty)
}

mod styles {
    use rsc_flow::prelude::{Viewport, FlowCanvasConfig};

    pub fn container(is_panning: bool, is_connecting: bool) -> String {
        let cursor = if is_connecting {
            "crosshair"
        } else if is_panning {
            "grabbing"
        } else {
            "grab"
        };
        format!(
            r#"
                position: relative;
                width: 100%;
                height: 100%;
                background: var(--color-bg-primary);
                overflow: hidden;
                cursor: {cursor};
                outline: none;
            "#,
            cursor = cursor,
        )
    }

    pub fn grid(viewport: &Viewport, config: &FlowCanvasConfig) -> String {
        if !config.show_grid {
            return "display: none;".to_string();
        }

        let base_grid_size = config.grid_size;
        let grid_size = base_grid_size * viewport.transform.zoom;
        format!(
            r#"
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background-image: radial-gradient(var(--color-border) 1px, transparent 1px);
                background-size: {grid_size}px {grid_size}px;
                background-position: {x}px {y}px;
                pointer-events: none;
            "#,
            grid_size = grid_size,
            x = viewport.transform.x % grid_size,
            y = viewport.transform.y % grid_size,
        )
    }

    pub fn edges_layer(viewport: &Viewport) -> String {
        format!(
            r#"
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                pointer-events: none;
                transform: translate({x}px, {y}px) scale({zoom});
                transform-origin: 0 0;
            "#,
            x = viewport.transform.x,
            y = viewport.transform.y,
            zoom = viewport.transform.zoom,
        )
    }

    pub fn nodes_layer(viewport: &Viewport) -> String {
        format!(
            r#"
                position: absolute;
                top: 0;
                left: 0;
                transform: translate({x}px, {y}px) scale({zoom});
                transform-origin: 0 0;
            "#,
            x = viewport.transform.x,
            y = viewport.transform.y,
            zoom = viewport.transform.zoom,
        )
    }
}
