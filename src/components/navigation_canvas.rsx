//! Navigation canvas component - specialized flow canvas for navigation designer.
//! Renders workflow, context, and preset nodes with proper labels and visuals.

use rsc::prelude::*;
use rsc_flow::prelude::{FlowCanvas, Position, Viewport};
use rsc_studio::designer::navigation::{NavigationNodeData, EntityType};

use super::{FlowEdge, Icon};

/// Navigation canvas component.
#[component]
pub fn NavigationCanvasView(
    canvas: Signal<FlowCanvas<NavigationNodeData, ()>>,
    on_node_select: Option<Callback<String>>,
    on_node_move: Option<Callback<(String, Position)>>,
) -> Element {
    let canvas_data = canvas.get();
    let is_panning = use_signal(|| false);
    let pan_start = use_signal(|| Position::zero());
    let viewport_start = use_signal(|| (0.0f64, 0.0f64));

    // Handle mouse down for panning (middle mouse button)
    let on_mouse_down = {
        let canvas = canvas.clone();
        move |e: MouseEvent| {
            if e.button() == 1 {
                e.prevent_default();
                is_panning.set(true);
                pan_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
                let vp = canvas.get().viewport.transform;
                viewport_start.set((vp.x, vp.y));
            }
        }
    };

    let on_mouse_move = {
        let canvas = canvas.clone();
        move |e: MouseEvent| {
            if is_panning.get() {
                let ps = pan_start.get();
                let dx = e.client_x() as f64 - ps.x;
                let dy = e.client_y() as f64 - ps.y;
                let (start_x, start_y) = viewport_start.get();
                canvas.update(|c| {
                    if c.viewport.pan_enabled {
                        c.viewport.transform.x = start_x + dx;
                        c.viewport.transform.y = start_y + dy;
                    }
                });
            }
        }
    };

    let on_mouse_up = move |_: MouseEvent| {
        is_panning.set(false);
    };

    let on_mouse_leave = move |_: MouseEvent| {
        is_panning.set(false);
    };

    // Handle wheel for zooming
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

    let on_context_menu = move |e: MouseEvent| {
        e.prevent_default();
    };

    rsx! {
        div(
            class: "navigation-canvas",
            style: styles::container(is_panning.get()),
            tabindex: "0",
            onmousedown: on_mouse_down,
            onmousemove: on_mouse_move,
            onmouseup: on_mouse_up,
            onmouseleave: on_mouse_leave,
            onwheel: on_wheel,
            oncontextmenu: on_context_menu
        ) {
            // Background grid
            div(class: "flow-grid", style: styles::grid(&canvas_data.viewport, canvas_data.config.grid_size))

            // SVG layer for edges
            svg(
                class: "flow-edges",
                style: styles::edges_layer(&canvas_data.viewport)
            ) {
                for edge in canvas_data.edges.values() {
                    {
                        let source_pos = canvas_data.get_node_center(&edge.source);
                        let target_pos = canvas_data.get_node_center(&edge.target);
                        rsx! {
                            FlowEdge {
                                edge: edge.clone(),
                                source_pos: source_pos,
                                target_pos: target_pos,
                            }
                        }
                    }
                }
            }

            // Node layer
            div(
                class: "flow-nodes",
                style: styles::nodes_layer(&canvas_data.viewport)
            ) {
                for node in canvas_data.nodes.values() {
                    NavigationNode {
                        id: node.id.clone(),
                        position: node.position,
                        data: node.data.clone(),
                        selected: node.selected,
                        zoom: canvas_data.viewport.transform.zoom,
                        on_select: on_node_select.clone(),
                        on_move: on_node_move.clone(),
                    }
                }
            }
        }
    }
}

