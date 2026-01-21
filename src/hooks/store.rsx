//! Studio store hook - global state management.

use rsc::prelude::*;
use std::collections::HashMap;

use rsc_studio::entity::{Workflow, Context, Preset, LayoutConfig, LayoutVariant, Position, ActivityBarConfig, SidebarConfig, BottomPanelConfig};
use rsc_studio::designer::css::{DesignTokens, ComponentStyles, ComponentStyle};

/// Studio store for global application state.
#[derive(Clone)]
pub struct StudioStore {
    inner: Signal<StudioStoreInner>,
}

#[derive(Clone, Default)]
struct StudioStoreInner {
    workflows: Vec<Workflow>,
    selected_workflow: Option<String>,
    selected_context: Option<String>,
    selected_preset: Option<String>,
    design_tokens: DesignTokens,
    component_styles: ComponentStyles,
    theme: Theme,
    /// Node positions for the navigation designer (entity_id -> (x, y))
    node_positions: HashMap<String, (f64, f64)>,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Theme {
    Light,
    Dark,
    System,
}

impl Default for Theme {
    fn default() -> Self {
        Theme::Light
    }
}

impl StudioStore {
    fn new() -> Self {
        Self {
            inner: signal(StudioStoreInner::default()),
        }
    }

    /// Get all workflows.
    pub fn workflows(&self) -> Vec<Workflow> {
        self.inner.get().workflows.clone()
    }

    /// Add a new workflow.
    pub fn add_workflow(&self, name: &str) -> String {
        let workflow = Workflow::new(name);
        let id = workflow.id.clone();
        self.inner.update(|s| {
            s.workflows.push(workflow);
        });
        id
    }

    /// Remove a workflow by ID.
    pub fn remove_workflow(&self, id: &str) {
        self.inner.update(|s| {
            s.workflows.retain(|w| w.id != id);
            // Clear selection if deleted workflow was selected
            if s.selected_workflow.as_ref() == Some(&id.to_string()) {
                s.selected_workflow = None;
                s.selected_context = None;
                s.selected_preset = None;
            }
        });
    }

