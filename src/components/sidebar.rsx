//! Sidebar component - contextual panel based on active view.

use rsc::prelude::*;

use crate::app::Route;
use crate::hooks::StudioStore;
use super::{Panel, Icon};

/// Sidebar component.
component Sidebar(route: Route, store: StudioStore) {
    let width = signal(280);

    render {
        <aside
            class="sidebar"
            style={styles::container(width.get())}
        >
            @match route {
                Route::Navigation => {
                    <NavigationSidebar store={store.clone()} />
                }
                Route::CssDesigner => {
                    <CssSidebar store={store.clone()} />
                }
                Route::Settings => {
                    <SettingsSidebar />
                }
            }
        </aside>
    }
}

/// Navigation designer sidebar.
component NavigationSidebar(store: StudioStore) {
    let workflows = store.workflows();

    render {
        <div class="navigation-sidebar">
            <Panel
                title="Workflows"
                icon={"folder".to_string()}
            >
                <div class="workflow-list" style={styles::list()}>
                    @for workflow in workflows {
                        <WorkflowItem
                            name={workflow.name.clone()}
                            context_count={workflow.contexts.len()}
                            on_select={Callback::new(|| {})}
                        />
                    }

                    // Add new workflow button
                    <button
                        class="add-workflow"
                        style={styles::add_button()}
                        on:click={|| store.add_workflow("New Workflow")}
                    >
                        <Icon name={"plus".to_string()} />
                        <span>Add Workflow</span>
                    </button>
                </div>
            </Panel>
        </div>
    }
}

component WorkflowItem(name: String, context_count: usize, on_select: Callback<()>) {
    render {
        <div
            class="workflow-item"
            style={styles::workflow_item()}
            on:click={|| on_select.call(())}
        >
            <Icon name={"git-branch".to_string()} />
            <div class="workflow-info">
                <span class="workflow-name" style={styles::workflow_name()}>
                    {name}
                </span>
                <span class="workflow-meta" style={styles::workflow_meta()}>
                    {format!("{} contexts", context_count)}
                </span>
            </div>
        </div>
    }
}

/// CSS designer sidebar.
component CssSidebar(store: StudioStore) {
    let categories = vec![
        ("Colors", "palette"),
        ("Spacing", "maximize"),
        ("Radius", "circle"),
        ("Shadows", "layers"),
        ("Typography", "type"),
    ];

    render {
        <div class="css-sidebar">
            <Panel
                title="Token Categories"
                icon={"sliders".to_string()}
            >
                <div class="category-list" style={styles::list()}>
                    @for (name, icon) in categories {
                        <CategoryItem
                            name={name.to_string()}
                            icon={icon.to_string()}
                            on_select={Callback::new(|| {})}
                        />
                    }
                </div>
            </Panel>
        </div>
    }
}

component CategoryItem(name: String, icon: String, on_select: Callback<()>) {
    render {
        <div
            class="category-item"
            style={styles::category_item()}
            on:click={|| on_select.call(())}
        >
            <Icon name={icon.clone()} />
            <span>{name}</span>
        </div>
    }
}

/// Settings sidebar.
component SettingsSidebar() {
    let sections = vec![
        ("General", "settings"),
        ("Appearance", "sun"),
        ("Keyboard Shortcuts", "keyboard"),
        ("Export", "download"),
    ];

    render {
        <div class="settings-sidebar">
            <Panel
                title="Settings"
                icon={"settings".to_string()}
            >
                <div class="settings-list" style={styles::list()}>
                    @for (name, icon) in sections {
                        <div class="settings-item" style={styles::settings_item()}>
                            <Icon name={icon.to_string()} />
                            <span>{name}</span>
                        </div>
                    }
                </div>
            </Panel>
        </div>
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
