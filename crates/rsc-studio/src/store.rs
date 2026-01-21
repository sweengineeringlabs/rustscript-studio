//! Studio state management (Zustand-like store).

use indexmap::IndexMap;

use crate::entity::{Context, EntityId, Preset, Workflow};

/// Studio store state.
#[derive(Debug, Clone, Default)]
pub struct StudioStore {
    /// All workflows.
    pub workflows: IndexMap<EntityId, Workflow>,
    /// Currently selected workflow.
    pub selected_workflow: Option<EntityId>,
    /// Currently selected context.
    pub selected_context: Option<EntityId>,
    /// Currently selected preset.
    pub selected_preset: Option<EntityId>,
    /// Draft entities (unsaved changes).
    pub drafts: Drafts,
    /// UI state.
    pub ui: UiState,
    /// Validation errors.
    pub errors: Vec<ValidationError>,
}

impl StudioStore {
    pub fn new() -> Self {
        Self::default()
    }

    // === Workflow operations ===

    pub fn add_workflow(&mut self, workflow: Workflow) {
        self.workflows.insert(workflow.id.clone(), workflow);
    }

    pub fn remove_workflow(&mut self, id: &str) -> Option<Workflow> {
        if self.selected_workflow.as_deref() == Some(id) {
            self.selected_workflow = None;
            self.selected_context = None;
            self.selected_preset = None;
        }
        self.workflows.shift_remove(id)
    }

    pub fn get_workflow(&self, id: &str) -> Option<&Workflow> {
        self.workflows.get(id)
    }

    pub fn get_workflow_mut(&mut self, id: &str) -> Option<&mut Workflow> {
        self.workflows.get_mut(id)
    }

    // === Selection ===

    pub fn select_workflow(&mut self, id: &str) {
        if self.workflows.contains_key(id) {
            self.selected_workflow = Some(id.to_string());
            self.selected_context = None;
            self.selected_preset = None;
        }
    }

    pub fn select_context(&mut self, workflow_id: &str, context_id: &str) {
        if let Some(workflow) = self.workflows.get(workflow_id) {
            if workflow.contexts.contains_key(context_id) {
                self.selected_workflow = Some(workflow_id.to_string());
                self.selected_context = Some(context_id.to_string());
                self.selected_preset = None;
            }
        }
    }

    pub fn select_preset(&mut self, workflow_id: &str, context_id: &str, preset_id: &str) {
        if let Some(workflow) = self.workflows.get(workflow_id) {
            if let Some(context) = workflow.contexts.get(context_id) {
                if context.presets.contains_key(preset_id) {
                    self.selected_workflow = Some(workflow_id.to_string());
                    self.selected_context = Some(context_id.to_string());
                    self.selected_preset = Some(preset_id.to_string());
                }
            }
        }
    }

    // === Current selection getters ===

    pub fn current_workflow(&self) -> Option<&Workflow> {
        self.selected_workflow.as_ref().and_then(|id| self.workflows.get(id))
    }

    pub fn current_context(&self) -> Option<&Context> {
        let workflow = self.current_workflow()?;
        self.selected_context.as_ref().and_then(|id| workflow.contexts.get(id))
    }

    pub fn current_preset(&self) -> Option<&Preset> {
        let context = self.current_context()?;
        self.selected_preset.as_ref().and_then(|id| context.presets.get(id))
    }

    // === Draft operations ===

    pub fn set_draft_workflow(&mut self, workflow: Workflow) {
        self.drafts.workflow = Some(workflow);
        self.drafts.dirty = true;
    }

    pub fn set_draft_context(&mut self, context: Context) {
        self.drafts.context = Some(context);
        self.drafts.dirty = true;
    }

    pub fn set_draft_preset(&mut self, preset: Preset) {
        self.drafts.preset = Some(preset);
        self.drafts.dirty = true;
    }

    pub fn clear_drafts(&mut self) {
        self.drafts = Drafts::default();
    }

    pub fn has_unsaved_changes(&self) -> bool {
        self.drafts.dirty
    }

    // === Validation ===

    pub fn validate(&mut self) {
        self.errors.clear();
        // Add validation logic here
    }

    pub fn has_errors(&self) -> bool {
        !self.errors.is_empty()
    }
}

/// Draft entities for editing.
#[derive(Debug, Clone, Default)]
pub struct Drafts {
    pub workflow: Option<Workflow>,
    pub context: Option<Context>,
    pub preset: Option<Preset>,
    pub dirty: bool,
}

/// UI state.
#[derive(Debug, Clone, Default)]
pub struct UiState {
    /// Currently active designer tab.
    pub active_designer: Designer,
    /// Sidebar visibility.
    pub sidebar_visible: bool,
    /// Bottom panel visibility.
    pub bottom_panel_visible: bool,
    /// Canvas state.
    pub canvas: CanvasState,
}

/// Active designer.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Designer {
    #[default]
    Navigation,
    Css,
    Component,
}

/// Canvas UI state.
#[derive(Debug, Clone, Default)]
pub struct CanvasState {
    pub auto_layout_enabled: bool,
    pub show_minimap: bool,
    pub zoom: f64,
}

impl Default for UiState {
    fn default() -> Self {
        Self {
            active_designer: Designer::default(),
            sidebar_visible: true,
            bottom_panel_visible: false,
            canvas: CanvasState {
                auto_layout_enabled: true,
                show_minimap: false,
                zoom: 1.0,
            },
        }
    }
}

/// Validation error.
#[derive(Debug, Clone)]
pub struct ValidationError {
    pub entity_id: EntityId,
    pub field: String,
    pub message: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_store_workflow_operations() {
        let mut store = StudioStore::new();

        let workflow = Workflow::new("Test").with_id("w1");
        store.add_workflow(workflow);

        assert!(store.get_workflow("w1").is_some());

        store.select_workflow("w1");
        assert_eq!(store.selected_workflow, Some("w1".to_string()));

        store.remove_workflow("w1");
        assert!(store.get_workflow("w1").is_none());
        assert!(store.selected_workflow.is_none());
    }
}
