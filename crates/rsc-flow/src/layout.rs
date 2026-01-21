//! Layout algorithms for automatic node positioning.

use serde::{Deserialize, Serialize};

use crate::edge::Edge;
use crate::node::{Node, NodeId};
use crate::position::{Dimensions, Position};

/// Layout direction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "kebab-case")]
pub enum LayoutDirection {
    /// Top to bottom.
    #[default]
    TopToBottom,
    /// Bottom to top.
    BottomToTop,
    /// Left to right.
    LeftToRight,
    /// Right to left.
    RightToLeft,
}

/// Layout configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutConfig {
    /// Layout direction.
    #[serde(default)]
    pub direction: LayoutDirection,
    /// Horizontal spacing between nodes.
    #[serde(default = "default_node_sep")]
    pub node_sep: f64,
    /// Vertical spacing between ranks.
    #[serde(default = "default_rank_sep")]
    pub rank_sep: f64,
    /// Margin around the graph.
    #[serde(default = "default_margin")]
    pub margin: f64,
    /// Default node dimensions.
    #[serde(default = "default_node_dimensions")]
    pub default_node_dimensions: Dimensions,
}

fn default_node_sep() -> f64 {
    50.0
}

fn default_rank_sep() -> f64 {
    100.0
}

fn default_margin() -> f64 {
    50.0
}

fn default_node_dimensions() -> Dimensions {
    Dimensions::new(150.0, 50.0)
}

impl Default for LayoutConfig {
    fn default() -> Self {
        Self {
            direction: LayoutDirection::default(),
            node_sep: default_node_sep(),
            rank_sep: default_rank_sep(),
            margin: default_margin(),
            default_node_dimensions: default_node_dimensions(),
        }
    }
}

/// Simple hierarchical layout algorithm.
/// For production, this would integrate with dagre or similar.
pub struct HierarchicalLayout {
    config: LayoutConfig,
}

impl HierarchicalLayout {
    pub fn new(config: LayoutConfig) -> Self {
        Self { config }
    }

    /// Apply layout to nodes.
    pub fn apply<T: Clone, E>(&self, nodes: &mut [Node<T>], edges: &[Edge<E>]) {
        if nodes.is_empty() {
            return;
        }

        // Build adjacency list
        let mut children: std::collections::HashMap<NodeId, Vec<NodeId>> =
            std::collections::HashMap::new();
        let mut has_parent: std::collections::HashSet<NodeId> = std::collections::HashSet::new();

        for edge in edges {
            children
                .entry(edge.source.clone())
                .or_default()
                .push(edge.target.clone());
            has_parent.insert(edge.target.clone());
        }

        // Find root nodes (no incoming edges)
        let roots: Vec<NodeId> = nodes
            .iter()
            .filter(|n| !has_parent.contains(&n.id))
            .map(|n| n.id.clone())
            .collect();

        // Assign ranks (BFS from roots)
        let mut ranks: std::collections::HashMap<NodeId, usize> = std::collections::HashMap::new();
        let mut queue: std::collections::VecDeque<(NodeId, usize)> =
            std::collections::VecDeque::new();

        for root in &roots {
            queue.push_back((root.clone(), 0));
        }

        // Handle disconnected nodes
        for node in nodes.iter() {
            if !roots.contains(&node.id) && !has_parent.contains(&node.id) {
                queue.push_back((node.id.clone(), 0));
            }
        }

        while let Some((node_id, rank)) = queue.pop_front() {
            if ranks.contains_key(&node_id) {
                continue;
            }
            ranks.insert(node_id.clone(), rank);

            if let Some(child_ids) = children.get(&node_id) {
                for child_id in child_ids {
                    if !ranks.contains_key(child_id) {
                        queue.push_back((child_id.clone(), rank + 1));
                    }
                }
            }
        }

        // Group nodes by rank
        let mut rank_groups: std::collections::BTreeMap<usize, Vec<NodeId>> =
            std::collections::BTreeMap::new();
        for (node_id, rank) in &ranks {
            rank_groups.entry(*rank).or_default().push(node_id.clone());
        }

        // Position nodes
        let node_width = self.config.default_node_dimensions.width;
        let node_height = self.config.default_node_dimensions.height;

        for (rank, node_ids) in rank_groups {
            let count = node_ids.len() as f64;
            let total_width = count * node_width + (count - 1.0) * self.config.node_sep;
            let start_x = -total_width / 2.0;

            for (i, node_id) in node_ids.iter().enumerate() {
                if let Some(node) = nodes.iter_mut().find(|n| &n.id == node_id) {
                    let (x, y) = match self.config.direction {
                        LayoutDirection::TopToBottom => (
                            start_x + i as f64 * (node_width + self.config.node_sep),
                            self.config.margin + rank as f64 * (node_height + self.config.rank_sep),
                        ),
                        LayoutDirection::BottomToTop => (
                            start_x + i as f64 * (node_width + self.config.node_sep),
                            -(self.config.margin + rank as f64 * (node_height + self.config.rank_sep)),
                        ),
                        LayoutDirection::LeftToRight => (
                            self.config.margin + rank as f64 * (node_width + self.config.rank_sep),
                            start_x + i as f64 * (node_height + self.config.node_sep),
                        ),
                        LayoutDirection::RightToLeft => (
                            -(self.config.margin + rank as f64 * (node_width + self.config.rank_sep)),
                            start_x + i as f64 * (node_height + self.config.node_sep),
                        ),
                    };
                    node.position = Position::new(x, y);
                    node.dimensions = Some(self.config.default_node_dimensions);
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::node::NodeType;

    #[test]
    fn test_hierarchical_layout() {
        let mut nodes: Vec<Node<()>> = vec![
            Node::new("1", NodeType::Default, Position::zero()),
            Node::new("2", NodeType::Default, Position::zero()),
            Node::new("3", NodeType::Default, Position::zero()),
        ];

        let edges: Vec<Edge<()>> = vec![
            Edge::new("e1", "1", "2"),
            Edge::new("e2", "1", "3"),
        ];

        let layout = HierarchicalLayout::new(LayoutConfig::default());
        layout.apply(&mut nodes, &edges);

        // Node 1 should be at rank 0, nodes 2 and 3 at rank 1
        let n1 = nodes.iter().find(|n| n.id == "1").unwrap();
        let n2 = nodes.iter().find(|n| n.id == "2").unwrap();

        assert!(n2.position.y > n1.position.y);
    }
}
