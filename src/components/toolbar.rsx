//! Toolbar component for action buttons.

use rsc::prelude::*;

use super::{Button, ButtonVariant, ButtonSize, Icon};

/// Toolbar component props.
#[derive(Props)]
pub struct ToolbarProps {
    pub children: Element,
}

/// Toolbar component.
#[component]
pub fn Toolbar(props: ToolbarProps) -> Element {
    rsx! {
        div(class="toolbar", style=styles::container()) {
            { props.children }
        }
    }
}

/// Toolbar group for organizing buttons.
#[derive(Props)]
pub struct ToolbarGroupProps {
    pub children: Element,
}

#[component]
pub fn ToolbarGroup(props: ToolbarGroupProps) -> Element {
    rsx! {
        div(class="toolbar-group", style=styles::group()) {
            { props.children }
        }
    }
}

/// Toolbar button.
#[derive(Props)]
pub struct ToolbarButtonProps {
    pub icon: String,
    #[prop(default)]
    pub label: Option<String>,
    #[prop(default)]
    pub active: bool,
    #[prop(into)]
    pub on_click: Callback<()>,
}

#[component]
pub fn ToolbarButton(props: ToolbarButtonProps) -> Element {
    let variant = if props.active {
        ButtonVariant::Primary
    } else {
        ButtonVariant::Ghost
    };

    rsx! {
        Button {
            variant: variant,
            size: ButtonSize::Sm,
            on_click: props.on_click.clone(),
        } {
            Icon { name: props.icon.clone(), size: 16 }
            if let Some(ref label) = props.label {
                span { { label.clone() } }
            }
        }
    }
}

/// Toolbar divider.
#[component]
pub fn ToolbarDivider() -> Element {
    rsx! {
        div(class="toolbar-divider", style=styles::divider())
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
