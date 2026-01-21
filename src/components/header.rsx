//! Header component - top bar with title and actions.

use rsc::prelude::*;

use super::{Button, ButtonVariant, ButtonSize, Icon};

/// Header component props.
#[derive(Props)]
pub struct HeaderProps {
    pub title: &'static str,
    pub sidebar_visible: Signal<bool>,
    pub bottom_panel_visible: Signal<bool>,
}

/// Header component.
#[component]
pub fn Header(props: HeaderProps) -> Element {
    rsx! {
        header(class="header", style=styles::container()) {
            // Left section - toggle buttons
            div(class="header-left", style=styles::section()) {
                Button {
                    variant: ButtonVariant::Ghost,
                    size: ButtonSize::Sm,
                    on_click: move |_| {
                        props.sidebar_visible.update(|v| *v = !*v);
                    },
                } {
                    Icon { name: "sidebar".to_string() }
                }

                h1(class="header-title", style=styles::title()) {
                    { props.title }
                }
            }

            // Center section - breadcrumbs or context
            div(class="header-center", style=styles::section()) {
                // Placeholder for breadcrumbs
            }

            // Right section - actions
            div(class="header-right", style=styles::section()) {
                Button {
                    variant: ButtonVariant::Ghost,
                    size: ButtonSize::Sm,
                    on_click: move |_| {
                        props.bottom_panel_visible.update(|v| *v = !*v);
                    },
                } {
                    Icon { name: "panel-bottom".to_string() }
                }

                Button {
                    variant: ButtonVariant::Ghost,
                    size: ButtonSize::Sm,
                    on_click: move |_| {},
                } {
                    Icon { name: "sun".to_string() }
                }
            }
        }
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            height: 48px;
            padding: 0 var(--spacing-md);
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn section() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
        "#
    }

    pub fn title() -> &'static str {
        r#"
            font-size: var(--font-size-base);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-primary);
            margin: 0;
        "#
    }
}
