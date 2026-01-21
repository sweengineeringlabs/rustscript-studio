//! Flow edge component - connection line between nodes with bezier curves and arrow markers.

use rsc::prelude::*;

use rsc_flow::prelude::{Edge, Position};

/// Edge style variants.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EdgeStyle {
    Default,
    Workflow,   // Workflow to context
    Context,    // Context to preset
}

impl Default for EdgeStyle {
    fn default() -> Self {
        EdgeStyle::Default
    }
}

/// Flow edge component with bezier curve routing and arrow markers.
#[component]
pub fn FlowEdge<T: Clone + 'static>(
    edge: Edge<T>,
    source_pos: Option<Position>,
    target_pos: Option<Position>,
    on_select: Option<Callback<String>>,
    /// Optional edge style for different connection types
    style: Option<EdgeStyle>,
) -> Element {
    let (source, target) = match (source_pos, target_pos) {
        (Some(s), Some(t)) => (s, t),
        _ => return rsx! {},
    };

    let edge_style = style.unwrap_or_default();
    let path = calculate_bezier_path(&source, &target);
    let arrow_path = calculate_arrow_path(&source, &target);

    // Get colors based on style
    let (stroke_color, arrow_color) = if edge.selected {
        ("var(--color-primary)", "var(--color-primary)")
    } else {
        match edge_style {
            EdgeStyle::Workflow => ("var(--color-secondary)", "var(--color-secondary)"),
            EdgeStyle::Context => ("var(--color-accent)", "var(--color-accent)"),
            EdgeStyle::Default => ("var(--color-border)", "var(--color-border)"),
        }
    };

    let stroke_width = if edge.selected { "3" } else { "2" };

    let on_click = {
        let id = edge.id.clone();
        move |_: MouseEvent| {
            if let Some(ref on_select) = on_select {
                on_select.call(id.clone());
            }
        }
    };

    rsx! {
        g(class: format!("flow-edge {}", if edge.selected { "selected" } else { "" }), onclick: on_click) {
            // Invisible wider path for easier clicking
            path(
                d: path.clone(),
                fill: "none",
                stroke: "transparent",
                stroke_width: "20",
                style: "cursor: pointer; pointer-events: stroke;",
            )

            // Visible edge path with gradient
            path(
                class: "edge-line",
                d: path.clone(),
                fill: "none",
                stroke: stroke_color,
                stroke_width: stroke_width,
                stroke_linecap: "round",
                style: "pointer-events: none; transition: stroke 0.15s ease, stroke-width 0.15s ease;",
            )

            // Arrow marker at target
            path(
                class: "edge-arrow",
                d: arrow_path,
                fill: arrow_color,
                stroke: "none",
                style: "pointer-events: none; transition: fill 0.15s ease;",
            )

            // Animated dot for active connections
            if edge.animated {
                circle(
                    r: "4",
                    fill: stroke_color,
                ) {
                    animateMotion(
                        dur: "1.5s",
                        repeatCount: "indefinite",
                        path: path,
                    )
                }
            }
        }
    }
}

/// Calculate a smooth bezier curve path between two points.
/// Uses vertical-oriented curves suitable for top-to-bottom flow.
fn calculate_bezier_path(source: &Position, target: &Position) -> String {
    let dx = target.x - source.x;
    let dy = target.y - source.y;

    // Control point offset based on distance, with minimum offset
    let offset = ((dx.abs() + dy.abs()) * 0.3).max(30.0);

    let sx = source.x;
    let sy = source.y;
    let tx = target.x;
    let ty = target.y;

    // Determine control points based on relative positions
    let (c1x, c1y, c2x, c2y) = if dy >= 0.0 {
        // Target is below source - normal downward curve
        (sx, sy + offset, tx, ty - offset)
    } else {
        // Target is above source - curved path that goes down then up
        let horizontal_offset = offset.max(dx.abs() * 0.5);
        (sx + horizontal_offset.copysign(dx), sy + offset,
         tx - horizontal_offset.copysign(dx), ty - offset)
    };

    format!("M {} {} C {} {}, {} {}, {} {}", sx, sy, c1x, c1y, c2x, c2y, tx, ty)
}

/// Calculate arrow marker path at the target end.
fn calculate_arrow_path(source: &Position, target: &Position) -> String {
    let dx = target.x - source.x;
    let dy = target.y - source.y;

    // Arrow size
    let arrow_size = 8.0;

    // Calculate angle from control point to target
    let offset = ((dx.abs() + dy.abs()) * 0.3).max(30.0);
    let c2x = target.x;
    let c2y = target.y - offset;

    // Direction from last control point to target
    let dir_x = target.x - c2x;
    let dir_y = target.y - c2y;
    let len = (dir_x * dir_x + dir_y * dir_y).sqrt().max(0.001);
    let norm_x = dir_x / len;
    let norm_y = dir_y / len;

    // Perpendicular direction
    let perp_x = -norm_y;
    let perp_y = norm_x;

    // Arrow points
    let tip_x = target.x;
    let tip_y = target.y;
    let base_x = tip_x - norm_x * arrow_size;
    let base_y = tip_y - norm_y * arrow_size;
    let left_x = base_x + perp_x * (arrow_size * 0.5);
    let left_y = base_y + perp_y * (arrow_size * 0.5);
    let right_x = base_x - perp_x * (arrow_size * 0.5);
    let right_y = base_y - perp_y * (arrow_size * 0.5);

    format!("M {} {} L {} {} L {} {} Z", tip_x, tip_y, left_x, left_y, right_x, right_y)
}
