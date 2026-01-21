//! Sidebar component - contextual panel based on active view.

use rsc::prelude::*;

use crate::app::Route;
use crate::hooks::StudioStore;
use super::{Panel, Icon};

/// Sidebar component props.
#[derive(Props)]
pub struct SidebarProps {
    pub route: Route,
    pub store: StudioStore,
}

/// Sidebar component.
#[component]
pub fn Sidebar(props: SidebarProps) -> Element {
    let width = use_signal(|| 280);

    rsx! {
        aside(
            class="sidebar",
            style=styles::container(width.get()),
        ) {
            match props.route {
                Route::Navigation => {
                    NavigationSidebar { store: props.store.clone() }
                }
                Route::CssDesigner => {
                    CssSidebar { store: props.store.clone() }
                }
                Route::Settings => {
                    SettingsSidebar {}
                }
            }
        }
    }
}

/// Navigation designer sidebar.
#[derive(Props)]
struct NavigationSidebarProps {
    store: StudioStore,
}

#[component]
fn NavigationSidebar(props: NavigationSidebarProps) -> Element {
    let workflows = props.store.workflows();

    rsx! {
        div(class="navigation-sidebar") {
            Panel {
                title: "Workflows",
                icon: Some("folder".to_string()),
            } {
                div(class="workflow-list", style=styles::list()) {
                    for workflow in workflows {
                        WorkflowItem {
                            name: workflow.name.clone(),
                            context_count: workflow.contexts.len(),
                            on_select: move |_| {},
                        }
                    }

                    // Add new workflow button
                    button(
                        class="add-workflow",
                        style=styles::add_button(),
                        on:click=move |_| props.store.add_workflow("New Workflow"),
                    ) {
                        Icon { name: "plus".to_string() }
                        span { "Add Workflow" }
                    }
                }
            }
        }
    }
}

#[derive(Props)]
struct WorkflowItemProps {
    name: String,
    context_count: usize,
    #[prop(into)]
    on_select: Callback<()>,
}

#[component]
fn WorkflowItem(props: WorkflowItemProps) -> Element {
    rsx! {
        div(
            class="workflow-item",
            style=styles::workflow_item(),
            on:click=move |_| props.on_select.call(()),
        ) {
            Icon { name: "git-branch".to_string() }
            div(class="workflow-info") {
                span(class="workflow-name", style=styles::workflow_name()) {
                    { props.name }
                }
                span(class="workflow-meta", style=styles::workflow_meta()) {
                    { format!("{} contexts", props.context_count) }
                }
            }
        }
    }
}

/// CSS designer sidebar.
#[derive(Props)]
struct CssSidebarProps {
    store: StudioStore,
}

#[component]
fn CssSidebar(props: CssSidebarProps) -> Element {
    let categories = vec![
        ("Colors", "palette"),
        ("Spacing", "maximize"),
        ("Radius", "circle"),
        ("Shadows", "layers"),
        ("Typography", "type"),
    ];

    rsx! {
        div(class="css-sidebar") {
            Panel {
                title: "Token Categories",
                icon: Some("sliders".to_string()),
            } {
                div(class="category-list", style=styles::list()) {
                    for (name, icon) in categories {
                        CategoryItem {
                            name: name.to_string(),
                            icon: icon.to_string(),
                            on_select: move |_| {},
                        }
                    }
                }
            }
        }
    }
}

#[derive(Props)]
struct CategoryItemProps {
    name: String,
    icon: String,
    #[prop(into)]
    on_select: Callback<()>,
}

#[component]
fn CategoryItem(props: CategoryItemProps) -> Element {
    rsx! {
        div(
            class="category-item",
            style=styles::category_item(),
            on:click=move |_| props.on_select.call(()),
        ) {
            Icon { name: props.icon.clone() }
            span { { props.name } }
        }
    }
}

/// Settings sidebar.
#[component]
fn SettingsSidebar() -> Element {
    let sections = vec![
        ("General", "settings"),
        ("Appearance", "sun"),
        ("Keyboard Shortcuts", "keyboard"),
        ("Export", "download"),
    ];

    rsx! {
        div(class="settings-sidebar") {
            Panel {
                title: "Settings",
                icon: Some("settings".to_string()),
            } {
                div(class="settings-list", style=styles::list()) {
                    for (name, icon) in sections {
                        div(class="settings-item", style=styles::settings_item()) {
                            Icon { name: icon.to_string() }
                            span { { name } }
                        }
                    }
                }
            }
        }
    }
}

mod styles {
    pub fn container(width: i32) -> String {
        format!(
            r#"
                display: flex;
                flex-direction: column;
                width: {}px;
                background: var(--color-bg-secondary);
                border-right: 1px solid var(--color-border);
                overflow-y: auto;
            "#,
            width
        )
    }

    pub fn list() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn workflow_item() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            border-radius: var(--radius-md);
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn workflow_name() -> &'static str {
        r#"
            font-weight: var(--font-weight-medium);
            color: var(--color-text-primary);
        "#
    }

    pub fn workflow_meta() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn category_item() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            border-radius: var(--radius-md);
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn settings_item() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            border-radius: var(--radius-md);
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn add_button() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            width: 100%;
            background: transparent;
            border: 1px dashed var(--color-border);
            border-radius: var(--radius-md);
            color: var(--color-text-secondary);
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }
}
