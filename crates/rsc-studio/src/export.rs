//! Export functionality for studio configurations.

use serde_yaml;

use crate::entity::Workflow;
use crate::store::StudioStore;

/// Export configuration to YAML.
pub fn export_to_yaml(store: &StudioStore) -> Result<String, serde_yaml::Error> {
    let workflows: Vec<&Workflow> = store.workflows.values().collect();
    serde_yaml::to_string(&workflows)
}

/// Import configuration from YAML.
pub fn import_from_yaml(yaml: &str) -> Result<Vec<Workflow>, serde_yaml::Error> {
    serde_yaml::from_str(yaml)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::entity::{Context, Preset};

    #[test]
    fn test_yaml_roundtrip() {
        let mut workflow = Workflow::new("Test");
        let mut context = Context::new("Default");
        context.add_preset(Preset::new("Minimal"));
        workflow.add_context(context);

        let mut store = StudioStore::new();
        store.add_workflow(workflow);

        let yaml = export_to_yaml(&store).unwrap();
        let imported = import_from_yaml(&yaml).unwrap();

        assert_eq!(imported.len(), 1);
        assert_eq!(imported[0].name, "Test");
    }
}
