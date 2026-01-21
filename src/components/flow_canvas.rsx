//! Flow canvas component - interactive graph visualization with pan/zoom gestures.

use rsc::prelude::*;

use rsc_flow::prelude::*;
use super::{FlowNode, FlowEdge};

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
}

/// Flow canvas component with pan/zoom gesture support.
///
/// ## Gestures
/// - **Pan**: Middle mouse button drag or Space + Left mouse drag
/// - **Zoom**: Mouse wheel (zooms towards cursor position)
/// - **Keyboard**: +/= to zoom in, - to zoom out, 0 to reset view
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

    let on_mouse_move = move |e: MouseEvent| {
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
    };

    let on_mouse_up = move |_: MouseEvent| {
        is_panning.set(false);
    };

    let on_mouse_leave = move |_: MouseEvent| {
        is_panning.set(false);
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
        // This creates a natural zoom-to-cursor effect
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
            // Zoom in with + or =
            "+" | "=" => {
                e.prevent_default();
                props.canvas.update(|c| {
                    if c.viewport.zoom_enabled {
                        c.viewport.zoom_in(1.2);
                    }
                });
            }
            // Zoom out with -
            "-" => {
                e.prevent_default();
                props.canvas.update(|c| {
                    if c.viewport.zoom_enabled {
                        c.viewport.zoom_out(1.2);
                    }
                });
            }
            // Reset view with 0
            "0" => {
                e.prevent_default();
                props.canvas.update(|c| {
                    c.viewport.reset();
                });
            }
            _ => {}
        }
    };

    // Context menu prevention to allow custom interactions
    let on_context_menu = move |e: MouseEvent| {
        e.prevent_default();
    };

    rsx! {
        div(
            class="flow-canvas",
            style=styles::container(is_panning.get()),
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
                for edge in canvas.edges.values() {
                    FlowEdge {
                        edge: edge.clone(),
                        source_pos: canvas.get_node_center(&edge.source),
                        target_pos: canvas.get_node_center(&edge.target),
                        on_select: props.on_edge_select.clone(),
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
                    }
                }
            }
        }
    }
}

mod styles {
    use rsc_flow::prelude::{Viewport, FlowCanvasConfig};

    pub fn container(is_panning: bool) -> String {
        let cursor = if is_panning { "grabbing" } else { "grab" };
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
