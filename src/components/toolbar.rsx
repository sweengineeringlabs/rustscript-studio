//! Toolbar component for action buttons.

use rsc::prelude::*;

use super::{Button, ButtonVariant, ButtonSize, Icon};

/// Toolbar component.
#[component]
pub fn Toolbar(children: Element) -> Element {
    rsx! {
        div(class: "toolbar", style: styles::container()) {
            { children }
        }
    }
}

/// Toolbar group for organizing buttons.
#[component]
pub fn ToolbarGroup(children: Element) -> Element {
    rsx! {
        div(class: "toolbar-group", style: styles::group()) {
            { children }
        }
    }
}

/// Toolbar button.
#[component]
pub fn ToolbarButton(
    icon: String,
    label: Option<String>,
    active: Option<bool>,
    on_click: Callback<()>,
) -> Element {
    let active = active.unwrap_or(false);

    let variant = if active {
        ButtonVariant::Primary
    } else {
        ButtonVariant::Ghost
    };

    rsx! {
        Button {
            variant: variant,
            size: ButtonSize::Sm,
            on_click: on_click.clone(),
        } {
            Icon { name: icon.clone(), size: 16 }
            if let Some(ref label) = label {
                span { { label.clone() } }
            }
        }
    }
}

/// Toolbar divider.
#[component]
pub fn ToolbarDivider() -> Element {
    rsx! {
        div(class: "toolbar-divider", style: styles::divider())
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm);
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn group() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: 2px;
        "#
    }

    pub fn divider() -> &'static str {
        r#"
            width: 1px;
            height: 24px;
            background: var(--color-border);
            margin: 0 var(--spacing-sm);
        "#
    }
}
