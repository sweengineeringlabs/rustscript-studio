//! Navigation canvas component - specialized flow canvas for navigation designer.
//! Renders workflow, context, and preset nodes with proper labels and visuals.

use rsc::prelude::*;
use rsc_flow::prelude::{FlowCanvas, Position, Viewport};
use rsc_studio::designer::navigation::{NavigationNodeData, EntityType};

use super::{FlowEdge, Icon};

/// Navigation canvas component with keyboard navigation support.
///
/// Keyboard shortcuts:
/// - Arrow keys: Navigate between nodes based on position
/// - Tab: Cycle through nodes in order
/// - Enter: Edit the selected node
/// - Escape: Deselect current node
/// - Delete/Backspace: Delete selected node
///
/// Drag and drop:
/// - Drag a Context node onto a Workflow node to move it
#[component]
pub fn NavigationCanvasView(
    canvas: Signal<FlowCanvas<NavigationNodeData, ()>>,
    on_node_select: Option<Callback<String>>,
    on_node_move: Option<Callback<(String, Position)>>,
    /// Callback when user requests to delete the selected node
    on_delete: Option<Callback<String>>,
    /// Callback when user requests to edit the selected node
    on_edit: Option<Callback<String>>,
    /// Currently selected node ID (for keyboard navigation)
    selected_node_id: Option<String>,
    /// Callback when a context is dropped on a workflow (source_workflow_id, target_workflow_id, context_id)
    on_move_context: Option<Callback<(String, String, String)>>,
) -> Element {
    let canvas_data = canvas.get();
    let is_panning = use_signal(|| false);
    let pan_start = use_signal(|| Position::zero());
    let viewport_start = use_signal(|| (0.0f64, 0.0f64));

    // State for context drag-and-drop between workflows
    // Stores (context_entity_id, source_workflow_id) when dragging a context
    let dragging_context = use_signal::<Option<(String, String)>>(|| None);
    let drop_target_workflow = use_signal::<Option<String>>(|| None);

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

    // Keyboard navigation handler
    let on_keydown = {
        let canvas = canvas.clone();
        let on_node_select = on_node_select.clone();
        let on_delete = on_delete.clone();
        let on_edit = on_edit.clone();
        let selected_node_id = selected_node_id.clone();
        move |e: KeyboardEvent| {
            let key = e.key();

            match key.as_str() {
                // Arrow key navigation
                "ArrowUp" | "ArrowDown" | "ArrowLeft" | "ArrowRight" => {
                    e.prevent_default();
                    let canvas_data = canvas.get();
                    let node_ids: Vec<String> = canvas_data.nodes.keys().cloned().collect();

                    if node_ids.is_empty() {
                        return;
                    }

                    if let Some(ref current_id) = selected_node_id {
                        // Find the best adjacent node based on direction
                        if let Some(current_node) = canvas_data.nodes.get(current_id) {
                            let current_pos = current_node.position;
                            let mut best_candidate: Option<(String, f64)> = None;

                            for (id, node) in &canvas_data.nodes {
                                if id == current_id {
                                    continue;
                                }

                                let dx = node.position.x - current_pos.x;
                                let dy = node.position.y - current_pos.y;

                                let is_valid_direction = match key.as_str() {
                                    "ArrowUp" => dy < -10.0,
                                    "ArrowDown" => dy > 10.0,
                                    "ArrowLeft" => dx < -10.0,
                                    "ArrowRight" => dx > 10.0,
                                    _ => false,
                                };

                                if is_valid_direction {
                                    // Calculate weighted distance (favor nodes more aligned with the direction)
                                    let distance = match key.as_str() {
                                        "ArrowUp" | "ArrowDown" => {
                                            dy.abs() + dx.abs() * 0.5
                                        }
                                        "ArrowLeft" | "ArrowRight" => {
                                            dx.abs() + dy.abs() * 0.5
                                        }
                                        _ => (dx * dx + dy * dy).sqrt(),
                                    };

                                    if best_candidate.is_none() || distance < best_candidate.as_ref().unwrap().1 {
                                        best_candidate = Some((id.clone(), distance));
                                    }
                                }
                            }

                            if let Some((next_id, _)) = best_candidate {
                                if let Some(ref callback) = on_node_select {
                                    callback.call(next_id.clone());
                                }
                                // Center the viewport on the new node
                                if let Some(next_node) = canvas_data.nodes.get(&next_id) {
                                    canvas.update(|c| {
                                        c.viewport.center_on(next_node.position);
                                    });
                                }
                            }
                        }
                    } else {
                        // No selection, select the first node
                        if let Some(first_id) = node_ids.first() {
                            if let Some(ref callback) = on_node_select {
                                callback.call(first_id.clone());
                            }
                        }
                    }
                }

                // Tab to cycle through nodes
                "Tab" => {
                    e.prevent_default();
                    let canvas_data = canvas.get();
                    let mut node_ids: Vec<String> = canvas_data.nodes.keys().cloned().collect();

                    if node_ids.is_empty() {
                        return;
                    }

                    // Sort nodes by position (top-to-bottom, left-to-right)
                    node_ids.sort_by(|a, b| {
                        let pos_a = canvas_data.nodes.get(a).map(|n| n.position).unwrap_or(Position::zero());
                        let pos_b = canvas_data.nodes.get(b).map(|n| n.position).unwrap_or(Position::zero());
                        pos_a.y.partial_cmp(&pos_b.y)
                            .unwrap_or(std::cmp::Ordering::Equal)
                            .then_with(|| pos_a.x.partial_cmp(&pos_b.x).unwrap_or(std::cmp::Ordering::Equal))
                    });

                    let current_index = selected_node_id
                        .as_ref()
                        .and_then(|id| node_ids.iter().position(|n| n == id));

                    let next_index = if e.shift_key() {
                        // Shift+Tab: go backwards
                        match current_index {
                            Some(0) => node_ids.len() - 1,
                            Some(i) => i - 1,
                            None => node_ids.len() - 1,
                        }
                    } else {
                        // Tab: go forward
                        match current_index {
                            Some(i) if i + 1 < node_ids.len() => i + 1,
                            _ => 0,
                        }
                    };

                    if let Some(next_id) = node_ids.get(next_index) {
                        if let Some(ref callback) = on_node_select {
                            callback.call(next_id.clone());
                        }
                        // Center on the new node
                        if let Some(next_node) = canvas_data.nodes.get(next_id) {
                            canvas.update(|c| {
                                c.viewport.center_on(next_node.position);
                            });
                        }
                    }
                }

                // Enter to edit
                "Enter" => {
                    if let Some(ref current_id) = selected_node_id {
                        if let Some(ref callback) = on_edit {
                            callback.call(current_id.clone());
                        }
                    }
                }

                // Escape to deselect
                "Escape" => {
                    if let Some(ref callback) = on_node_select {
                        // Passing empty string to indicate deselection
                        // The parent will handle this appropriately
                        callback.call(String::new());
                    }
                }

                // Delete/Backspace to delete
                "Delete" | "Backspace" => {
                    if let Some(ref current_id) = selected_node_id {
                        if let Some(ref callback) = on_delete {
                            callback.call(current_id.clone());
                        }
                    }
                }

                // Focus shortcuts
                "Home" => {
                    // Jump to first node
                    e.prevent_default();
                    let canvas_data = canvas.get();
                    let mut node_ids: Vec<_> = canvas_data.nodes.keys().cloned().collect();
                    node_ids.sort_by(|a, b| {
                        let pos_a = canvas_data.nodes.get(a).map(|n| n.position).unwrap_or(Position::zero());
                        let pos_b = canvas_data.nodes.get(b).map(|n| n.position).unwrap_or(Position::zero());
                        pos_a.y.partial_cmp(&pos_b.y)
                            .unwrap_or(std::cmp::Ordering::Equal)
                            .then_with(|| pos_a.x.partial_cmp(&pos_b.x).unwrap_or(std::cmp::Ordering::Equal))
                    });

                    if let Some(first_id) = node_ids.first() {
                        if let Some(ref callback) = on_node_select {
                            callback.call(first_id.clone());
                        }
                        if let Some(first_node) = canvas_data.nodes.get(first_id) {
                            canvas.update(|c| {
                                c.viewport.center_on(first_node.position);
                            });
                        }
                    }
                }

                "End" => {
                    // Jump to last node
                    e.prevent_default();
                    let canvas_data = canvas.get();
                    let mut node_ids: Vec<_> = canvas_data.nodes.keys().cloned().collect();
                    node_ids.sort_by(|a, b| {
                        let pos_a = canvas_data.nodes.get(a).map(|n| n.position).unwrap_or(Position::zero());
                        let pos_b = canvas_data.nodes.get(b).map(|n| n.position).unwrap_or(Position::zero());
                        pos_a.y.partial_cmp(&pos_b.y)
                            .unwrap_or(std::cmp::Ordering::Equal)
                            .then_with(|| pos_a.x.partial_cmp(&pos_b.x).unwrap_or(std::cmp::Ordering::Equal))
                    });

                    if let Some(last_id) = node_ids.last() {
                        if let Some(ref callback) = on_node_select {
                            callback.call(last_id.clone());
                        }
                        if let Some(last_node) = canvas_data.nodes.get(last_id) {
                            canvas.update(|c| {
                                c.viewport.center_on(last_node.position);
                            });
                        }
                    }
                }

                _ => {}
            }
        }
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
            oncontextmenu: on_context_menu,
            onkeydown: on_keydown
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
                    {
                        let is_drop_target = drop_target_workflow.get()
                            .as_ref()
                            .map(|id| {
                                node.data.as_ref()
                                    .map(|d| d.entity_type == EntityType::Workflow && &d.entity_id == id)
                                    .unwrap_or(false)
                            })
                            .unwrap_or(false);

                        rsx! {
                            NavigationNode {
                                id: node.id.clone(),
                                position: node.position,
                                data: node.data.clone(),
                                selected: node.selected,
                                zoom: canvas_data.viewport.transform.zoom,
                                on_select: on_node_select.clone(),
                                on_move: on_node_move.clone(),
                                is_drop_target: is_drop_target,
                                on_drag_start_context: {
                                    let dragging_context = dragging_context.clone();
                                    Callback::new(move |(ctx_id, wf_id): (String, String)| {
                                        dragging_context.set(Some((ctx_id, wf_id)));
                                    })
                                },
                                on_drag_end: {
                                    let dragging_context = dragging_context.clone();
                                    let drop_target_workflow = drop_target_workflow.clone();
                                    let on_move_context = on_move_context.clone();
                                    Callback::new(move |_: ()| {
                                        // Check if we have both a context being dragged and a target workflow
                                        if let (Some((ctx_id, src_wf_id)), Some(tgt_wf_id)) =
                                            (dragging_context.get(), drop_target_workflow.get())
                                        {
                                            if src_wf_id != tgt_wf_id {
                                                if let Some(ref callback) = on_move_context {
                                                    callback.call((src_wf_id, tgt_wf_id, ctx_id));
                                                }
                                            }
                                        }
                                        dragging_context.set(None);
                                        drop_target_workflow.set(None);
                                    })
                                },
                                on_drag_enter_workflow: {
                                    let drop_target_workflow = drop_target_workflow.clone();
                                    let dragging_context = dragging_context.clone();
                                    Callback::new(move |wf_id: String| {
                                        // Only set drop target if we're dragging a context
                                        if dragging_context.get().is_some() {
                                            drop_target_workflow.set(Some(wf_id));
                                        }
                                    })
                                },
                                on_drag_leave: {
                                    let drop_target_workflow = drop_target_workflow.clone();
                                    Callback::new(move |_: ()| {
                                        drop_target_workflow.set(None);
                                    })
                                },
                                is_dragging_context: dragging_context.get().is_some(),
                            }
                        }
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
    /// Whether this workflow node is a valid drop target
    is_drop_target: bool,
    /// Called when starting to drag a context (context_id, parent_workflow_id)
    on_drag_start_context: Callback<(String, String)>,
    /// Called when drag ends (to finalize or cancel)
    on_drag_end: Callback<()>,
    /// Called when mouse enters a workflow during context drag
    on_drag_enter_workflow: Callback<String>,
    /// Called when mouse leaves the drop zone
    on_drag_leave: Callback<()>,
    /// Whether a context is currently being dragged anywhere in the canvas
    is_dragging_context: bool,
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
    let entity_id = data.entity_id.clone();
    let parent_id = data.parent_id.clone();

    // Node drag handlers
    let on_mouse_down = {
        let id = id.clone();
        let pos = position;
        let on_select = on_select.clone();
        let on_drag_start_context = on_drag_start_context.clone();
        let entity_id = entity_id.clone();
        let parent_id = parent_id.clone();
        move |e: MouseEvent| {
            if e.button() == 0 {
                e.stop_propagation();
                is_dragging.set(true);
                drag_start.set(Position::new(e.client_x() as f64, e.client_y() as f64));
                node_start.set(pos);

                // If this is a context, start context drag
                if entity_type == EntityType::Context {
                    if let Some(ref wf_id) = parent_id {
                        on_drag_start_context.call((entity_id.clone(), wf_id.clone()));
                    }
                }

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

    let on_mouse_up = {
        let on_drag_end = on_drag_end.clone();
        move |_: MouseEvent| {
            if is_dragging.get() {
                is_dragging.set(false);
                // Signal drag end for context-to-workflow drops
                on_drag_end.call(());
            }
        }
    };

    // Mouse enter handler for workflow nodes (drop targets)
    let on_mouse_enter = {
        let on_drag_enter_workflow = on_drag_enter_workflow.clone();
        let entity_id = entity_id.clone();
        move |_: MouseEvent| {
            if is_dragging_context && entity_type == EntityType::Workflow {
                on_drag_enter_workflow.call(entity_id.clone());
            }
        }
    };

    // Mouse leave handler for workflow nodes
    let on_mouse_leave_node = {
        let on_drag_leave = on_drag_leave.clone();
        move |_: MouseEvent| {
            if is_dragging_context && entity_type == EntityType::Workflow {
                on_drag_leave.call(());
            }
        }
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
            class: format!("navigation-node navigation-node-{:?}{}", entity_type, if is_drop_target { " drop-target" } else { "" }).to_lowercase(),
            style: node_styles::container(&position, entity_type, selected, is_dragging.get(), is_drop_target),
            onmousedown: on_mouse_down,
            onmousemove: on_mouse_move,
            onmouseup: on_mouse_up,
            onmouseenter: on_mouse_enter,
            onmouseleave: on_mouse_leave_node,
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

    pub fn container(pos: &Position, entity_type: EntityType, selected: bool, is_dragging: bool, is_drop_target: bool) -> String {
        let border_color = match entity_type {
            EntityType::Workflow => "var(--color-primary)",
            EntityType::Context => "var(--color-secondary)",
            EntityType::Preset => "var(--color-accent)",
        };

        let selected_style = if is_drop_target {
            // Highlight as drop target
            "box-shadow: 0 0 0 4px var(--color-success), var(--shadow-lg); transform: scale(1.02);"
        } else if selected {
            "box-shadow: 0 0 0 3px var(--color-primary-alpha), var(--shadow-lg);"
        } else {
            "box-shadow: var(--shadow-md);"
        };

        let cursor = if is_dragging { "grabbing" } else { "grab" };
        let opacity = if is_dragging { "0.85" } else { "1" };
        let background = if is_drop_target {
            "var(--color-success-alpha, rgba(34, 197, 94, 0.1))"
        } else {
            "var(--color-surface)"
        };

        format!(
            r#"
                position: absolute;
                left: {x}px;
                top: {y}px;
                min-width: 180px;
                max-width: 240px;
                background: {background};
                border: 2px solid {border_color};
                border-radius: var(--radius-lg);
                cursor: {cursor};
                user-select: none;
                opacity: {opacity};
                transition: box-shadow 0.15s ease, transform 0.1s ease, background 0.15s ease;
                {selected_style}
            "#,
            x = pos.x,
            y = pos.y,
            background = background,
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
