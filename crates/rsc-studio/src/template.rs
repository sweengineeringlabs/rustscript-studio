//! Built-in templates for presets.

use crate::entity::{
    ActivityBarConfig, ActivityItem, BottomPanelConfig, LayoutConfig, LayoutVariant,
    PanelConfig, Position, Preset, SidebarConfig, TabConfig,
};

/// Template category.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TemplateCategory {
    Developer,
    Designer,
    Minimal,
    Custom,
}

/// Get all built-in templates.
pub fn get_templates() -> Vec<PresetTemplate> {
    vec![
        ide_template(),
        minimal_template(),
        focus_template(),
        review_template(),
    ]
}

/// Template definition.
#[derive(Debug, Clone)]
pub struct PresetTemplate {
    pub id: String,
    pub name: String,
    pub description: String,
    pub category: TemplateCategory,
    pub preset: Preset,
}

/// IDE-style template with full panels.
fn ide_template() -> PresetTemplate {
    let mut preset = Preset::new("IDE Layout");
    preset.layout = LayoutConfig {
        variant: LayoutVariant::Ide,
        activity_bar: Some(ActivityBarConfig {
            visible: true,
            position: Position::Left,
            items: vec![
                ActivityItem {
                    id: "explorer".to_string(),
                    label: "Explorer".to_string(),
                    icon: Some("folder".to_string()),
                    view: Some("file-explorer".to_string()),
                },
                ActivityItem {
                    id: "search".to_string(),
                    label: "Search".to_string(),
                    icon: Some("search".to_string()),
                    view: Some("search-panel".to_string()),
                },
                ActivityItem {
                    id: "git".to_string(),
                    label: "Source Control".to_string(),
                    icon: Some("git-branch".to_string()),
                    view: Some("git-panel".to_string()),
                },
            ],
        }),
        sidebar: Some(SidebarConfig {
            visible: true,
            position: Position::Left,
            width: 280,
            panels: vec![PanelConfig {
                id: "file-explorer".to_string(),
                label: "Explorer".to_string(),
                icon: Some("folder".to_string()),
                component: "FileExplorer".to_string(),
            }],
        }),
        bottom_panel: Some(BottomPanelConfig {
            visible: true,
            height: 200,
            tabs: vec![
                TabConfig {
                    id: "terminal".to_string(),
                    label: "Terminal".to_string(),
                    icon: Some("terminal".to_string()),
                    component: "Terminal".to_string(),
                },
                TabConfig {
                    id: "problems".to_string(),
                    label: "Problems".to_string(),
                    icon: Some("alert-circle".to_string()),
                    component: "Problems".to_string(),
                },
            ],
        }),
    };

    PresetTemplate {
        id: "ide".to_string(),
        name: "IDE Layout".to_string(),
        description: "Full IDE-style layout with activity bar, sidebar, and bottom panel".to_string(),
        category: TemplateCategory::Developer,
        preset,
    }
}

/// Minimal template with just the main content.
fn minimal_template() -> PresetTemplate {
    let mut preset = Preset::new("Minimal");
    preset.layout = LayoutConfig {
        variant: LayoutVariant::Minimal,
        activity_bar: None,
        sidebar: None,
        bottom_panel: None,
    };

    PresetTemplate {
        id: "minimal".to_string(),
        name: "Minimal".to_string(),
        description: "Clean layout with no panels - just the main content area".to_string(),
        category: TemplateCategory::Minimal,
        preset,
    }
}

/// Focus mode template.
fn focus_template() -> PresetTemplate {
    let mut preset = Preset::new("Focus Mode");
    preset.layout = LayoutConfig {
        variant: LayoutVariant::Custom,
        activity_bar: Some(ActivityBarConfig {
            visible: true,
            position: Position::Left,
            items: vec![ActivityItem {
                id: "focus".to_string(),
                label: "Focus".to_string(),
                icon: Some("eye".to_string()),
                view: None,
            }],
        }),
        sidebar: None,
        bottom_panel: None,
    };

    PresetTemplate {
        id: "focus".to_string(),
        name: "Focus Mode".to_string(),
        description: "Distraction-free mode with minimal UI".to_string(),
        category: TemplateCategory::Minimal,
        preset,
    }
}

/// Code review template.
fn review_template() -> PresetTemplate {
    let mut preset = Preset::new("Code Review");
    preset.layout = LayoutConfig {
        variant: LayoutVariant::Ide,
        activity_bar: Some(ActivityBarConfig {
            visible: true,
            position: Position::Left,
            items: vec![
                ActivityItem {
                    id: "changes".to_string(),
                    label: "Changes".to_string(),
                    icon: Some("git-pull-request".to_string()),
                    view: Some("changes-panel".to_string()),
                },
                ActivityItem {
                    id: "comments".to_string(),
                    label: "Comments".to_string(),
                    icon: Some("message-square".to_string()),
                    view: Some("comments-panel".to_string()),
                },
            ],
        }),
        sidebar: Some(SidebarConfig {
            visible: true,
            position: Position::Left,
            width: 320,
            panels: vec![PanelConfig {
                id: "changes-panel".to_string(),
                label: "Changed Files".to_string(),
                icon: Some("file-diff".to_string()),
                component: "ChangesList".to_string(),
            }],
        }),
        bottom_panel: Some(BottomPanelConfig {
            visible: true,
            height: 250,
            tabs: vec![TabConfig {
                id: "diff".to_string(),
                label: "Diff View".to_string(),
                icon: Some("diff".to_string()),
                component: "DiffViewer".to_string(),
            }],
        }),
    };

    PresetTemplate {
        id: "review".to_string(),
        name: "Code Review".to_string(),
        description: "Layout optimized for reviewing pull requests and changes".to_string(),
        category: TemplateCategory::Developer,
        preset,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_templates() {
        let templates = get_templates();
        assert!(!templates.is_empty());

        let ide = templates.iter().find(|t| t.id == "ide").unwrap();
        assert!(ide.preset.layout.activity_bar.is_some());
    }
}
