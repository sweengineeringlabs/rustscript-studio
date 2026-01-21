//! Studio store hook - global state management.

use rsc::prelude::*;

use rsc_studio::entity::{Workflow, Context, Preset};
use rsc_studio::designer::css::DesignTokens;

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
    theme: Theme,
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
            inner: use_signal(StudioStoreInner::default),
        }
    }

    /// Get all workflows.
    pub fn workflows(&self) -> Vec<Workflow> {
        self.inner.get().workflows.clone()
    }

    /// Add a new workflow.
    pub fn add_workflow(&self, name: &str) {
        self.inner.update(|s| {
            s.workflows.push(Workflow::new(name));
        });
    }

    /// Remove a workflow by ID.
    pub fn remove_workflow(&self, id: &str) {
        self.inner.update(|s| {
            s.workflows.retain(|w| w.id != id);
        });
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
    pub fn add_context(&self, workflow_id: &str, name: &str) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                workflow.add_context(Context::new(name));
            }
        });
    }

    /// Add a preset to a context.
    pub fn add_preset(&self, workflow_id: &str, context_id: &str, name: &str) {
        self.inner.update(|s| {
            if let Some(workflow) = s.workflows.iter_mut().find(|w| w.id == workflow_id) {
                if let Some(context) = workflow.contexts.get_mut(context_id) {
                    context.add_preset(Preset::new(name));
                }
            }
        });
    }

    /// Get the design tokens.
    pub fn design_tokens(&self) -> Signal<DesignTokens> {
        let tokens = self.inner.get().design_tokens.clone();
        use_signal(|| tokens)
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
                    _ => {}
                }
            }
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
}

/// Hook to access the studio store.
pub fn use_studio_store() -> StudioStore {
    // Create or get the store from context
    let store = use_context::<StudioStore>();

    match store {
        Some(s) => s,
        None => {
            let new_store = StudioStore::new();
            provide_context(new_store.clone());
            new_store
        }
    }
}