    /// Update workflow properties.
    pub fn update_workflow(&self, id: &str, name: Option<String>, description: Option<String>, icon: Option<String>) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == id) {
                if let Some(n) = name {
                    workflow.name = n;
                }
                if description.is_some() {
                    workflow.description = description;
                }
                if icon.is_some() {
                    workflow.icon = icon;
                }
            }
        });
    }

    /// Duplicate a workflow.
    pub fn duplicate_workflow(&self, id: &str) -> Option<String> {
        let inner = self.inner.get();
        let workflow = inner.workflows.iter().find(|w| w.id == id)?;

        let mut new_workflow = workflow.clone();
        new_workflow.id = uuid::Uuid::new_v4().to_string();
        new_workflow.name = format!("{} (Copy)", workflow.name);

        let new_id = new_workflow.id.clone();
        drop(inner);
        self.inner.update(|s| {
            s.workflows.push(new_workflow);
        });
        Some(new_id)
    }

    /// Reorder workflows by moving one to a new index.
    pub fn reorder_workflow(&self, from_index: usize, to_index: usize) {
        self.inner.update(|s| {
            if from_index < s.workflows.len() && to_index < s.workflows.len() {
                let workflow = s.workflows.remove(from_index);
                s.workflows.insert(to_index, workflow);
            }
        });
    }

    /// Get a workflow by ID.
    pub fn get_workflow(&self, id: &str) -> Option<Workflow> {
        self.inner.get().workflows.iter().find(|w| w.id == id).cloned()
    }

    /// Get the selected workflow.
    pub fn selected_workflow(&self) -> Option<Workflow> {
        let inner = self.inner.get();
        inner
            .selected_workflow
            .as_ref()
            .and_then(|id| inner.workflows.iter().find(|w| &w.id == id).cloned())
    }

    /// Select a workflow.
    pub fn select_workflow(&self, id: Option<String>) {
        self.inner.update(|s| {
            s.selected_workflow = id;
            s.selected_context = None;
            s.selected_preset = None;
        });
    }

    /// Add a context to a workflow.
    pub fn add_context(&self, workflow_id: &str, name: &str) -> Option<String> {
        let context = Context::new(name);
        let id = context.id.clone();
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                workflow.add_context(context);
            }
        });
        Some(id)
    }

    /// Remove a context from a workflow.
    pub fn remove_context(&self, workflow_id: &str, context_id: &str) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                workflow.contexts.shift_remove(context_id);
                // Clear selection if deleted context was selected
                if s.selected_context.as_ref() == Some(&context_id.to_string()) {
                    s.selected_context = None;
                    s.selected_preset = None;
                }
            }
        });
    }

    /// Move a context from one workflow to another.
    pub fn move_context(&self, source_workflow_id: &str, target_workflow_id: &str, context_id: &str) -> bool {
        if source_workflow_id == target_workflow_id {
            return false; // No-op, same workflow
        }

        let inner = self.inner.get();

        // Check if source and target workflows exist and context exists in source
        let source_has_context = inner.workflows.iter()
            .find(|w| w.id == source_workflow_id)
            .map(|w| w.contexts.contains_key(context_id))
            .unwrap_or(false);

        let target_exists = inner.workflows.iter()
            .any(|w| w.id == target_workflow_id);

        if !source_has_context || !target_exists {
            return false;
        }

        drop(inner);

        self.inner.update(|s| {
            // Find and remove context from source workflow
            let context = {
                let source_workflow = s.workflows.iter_mut().find(|w| w.id == source_workflow_id);
                source_workflow.and_then(|w| w.contexts.shift_remove(context_id))
            };

            // Add context to target workflow
            if let Some(ctx) = context {
                if let Some(target_workflow) = s.workflows.iter_mut().find(|w| w.id == target_workflow_id) {
                    target_workflow.contexts.insert(ctx.id.clone(), ctx);
                }
            }
        });

        true
    }

    /// Update context properties.
    pub fn update_context(&self, workflow_id: &str, context_id: &str, name: Option<String>, description: Option<String>, icon: Option<String>) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    if let Some(n) = name {
                        context.name = n;
                    }
                    if description.is_some() {
                        context.description = description;
                    }
                    if icon.is_some() {
                        context.icon = icon;
                    }
                }
            }
        });
    }

    /// Add a preset to a context.
    pub fn add_preset(&self, workflow_id: &str, context_id: &str, name: &str) -> Option<String> {
        let preset = Preset::new(name);
        let id = preset.id.clone();
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    context.add_preset(preset);
                }
            }
        });
        Some(id)
    }

    /// Remove a preset from a context.
    pub fn remove_preset(&self, workflow_id: &str, context_id: &str, preset_id: &str) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    context.presets.shift_remove(preset_id);
                }
            }
        });
    }

    /// Update preset properties.
    pub fn update_preset(&self, workflow_id: &str, context_id: &str, preset_id: &str, name: Option<String>, description: Option<String>) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    if let Some(preset) = context.presets.get_mut(preset_id) {
                        if let Some(n) = name {
                            preset.name = n;
                        }
                        if description.is_some() {
                            preset.description = description;
                        }
                    }
                }
            }
        });
    }

    /// Update preset layout configuration.
    pub fn update_preset_layout(&self, workflow_id: &str, context_id: &str, preset_id: &str, layout: LayoutConfig) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    if let Some(preset) = context.presets.get_mut(preset_id) {
                        preset.layout = layout;
                    }
                }
            }
        });
    }

    /// Get preset by ID.
    pub fn get_preset(&self, workflow_id: &str, context_id: &str, preset_id: &str) -> Option<Preset> {
        let inner = self.inner.get();
        inner.workflows.iter()
            .find(|w| w.id == workflow_id)
            .and_then(|w| w.contexts.get(context_id))
            .and_then(|c| c.presets.get(preset_id))
            .cloned()
    }

    /// Find preset location (returns workflow_id, context_id).
    pub fn find_preset_location(&self, preset_id: &str) -> Option<(String, String)> {
        let inner = self.inner.get();
        for workflow in &inner.workflows {
            for (ctx_id, context) in &workflow.contexts {
                if context.presets.contains_key(preset_id) {
                    return Some((workflow.id.clone(), ctx_id.clone()));
                }
            }
        }
        None
    }

    /// Duplicate a preset.
    pub fn duplicate_preset(&self, workflow_id: &str, context_id: &str, preset_id: &str) -> Option<String> {
        let inner = self.inner.get();
        let workflow = inner.workflows.iter().find(|w| w.id == workflow_id)?;
        let context = workflow.contexts.get(context_id)?;
        let preset = context.presets.get(preset_id)?;

        let mut new_preset = preset.clone();
        new_preset.id = uuid::Uuid::new_v4().to_string();
        new_preset.name = format!("{} (Copy)", preset.name);

        let new_id = new_preset.id.clone();
        drop(inner);
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    context.presets.insert(new_preset.id.clone(), new_preset);
                }
            }
        });
        Some(new_id)
    }

    /// Duplicate a context.
    pub fn duplicate_context(&self, workflow_id: &str, context_id: &str) -> Option<String> {
        let inner = self.inner.get();
        let workflow = inner.workflows.iter().find(|w| w.id == workflow_id)?;
        let context = workflow.contexts.get(context_id)?;

        let mut new_context = context.clone();
        new_context.id = uuid::Uuid::new_v4().to_string();
        new_context.name = format!("{} (Copy)", context.name);
        // Update all preset IDs in the duplicated context
        let mut new_presets = indexmap::IndexMap::new();
        for preset in new_context.presets.values() {
            let mut new_preset = preset.clone();
            new_preset.id = uuid::Uuid::new_v4().to_string();
            new_presets.insert(new_preset.id.clone(), new_preset);
        }
        new_context.presets = new_presets;

        let new_id = new_context.id.clone();
        drop(inner);
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                workflow.contexts.insert(new_context.id.clone(), new_context);
            }
        });
        Some(new_id)
    }

    /// Get the design tokens.
    pub fn design_tokens(&self) -> Signal<DesignTokens> {
        let tokens = self.inner.get().design_tokens.clone();
        signal(tokens)
    }

    /// Update a design token.
    pub fn update_token(&self, path: &str, value: rsc_studio::designer::css::TokenValue) {
        self.inner.update(|s| {
            let parts: Vec<&str> = path.split('.').collect();
            if parts.len() >= 2 {
                match parts[0] {
                    "colors" => {
                        s.design_tokens.colors.insert(parts[1].to_string(), value);
                    }
                    "spacing" => {
                        s.design_tokens.spacing.insert(parts[1].to_string(), value);
                    }
                    "radius" => {
                        s.design_tokens.radius.insert(parts[1].to_string(), value);
                    }
                    "shadows" => {
                        s.design_tokens.shadows.insert(parts[1].to_string(), value);
                    }
                    "transitions" => {
                        s.design_tokens.transitions.insert(parts[1].to_string(), value);
                    }
                    "z-index" => {
                        s.design_tokens.z_index.insert(parts[1].to_string(), value);
                    }
                    _ => {}
                }
            }
        });
    }

    /// Add a new token to a category.
    pub fn add_token(&self, category: &str, name: &str, value: rsc_studio::designer::css::TokenValue) {
        self.inner.update(|s| {
            match category {
                "colors" => { s.design_tokens.colors.insert(name.to_string(), value); }
                "spacing" => { s.design_tokens.spacing.insert(name.to_string(), value); }
                "radius" => { s.design_tokens.radius.insert(name.to_string(), value); }
                "shadows" => { s.design_tokens.shadows.insert(name.to_string(), value); }
                "transitions" => { s.design_tokens.transitions.insert(name.to_string(), value); }
                "z-index" => { s.design_tokens.z_index.insert(name.to_string(), value); }
                _ => {}
            }
        });
    }

    /// Remove a token from a category.
    pub fn remove_token(&self, category: &str, name: &str) {
        self.inner.update(|s| {
            match category {
                "colors" => { s.design_tokens.colors.shift_remove(name); }
                "spacing" => { s.design_tokens.spacing.shift_remove(name); }
                "radius" => { s.design_tokens.radius.shift_remove(name); }
                "shadows" => { s.design_tokens.shadows.shift_remove(name); }
                "transitions" => { s.design_tokens.transitions.shift_remove(name); }
                "z-index" => { s.design_tokens.z_index.shift_remove(name); }
                _ => {}
            }
        });
    }

    // ============== Component Styles Methods ==============

    /// Get the component styles.
    pub fn component_styles(&self) -> Signal<ComponentStyles> {
        let styles = self.inner.get().component_styles.clone();
        signal(styles)
    }

    /// Update a component style.
    pub fn update_component_style(&self, name: &str, component_style: ComponentStyle) {
        self.inner.update(|s| {
            s.component_styles.set(name.to_string(), component_style);
        });
    }

    /// Get generated CSS for component styles.
    pub fn get_component_css(&self) -> String {
        self.inner.get().component_styles.generate_css()
    }

    /// Import tokens, replacing existing ones.
    pub fn import_tokens(&self, tokens: rsc_studio::designer::css::DesignTokens) {
        self.inner.update(|s| {
            s.design_tokens = tokens;
        });
    }

    /// Get generated CSS from current tokens.
    pub fn get_generated_css(&self) -> String {
        let tokens = &self.inner.get().design_tokens;
        let mut css = String::from(":root {\n");

        // Colors
        for (name, value) in &tokens.colors {
            if let rsc_studio::designer::css::TokenValue::Simple(v) = value {
                css.push_str(&format!("  --color-{}: {};\n", name, v));
            }
        }

        // Spacing
        for (name, value) in &tokens.spacing {
            if let rsc_studio::designer::css::TokenValue::Simple(v) = value {
                css.push_str(&format!("  --spacing-{}: {};\n", name, v));
            }
        }

        // Radius
        for (name, value) in &tokens.radius {
            if let rsc_studio::designer::css::TokenValue::Simple(v) = value {
                css.push_str(&format!("  --radius-{}: {};\n", name, v));
            }
        }

        // Shadows
        for (name, value) in &tokens.shadows {
            if let rsc_studio::designer::css::TokenValue::Simple(v) = value {
                css.push_str(&format!("  --shadow-{}: {};\n", name, v));
            }
        }

        css.push_str("}\n");
        css
    }

    /// Get current theme.
    pub fn theme(&self) -> Theme {
        self.inner.get().theme
    }

    /// Set theme.
    pub fn set_theme(&self, theme: Theme) {
        self.inner.update(|s| {
            s.theme = theme;
        });
    }

    /// Load sample data for demo purposes.
    pub fn load_sample_data(&self) {
        self.inner.update(|s| {
            // Create sample workflow
            let mut workflow = Workflow::new("Development");
            workflow.description = Some("Development workflow".to_string());
            workflow.icon = Some("code".to_string());

            // Add contexts
            let mut coding_ctx = Context::new("Coding");
            coding_ctx.description = Some("Writing code context".to_string());
            coding_ctx.add_preset(Preset::new("Default IDE"));
            coding_ctx.add_preset(Preset::new("Focus Mode"));
            workflow.add_context(coding_ctx);

            let mut review_ctx = Context::new("Code Review");
            review_ctx.description = Some("Reviewing pull requests".to_string());
            review_ctx.add_preset(Preset::new("Side by Side"));
            review_ctx.add_preset(Preset::new("Unified Diff"));
            workflow.add_context(review_ctx);

            s.workflows.push(workflow);

            // Create another workflow
            let mut design_workflow = Workflow::new("Design");
            design_workflow.description = Some("Design workflow".to_string());
            design_workflow.icon = Some("palette".to_string());

            let mut tokens_ctx = Context::new("Token Design");
            tokens_ctx.add_preset(Preset::new("Light Mode"));
            tokens_ctx.add_preset(Preset::new("Dark Mode"));
            design_workflow.add_context(tokens_ctx);

            s.workflows.push(design_workflow);
        });
    }

    // ============== Node Position Methods ==============

    /// Get all node positions.
    pub fn node_positions(&self) -> HashMap<String, (f64, f64)> {
        self.inner.get().node_positions.clone()
    }

    /// Get position for a specific node.
    pub fn get_node_position(&self, node_id: &str) -> Option<(f64, f64)> {
        self.inner.get().node_positions.get(node_id).copied()
    }

    /// Set position for a specific node.
    pub fn set_node_position(&self, node_id: &str, x: f64, y: f64) {
        self.inner.update(|s| {
            s.node_positions.insert(node_id.to_string(), (x, y));
        });
    }

    /// Set multiple node positions at once.
    pub fn set_node_positions(&self, positions: HashMap<String, (f64, f64)>) {
        self.inner.update(|s| {
            for (id, pos) in positions {
                s.node_positions.insert(id, pos);
            }
        });
    }

    /// Clear position for a specific node.
    pub fn clear_node_position(&self, node_id: &str) {
        self.inner.update(|s| {
            s.node_positions.remove(node_id);
        });
    }

    /// Check if any positions are saved.
    pub fn has_saved_positions(&self) -> bool {
        !self.inner.get().node_positions.is_empty()
    }
}

/// Hook to access the studio store.
pub fn use_studio_store() -> StudioStore {
    // Create or get the store from context
    let store = use_context::<StudioStore>();

    if let Some(s) = store {
        s
    } else {
        let new_store = StudioStore::new();
        provide_context(new_store.clone());
        new_store
    }
}
