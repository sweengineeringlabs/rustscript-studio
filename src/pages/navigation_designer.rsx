//! Navigation designer page - visual workflow/context/preset editor.

use rsc::prelude::*;

use rsc_flow::prelude::{FlowCanvas as RscFlowCanvas, LayoutConfig as FlowLayoutConfig, LayoutDirection};
use rsc_studio::designer::navigation::{NavigationDesigner, NavigationNodeData, EntityType};
use rsc_studio::entity::LayoutConfig as PresetLayoutConfig;

use crate::components::{NavigationCanvasView, NavigationPreview, Toolbar, ToolbarGroup, ToolbarButton, ToolbarDivider, Button, ButtonVariant, ButtonSize, Icon, Input, Modal, PresetLayoutEditor};
use crate::hooks::StudioStore;

/// Navigation designer page.
#[component]
pub fn NavigationDesignerPage(store: StudioStore) -> Element {
    let canvas = use_signal(|| {
        let mut designer = NavigationDesigner::new();
        let workflows = store.workflows();
        let workflow_refs: Vec<_> = workflows.iter().collect();
        designer.load_workflows(&workflow_refs);

        // Check for saved positions
        let saved_positions = store.node_positions();
        if saved_positions.is_empty() {
            // No saved positions, apply auto-layout
            designer.canvas.auto_layout(FlowLayoutConfig {
                direction: LayoutDirection::TopToBottom,
                node_sep: 80.0,
                rank_sep: 120.0,
                ..Default::default()
            });
        } else {
            // Apply saved positions
            for (node_id, (x, y)) in saved_positions {
                if let Some(node) = designer.canvas.nodes.get_mut(&node_id) {
                    node.position = rsc_flow::prelude::Position::new(x, y);
                }
            }
        }

        designer.canvas
    });

    let selected_node = use_signal::<Option<String>>(|| None);
    let zoom_level = use_signal(|| 100);
    let show_delete_modal = use_signal(|| false);
    let delete_target = use_signal::<Option<(String, EntityType)>>(|| None);
    let search_query = use_signal(String::new);
    let show_preview_panel = use_signal(|| false);

    // Helper to reload canvas preserving positions
    let reload_canvas = {
        let store = store.clone();
        let canvas = canvas.clone();
        move || {
            let workflows = store.workflows();
            let workflow_refs: Vec<_> = workflows.iter().collect();
            let mut designer = NavigationDesigner::new();
            designer.load_workflows(&workflow_refs);

            // Get saved positions
            let saved_positions = store.node_positions();

            // Auto-layout first for new nodes
            designer.canvas.auto_layout(FlowLayoutConfig {
                direction: LayoutDirection::TopToBottom,
                node_sep: 80.0,
                rank_sep: 120.0,
                ..Default::default()
            });

            // Then apply saved positions for existing nodes
            for (node_id, (x, y)) in saved_positions {
                if let Some(node) = designer.canvas.nodes.get_mut(&node_id) {
                    node.position = rsc_flow::prelude::Position::new(x, y);
                }
            }

            // Save the new layout positions for nodes that didn't have saved positions
            for (node_id, node) in &designer.canvas.nodes {
                if store.get_node_position(node_id).is_none() {
                    store.set_node_position(node_id, node.position.x, node.position.y);
                }
            }

            canvas.set(designer.canvas);
        }
    };

    // Toolbar actions
    let on_add_workflow = {
        let reload_canvas = reload_canvas.clone();
        let store = store.clone();
        move |_| {
            store.add_workflow("New Workflow");
            reload_canvas();
        }
    };

    let on_zoom_in = move |_| {
        zoom_level.update(|z| *z = (*z + 10).min(200));
        canvas.update(|c| {
            c.viewport.zoom = zoom_level.get() as f64 / 100.0;
        });
    };

    let on_zoom_out = move |_| {
        zoom_level.update(|z| *z = (*z - 10).max(25));
        canvas.update(|c| {
            c.viewport.zoom = zoom_level.get() as f64 / 100.0;
        });
    };

    let on_fit_view = move |_| {
        canvas.update(|c| {
            c.fit_view(50.0, rsc_flow::prelude::Dimensions::new(800.0, 600.0));
        });
        zoom_level.set(100);
    };

    let on_auto_layout = {
        let store = store.clone();
        move |_| {
            canvas.update(|c| {
                c.auto_layout(FlowLayoutConfig {
                    direction: LayoutDirection::TopToBottom,
                    node_sep: 80.0,
                    rank_sep: 120.0,
                    ..Default::default()
                });

                // Save the new positions
                for (node_id, node) in &c.nodes {
                    store.set_node_position(node_id, node.position.x, node.position.y);
                }
            });
        }
    };

    // Zoom to selected node
    let on_zoom_to_selection = {
        let canvas = canvas.clone();
        let selected_node = selected_node.clone();
        move |_| {
            if let Some(ref node_id) = selected_node.get() {
                canvas.update(|c| {
                    if let Some(node) = c.nodes.get(node_id) {
                        c.viewport.center_on(node.position);
                        c.viewport.zoom = 1.5;
                    }
                });
            }
        }
    };

    // Delete confirmation handler
    let on_confirm_delete = {
        let store = store.clone();
        let reload_canvas = reload_canvas.clone();
        let delete_target = delete_target.clone();
        let show_delete_modal = show_delete_modal.clone();
        let selected_node = selected_node.clone();
        move |_| {
            if let Some((id, entity_type)) = delete_target.get() {
                match entity_type {
                    EntityType::Workflow => {
                        store.remove_workflow(&id);
                    }
                    EntityType::Context => {
                        // Find parent workflow
                        for workflow in store.workflows() {
                            if workflow.contexts.contains_key(&id) {
                                store.remove_context(&workflow.id, &id);
                                break;
                            }
                        }
                    }
                    EntityType::Preset => {
                        // Find parent workflow and context
                        'outer: for workflow in store.workflows() {
                            for (ctx_id, context) in &workflow.contexts {
                                if context.presets.contains_key(&id) {
                                    store.remove_preset(&workflow.id, ctx_id, &id);
                                    break 'outer;
                                }
                            }
                        }
                    }
                }
                reload_canvas();
                selected_node.set(None);
            }
            show_delete_modal.set(false);
            delete_target.set(None);
        }
    };

    // Search handler
    let filtered_nodes: Vec<String> = {
        let query = search_query.get().to_lowercase();
        if query.is_empty() {
            vec![]
        } else {
            canvas.get().nodes.iter()
                .filter(|(_, node)| {
                    node.data.as_ref()
                        .map(|d| d.label.to_lowercase().contains(&query))
                        .unwrap_or(false)
                })
                .map(|(id, _)| id.clone())
                .collect()
        }
    };

    rsx! {
        div(class: "navigation-designer-page", style: styles::container()) {
            // Toolbar
            Toolbar {
                ToolbarGroup {
                    ToolbarButton {
                        icon: "plus".to_string(),
                        label: Some("Add Workflow".to_string()),
                        onclick: on_add_workflow.clone(),
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "zoom-in".to_string(),
                        onclick: on_zoom_in,
                    }

                    span(style: styles::zoom_label()) {
                        { format!("{}%", zoom_level.get()) }
                    }

                    ToolbarButton {
                        icon: "zoom-out".to_string(),
                        onclick: on_zoom_out,
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "maximize".to_string(),
                        label: Some("Fit".to_string()),
                        onclick: on_fit_view,
                    }

                    ToolbarButton {
                        icon: "target".to_string(),
                        label: Some("Zoom to Selection".to_string()),
                        onclick: on_zoom_to_selection,
                        disabled: selected_node.get().is_none(),
                    }

                    ToolbarButton {
                        icon: "layout".to_string(),
                        label: Some("Auto Layout".to_string()),
                        onclick: on_auto_layout,
                    }
                }

                ToolbarDivider {}

                // Preview toggle
                ToolbarGroup {
                    ToolbarButton {
                        icon: "play-circle".to_string(),
                        label: Some("Preview".to_string()),
                        active: show_preview_panel.get(),
                        onclick: {
                            let show_preview_panel = show_preview_panel.clone();
                            move |_| show_preview_panel.update(|v| *v = !*v)
                        },
                    }
                }

                ToolbarDivider {}

                // Keyboard shortcuts help
                ToolbarGroup {
                    div(style: styles::keyboard_help()) {
                        Icon { name: "keyboard".to_string(), size: 14 }
                        span(style: styles::keyboard_help_text()) {
                            "Arrow/Tab: Navigate • Enter: Edit • Del: Delete • Esc: Deselect"
                        }
                    }
                }

                ToolbarDivider {}

                // Search box
                ToolbarGroup {
                    div(style: styles::search_container()) {
                        Icon { name: "search".to_string(), size: 16 }
                        input(
                            r#type: "text",
                            placeholder: "Search nodes...",
                            style: styles::search_input(),
                            value: search_query.get().clone(),
                            oninput: move |e: FormEvent| {
                                search_query.set(e.value.clone());
                            }
                        )
                    }
                }
            }

            // Search results dropdown
            if !filtered_nodes.is_empty() {
                div(class: "search-results", style: styles::search_results()) {
                    for node_id in filtered_nodes {
                        {
                            let canvas_value = canvas.get();
                            let node = canvas_value.nodes.get(&node_id);
                            if let Some(node) = node {
                                let label = node.data.as_ref().map(|d| d.label.clone()).unwrap_or_default();
                                let entity_type = node.data.as_ref().map(|d| d.entity_type);
                                rsx! {
                                    div(
                                        class: "search-result-item",
                                        style: styles::search_result_item(),
                                        onclick: {
                                            let node_id = node_id.clone();
                                            let selected_node = selected_node.clone();
                                            let search_query = search_query.clone();
                                            let canvas = canvas.clone();
                                            move |_| {
                                                selected_node.set(Some(node_id.clone()));
                                                search_query.set(String::new());
                                                // Center on node
                                                canvas.update(|c| {
                                                    if let Some(n) = c.nodes.get(&node_id) {
                                                        c.viewport.center_on(n.position);
                                                    }
                                                });
                                            }
                                        }
                                    ) {
                                        if let Some(et) = entity_type {
                                            span(style: styles::type_badge_small(et)) {
                                                { format!("{:?}", et) }
                                            }
                                        }
                                        span { { label } }
                                    }
                                }
                            } else {
                                rsx! {}
                            }
                        }
                    }
                }
            }

            // Main content area (canvas + optional preview)
            div(class: "main-content", style: styles::main_content()) {
                // Canvas area
                div(class: "canvas-container", style: styles::canvas_container_with_preview(show_preview_panel.get())) {
                    NavigationCanvasView {
                    canvas: canvas.clone(),
                    selected_node_id: selected_node.get(),
                    on_node_select: Some({
                        let selected_node = selected_node.clone();
                        Callback::new(move |id: String| {
                            // Empty string means deselect (from Escape key)
                            if id.is_empty() {
                                selected_node.set(None);
                            } else {
                                selected_node.set(Some(id));
                            }
                        })
                    }),
                    on_node_move: Some({
                        let store = store.clone();
                        Callback::new(move |(id, pos): (String, rsc_flow::prelude::Position)| {
                            // Update canvas
                            canvas.update(|c| {
                                if let Some(node) = c.nodes.get_mut(&id) {
                                    node.position = pos;
                                }
                            });
                            // Persist position to store
                            store.set_node_position(&id, pos.x, pos.y);
                        })
                    }),
                    on_delete: Some({
                        let canvas = canvas.clone();
                        let show_delete_modal = show_delete_modal.clone();
                        let delete_target = delete_target.clone();
                        Callback::new(move |id: String| {
                            // Find the entity type for this node
                            let canvas_data = canvas.get();
                            if let Some(node) = canvas_data.nodes.get(&id) {
                                if let Some(ref data) = node.data {
                                    delete_target.set(Some((data.entity_id.clone(), data.entity_type)));
                                    show_delete_modal.set(true);
                                }
                            }
                        })
                    }),
                    on_edit: Some({
                        // Selecting a node already opens the details panel
                        // which has edit functionality
                        Callback::new(move |_id: String| {
                            // The node is already selected, so the panel is open
                            // We could potentially trigger edit mode directly here
                        })
                    }),
                }

                    // Empty state
                    if store.workflows().is_empty() {
                        EmptyState {
                            on_add: on_add_workflow.clone(),
                            on_load_sample: {
                                let store = store.clone();
                                let reload_canvas = reload_canvas.clone();
                                move |_| {
                                    store.load_sample_data();
                                    reload_canvas();
                                }
                            },
                        }
                    }
                }

                // Preview panel
                if show_preview_panel.get() {
                    div(class: "preview-panel", style: styles::preview_panel()) {
                        NavigationPreview {
                            store: store.clone(),
                        }
                    }
                }
            }

            // Selection details panel (if a node is selected)
            if let Some(ref node_id) = selected_node.get() {
                NodeDetailsPanel {
                    canvas: canvas.clone(),
                    node_id: node_id.clone(),
                    store: store.clone(),
                    on_close: {
                        let selected_node = selected_node.clone();
                        move |_| selected_node.set(None)
                    },
                    on_delete: {
                        let show_delete_modal = show_delete_modal.clone();
                        let delete_target = delete_target.clone();
                        move |(id, entity_type): (String, EntityType)| {
                            delete_target.set(Some((id, entity_type)));
                            show_delete_modal.set(true);
                        }
                    },
                    on_update: {
                        let reload_canvas = reload_canvas.clone();
                        move |_| reload_canvas()
                    },
                    on_add_context: {
                        let store = store.clone();
                        let reload_canvas = reload_canvas.clone();
                        move |workflow_id: String| {
                            store.add_context(&workflow_id, "New Context");
                            reload_canvas();
                        }
                    },
                    on_add_preset: {
                        let store = store.clone();
                        let reload_canvas = reload_canvas.clone();
                        move |(workflow_id, context_id): (String, String)| {
                            store.add_preset(&workflow_id, &context_id, "New Preset");
                            reload_canvas();
                        }
                    },
                    on_duplicate: {
                        let store = store.clone();
                        let reload_canvas = reload_canvas.clone();
                        move |(id, entity_type, parent_id): (String, EntityType, Option<String>)| {
                            match entity_type {
                                EntityType::Workflow => {
                                    store.duplicate_workflow(&id);
                                }
                                EntityType::Context => {
                                    if let Some(wf_id) = parent_id {
                                        store.duplicate_context(&wf_id, &id);
                                    }
                                }
                                EntityType::Preset => {
                                    // Find workflow and context
                                    for workflow in store.workflows() {
                                        for (ctx_id, context) in &workflow.contexts {
                                            if context.presets.contains_key(&id) {
                                                store.duplicate_preset(&workflow.id, ctx_id, &id);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            reload_canvas();
                        }
                    },
                    on_layout_change: Some({
                        let store = store.clone();
                        Callback::new(move |(preset_id, layout): (String, PresetLayoutConfig)| {
                            // Find the preset location and update the layout
                            if let Some((wf_id, ctx_id)) = store.find_preset_location(&preset_id) {
                                store.update_preset_layout(&wf_id, &ctx_id, &preset_id, layout);
                            }
                        })
                    }),
                }
            }
        }

        // Delete confirmation modal
        if show_delete_modal.get() {
            Modal {
                title: "Confirm Delete".to_string(),
                on_close: {
                    let show_delete_modal = show_delete_modal.clone();
                    move |_| show_delete_modal.set(false)
                },
            } {
                p { "Are you sure you want to delete this item? This action cannot be undone." }
                div(style: "display: flex; gap: var(--spacing-md); justify-content: flex-end; margin-top: var(--spacing-lg);") {
                    Button {
                        variant: ButtonVariant::Secondary,
                        onclick: {
                            let show_delete_modal = show_delete_modal.clone();
                            move |_| show_delete_modal.set(false)
                        },
                    } { "Cancel" }
                    Button {
                        variant: ButtonVariant::Danger,
                        onclick: on_confirm_delete,
                    } { "Delete" }
                }
            }
        }
    }
}

/// Empty state when no workflows exist.
#[component]
fn EmptyState(on_add: Callback<()>, on_load_sample: Callback<()>) -> Element {
    rsx! {
        div(class: "empty-state", style: styles::empty_state()) {
            Icon { name: "git-branch".to_string(), size: 48 }
            h2(style: styles::empty_title()) { "No Workflows Yet" }
            p(style: styles::empty_description()) {
                "Create your first workflow to start designing navigation flows."
            }
            div(class: "empty-actions", style: styles::empty_actions()) {
                Button {
                    variant: ButtonVariant::Primary,
                    onclick: on_add.clone(),
                } {
                    Icon { name: "plus".to_string() }
                    "Create Workflow"
                }
                Button {
                    variant: ButtonVariant::Secondary,
                    onclick: on_load_sample.clone(),
                } {
                    Icon { name: "download".to_string() }
                    "Load Sample Data"
                }
            }
        }
    }
}

/// Node details panel with editing capabilities.
#[component]
fn NodeDetailsPanel(
    canvas: Signal<RscFlowCanvas<NavigationNodeData, ()>>,
    node_id: String,
    store: StudioStore,
    on_close: Callback<()>,
    on_delete: Callback<(String, EntityType)>,
    on_update: Callback<()>,
    on_add_context: Callback<String>,
    on_add_preset: Callback<(String, String)>,
    on_duplicate: Callback<(String, EntityType, Option<String>)>,
    on_layout_change: Option<Callback<(String, PresetLayoutConfig)>>,
) -> Element {
    let canvas_value = canvas.get();
    let node = canvas_value.nodes.get(&node_id);

    let Some(node) = node else {
        return rsx! {};
    };

    let data = node.data.as_ref();
    let Some(data) = data else {
        return rsx! {};
    };

    let is_editing = use_signal(|| false);
    let edit_name = use_signal(|| data.label.clone());
    let edit_description = use_signal(|| data.description.clone().unwrap_or_default());

    let entity_type = data.entity_type;
    let entity_id = data.entity_id.clone();
    let parent_id = data.parent_id.clone();

    // Save handler
    let on_save = {
        let store = store.clone();
        let entity_id = entity_id.clone();
        let parent_id = parent_id.clone();
        let is_editing = is_editing.clone();
        let on_update = on_update.clone();
        move |_| {
            let name = Some(edit_name.get().clone());
            let desc = if edit_description.get().is_empty() {
                None
            } else {
                Some(edit_description.get().clone())
            };

            match entity_type {
                EntityType::Workflow => {
                    store.update_workflow(&entity_id, name, desc, None);
                }
                EntityType::Context => {
                    if let Some(ref wf_id) = parent_id {
                        store.update_context(wf_id, &entity_id, name, desc, None);
                    }
                }
                EntityType::Preset => {
                    // Find workflow and context for this preset
                    for workflow in store.workflows() {
                        for (ctx_id, context) in &workflow.contexts {
                            if context.presets.contains_key(&entity_id) {
                                store.update_preset(&workflow.id, ctx_id, &entity_id, name.clone(), desc.clone());
                                break;
                            }
                        }
                    }
                }
            }

            is_editing.set(false);
            on_update.call(());
        }
    };

    rsx! {
        div(class: "node-details-panel", style: styles::details_panel()) {
            div(class: "panel-header", style: styles::panel_header()) {
                h3(style: styles::panel_title()) {
                    { data.label.clone() }
                }
                div(style: "display: flex; gap: var(--spacing-xs);") {
                    Button {
                        variant: ButtonVariant::Ghost,
                        size: ButtonSize::Sm,
                        onclick: on_close.clone(),
                    } {
                        Icon { name: "x".to_string() }
                    }
                }
            }

            div(class: "panel-content", style: styles::panel_content()) {
                // Entity type badge
                div(class: "detail-row", style: styles::detail_row()) {
                    span(class: "detail-label", style: styles::detail_label()) { "Type" }
                    span(class: "badge", style: styles::type_badge(entity_type)) {
                        { format!("{:?}", entity_type) }
                    }
                }

                // Editable fields
                if is_editing.get() {
                    div(class: "edit-form", style: styles::edit_form()) {
                        div(class: "form-group") {
                            label(style: styles::form_label()) { "Name" }
                            Input {
                                value: edit_name.get().clone(),
                                on_change: {
                                    let edit_name = edit_name.clone();
                                    move |v: String| edit_name.set(v)
                                },
                            }
                        }
                        div(class: "form-group") {
                            label(style: styles::form_label()) { "Description" }
                            Input {
                                value: edit_description.get().clone(),
                                placeholder: Some("Optional description".to_string()),
                                on_change: {
                                    let edit_description = edit_description.clone();
                                    move |v: String| edit_description.set(v)
                                },
                            }
                        }
                        div(style: "display: flex; gap: var(--spacing-sm); margin-top: var(--spacing-md);") {
                            Button {
                                variant: ButtonVariant::Primary,
                                size: ButtonSize::Sm,
                                onclick: on_save,
                            } { "Save" }
                            Button {
                                variant: ButtonVariant::Secondary,
                                size: ButtonSize::Sm,
                                onclick: {
                                    let is_editing = is_editing.clone();
                                    move |_| is_editing.set(false)
                                },
                            } { "Cancel" }
                        }
                    }
                } else {
                    // Display mode
                    if let Some(ref desc) = data.description {
                        div(class: "detail-row", style: styles::detail_row()) {
                            span(class: "detail-label", style: styles::detail_label()) { "Description" }
                            span(class: "detail-value") { { desc.clone() } }
                        }
                    }

                    div(class: "detail-row", style: styles::detail_row()) {
                        span(class: "detail-label", style: styles::detail_label()) { "Position" }
                        span(class: "detail-value") {
                            { format!("({:.0}, {:.0})", node.position.x, node.position.y) }
                        }
                    }
                }

                // Actions
                div(class: "panel-actions", style: styles::panel_actions()) {
                    if !is_editing.get() {
                        Button {
                            variant: ButtonVariant::Secondary,
                            size: ButtonSize::Sm,
                            onclick: {
                                let is_editing = is_editing.clone();
                                let edit_name = edit_name.clone();
                                let edit_description = edit_description.clone();
                                let label = data.label.clone();
                                let desc = data.description.clone();
                                move |_| {
                                    edit_name.set(label.clone());
                                    edit_description.set(desc.clone().unwrap_or_default());
                                    is_editing.set(true);
                                }
                            },
                        } {
                            Icon { name: "edit".to_string() }
                            "Edit"
                        }
                    }

                    // Workflow-specific actions
                    if entity_type == EntityType::Workflow {
                        Button {
                            variant: ButtonVariant::Secondary,
                            size: ButtonSize::Sm,
                            onclick: {
                                let on_add_context = on_add_context.clone();
                                let entity_id = entity_id.clone();
                                move |_| on_add_context.call(entity_id.clone())
                            },
                        } {
                            Icon { name: "plus".to_string() }
                            "Add Context"
                        }
                    }

                    // Context-specific actions
                    if entity_type == EntityType::Context {
                        if let Some(ref wf_id) = parent_id {
                            Button {
                                variant: ButtonVariant::Secondary,
                                size: ButtonSize::Sm,
                                onclick: {
                                    let on_add_preset = on_add_preset.clone();
                                    let wf_id = wf_id.clone();
                                    let entity_id = entity_id.clone();
                                    move |_| on_add_preset.call((wf_id.clone(), entity_id.clone()))
                                },
                            } {
                                Icon { name: "plus".to_string() }
                                "Add Preset"
                            }
                        }
                    }

                    // Duplicate button (for all types)
                    Button {
                        variant: ButtonVariant::Secondary,
                        size: ButtonSize::Sm,
                        onclick: {
                            let on_duplicate = on_duplicate.clone();
                            let entity_id = entity_id.clone();
                            let parent_id = parent_id.clone();
                            move |_| on_duplicate.call((entity_id.clone(), entity_type, parent_id.clone()))
                        },
                    } {
                        Icon { name: "copy".to_string() }
                        "Duplicate"
                    }

                    // Delete button (available for all types)
                    Button {
                        variant: ButtonVariant::Danger,
                        size: ButtonSize::Sm,
                        onclick: {
                            let on_delete = on_delete.clone();
                            let entity_id = entity_id.clone();
                            move |_| on_delete.call((entity_id.clone(), entity_type))
                        },
                    } {
                        Icon { name: "trash".to_string() }
                        "Delete"
                    }
                }

                // Layout editor for Presets
                if entity_type == EntityType::Preset && !is_editing.get() {
                    {
                        // Get the preset layout
                        let preset_layout = {
                            let location = store.find_preset_location(&entity_id);
                            if let Some((wf_id, ctx_id)) = location {
                                store.get_preset(&wf_id, &ctx_id, &entity_id)
                                    .map(|p| p.layout)
                                    .unwrap_or_default()
                            } else {
                                PresetLayoutConfig::default()
                            }
                        };

                        rsx! {
                            div(class: "layout-editor-section", style: styles::layout_editor_section()) {
                                h4(style: styles::section_title()) {
                                    Icon { name: "layout".to_string(), size: 16 }
                                    span { "Layout Configuration" }
                                }
                                PresetLayoutEditor {
                                    layout: preset_layout,
                                    on_change: {
                                        let on_layout_change = on_layout_change.clone();
                                        let entity_id = entity_id.clone();
                                        Callback::new(move |new_layout: PresetLayoutConfig| {
                                            if let Some(ref callback) = on_layout_change {
                                                callback.call((entity_id.clone(), new_layout));
                                            }
                                        })
                                    },
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

mod styles {
    use rsc_studio::designer::navigation::EntityType;

    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            height: 100%;
        "#
    }

    pub fn main_content() -> &'static str {
        r#"
            display: flex;
            flex: 1;
            overflow: hidden;
        "#
    }

    pub fn canvas_container_with_preview(has_preview: bool) -> String {
        format!(
            r#"
                flex: {};
                position: relative;
                overflow: hidden;
            "#,
            if has_preview { "1" } else { "1" }
        )
    }

    pub fn canvas_container() -> &'static str {
        r#"
            flex: 1;
            position: relative;
            overflow: hidden;
        "#
    }

    pub fn preview_panel() -> &'static str {
        r#"
            width: 380px;
            min-width: 320px;
            border-left: 1px solid var(--color-border);
            background: var(--color-bg-secondary);
            overflow: hidden;
        "#
    }

    pub fn zoom_label() -> &'static str {
        r#"
            min-width: 48px;
            text-align: center;
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn keyboard_help() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-xs) var(--spacing-sm);
            color: var(--color-text-secondary);
            opacity: 0.7;
        "#
    }

    pub fn keyboard_help_text() -> &'static str {
        r#"
            font-size: 11px;
            white-space: nowrap;
        "#
    }

    pub fn search_container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-xs) var(--spacing-sm);
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
        "#
    }

    pub fn search_input() -> &'static str {
        r#"
            border: none;
            background: transparent;
            outline: none;
            font-size: var(--font-size-sm);
            width: 150px;
        "#
    }

    pub fn search_results() -> &'static str {
        r#"
            position: absolute;
            top: 48px;
            right: var(--spacing-md);
            width: 250px;
            max-height: 300px;
            overflow-y: auto;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-lg);
            z-index: 100;
        "#
    }

    pub fn search_result_item() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            cursor: pointer;
            transition: background 0.15s ease;
        "#
    }

    pub fn type_badge_small(entity_type: EntityType) -> String {
        let color = match entity_type {
            EntityType::Workflow => "var(--color-primary)",
            EntityType::Context => "var(--color-secondary)",
            EntityType::Preset => "var(--color-accent)",
        };
        format!(
            r#"
                display: inline-block;
                padding: 1px 6px;
                border-radius: var(--radius-xs);
                font-size: 10px;
                font-weight: var(--font-weight-medium);
                background: {};
                color: white;
            "#,
            color
        )
    }

    pub fn empty_state() -> &'static str {
        r#"
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            color: var(--color-text-secondary);
        "#
    }

    pub fn empty_title() -> &'static str {
        r#"
            margin: var(--spacing-md) 0 var(--spacing-sm);
            font-size: var(--font-size-xl);
            color: var(--color-text-primary);
        "#
    }

    pub fn empty_description() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-lg);
            max-width: 300px;
        "#
    }

    pub fn empty_actions() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-md);
        "#
    }

    pub fn details_panel() -> &'static str {
        r#"
            position: absolute;
            top: var(--spacing-md);
            right: var(--spacing-md);
            width: 320px;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-lg);
            overflow: hidden;
        "#
    }

    pub fn panel_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: var(--spacing-sm) var(--spacing-md);
            border-bottom: 1px solid var(--color-border);
            background: var(--color-bg-secondary);
        "#
    }

    pub fn panel_title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-base);
            font-weight: var(--font-weight-semibold);
        "#
    }

    pub fn panel_content() -> &'static str {
        r#"
            padding: var(--spacing-md);
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }

    pub fn detail_row() -> &'static str {
        r#"
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: var(--spacing-xs) 0;
        "#
    }

    pub fn detail_label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn type_badge(entity_type: EntityType) -> String {
        let color = match entity_type {
            EntityType::Workflow => "var(--color-primary)",
            EntityType::Context => "var(--color-secondary)",
            EntityType::Preset => "var(--color-accent)",
        };
        format!(
            r#"
                display: inline-block;
                padding: 2px 8px;
                border-radius: var(--radius-sm);
                font-size: var(--font-size-xs);
                font-weight: var(--font-weight-medium);
                background: {};
                color: white;
            "#,
            color
        )
    }

    pub fn edit_form() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-md);
            padding: var(--spacing-sm) 0;
        "#
    }

    pub fn form_label() -> &'static str {
        r#"
            display: block;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            margin-bottom: var(--spacing-xs);
        "#
    }

    pub fn panel_actions() -> &'static str {
        r#"
            display: flex;
            flex-wrap: wrap;
            gap: var(--spacing-sm);
            padding-top: var(--spacing-md);
            border-top: 1px solid var(--color-border);
            margin-top: var(--spacing-sm);
        "#
    }

    pub fn layout_editor_section() -> &'static str {
        r#"
            margin-top: var(--spacing-lg);
            padding-top: var(--spacing-md);
            border-top: 1px solid var(--color-border);
        "#
    }

    pub fn section_title() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            margin: 0 0 var(--spacing-md) 0;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-primary);
        "#
    }
}
