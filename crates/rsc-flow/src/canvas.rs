//! Flow canvas state and configuration.

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};

use crate::edge::{Edge, EdgeId};
use crate::layout::{HierarchicalLayout, LayoutConfig};
use crate::node::{Node, NodeId};
use crate::position::{Dimensions, Position, Rect};
use crate::viewport::Viewport;

/// Flow canvas state.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowCanvas<N = (), E = ()> {
    /// All nodes.
    pub nodes: IndexMap<NodeId, Node<N>>,
    /// All edges.
    pub edges: IndexMap<EdgeId, Edge<E>>,
    /// Viewport state.
    #[serde(default)]
    pub viewport: Viewport,
    /// Selected node IDs.
    #[serde(default)]
    pub selected_nodes: Vec<NodeId>,
    /// Selected edge IDs.
    #[serde(default)]
    pub selected_edges: Vec<EdgeId>,
    /// Canvas configuration.
    #[serde(default)]
    pub config: FlowCanvasConfig,
}

impl<N, E> Default for FlowCanvas<N, E> {
    fn default() -> Self {
        Self::new()
    }
}

impl<N, E> FlowCanvas<N, E> {
    /// Create a new empty canvas.
    pub fn new() -> Self {
        Self {
            nodes: IndexMap::new(),
            edges: IndexMap::new(),
            viewport: Viewport::default(),
            selected_nodes: Vec::new(),
            selected_edges: Vec::new(),
            config: FlowCanvasConfig::default(),
        }
    }

    /// Create from nodes and edges.
    pub fn from_elements(nodes: Vec<Node<N>>, edges: Vec<Edge<E>>) -> Self {
        let mut canvas = Self::new();
        for node in nodes {
            canvas.nodes.insert(node.id.clone(), node);
        }
        for edge in edges {
            canvas.edges.insert(edge.id.clone(), edge);
        }
        canvas
    }

    /// Add a node.
    pub fn add_node(&mut self, node: Node<N>) {
        self.nodes.insert(node.id.clone(), node);
    }

    /// Remove a node and its connected edges.
    pub fn remove_node(&mut self, id: &str) -> Option<Node<N>> {
        // Remove connected edges
        self.edges
            .retain(|_, edge| edge.source != id && edge.target != id);
        // Remove from selection
        self.selected_nodes.retain(|n| n != id);
        // Remove node
        self.nodes.shift_remove(id)
    }

    /// Add an edge.
    pub fn add_edge(&mut self, edge: Edge<E>) {
        self.edges.insert(edge.id.clone(), edge);
    }

    /// Remove an edge.
    pub fn remove_edge(&mut self, id: &str) -> Option<Edge<E>> {
        self.selected_edges.retain(|e| e != id);
        self.edges.shift_remove(id)
    }

    /// Get a node by ID.
    pub fn get_node(&self, id: &str) -> Option<&Node<N>> {
        self.nodes.get(id)
    }

    /// Get a mutable node by ID.
    pub fn get_node_mut(&mut self, id: &str) -> Option<&mut Node<N>> {
        self.nodes.get_mut(id)
    }

    /// Get an edge by ID.
    pub fn get_edge(&self, id: &str) -> Option<&Edge<E>> {
        self.edges.get(id)
    }

    /// Get edges connected to a node.
    pub fn get_connected_edges(&self, node_id: &str) -> Vec<&Edge<E>> {
        self.edges
            .values()
            .filter(|e| e.source == node_id || e.target == node_id)
            .collect()
    }

    /// Get incoming edges to a node.
    pub fn get_incoming_edges(&self, node_id: &str) -> Vec<&Edge<E>> {
        self.edges
            .values()
            .filter(|e| e.target == node_id)
            .collect()
    }

    /// Get outgoing edges from a node.
    pub fn get_outgoing_edges(&self, node_id: &str) -> Vec<&Edge<E>> {
        self.edges
            .values()
            .filter(|e| e.source == node_id)
            .collect()
    }

    /// Select a node.
    pub fn select_node(&mut self, id: &str, multi: bool) {
        if !multi {
            self.clear_selection();
        }
        if let Some(node) = self.nodes.get_mut(id) {
            node.selected = true;
            if !self.selected_nodes.contains(&id.to_string()) {
                self.selected_nodes.push(id.to_string());
            }
        }
    }

