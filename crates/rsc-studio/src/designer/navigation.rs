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

    #[test]
    fn test_designer_default_state() {
        let designer = NavigationDesigner::new();

        // Canvas should be empty initially
        assert!(designer.canvas.nodes.is_empty());
        assert!(designer.canvas.edges.is_empty());

        // Layout config should have defaults
        assert_eq!(designer.layout_config.direction, LayoutDirection::TopToBottom);
        assert!(designer.layout_config.node_sep > 0.0);
        assert!(designer.layout_config.rank_sep > 0.0);
    }

    #[test]
    fn test_multiple_workflows() {
        let mut workflow1 = Workflow::new("Flow 1").with_id("w1");
        workflow1.add_context(Context::new("Ctx 1").with_id("c1"));

        let mut workflow2 = Workflow::new("Flow 2").with_id("w2");
        workflow2.add_context(Context::new("Ctx 2").with_id("c2"));

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow1, &workflow2]);

        // Should have 4 nodes (2 workflows + 2 contexts)
        assert_eq!(designer.canvas.nodes.len(), 4);
        // Should have 2 edges (w1->c1, w2->c2)
        assert_eq!(designer.canvas.edges.len(), 2);
    }

    #[test]
    fn test_entity_type_node_data() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        let mut context = Context::new("Code").with_id("c1");
        context.add_preset(Preset::new("Default").with_id("p1"));
        workflow.add_context(context);

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // Check workflow node data
        let workflow_data = designer.get_entity_at("w1");
        assert!(workflow_data.is_some());
        assert_eq!(workflow_data.unwrap().entity_type, EntityType::Workflow);
        assert_eq!(workflow_data.unwrap().label, "Main");

        // Check context node data
        let context_data = designer.get_entity_at("c1");
        assert!(context_data.is_some());
        assert_eq!(context_data.unwrap().entity_type, EntityType::Context);
        assert_eq!(context_data.unwrap().label, "Code");

        // Check preset node data
        let preset_data = designer.get_entity_at("p1");
        assert!(preset_data.is_some());
        assert_eq!(preset_data.unwrap().entity_type, EntityType::Preset);
        assert_eq!(preset_data.unwrap().label, "Default");
    }

    #[test]
    fn test_parent_child_relationships() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        let mut context = Context::new("Code").with_id("c1");
        context.add_preset(Preset::new("Default").with_id("p1"));
        workflow.add_context(context);

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // Context should have workflow as parent
        let context_data = designer.get_entity_at("c1").unwrap();
        assert_eq!(context_data.parent_id, Some("w1".to_string()));

        // Preset should have context as parent
        let preset_data = designer.get_entity_at("p1").unwrap();
        assert_eq!(preset_data.parent_id, Some("c1".to_string()));

        // Workflow should have no parent
        let workflow_data = designer.get_entity_at("w1").unwrap();
        assert!(workflow_data.parent_id.is_none());
    }

    #[test]
    fn test_reload_workflows() {
        let mut designer = NavigationDesigner::new();

        // Load first workflow
        let workflow1 = Workflow::new("Flow 1").with_id("w1");
        designer.load_workflows(&[&workflow1]);
        assert_eq!(designer.canvas.nodes.len(), 1);

        // Load new workflows (should replace old)
        let workflow2 = Workflow::new("Flow 2").with_id("w2");
        designer.load_workflows(&[&workflow2]);
        assert_eq!(designer.canvas.nodes.len(), 1);
        assert!(designer.canvas.nodes.contains_key("w2"));
        assert!(!designer.canvas.nodes.contains_key("w1"));
    }

    #[test]
    fn test_node_icons_and_descriptions() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        workflow.icon = Some("home".to_string());
        workflow.description = Some("Main workflow".to_string());

        let mut context = Context::new("Code").with_id("c1");
        context.icon = Some("code".to_string());
        context.description = Some("Coding context".to_string());
        workflow.add_context(context);

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // Check workflow node has icon/description
        let workflow_data = designer.get_entity_at("w1").unwrap();
        assert_eq!(workflow_data.icon, Some("home".to_string()));
        assert_eq!(workflow_data.description, Some("Main workflow".to_string()));

        // Check context node has icon/description
        let context_data = designer.get_entity_at("c1").unwrap();
        assert_eq!(context_data.icon, Some("code".to_string()));
        assert_eq!(context_data.description, Some("Coding context".to_string()));
    }

    #[test]
    fn test_nonexistent_entity() {
        let designer = NavigationDesigner::new();

        let result = designer.get_entity_at("nonexistent");
        assert!(result.is_none());
    }

    #[test]
    fn test_deep_hierarchy() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        let mut context = Context::new("Code").with_id("c1");

        // Add multiple presets
        context.add_preset(Preset::new("Default").with_id("p1"));
        context.add_preset(Preset::new("Dark").with_id("p2"));
        context.add_preset(Preset::new("Light").with_id("p3"));
        workflow.add_context(context);

        // Add another context with presets
        let mut context2 = Context::new("Review").with_id("c2");
        context2.add_preset(Preset::new("Review Default").with_id("p4"));
        workflow.add_context(context2);

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // 1 workflow + 2 contexts + 4 presets = 7 nodes
        assert_eq!(designer.canvas.nodes.len(), 7);
        // w1->c1, c1->p1, c1->p2, c1->p3, w1->c2, c2->p4 = 6 edges
        assert_eq!(designer.canvas.edges.len(), 6);
    }

    #[test]
    fn test_apply_layout() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        workflow.add_context(Context::new("Code").with_id("c1"));

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // Nodes should have positions after load (auto-layout is called)
        let workflow_node = designer.canvas.get_node("w1").unwrap();
        let context_node = designer.canvas.get_node("c1").unwrap();

        // Positions should be set (not both zero)
        let workflow_pos = workflow_node.position;
        let context_pos = context_node.position;

        // At least one position should be non-zero after layout
        assert!(
            workflow_pos.x != 0.0 || workflow_pos.y != 0.0 ||
            context_pos.x != 0.0 || context_pos.y != 0.0,
            "Layout should set node positions"
        );
    }

    #[test]
    fn test_canvas_node_selection() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        workflow.add_context(Context::new("Code").with_id("c1"));

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // Initially no selection
        assert!(designer.canvas.selected_nodes.is_empty());

        // Select a node
        designer.canvas.select_node("w1", false);
        assert!(designer.canvas.selected_nodes.contains(&"w1".to_string()));

        // Multi-select
        designer.canvas.select_node("c1", true);
        assert!(designer.canvas.selected_nodes.contains(&"w1".to_string()));
        assert!(designer.canvas.selected_nodes.contains(&"c1".to_string()));

        // Clear selection
        designer.canvas.clear_selection();
        assert!(designer.canvas.selected_nodes.is_empty());
    }

    #[test]
    fn test_canvas_edges_between_nodes() {
        let mut workflow = Workflow::new("Main").with_id("w1");
        workflow.add_context(Context::new("Code").with_id("c1"));

        let mut designer = NavigationDesigner::new();
        designer.load_workflows(&[&workflow]);

        // Get edges for workflow
        let workflow_edges = designer.canvas.get_outgoing_edges("w1");
        assert_eq!(workflow_edges.len(), 1);
        assert_eq!(workflow_edges[0].target, "c1");

        // Get incoming edges for context
        let context_edges = designer.canvas.get_incoming_edges("c1");
        assert_eq!(context_edges.len(), 1);
        assert_eq!(context_edges[0].source, "w1");
    }
}
