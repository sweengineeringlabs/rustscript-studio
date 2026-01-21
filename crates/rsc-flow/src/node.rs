//! Node types and data structures.

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::position::{Dimensions, Position};

/// Unique node identifier.
pub type NodeId = String;

/// Node in the flow graph.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node<T = ()> {
    /// Unique identifier.
    pub id: NodeId,
    /// Node type for rendering.
    pub node_type: NodeType,
    /// Position on canvas.
    pub position: Position,
    /// Node dimensions (computed or explicit).
    #[serde(default)]
    pub dimensions: Option<Dimensions>,
    /// Custom data payload.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub data: Option<T>,
    /// Whether the node is selected.
    #[serde(default)]
    pub selected: bool,
    /// Whether the node is draggable.
    #[serde(default = "default_true")]
    pub draggable: bool,
    /// Whether the node can be connected.
    #[serde(default = "default_true")]
    pub connectable: bool,
    /// Parent node ID for grouping.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<NodeId>,
    /// Z-index for layering.
    #[serde(default)]
    pub z_index: i32,
    /// CSS class names.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub class_names: Vec<String>,
    /// Inline styles.
    #[serde(default, skip_serializing_if = "IndexMap::is_empty")]
    pub style: IndexMap<String, String>,
}

fn default_true() -> bool {
    true
}

impl<T> Node<T> {
    /// Create a new node with default settings.
    pub fn new(id: impl Into<String>, node_type: NodeType, position: Position) -> Self {
        Self {
            id: id.into(),
            node_type,
            position,
            dimensions: None,
            data: None,
            selected: false,
            draggable: true,
            connectable: true,
            parent_id: None,
            z_index: 0,
            class_names: Vec::new(),
            style: IndexMap::new(),
        }
    }

    /// Create a new node with auto-generated ID.
    pub fn auto(node_type: NodeType, position: Position) -> Self {
        Self::new(Uuid::new_v4().to_string(), node_type, position)
    }

    /// Set the node data.
    pub fn with_data(mut self, data: T) -> Self {
        self.data = Some(data);
        self
    }

    /// Set dimensions.
    pub fn with_dimensions(mut self, dimensions: Dimensions) -> Self {
        self.dimensions = Some(dimensions);
        self
    }

    /// Set parent node.
    pub fn with_parent(mut self, parent_id: impl Into<String>) -> Self {
        self.parent_id = Some(parent_id.into());
        self
    }

    /// Get the bounding rect.
    pub fn bounds(&self) -> Option<crate::position::Rect> {
        self.dimensions.map(|d| crate::position::Rect {
            position: self.position,
            dimensions: d,
        })
    }
}

impl<T: Default> Default for Node<T> {
    fn default() -> Self {
        Self::new(Uuid::new_v4().to_string(), NodeType::Default, Position::zero())
    }
}

/// Node type determines rendering behavior.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum NodeType {
    /// Default node rendering.
    Default,
    /// Input node (source).
    Input,
    /// Output node (sink).
    Output,
    /// Group node (contains children).
    Group,
    /// Custom node type.
    Custom(String),
}

impl Default for NodeType {
    fn default() -> Self {
        Self::Default
    }
}

/// Common node data structure.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct NodeData {
    /// Display label.
    #[serde(default)]
    pub label: String,
    /// Icon identifier.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    /// Description text.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Status indicator.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub status: Option<NodeStatus>,
    /// Additional metadata.
    #[serde(default, skip_serializing_if = "IndexMap::is_empty")]
    pub metadata: IndexMap<String, serde_json::Value>,
}

impl NodeData {
    pub fn new(label: impl Into<String>) -> Self {
        Self {
            label: label.into(),
            ..Default::default()
        }
    }

    pub fn with_icon(mut self, icon: impl Into<String>) -> Self {
        self.icon = Some(icon.into());
        self
    }

    pub fn with_description(mut self, description: impl Into<String>) -> Self {
        self.description = Some(description.into());
        self
    }
}

/// Node status for visual indicators.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum NodeStatus {
    Idle,
    Active,
    Success,
    Warning,
    Error,
    Disabled,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_node_creation() {
        let node: Node<NodeData> = Node::new("test", NodeType::Default, Position::new(100.0, 50.0))
            .with_data(NodeData::new("Test Node"));

        assert_eq!(node.id, "test");
        assert_eq!(node.data.as_ref().unwrap().label, "Test Node");
    }
}
