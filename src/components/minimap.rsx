//! Minimap component for flow canvas navigation.

use rsc::prelude::*;

use rsc_flow::prelude::{FlowCanvas, Position, Dimensions, NodeType};
use super::flow_canvas::StudioCanvas;

/// Minimap component showing an overview of the flow canvas.
///
/// ## Example
/// ```rust,ignore
/// <Minimap
///     canvas={canvas_signal}
///     width={200.0}
///     height={150.0}
///     on_viewport_change={Callback::new(move |pos| {
///         canvas.update(|c| c.viewport.transform.x = pos.x);
///     })}
/// />
/// ```
component Minimap(
    /// Canvas data
    canvas: Signal<StudioCanvas>,
    /// Minimap width
    width?: f64,
    /// Minimap height
    height?: f64,
    /// Callback when viewport position changes via minimap click
    on_viewport_change?: Callback<Position>,
) {
    let width = width.unwrap_or(200.0);
    let height = height.unwrap_or(150.0);

    let canvas = canvas.get();
    let is_dragging = signal(false);

    // Calculate bounds of all nodes
    let bounds = canvas.get_bounds();
    let (min_x, min_y, content_width, content_height) = if let Some(b) = bounds {
        let padding = 50.0;
        (
            b.position.x - padding,
            b.position.y - padding,
            b.dimensions.width + padding * 2.0,
            b.dimensions.height + padding * 2.0,
        )
    } else {
        (0.0, 0.0, 1000.0, 1000.0)
    };

    // Calculate scale to fit content in minimap
    let scale_x = width / content_width;
    let scale_y = height / content_height;
    let scale = scale_x.min(scale_y);

    // Calculate viewport rectangle
    let vp = &canvas.viewport.transform;
    let viewport_width = width / vp.zoom;
    let viewport_height = height / vp.zoom;
    let viewport_x = (-vp.x / vp.zoom - min_x) * scale;
    let viewport_y = (-vp.y / vp.zoom - min_y) * scale;
    let viewport_w = viewport_width * scale;
    let viewport_h = viewport_height * scale;

    render {
        <div
            class="minimap"
            style={styles::container(width, height)}
            on:mousedown={|e: MouseEvent| {
                is_dragging.set(true);
                handle_minimap_click(&e, min_x, min_y, scale, &on_viewport_change);
            }}
            on:mousemove={|e: MouseEvent| {
                if is_dragging.get() {
                    handle_minimap_click(&e, min_x, min_y, scale, &on_viewport_change);
                }
            }}
            on:mouseup={|_: MouseEvent| {
                is_dragging.set(false);
            }}
            on:mouseleave={|_: MouseEvent| {
                is_dragging.set(false);
            }}
        >
            // Node indicators
            <svg
                width={width.to_string()}
                height={height.to_string()}
                style={styles::svg()}
            >
                // Nodes
                @for node in canvas.nodes.values() {
                    <rect
                        x={((node.position.x - min_x) * scale).to_string()}
                        y={((node.position.y - min_y) * scale).to_string()}
                        width={(node.dimensions.unwrap_or(Dimensions::new(160.0, 50.0)).width * scale).to_string()}
                        height={(node.dimensions.unwrap_or(Dimensions::new(160.0, 50.0)).height * scale).to_string()}
                        fill={get_node_color(&node.node_type)}
                        rx="2"
                    />
                }

                // Edges
                @for edge in canvas.edges.values() {
                    @if let (Some(source), Some(target)) = (
                        canvas.get_node_center(&edge.source),
                        canvas.get_node_center(&edge.target)
                    ) {
                        <line
                            x1={((source.x - min_x) * scale).to_string()}
                            y1={((source.y - min_y) * scale).to_string()}
                            x2={((target.x - min_x) * scale).to_string()}
                            y2={((target.y - min_y) * scale).to_string()}
                            stroke="var(--color-edge-default)"
                            stroke-width="1"
                            opacity="0.5"
                        />
                    }
                }

                // Viewport rectangle
                <rect
                    x={viewport_x.to_string()}
                    y={viewport_y.to_string()}
                    width={viewport_w.to_string()}
                    height={viewport_h.to_string()}
                    fill="transparent"
                    stroke="var(--color-primary)"
                    stroke-width="2"
                    rx="2"
                />
            </svg>
        </div>
    }
}

fn handle_minimap_click(
    e: &MouseEvent,
    min_x: f64,
    min_y: f64,
    scale: f64,
    on_change: &Option<Callback<Position>>,
) {
    if let Some(ref callback) = on_change {
        let x = e.offset_x() as f64 / scale + min_x;
        let y = e.offset_y() as f64 / scale + min_y;
        callback.call(Position::new(-x, -y));
    }
}

fn get_node_color(node_type: &NodeType) -> &'static str {
    if let NodeType::Custom(t) = node_type {
        match t.as_str() {
            "workflow" => "var(--color-node-workflow)",
            "context" => "var(--color-node-context)",
            "preset" => "var(--color-node-preset)",
            other => "var(--color-text-muted)",
        }
    } else {
        "var(--color-text-muted)"
    }
}

mod styles {
    pub fn container(width: f64, height: f64) -> String {
        format!(
            r#"
                width: {width}px;
                height: {height}px;
                background: var(--color-bg-secondary);
                border: 1px solid var(--color-border);
                border-radius: var(--radius-md);
                overflow: hidden;
                cursor: crosshair;
            "#,
            width = width,
            height = height,
        )
    }

    pub fn svg() -> &'static str {
        r#"
            display: block;
        "#
    }
}
