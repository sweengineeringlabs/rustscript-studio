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

/// Tabs component.
component Tabs(tabs: Vec<Tab>, active: Signal<String>, on_change: Callback<String>) {
    render {
        <div class="tabs" style={styles::container()}>
            @for tab in tabs.iter() {
                <TabItem
                    tab={tab.clone()}
                    is_active={active.get() == tab.id}
                    on_click={on_change.clone()}
                />
            }
        </div>
    }
}

component TabItem(tab: Tab, is_active: bool, on_click: Callback<String>) {
    let tab_style = if is_active {
        styles::tab_active()
    } else {
        styles::tab()
    };

    render {
        <button
            class="tab"
            style={tab_style}
            on:click={|| on_click.call(tab.id.clone())}
        >
            @if let Some(ref icon) = tab.icon {
                <Icon name={icon.clone()} size={16} />
            }
            <span>{tab.label.clone()}</span>
        </button>
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
