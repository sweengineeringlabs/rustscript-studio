//! Bottom panel component - resizable panel for output, problems, etc.

use rsc::prelude::*;

use crate::hooks::StudioStore;
use super::{Tabs, Tab, Icon};

/// Bottom panel component.
component BottomPanel(store: StudioStore) {
    let active_tab = signal("output".to_string());
    let height = signal(200);

    let tabs = vec![
        Tab {
            id: "output".to_string(),
            label: "Output".to_string(),
            icon: Some("terminal".to_string()),
        },
        Tab {
            id: "problems".to_string(),
            label: "Problems".to_string(),
            icon: Some("alert-circle".to_string()),
        },
        Tab {
            id: "css-preview".to_string(),
            label: "CSS Preview".to_string(),
            icon: Some("code".to_string()),
        },
    ];

    render {
        <div
            class="bottom-panel"
            style={styles::container(height.get())}
        >
            // Resize handle
            <div
                class="resize-handle"
                style={styles::resize_handle()}
                // TODO: Add drag handlers for resizing
            />

            // Tab bar
            <Tabs
                tabs={tabs}
                active={active_tab.clone()}
                on_change={Callback::new(|id| active_tab.set(id))}
            />

            // Content
            <div class="bottom-panel-content" style={styles::content()}>
                @match active_tab.get().as_str() {
                    "output" => {
                        <OutputPanel />
                    }
                    "problems" => {
                        <ProblemsPanel />
                    }
                    "css-preview" => {
                        <CssPreviewPanel store={store.clone()} />
                    }
                    _ => {
                        <div>Unknown tab</div>
                    }
                }
            </div>
        </div>
    }
}

/// Output panel for logs and messages.
component OutputPanel() {
    render {
        <div class="output-panel" style={styles::output_panel()}>
            <pre style={styles::output_text()}>
                "[info] RustScript Studio started\n"
                "[info] Design tokens loaded from design/theme.yaml\n"
                "[info] Ready"
            </pre>
        </div>
    }
}

/// Problems panel for validation errors.
component ProblemsPanel() {
    render {
        <div class="problems-panel" style={styles::problems_panel()}>
            <div class="no-problems" style={styles::no_problems()}>
                <Icon name={"check-circle".to_string()} />
                <span>No problems detected</span>
            </div>
        </div>
    }
}

/// CSS preview panel.
component CssPreviewPanel(store: StudioStore) {
    let css = store.get_generated_css();

    render {
        <div class="css-preview-panel" style={styles::css_preview()}>
            <pre style={styles::css_code()}>
                {css}
            </pre>
        </div>
    }
}

mod styles {
    pub fn container(height: i32) -> String {
        format!(
            r#"
                display: flex;
                flex-direction: column;
                height: {}px;
                background: var(--color-bg-secondary);
                border-top: 1px solid var(--color-border);
            "#,
            height
        )
    }

    pub fn resize_handle() -> &'static str {
        r#"
            height: 4px;
            cursor: ns-resize;
            background: transparent;
            transition: var(--transition-fast);
        "#
    }

    pub fn content() -> &'static str {
        r#"
            flex: 1;
            overflow: auto;
        "#
    }

    pub fn output_panel() -> &'static str {
        r#"
            height: 100%;
            padding: var(--spacing-sm) var(--spacing-md);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
        "#
    }

    pub fn output_text() -> &'static str {
        r#"
            margin: 0;
            color: var(--color-text-secondary);
            white-space: pre-wrap;
        "#
    }

    pub fn problems_panel() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
        "#
    }

    pub fn no_problems() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            color: var(--color-success);
        "#
    }

    pub fn css_preview() -> &'static str {
        r#"
            height: 100%;
            overflow: auto;
        "#
    }

    pub fn css_code() -> &'static str {
        r#"
            margin: 0;
            padding: var(--spacing-md);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
            color: var(--color-text-primary);
            white-space: pre-wrap;
        "#
    }
}
