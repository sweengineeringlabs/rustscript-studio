//! Flow canvas component - interactive graph visualization.

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

/// Flow canvas component.
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

    // Handle mouse events for panning
    let on_mouse_down = move |e: MouseEvent| {
        if e.button() == 1 {
            // Middle mouse button
            is_panning.set(true);
            pan_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
        }
    };

    let on_mouse_move = move |e: MouseEvent| {
        if is_panning.get() {
            let dx = e.client_x() as f64 - pan_start.get().x;
            let dy = e.client_y() as f64 - pan_start.get().y;
            props.canvas.update(|c| {
                c.viewport.pan.x += dx;
                c.viewport.pan.y += dy;
            });
            pan_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
        }
    };

    let on_mouse_up = move |_: MouseEvent| {
        is_panning.set(false);
    };

    // Handle wheel for zooming
    let on_wheel = move |e: WheelEvent| {
        let delta = if e.delta_y() > 0.0 { 0.9 } else { 1.1 };
        props.canvas.update(|c| {
            c.viewport.zoom = (c.viewport.zoom * delta).clamp(0.1, 3.0);
        });
    };

    rsx! {
        div(
            class="flow-canvas",
            style=styles::container(),
            ref=container_ref,
            on:mousedown=on_mouse_down,
            on:mousemove=on_mouse_move,
            on:mouseup=on_mouse_up,
            on:wheel=on_wheel,
        ) {
            // Background grid
            div(class="flow-grid", style=styles::grid(&canvas.viewport))

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

            // Node layer
            div(
                class="flow-nodes",
                style=styles::nodes_layer(&canvas.viewport),
            ) {
                for node in canvas.nodes.values() {
                    FlowNode {
                        node: node.clone(),
                        on_select: props.on_node_select.clone(),
                        on_move: props.on_node_move.clone(),
                    }
                }
            }
        }
    }
}

mod styles {
    use rsc_flow::prelude::Viewport;

    pub fn container() -> &'static str {
        r#"
            position: relative;
            width: 100%;
            height: 100%;
            background: var(--color-bg-primary);
            overflow: hidden;
            cursor: grab;
        "#
    }

    pub fn grid(viewport: &Viewport) -> String {
        let grid_size = 20.0 * viewport.zoom;
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
            x = viewport.pan.x % grid_size,
            y = viewport.pan.y % grid_size,
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
            x = viewport.pan.x,
            y = viewport.pan.y,
            zoom = viewport.zoom,
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
            x = viewport.pan.x,
            y = viewport.pan.y,
            zoom = viewport.zoom,
        )
    }
}
