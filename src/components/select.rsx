//! Select component with dropdown options.

use rsc::prelude::*;

/// Select size.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SelectSize {
    Sm,
    Md,
    Lg,
}

impl Default for SelectSize {
    fn default() -> Self {
        SelectSize::Md
    }
}

/// Select variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SelectVariant {
    Outline,
    Filled,
    Flushed,
}

impl Default for SelectVariant {
    fn default() -> Self {
        SelectVariant::Outline
    }
}

/// Option item for the select component.
#[derive(Debug, Clone, PartialEq)]
pub struct SelectOption {
    pub value: String,
    pub label: String,
    pub disabled: bool,
}

impl SelectOption {
    pub fn new(value: impl Into<String>, label: impl Into<String>) -> Self {
        Self {
            value: value.into(),
            label: label.into(),
            disabled: false,
        }
    }

    pub fn disabled(mut self) -> Self {
        self.disabled = true;
        self
    }
}

/// Select component with native dropdown.
///
/// ## Example
/// ```rust,ignore
/// Select {
///     value: selected.get(),
///     options: vec![
///         SelectOption::new("opt1", "Option 1"),
///         SelectOption::new("opt2", "Option 2"),
///     ],
///     placeholder: Some("Choose an option".to_string()),
///     on_change: Callback::new(move |v| selected.set(v)),
/// }
/// ```
#[component]
pub fn Select(
    /// Currently selected value
    value: Option<String>,
    /// Available options
    options: Vec<SelectOption>,
    /// Placeholder text when no value is selected
    placeholder: Option<String>,
    /// Select size
    size: Option<SelectSize>,
    /// Select variant
    variant: Option<SelectVariant>,
    /// Whether the select is disabled
    disabled: Option<bool>,
    /// Whether the select is required
    required: Option<bool>,
    /// Whether the select has an error state
    error: Option<bool>,
    /// Callback when selection changes
    on_change: Option<Callback<String>>,
    /// Callback when select receives focus
    on_focus: Option<Callback<()>>,
    /// Callback when select loses focus
    on_blur: Option<Callback<()>>,
    /// Additional CSS class
    css_class: Option<String>,
) -> Element {
    let value = value.unwrap_or(String::new());
    let size = size.unwrap_or(SelectSize::default());
    let variant = variant.unwrap_or(SelectVariant::default());
    let disabled = disabled.unwrap_or(false);
    let required = required.unwrap_or(false);
    let error = error.unwrap_or(false);

    let is_focused = use_signal(|| false);
    let style = get_select_style(
        variant,
        size,
        disabled,
        error,
        is_focused.get(),
    );
    let class = class.clone().unwrap_or_default();

    let on_change_handler = {
        let on_change = on_change.clone();
        move |e: InputEvent| {
            if let Some(ref callback) = on_change {
                callback.call(e.value());
            }
        }
    };

    let on_focus_handler = {
        let on_focus_cb = on_focus.clone();
        move |_: FocusEvent| {
            is_focused.set(true);
            if let Some(ref callback) = on_focus_cb {
                callback.call(());
            }
        }
    };

    let on_blur_handler = {
        let on_blur_cb = on_blur.clone();
        move |_: FocusEvent| {
            is_focused.set(false);
            if let Some(ref callback) = on_blur_cb {
                callback.call(());
            }
        }
    };

    rsx! {
        div(class: format!("select-wrapper {}", class), style: styles::wrapper()) {
            select(
                class: "select",
                style: style,
                disabled: disabled,
                required: required,
                onchange: on_change_handler,
                onfocus: on_focus_handler,
                onblur: on_blur_handler,
            ) {
                // Placeholder option
                if let Some(ref placeholder) = placeholder {
                    option(
                        value: "",
                        disabled: true,
                        selected: value.is_empty(),
                        style: styles::placeholder_option(),
                    ) {
                        { placeholder.clone() }
                    }
                }

                // Options
                for opt in options.iter() {
                    option(
                        value: opt.value.clone(),
                        disabled: opt.disabled,
                        selected: value == opt.value,
                    ) {
                        { opt.label.clone() }
                    }
                }
            }

            // Chevron icon
            div(class: "select-icon", style: styles::icon()) {
                svg(
                    width: "16",
                    height: "16",
                    viewBox: "0 0 24 24",
                    fill: "none",
                    stroke: "currentColor",
                    stroke-width: "2",
                ) {
                    path(d: "M6 9l6 6 6-6")
                }
            }
        }
    }
}