/// Navigation node component with proper visuals for each entity type.
#[component]
fn NavigationNode(
    id: String,
    position: Position,
    data: Option<NavigationNodeData>,
    selected: bool,
    zoom: f64,
    on_select: Option<Callback<String>>,
    on_move: Option<Callback<(String, Position)>>,
) -> Element {
    let is_dragging = use_signal(|| false);
    let drag_start = use_signal(|| Position::zero());
    let node_start = use_signal(|| Position::zero());

    let data = data.unwrap_or(NavigationNodeData {
        entity_type: EntityType::Workflow,
        entity_id: id.clone(),
        parent_id: None,
        label: id.clone(),
        icon: None,
        description: None,
    });

    let entity_type = data.entity_type;

    // Node drag handlers
    let on_mouse_down = {
        let id = id.clone();
        let pos = position;
        let on_select = on_select.clone();
        move |e: MouseEvent| {
            if e.button() == 0 {
                e.stop_propagation();
                is_dragging.set(true);
                drag_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
                node_start.set(pos);

                if let Some(ref callback) = on_select {
                    callback.call(id.clone());
                }
            }
        }
    };

    let on_mouse_move = {
        let id = id.clone();
        let on_move = on_move.clone();
        move |e: MouseEvent| {
            if is_dragging.get() {
                let dx = (e.client_x() as f64 - drag_start.get().x) / zoom;
                let dy = (e.client_y() as f64 - drag_start.get().y) / zoom;
                let new_pos = Position::new(
                    node_start.get().x + dx,
                    node_start.get().y + dy,
                );

                if let Some(ref callback) = on_move {
                    callback.call((id.clone(), new_pos));
                }
            }
        }
    };

    let on_mouse_up = move |_: MouseEvent| {
        is_dragging.set(false);
    };

    // Get icon based on entity type
    let icon_name = data.icon.clone().unwrap_or_else(|| {
        match entity_type {
            EntityType::Workflow => "git-branch".to_string(),
            EntityType::Context => "layers".to_string(),
            EntityType::Preset => "layout".to_string(),
        }
    });

    rsx! {
        div(
            class: format!("navigation-node navigation-node-{:?}", entity_type).to_lowercase(),
            style: node_styles::container(&position, entity_type, selected, is_dragging.get()),
            onmousedown: on_mouse_down,
            onmousemove: on_mouse_move,
            onmouseup: on_mouse_up,
        ) {
            // Header
            div(class: "node-header", style: node_styles::header(entity_type)) {
                Icon { name: icon_name, size: 16 }
                span(class: "node-label", style: node_styles::label()) {
                    { data.label.clone() }
                }
            }

            // Body (description or layout preview for presets)
            if data.description.is_some() || entity_type == EntityType::Preset {
                div(class: "node-body", style: node_styles::body()) {
                    // Description
                    if let Some(ref desc) = data.description {
                        p(class: "node-description", style: node_styles::description()) {
                            { desc.clone() }
                        }
                    }

                    // Layout preview for presets
                    if entity_type == EntityType::Preset {
                        div(class: "node-layout-preview", style: node_styles::layout_preview()) {
                            div(style: node_styles::layout_activity_bar()) {}
                            div(style: node_styles::layout_sidebar()) {}
                            div(style: node_styles::layout_main()) {}
                        }
                    }
                }
            }

            // Type badge
            div(class: "node-badge", style: node_styles::badge(entity_type)) {
                { format!("{:?}", entity_type) }
            }

            // Connection handles
            div(class: "node-handle node-handle-top", style: node_styles::handle_top())
            div(class: "node-handle node-handle-bottom", style: node_styles::handle_bottom())
        }
    }
}

mod styles {
    use rsc_flow::prelude::Viewport;

