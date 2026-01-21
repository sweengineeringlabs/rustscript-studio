// Button component with variants

use rsc::prelude::*;

/// Button variant
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ButtonVariant {
    Primary,
    Secondary,
    Ghost,
    Danger,
}

/// Button size
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ButtonSize {
    Sm,
    Md,
    Lg,
}

/// Button component
component Button(
    variant?: ButtonVariant,
    size?: ButtonSize,
    disabled?: bool,
    css_class?: String,
    onclick?: Callback<()>,
    children: Children,
) {
    let variant = variant.unwrap_or(ButtonVariant::Primary);
    let size = size.unwrap_or(ButtonSize::Md);
    let disabled = disabled.unwrap_or(false);
    let extra_class = css_class.unwrap_or_default();

    let btn_style = get_button_style(variant, size, disabled);

    render {
        <button
            class={format!("button {}", extra_class)}
            style={btn_style}
            disabled={disabled}
            on:click={|| {
                if !disabled {
                    if let Some(ref cb) = onclick {
                        cb.call(());
                    }
                }
            }}
        >
            {children}
        </button>
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
