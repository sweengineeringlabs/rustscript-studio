//! Flow edge component - connection line between nodes.

use rsc::prelude::*;

use rsc_flow::prelude::{Edge, Position};

/// Flow edge component.
#[component]
pub fn FlowEdge<T: Clone + 'static>(
    edge: Edge<T>,
    source_pos: Option<Position>,
    target_pos: Option<Position>,
    on_select: Option<Callback<String>>,
) -> Element {
    let (source, target) = match (source_pos, target_pos) {
        (Some(s), Some(t)) => (s, t),
        _ => return rsx! {},
    };

    let path = calculate_bezier_path(&source, &target);

    let on_click = {
        let id = edge.id.clone();
        move |_: MouseEvent| {
            if let Some(ref on_select) = on_select {
                on_select.call(id.clone());
            }
        }
    };

    rsx! {
        g(class: "flow-edge", onclick: on_click) {
            // Invisible wider path for easier clicking
            path(
                d: path.clone(),
                fill: "none",
                stroke: "transparent",
                stroke_width: "20",
                style: "cursor: pointer; pointer-events: stroke;",
            )

            // Visible edge path
            path(
                d: path,
                fill: "none",
                stroke: if edge.selected {
                    "var(--color-edge-selected)"
                } else {
                    "var(--color-edge-default)"
                },
                stroke_width: if edge.selected { "3" } else { "2" },
                style: "pointer-events: none;",
            )

            // Arrow marker at target
            if edge.animated {
                circle(
                    r: "4",
                    fill: "var(--color-edge-default)",
                ) {
                    animateMotion(
                        dur: "2s",
                        repeatCount: "indefinite",
                        path: calculate_bezier_path(&source, &target),
                    )
                }
            }
        }
    }
}

/// Calculate a smooth bezier curve path between two points.
fn calculate_bezier_path(source: &Position, target: &Position) -> String {
    let dx = target.x - source.x;
    let dy = target.y - source.y;

    // Control point offset based on distance
    let offset = (dx.abs() + dy.abs()) * 0.3;

    // Source exits downward, target enters upward
    let sx = source.x;
    let sy = source.y;
    let tx = target.x;
    let ty = target.y;

    let c1x = sx;
    let c1y = sy + offset;
    let c2x = tx;
    let c2y = ty - offset;

    format!("M {} {} C {} {}, {} {}, {} {}", sx, sy, c1x, c1y, c2x, c2y, tx, ty)
}
