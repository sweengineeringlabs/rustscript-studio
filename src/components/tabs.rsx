//! Tabs component for tab-based navigation.

use rsc::prelude::*;

use super::Icon;

/// Tab configuration.
#[derive(Debug, Clone)]
pub struct Tab {
    pub id: String,
    pub label: String,
    pub icon: Option<String>,
}

/// Tabs component props.
#[derive(Props)]
pub struct TabsProps {
    pub tabs: Vec<Tab>,
    pub active: Signal<String>,
    #[prop(into)]
    pub on_change: Callback<String>,
}

/// Tabs component.
#[component]
pub fn Tabs(props: TabsProps) -> Element {
    rsx! {
        div(class="tabs", style=styles::container()) {
            for tab in props.tabs {
                TabItem {
                    tab: tab.clone(),
                    is_active: props.active.get() == tab.id,
                    on_click: props.on_change.clone(),
                }
            }
        }
    }
}

#[derive(Props)]
struct TabItemProps {
    tab: Tab,
    is_active: bool,
    #[prop(into)]
    on_click: Callback<String>,
}

#[component]
fn TabItem(props: TabItemProps) -> Element {
    let style = if props.is_active {
        styles::tab_active()
    } else {
        styles::tab()
    };

    rsx! {
        button(
            class="tab",
            style=style,
            on:click=move |_| props.on_click.call(props.tab.id.clone()),
        ) {
            if let Some(ref icon) = props.tab.icon {
                Icon { name: icon.clone(), size: 16 }
            }
            span { { props.tab.label.clone() } }
        }
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
            padding: 0 var(--spacing-sm);
        "#
    }

    pub fn tab() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-sm) var(--spacing-md);
            background: transparent;
            border: none;
            border-bottom: 2px solid transparent;
            color: var(--color-text-secondary);
            font-size: var(--font-size-sm);
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn tab_active() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-sm) var(--spacing-md);
            background: transparent;
            border: none;
            border-bottom: 2px solid var(--color-primary);
            color: var(--color-primary);
            font-size: var(--font-size-sm);
            cursor: pointer;
        "#
    }
}
