//! Navigation flow designer.
//! Visual editor for designing workflow → context → preset hierarchies.

use rsc_flow::prelude::*;

use crate::entity::{Context, Preset, Workflow};

/// Navigation designer state.
#[derive(Debug, Clone)]
pub struct NavigationDesigner {
    /// Flow canvas for visualization.
    pub canvas: FlowCanvas<NavigationNodeData, ()>,
    /// Layout configuration.
    pub layout_config: LayoutConfig,
}

impl Default for NavigationDesigner {
    fn default() -> Self {
        Self::new()
    }
}

impl NavigationDesigner {
    pub fn new() -> Self {
        Self {
            canvas: FlowCanvas::new(),
            layout_config: LayoutConfig {
                direction: LayoutDirection::TopToBottom,
                node_sep: 80.0,
                rank_sep: 120.0,
                ..Default::default()
            },
        }
    }

    /// Load workflows into the canvas.
    pub fn load_workflows(&mut self, workflows: &[&Workflow]) {
        self.canvas = FlowCanvas::new();

        for workflow in workflows {
            self.add_workflow_node(workflow);
        }

        // Apply auto-layout
        self.canvas.auto_layout(self.layout_config.clone());
    }

    /// Add a workflow node and its children.
    fn add_workflow_node(&mut self, workflow: &Workflow) {
        let node = Node::new(
            &workflow.id,
            NodeType::Custom("workflow".to_string()),
            Position::zero(),
        )
        .with_data(NavigationNodeData {
            entity_type: EntityType::Workflow,
            entity_id: workflow.id.clone(),
            parent_id: None,
            label: workflow.name.clone(),
            icon: workflow.icon.clone(),
            description: workflow.description.clone(),
        });

        self.canvas.add_node(node);

        for context in workflow.contexts.values() {
            self.add_context_node(context, &workflow.id);
        }
    }

    /// Add a context node and its children.
    fn add_context_node(&mut self, context: &Context, parent_id: &str) {
        let node = Node::new(
            &context.id,
            NodeType::Custom("context".to_string()),
            Position::zero(),
        )
        .with_data(NavigationNodeData {
            entity_type: EntityType::Context,
            entity_id: context.id.clone(),
            parent_id: Some(parent_id.to_string()),
            label: context.name.clone(),
            icon: context.icon.clone(),
            description: context.description.clone(),
        });

        self.canvas.add_node(node);
        self.canvas.add_edge(Edge::auto(parent_id, &context.id));

        for preset in context.presets.values() {
            self.add_preset_node(preset, &context.id);
        }
    }

    /// Add a preset node.
    fn add_preset_node(&mut self, preset: &Preset, context_id: &str) {
        let node = Node::new(
            &preset.id,
            NodeType::Custom("preset".to_string()),
            Position::zero(),
        )
        .with_data(NavigationNodeData {
            entity_type: EntityType::Preset,
            entity_id: preset.id.clone(),
            parent_id: Some(context_id.to_string()),
            label: preset.name.clone(),
            icon: preset.icon.clone(),
            description: preset.description.clone(),
        });

        self.canvas.add_node(node);
        self.canvas.add_edge(Edge::auto(context_id, &preset.id));
    }

    /// Get the entity at a node.
    pub fn get_entity_at(&self, node_id: &str) -> Option<&NavigationNodeData> {
        self.canvas.get_node(node_id).and_then(|n| n.data.as_ref())
    }

    /// Re-layout the canvas.
    pub fn apply_layout(&mut self) {
        self.canvas.auto_layout(self.layout_config.clone());
    }

    /// Fit the viewport to show all nodes.
    pub fn fit_view(&mut self, canvas_size: Dimensions) {
        self.canvas.fit_view(50.0, canvas_size);
    }
}

/// Node data for navigation entities.
#[derive(Debug, Clone)]
pub struct NavigationNodeData {
    pub entity_type: EntityType,
    pub entity_id: String,
    pub parent_id: Option<String>,
    pub label: String,
    pub icon: Option<String>,
    pub description: Option<String>,
}

/// Entity type for node styling.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EntityType {
    Workflow,
    Context,
    Preset,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_load_workflows() {
        let mut workflow = Workflow::new("Dev").with_id("w1");
        let mut context = Context::new("Code").with_id("c1");
        context.add_preset(Preset::new("Default").with_id("p1"));
        workflow.add_context(context);

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        assert_eq!(designer.canvas.nodes.len(), 3); // workflow + context + preset
        assert_eq!(designer.canvas.edges.len(), 2); // w1->c1, c1->p1
    }
}
