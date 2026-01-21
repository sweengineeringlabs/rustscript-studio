//! Flow node component - draggable node in the flow canvas.

use rsc::prelude::*;

use rsc_flow::prelude::{Node, Position};
use super::Icon;

/// Flow node component props.
#[derive(Props)]
pub struct FlowNodeProps<T: Clone + 'static> {
    pub node: Node<T>,
    #[prop(default)]
    pub on_select: Option<Callback<String>>,
    #[prop(default)]
    pub on_move: Option<Callback<(String, Position)>>,
}

/// Flow node component.
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
        move |e: MouseEvent| {
            if e.button() == 0 {
                // Left click
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
        move |e: MouseEvent| {
            if is_dragging.get() {
                let dx = e.client_x() as f64 - drag_start.get().x;
                let dy = e.client_y() as f64 - drag_start.get().y;
                let new_pos = Position::new(node_start.get().x + dx, node_start.get().y + dy);

                if let Some(ref on_move) = props.on_move {
                    on_move.call((id.clone(), new_pos));
                }
            }
        }
    };

    let on_mouse_up = move |_: MouseEvent| {
        is_dragging.set(false);
    };

    rsx! {
        div(
            class=format!("flow-node flow-node-{}", node_type),
            style=styles::node(&props.node.position, node_type, props.node.selected),
            on:mousedown=on_mouse_down,
            on:mousemove=on_mouse_move,
            on:mouseup=on_mouse_up,
        ) {
            // Header
            div(class="flow-node-header", style=styles::header(node_type)) {
                Icon { name: get_node_icon(node_type).to_string(), size: 16 }
                span(style=styles::label()) {
                    { props.node.id.clone() }
                }
            }

            // Handles
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

    pub fn node(pos: &Position, node_type: &str, selected: bool) -> String {
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
                cursor: grab;
                user-select: none;
                {selected_style}
            "#,
            x = pos.x,
            y = pos.y,
            border_color = border_color,
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
        "#
    }
}