    pub fn container(is_panning: bool) -> String {
        let cursor = if is_panning { "grabbing" } else { "grab" };
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

    pub fn grid(viewport: &Viewport, grid_size: f64) -> String {
        let scaled_size = grid_size * viewport.transform.zoom;
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
            scaled_size, scaled_size,
            viewport.transform.x % scaled_size,
            viewport.transform.y % scaled_size
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

mod node_styles {
    use rsc_flow::prelude::Position;
    use rsc_studio::designer::navigation::EntityType;

    pub fn container(pos: &Position, entity_type: EntityType, selected: bool, is_dragging: bool) -> String {
        let border_color = match entity_type {
            EntityType::Workflow => "var(--color-primary)",
            EntityType::Context => "var(--color-secondary)",
            EntityType::Preset => "var(--color-accent)",
        };

        let selected_style = if selected {
            "box-shadow: 0 0 0 3px var(--color-primary-alpha), var(--shadow-lg);"
        } else {
            "box-shadow: var(--shadow-md);"
        };

        let cursor = if is_dragging { "grabbing" } else { "grab" };
        let opacity = if is_dragging { "0.85" } else { "1" };

        format!(
            r#"
                position: absolute;
                left: {x}px;
                top: {y}px;
                min-width: 180px;
                max-width: 240px;
                background: var(--color-surface);
                border: 2px solid {border_color};
                border-radius: var(--radius-lg);
                cursor: {cursor};
                user-select: none;
                opacity: {opacity};
                transition: box-shadow 0.15s ease, transform 0.1s ease;
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

    pub fn header(entity_type: EntityType) -> String {
        let bg_color = match entity_type {
            EntityType::Workflow => "var(--color-primary)",
            EntityType::Context => "var(--color-secondary)",
            EntityType::Preset => "var(--color-accent)",
        };

        format!(
            r#"
                display: flex;
                align-items: center;
                gap: var(--spacing-sm);
                padding: var(--spacing-sm) var(--spacing-md);
                background: {bg_color};
                color: white;
                border-radius: var(--radius-md) var(--radius-md) 0 0;
                font-weight: var(--font-weight-semibold);
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
            flex: 1;
        "#
    }

    pub fn body() -> &'static str {
        r#"
            padding: var(--spacing-sm) var(--spacing-md);
            border-top: 1px solid var(--color-border);
        "#
    }

    pub fn description() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
            line-height: 1.4;
            overflow: hidden;
            text-overflow: ellipsis;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
        "#
    }

    pub fn layout_preview() -> &'static str {
        r#"
            display: flex;
            height: 36px;
            margin-top: var(--spacing-xs);
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
            overflow: hidden;
        "#
    }

    pub fn layout_activity_bar() -> &'static str {
        r#"
            width: 12px;
            background: var(--color-primary);
            opacity: 0.6;
        "#
    }

    pub fn layout_sidebar() -> &'static str {
        r#"
            width: 28px;
            background: var(--color-bg-tertiary);
            border-right: 1px solid var(--color-border);
        "#
    }

    pub fn layout_main() -> &'static str {
        r#"
            flex: 1;
            background: var(--color-surface);
        "#
    }

    pub fn badge(entity_type: EntityType) -> String {
        let bg_color = match entity_type {
            EntityType::Workflow => "var(--color-primary)",
            EntityType::Context => "var(--color-secondary)",
            EntityType::Preset => "var(--color-accent)",
        };

        format!(
            r#"
                position: absolute;
                top: -8px;
                right: 8px;
                padding: 2px 6px;
                background: {bg_color};
                color: white;
                font-size: 9px;
                font-weight: var(--font-weight-bold);
                text-transform: uppercase;
                border-radius: var(--radius-sm);
            "#,
            bg_color = bg_color,
        )
    }

    pub fn handle_top() -> &'static str {
        r#"
            position: absolute;
            top: -5px;
            left: 50%;
            transform: translateX(-50%);
            width: 10px;
            height: 10px;
            background: var(--color-surface);
            border: 2px solid var(--color-border);
            border-radius: 50%;
            cursor: crosshair;
            transition: all 0.15s ease;
            z-index: 10;
        "#
    }

    pub fn handle_bottom() -> &'static str {
        r#"
            position: absolute;
            bottom: -5px;
            left: 50%;
            transform: translateX(-50%);
            width: 10px;
            height: 10px;
            background: var(--color-surface);
            border: 2px solid var(--color-border);
            border-radius: 50%;
            cursor: crosshair;
            transition: all 0.15s ease;
            z-index: 10;
        "#
    }
}
