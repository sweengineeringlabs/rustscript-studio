// Flow canvas component - interactive graph visualization with pan/zoom gestures

use rsc::prelude::*;
use rsc_flow::prelude::*;
use super::{FlowNode, FlowEdge};

// Use concrete types for the flow canvas (no generics)
pub type StudioCanvas = FlowCanvas<(), ()>;
pub type StudioNode = Node<()>;
pub type StudioEdge = Edge<()>;

/// Connection state for edge creation by dragging
#[derive(Debug, Clone, Default)]
pub struct ConnectionState {
    pub source_node: Option<String>,
    pub from_top: bool,
    pub current_pos: Position,
    pub is_connecting: bool,
}

/// Callback type alias for node move events
pub type NodeMoveCallback = Callback<(String, Position)>;
/// Callback type alias for edge create events
pub type EdgeCreateCallback = Callback<(String, String)>;

/// Flow canvas component with pan/zoom gesture support and edge creation
#[component]
pub fn FlowCanvasView(
    canvas: Signal<StudioCanvas>,
    on_node_select: Option<Callback<String>>,
    on_node_move: Option<NodeMoveCallback>,
    on_edge_select: Option<Callback<String>>,
    on_edge_create: Option<EdgeCreateCallback>,
) -> Element {
    let canvas_data = canvas.get();
    let (is_panning, set_panning) = use_state(false);
    let (pan_start, set_pan_start) = use_state(Position::zero());
    let (viewport_start, set_viewport_start) = use_state((0.0f64, 0.0f64));
    let (connection, set_connection) = use_state(ConnectionState::default());

    // Handle mouse down for panning (middle mouse button)
    let on_mouse_down = {
        let canvas = canvas.clone();
        move |e: MouseEvent| {
            if e.button() == 1 {
                e.prevent_default();
                set_panning(true);
                set_pan_start(Position::new(e.client_x() as f64, e.client_y() as f64));
                let vp = canvas.get().viewport.transform;
                set_viewport_start((vp.x, vp.y));
            }
        }
    };

    let on_mouse_move = {
        let canvas = canvas.clone();
        move |e: MouseEvent| {
            // Handle panning
            if *is_panning {
                let dx = e.client_x() as f64 - pan_start.x;
                let dy = e.client_y() as f64 - pan_start.y;
                let (start_x, start_y) = *viewport_start;
                canvas.update(|c| {
                    if c.viewport.pan_enabled {
                        c.viewport.transform.x = start_x + dx;
                        c.viewport.transform.y = start_y + dy;
                    }
                });
            }

            // Handle connection dragging
            if connection.is_connecting {
                let canvas_data = canvas.get();
                let vp = &canvas_data.viewport.transform;
                let canvas_x = (e.offset_x() as f64 - vp.x) / vp.zoom;
                let canvas_y = (e.offset_y() as f64 - vp.y) / vp.zoom;
                set_connection(ConnectionState {
                    current_pos: Position::new(canvas_x, canvas_y),
                    ..(*connection).clone()
                });
            }
        }
    };

    let on_mouse_up = move |_: MouseEvent| {
        set_panning(false);
        if connection.is_connecting {
            set_connection(ConnectionState::default());
        }
    };

    let on_mouse_leave = move |_: MouseEvent| {
        set_panning(false);
        if connection.is_connecting {
            set_connection(ConnectionState::default());
        }
    };

    // Handle wheel for zooming towards mouse position
    let on_wheel = {
        let canvas = canvas.clone();
        move |e: WheelEvent| {
            e.prevent_default();

            let canvas_data = canvas.get();
            if !canvas_data.viewport.zoom_enabled {
                return;
            }

            let zoom_intensity = 0.08;
            let delta = if e.delta_y() > 0.0 { -zoom_intensity } else { zoom_intensity };
            let current_zoom = canvas_data.viewport.transform.zoom;
            let new_zoom = (current_zoom * (1.0 + delta))
                .clamp(canvas_data.viewport.min_zoom, canvas_data.viewport.max_zoom);

            if (new_zoom - current_zoom).abs() < 0.0001 {
                return;
            }

            let mouse_x = e.offset_x() as f64;
            let mouse_y = e.offset_y() as f64;
            let vp = &canvas_data.viewport.transform;
            let canvas_x = (mouse_x - vp.x) / vp.zoom;
            let canvas_y = (mouse_y - vp.y) / vp.zoom;
            let new_vp_x = mouse_x - canvas_x * new_zoom;
            let new_vp_y = mouse_y - canvas_y * new_zoom;

            canvas.update(|c| {
                c.viewport.transform.x = new_vp_x;
                c.viewport.transform.y = new_vp_y;
                c.viewport.transform.zoom = new_zoom;
            });
        }
    };

    // Handle keyboard shortcuts
    let on_key_down = {
        let canvas = canvas.clone();
        move |e: KeyboardEvent| {
            let key = e.key();
            match key.as_str() {
                "+" | "=" => {
                    e.prevent_default();
                    canvas.update(|c| {
                        if c.viewport.zoom_enabled {
                            c.viewport.zoom_in(1.2);
                        }
                    });
                }
                "-" => {
                    e.prevent_default();
                    canvas.update(|c| {
                        if c.viewport.zoom_enabled {
                            c.viewport.zoom_out(1.2);
                        }
                    });
                }
                "0" => {
                    e.prevent_default();
                    canvas.update(|c| c.viewport.reset());
                }
                "Escape" => {
                    set_connection(ConnectionState::default());
                }
                _ => {}
            }
        }
    };

    let on_context_menu = move |e: MouseEvent| {
        e.prevent_default();
    };

    // Connection callbacks
    let on_connection_start = {
        Callback::new(move |(node_id, from_top, pos): (String, bool, Position)| {
            set_connection(ConnectionState {
                is_connecting: true,
                source_node: Some(node_id),
                from_top,
                current_pos: pos,
            });
        })
    };

    let on_connection_end = {
        let on_edge_create = on_edge_create.clone();
        Callback::new(move |target_node_id: String| {
            let conn = &*connection;
            if conn.is_connecting {
                if let Some(ref source_id) = conn.source_node {
                    if source_id != &target_node_id {
                        if let Some(ref callback) = on_edge_create {
                            if conn.from_top {
                                callback.call((target_node_id.clone(), source_id.clone()));
                            } else {
                                callback.call((source_id.clone(), target_node_id.clone()));
                            }
                        }
                    }
                }
            }
            set_connection(ConnectionState::default());
        })
    };

    // Get connection line source position
    let conn_state = &*connection;
    let connection_source_pos = if conn_state.is_connecting {
        conn_state.source_node.as_ref().and_then(|id| {
            canvas_data.get_node_center(id).map(|center| {
                let node = canvas_data.nodes.get(id);
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
            class: "flow-canvas",
            style: styles::container(*is_panning, conn_state.is_connecting),
            tabindex: "0",
            onmousedown: on_mouse_down,
            onmousemove: on_mouse_move,
            onmouseup: on_mouse_up,
            onmouseleave: on_mouse_leave,
            onwheel: on_wheel,
            onkeydown: on_key_down,
            oncontextmenu: on_context_menu
        ) {
            // Background grid layer
            div(class: "flow-grid", style: styles::grid(&canvas_data.viewport, &canvas_data.config))

            // SVG layer for edges
            svg(
                class: "flow-edges",
                style: styles::edges_layer(&canvas_data.viewport)
            ) {
                for edge in canvas_data.edges.values() {
                    FlowEdge(
                        edge: edge.clone(),
                        source_pos: canvas_data.get_node_center(&edge.source),
                        target_pos: canvas_data.get_node_center(&edge.target),
                        on_select: on_edge_select.clone()
                    )
                }

                if conn_state.is_connecting {
                    if let Some(source_pos) = connection_source_pos {
                        ConnectionLine(source: source_pos, target: conn_state.current_pos.clone())
                    }
                }
            }

            // Node layer with viewport transform
            div(
                class: "flow-nodes",
                style: styles::nodes_layer(&canvas_data.viewport)
            ) {
                for node in canvas_data.nodes.values() {
                    FlowNode(
                        node: node.clone(),
                        zoom: canvas_data.viewport.transform.zoom,
                        snap_to_grid: canvas_data.config.snap_to_grid,
                        grid_size: canvas_data.config.grid_size,
                        on_select: on_node_select.clone(),
                        on_move: on_node_move.clone(),
                        on_connection_start: Some(on_connection_start.clone()),
                        on_connection_end: Some(on_connection_end.clone()),
                        is_connection_target: conn_state.is_connecting && conn_state.source_node.as_ref() != Some(&node.id)
                    )
                }
            }
        }
    }
}

/// Connection line component for showing edge preview while dragging
#[component]
fn ConnectionLine(source: Position, target: Position) -> Element {
    let path = calculate_bezier_path(&source, &target);

    rsx! {
        path(
            d: path,
            fill: "none",
            stroke: "var(--color-primary)",
            stroke_width: "2",
            stroke_dasharray: "5,5",
            style: "pointer-events: none; opacity: 0.7;"
        )
    }
}

fn calculate_bezier_path(source: &Position, target: &Position) -> String {
    let dx = target.x - source.x;
    let dy = target.y - source.y;
    let offset = (dx.abs() + dy.abs()).max(50.0) * 0.3;

    let sx = source.x;
    let sy = source.y;
    let tx = target.x;
    let ty = target.y;

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
                cursor: {};
                outline: none;
            "#,
            cursor
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
                background-size: {}px {}px;
                background-position: {}px {}px;
                pointer-events: none;
            "#,
            grid_size, grid_size,
            viewport.transform.x % grid_size,
            viewport.transform.y % grid_size
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
                transform: translate({}px, {}px) scale({});
                transform-origin: 0 0;
            "#,
            viewport.transform.x,
            viewport.transform.y,
            viewport.transform.zoom
        )
    }

    pub fn nodes_layer(viewport: &Viewport) -> String {
        format!(
            r#"
                position: absolute;
                top: 0;
                left: 0;
                transform: translate({}px, {}px) scale({});
                transform-origin: 0 0;
            "#,
            viewport.transform.x,
            viewport.transform.y,
            viewport.transform.zoom
        )
    }
}