fn get_select_style(
    variant: SelectVariant,
    size: SelectSize,
    disabled: bool,
    error: bool,
    focused: bool,
) -> String {
    let base = r#"
        display: block;
        width: 100%;
        font-family: var(--font-sans);
        color: var(--color-text-primary);
        background: var(--color-surface);
        transition: var(--transition-fast);
        outline: none;
        cursor: pointer;
        appearance: none;
        -webkit-appearance: none;
        -moz-appearance: none;
    "#;

    let variant_style = match variant {
        SelectVariant::Outline => r#"
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
        "#,
        SelectVariant::Filled => r#"
            border: 1px solid transparent;
            border-radius: var(--radius-md);
            background: var(--color-bg-secondary);
        "#,
        SelectVariant::Flushed => r#"
            border: none;
            border-bottom: 1px solid var(--color-border);
            border-radius: 0;
            background: transparent;
        "#,
    };

    let size_style = match size {
        SelectSize::Sm => r#"
            height: 32px;
            padding: 0 var(--spacing-xl) 0 var(--spacing-sm);
            font-size: var(--font-size-sm);
        "#,
        SelectSize::Md => r#"
            height: 40px;
            padding: 0 var(--spacing-xl) 0 var(--spacing-md);
            font-size: var(--font-size-base);
        "#,
        SelectSize::Lg => r#"
            height: 48px;
            padding: 0 var(--spacing-2xl) 0 var(--spacing-lg);
            font-size: var(--font-size-lg);
        "#,
    };

    let state_style = if disabled {
        "opacity: 0.5; cursor: not-allowed;"
    } else if error {
        "border-color: var(--color-error);"
    } else if focused {
        "border-color: var(--color-primary); box-shadow: 0 0 0 2px var(--color-primary-alpha);"
    } else {
        ""
    };

    format!("{} {} {} {}", base, variant_style, size_style, state_style)
}

mod styles {
    pub fn wrapper() -> &'static str {
        r#"
            position: relative;
            display: inline-block;
            width: 100%;
        "#
    }

    pub fn icon() -> &'static str {
        r#"
            position: absolute;
            right: var(--spacing-sm);
            top: 50%;
            transform: translateY(-50%);
            pointer-events: none;
            color: var(--color-text-secondary);
        "#
    }

    pub fn placeholder_option() -> &'static str {
        r#"
            color: var(--color-text-muted);
        "#
    }
}

/// Labeled select wrapper that provides consistent label, helper text, and error styling.
#[component]
pub fn LabeledSelect(
    /// Label text
    label: String,
    /// Optional helper text
    helper: Option<String>,
    /// Optional error message
    error_message: Option<String>,
    /// Whether the field is required
    required: Option<bool>,
    /// The select element
    children: Element,
) -> Element {
    let required = required.unwrap_or(false);

    rsx! {
        div(class: "labeled-select", style: label_styles::wrapper()) {
            label(style: label_styles::label()) {
                { label.clone() }
                if required {
                    span(style: label_styles::required()) { " *" }
                }
            }

            { children }

            if let Some(ref error) = error_message {
                span(style: label_styles::error_text()) { { error.clone() } }
            } else if let Some(ref helper) = helper {
                span(style: label_styles::helper_text()) { { helper.clone() } }
            }
        }
    }
}

mod label_styles {
    pub fn wrapper() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-primary);
        "#
    }

    pub fn required() -> &'static str {
        r#"
            color: var(--color-error);
        "#
    }

    pub fn helper_text() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            color: var(--color-text-muted);
        "#
    }

    pub fn error_text() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            color: var(--color-error);
        "#
    }
}
