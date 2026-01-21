//! Edge types and data structures.

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::node::NodeId;

/// Unique edge identifier.
pub type EdgeId = String;

/// Edge connecting two nodes.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Edge<T = ()> {
    /// Unique identifier.
    pub id: EdgeId,
    /// Source node ID.
    pub source: NodeId,
    /// Target node ID.
    pub target: NodeId,
    /// Source handle (connection point).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub source_handle: Option<String>,
    /// Target handle (connection point).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub target_handle: Option<String>,
    /// Edge type for rendering.
    #[serde(default)]
    pub edge_type: EdgeType,
    /// Whether the edge is animated.
    #[serde(default)]
    pub animated: bool,
    /// Whether the edge is selected.
    #[serde(default)]
    pub selected: bool,
    /// Custom data payload.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub data: Option<T>,
    /// Label configuration.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub label: Option<EdgeLabel>,
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

impl<T> Edge<T> {
    /// Create a new edge.
    pub fn new(id: impl Into<String>, source: impl Into<String>, target: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            source: source.into(),
            target: target.into(),
            source_handle: None,
            target_handle: None,
            edge_type: EdgeType::default(),
            animated: false,
            selected: false,
            data: None,
            label: None,
            z_index: 0,
            class_names: Vec::new(),
            style: IndexMap::new(),
        }
    }

    /// Create a new edge with auto-generated ID.
    pub fn auto(source: impl Into<String>, target: impl Into<String>) -> Self {
        Self::new(Uuid::new_v4().to_string(), source, target)
    }

    /// Set the edge data.
    pub fn with_data(mut self, data: T) -> Self {
        self.data = Some(data);
        self
    }

    /// Set edge type.
    pub fn with_type(mut self, edge_type: EdgeType) -> Self {
        self.edge_type = edge_type;
        self
    }

    /// Set animated.
    pub fn animated(mut self) -> Self {
        self.animated = true;
        self
    }

    /// Set label.
    pub fn with_label(mut self, label: impl Into<String>) -> Self {
        self.label = Some(EdgeLabel::new(label));
        self
    }

    /// Set handles.
    pub fn with_handles(
        mut self,
        source_handle: impl Into<String>,
        target_handle: impl Into<String>,
    ) -> Self {
        self.source_handle = Some(source_handle.into());
        self.target_handle = Some(target_handle.into());
        self
    }
}

/// Edge rendering type.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub enum EdgeType {
    /// Straight line.
    #[default]
    Default,
    /// Straight line.
    Straight,
    /// Smooth bezier curve.
    Bezier,
    /// Step (right angles).
    Step,
    /// Smooth step.
    SmoothStep,
    /// Custom edge type.
    Custom(String),
}

/// Edge label configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EdgeLabel {
    /// Label text.
    pub text: String,
    /// Position along edge (0.0 to 1.0).
    #[serde(default = "default_label_position")]
    pub position: f64,
    /// X offset.
    #[serde(default)]
    pub offset_x: f64,
    /// Y offset.
    #[serde(default)]
    pub offset_y: f64,
    /// CSS class names.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub class_names: Vec<String>,
}

fn default_label_position() -> f64 {
    0.5
}

impl EdgeLabel {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            position: 0.5,
            offset_x: 0.0,
            offset_y: 0.0,
            class_names: Vec::new(),
        }
    }
}

/// Common edge data structure.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EdgeData {
    /// Display label.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    /// Edge weight/priority.
    #[serde(default)]
    pub weight: f64,
    /// Additional metadata.
    #[serde(default, skip_serializing_if = "IndexMap::is_empty")]
    pub metadata: IndexMap<String, serde_json::Value>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_edge_creation() {
        let edge: Edge<EdgeData> = Edge::new("e1", "node1", "node2")
            .with_type(EdgeType::Bezier)
            .animated();

        assert_eq!(edge.id, "e1");
        assert_eq!(edge.source, "node1");
        assert_eq!(edge.target, "node2");
        assert!(edge.animated);
    }
}
