//! Button component with variants.

use rsc::prelude::*;

/// Button variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ButtonVariant {
    #[default]
    Primary,
    Secondary,
    Ghost,
    Danger,
}

/// Button size.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ButtonSize {
    Sm,
    #[default]
    Md,
    Lg,
}

/// Button component props.
#[derive(Props)]
pub struct ButtonProps {
    #[prop(default)]
    pub variant: ButtonVariant,
    #[prop(default)]
    pub size: ButtonSize,
    #[prop(default)]
    pub disabled: bool,
    #[prop(into)]
    pub on_click: Callback<()>,
    #[prop(default)]
    pub class: Option<String>,
    pub children: Element,
}

/// Button component.
#[component]
pub fn Button(props: ButtonProps) -> Element {
    let style = get_button_style(props.variant, props.size, props.disabled);
    let class = props.class.unwrap_or_default();

    rsx! {
        button(
            class=format!("button {}", class),
            style=style,
            disabled=props.disabled,
            on:click=move |_| {
                if !props.disabled {
                    props.on_click.call(());
                }
            },
        ) {
            { props.children }
        }
    }
}

fn get_button_style(variant: ButtonVariant, size: ButtonSize, disabled: bool) -> String {
    let base = r#"
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: var(--spacing-sm);
        font-family: var(--font-sans);
        font-weight: var(--font-weight-medium);
        border-radius: var(--radius-md);
        transition: var(--transition-fast);
        cursor: pointer;
        border: none;
    "#;

    let variant_style = match variant {
        ButtonVariant::Primary => r#"
            background: var(--color-primary);
            color: var(--color-text-inverse);
        "#,
        ButtonVariant::Secondary => r#"
            background: var(--color-surface);
            color: var(--color-text-primary);
            border: 1px solid var(--color-border);
        "#,
        ButtonVariant::Ghost => r#"
            background: transparent;
            color: var(--color-text-secondary);
        "#,
        ButtonVariant::Danger => r#"
            background: var(--color-error);
            color: var(--color-text-inverse);
        "#,
    };

    let size_style = match size {
        ButtonSize::Sm => r#"
            height: 32px;
            padding: 0 var(--spacing-sm);
            font-size: var(--font-size-sm);
        "#,
        ButtonSize::Md => r#"
            height: 40px;
            padding: 0 var(--spacing-md);
            font-size: var(--font-size-base);
        "#,
        ButtonSize::Lg => r#"
            height: 48px;
            padding: 0 var(--spacing-lg);
            font-size: var(--font-size-lg);
        "#,
    };

    let disabled_style = if disabled {
        "opacity: 0.5; cursor: not-allowed;"
    } else {
        ""
    };

    format!("{} {} {} {}", base, variant_style, size_style, disabled_style)
}
