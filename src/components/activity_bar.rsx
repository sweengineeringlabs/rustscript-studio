//! Activity bar component - vertical icon bar for view switching.

use rsc::prelude::*;

use crate::app::Route;
use super::Icon;

/// Activity bar item configuration.
#[derive(Debug, Clone)]
pub struct ActivityItem {
    pub id: String,
    pub icon: String,
    pub label: String,
    pub route: Route,
}

/// Activity bar component.
#[component]
pub fn ActivityBar(active_view: Signal<Route>, on_change: Callback<Route>) -> Element {
    let items = vec![
        ActivityItem {
            id: "navigation".to_string(),
            icon: "git-branch".to_string(),
            label: "Navigation Designer".to_string(),
            route: Route::Navigation,
        },
        ActivityItem {
            id: "css".to_string(),
            icon: "palette".to_string(),
            label: "CSS Designer".to_string(),
            route: Route::CssDesigner,
        },
        ActivityItem {
            id: "settings".to_string(),
            icon: "settings".to_string(),
            label: "Settings".to_string(),
            route: Route::Settings,
        },
    ];

    rsx! {
        aside(class: "activity-bar", style: styles::container()) {
            div(class: "activity-items", style: styles::items()) {
                for item in items {
                    ActivityBarItem {
                        item: item.clone(),
                        is_active: active_view.get() == item.route,
                        on_click: on_change.clone(),
                    }
                }
            }
        }
    }
}

#[component]
fn ActivityBarItem(item: ActivityItem, is_active: bool, on_click: Callback<Route>) -> Element {
    let style = if is_active {
        styles::item_active()
    } else {
        styles::item()
    };

    rsx! {
        button(
            class: "activity-item",
            style: style,
            title: item.label.clone(),
            onclick: move |_| on_click.call(item.route.clone()),
        ) {
            Icon { name: item.icon.clone() }
        }
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            width: 48px;
            background: var(--color-bg-secondary);
            border-right: 1px solid var(--color-border);
        "#
    }

    pub fn items() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            padding-top: var(--spacing-sm);
        "#
    }

    pub fn item() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: center;
            width: 48px;
            height: 48px;
            color: var(--color-text-secondary);
            background: transparent;
            border: none;
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn item_active() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: center;
            width: 48px;
            height: 48px;
            color: var(--color-primary);
            background: var(--color-surface-active);
            border: none;
            border-left: 2px solid var(--color-primary);
            cursor: pointer;
        "#
    }
}