    /// Clear all selection.
    pub fn clear_selection(&mut self) {
        for node in self.nodes.values_mut() {
            node.selected = false;
        }
        for edge in self.edges.values_mut() {
            edge.selected = false;
        }
        self.selected_nodes.clear();
        self.selected_edges.clear();
    }

    /// Get bounding box of all nodes.
    pub fn get_bounds(&self) -> Option<Rect> {
        if self.nodes.is_empty() {
            return None;
        }

        let mut min_x = f64::MAX;
        let mut min_y = f64::MAX;
        let mut max_x = f64::MIN;
        let mut max_y = f64::MIN;

        for node in self.nodes.values() {
            let dims = node.dimensions.unwrap_or(Dimensions::new(150.0, 50.0));
            min_x = min_x.min(node.position.x);
            min_y = min_y.min(node.position.y);
            max_x = max_x.max(node.position.x + dims.width);
            max_y = max_y.max(node.position.y + dims.height);
        }

        Some(Rect::new(min_x, min_y, max_x - min_x, max_y - min_y))
    }

    /// Fit viewport to content.
    pub fn fit_view(&mut self, padding: f64, canvas_size: Dimensions) {
        if let Some(bounds) = self.get_bounds() {
            self.viewport.fit_to_bounds(&bounds, padding, &canvas_size);
        }
    }
}

impl<N: Clone, E: Clone> FlowCanvas<N, E> {
    /// Apply automatic layout.
    pub fn auto_layout(&mut self, config: LayoutConfig) {
        let mut nodes: Vec<Node<N>> = self.nodes.values().cloned().collect();
        let edges: Vec<Edge<E>> = self.edges.values().cloned().collect();

        let layout = HierarchicalLayout::new(config);
        layout.apply(&mut nodes, &edges);

        // Update node positions
        for node in nodes {
            if let Some(existing) = self.nodes.get_mut(&node.id) {
                existing.position = node.position;
                existing.dimensions = node.dimensions;
            }
        }
    }
}

/// Canvas configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowCanvasConfig {
    /// Show grid.
    #[serde(default = "default_true")]
    pub show_grid: bool,
    /// Grid size.
    #[serde(default = "default_grid_size")]
    pub grid_size: f64,
    /// Snap to grid.
    #[serde(default)]
    pub snap_to_grid: bool,
    /// Show minimap.
    #[serde(default)]
    pub show_minimap: bool,
    /// Show controls.
    #[serde(default = "default_true")]
    pub show_controls: bool,
    /// Connection line type.
    #[serde(default)]
    pub connection_line_type: crate::edge::EdgeType,
    /// Allow node deletion.
    #[serde(default = "default_true")]
    pub deletable: bool,
    /// Allow edge creation by dragging.
    #[serde(default = "default_true")]
    pub edges_updatable: bool,
}

fn default_true() -> bool {
    true
}

fn default_grid_size() -> f64 {
    20.0
}

impl Default for FlowCanvasConfig {
    fn default() -> Self {
        Self {
            show_grid: true,
            grid_size: default_grid_size(),
            snap_to_grid: false,
            show_minimap: false,
            show_controls: true,
            connection_line_type: crate::edge::EdgeType::default(),
            deletable: true,
            edges_updatable: true,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::node::NodeType;

    #[test]
    fn test_canvas_operations() {
        let mut canvas: FlowCanvas<(), ()> = FlowCanvas::new();

        canvas.add_node(Node::new("1", NodeType::Default, Position::new(0.0, 0.0)));
        canvas.add_node(Node::new("2", NodeType::Default, Position::new(100.0, 100.0)));
        canvas.add_edge(Edge::new("e1", "1", "2"));

        assert_eq!(canvas.nodes.len(), 2);
        assert_eq!(canvas.edges.len(), 1);

        let connected = canvas.get_connected_edges("1");
        assert_eq!(connected.len(), 1);

        canvas.remove_node("1");
        assert_eq!(canvas.nodes.len(), 1);
        assert_eq!(canvas.edges.len(), 0); // Edge removed too
    }
}
