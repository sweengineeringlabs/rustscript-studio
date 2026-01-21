//! Studio entities (Workflow, Context, Preset).
//! Ported from Flowize's entity model.

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Entity identifier.
pub type EntityId = String;

/// Workflow - represents a high-level feature area or user journey.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Workflow {
    /// Unique identifier.
    pub id: EntityId,
    /// Display name.
    pub name: String,
    /// Description.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Icon identifier.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    /// Child contexts.
    #[serde(default)]
    pub contexts: IndexMap<EntityId, Context>,
    /// Default context ID.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub default_context: Option<EntityId>,
    /// Metadata.
    #[serde(default, skip_serializing_if = "IndexMap::is_empty")]
    pub metadata: IndexMap<String, serde_json::Value>,
}

impl Workflow {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: name.into(),
            description: None,
            icon: None,
            contexts: IndexMap::new(),
            default_context: None,
            metadata: IndexMap::new(),
        }
    }

    pub fn with_id(mut self, id: impl Into<String>) -> Self {
        self.id = id.into();
        self
    }

    pub fn add_context(&mut self, context: Context) {
        if self.default_context.is_none() {
            self.default_context = Some(context.id.clone());
        }
        self.contexts.insert(context.id.clone(), context);
    }
}

/// Context - represents a sub-phase or mode within a workflow.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Context {
    /// Unique identifier.
    pub id: EntityId,
    /// Display name.
    pub name: String,
    /// Description.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Icon identifier.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    /// Child presets.
    #[serde(default)]
    pub presets: IndexMap<EntityId, Preset>,
    /// Default preset ID.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub default_preset: Option<EntityId>,
    /// Metadata.
    #[serde(default, skip_serializing_if = "IndexMap::is_empty")]
    pub metadata: IndexMap<String, serde_json::Value>,
}

impl Context {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: name.into(),
            description: None,
            icon: None,
            presets: IndexMap::new(),
            default_preset: None,
            metadata: IndexMap::new(),
        }
    }

    pub fn with_id(mut self, id: impl Into<String>) -> Self {
        self.id = id.into();
        self
    }

    pub fn add_preset(&mut self, preset: Preset) {
        if self.default_preset.is_none() {
            self.default_preset = Some(preset.id.clone());
        }
        self.presets.insert(preset.id.clone(), preset);
    }
}

/// Preset - represents a specific UI configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Preset {
    /// Unique identifier.
    pub id: EntityId,
    /// Display name.
    pub name: String,
    /// Description.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Icon identifier.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    /// Layout configuration.
    #[serde(default)]
    pub layout: LayoutConfig,
    /// Tool configurations.
    #[serde(default)]
    pub tools: IndexMap<String, ToolConfig>,
    /// Extends another preset.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub extends: Option<EntityId>,
    /// Metadata.
    #[serde(default, skip_serializing_if = "IndexMap::is_empty")]
    pub metadata: IndexMap<String, serde_json::Value>,
}

impl Preset {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name: name.into(),
            description: None,
            icon: None,
            layout: LayoutConfig::default(),
            tools: IndexMap::new(),
            extends: None,
            metadata: IndexMap::new(),
        }
    }

    pub fn with_id(mut self, id: impl Into<String>) -> Self {
        self.id = id.into();
        self
    }
}

/// Layout configuration for a preset.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct LayoutConfig {
    /// Layout variant.
    #[serde(default)]
    pub variant: LayoutVariant,
    /// Activity bar configuration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub activity_bar: Option<ActivityBarConfig>,
    /// Sidebar configuration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sidebar: Option<SidebarConfig>,
    /// Bottom panel configuration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub bottom_panel: Option<BottomPanelConfig>,
}

/// Layout variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum LayoutVariant {
    #[default]
    Ide,
    Tabs,
    Minimal,
    Custom,
}

/// Activity bar configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ActivityBarConfig {
    /// Whether to show the activity bar.
    #[serde(default = "default_true")]
    pub visible: bool,
    /// Position.
    #[serde(default)]
    pub position: Position,
    /// Activity items.
    #[serde(default)]
    pub items: Vec<ActivityItem>,
}

fn default_true() -> bool {
    true
}

/// Activity item.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActivityItem {
    /// Unique identifier.
    pub id: String,
    /// Display label.
    pub label: String,
    /// Icon identifier.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    /// Associated view/panel.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub view: Option<String>,
}

/// Sidebar configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SidebarConfig {
    /// Whether to show the sidebar.
    #[serde(default = "default_true")]
    pub visible: bool,
    /// Position.
    #[serde(default)]
    pub position: Position,
    /// Default width.
    #[serde(default = "default_sidebar_width")]
    pub width: u32,
    /// Panels in the sidebar.
    #[serde(default)]
    pub panels: Vec<PanelConfig>,
}

fn default_sidebar_width() -> u32 {
    280
}

/// Bottom panel configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct BottomPanelConfig {
    /// Whether to show the bottom panel.
    #[serde(default)]
    pub visible: bool,
    /// Default height.
    #[serde(default = "default_panel_height")]
    pub height: u32,
    /// Tabs in the panel.
    #[serde(default)]
    pub tabs: Vec<TabConfig>,
}

fn default_panel_height() -> u32 {
    200
}

/// Panel configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PanelConfig {
    pub id: String,
    pub label: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    #[serde(default)]
    pub component: String,
}

/// Tab configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TabConfig {
    pub id: String,
    pub label: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    #[serde(default)]
    pub component: String,
}

/// Tool configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ToolConfig {
    /// Whether the tool is enabled.
    #[serde(default = "default_true")]
    pub enabled: bool,
    /// Tool-specific settings.
    #[serde(default)]
    pub settings: IndexMap<String, serde_json::Value>,
}

/// Position enum.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum Position {
    #[default]
    Left,
    Right,
    Top,
    Bottom,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_workflow_creation() {
        let mut workflow = Workflow::new("Development");
        let context = Context::new("Coding");
        workflow.add_context(context);

        assert_eq!(workflow.name, "Development");
        assert_eq!(workflow.contexts.len(), 1);
    }
}
