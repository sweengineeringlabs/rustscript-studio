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
/// <Select
///     value={selected.get()}
///     options={vec![
///         SelectOption::new("opt1", "Option 1"),
///         SelectOption::new("opt2", "Option 2"),
///     ]}
///     placeholder={"Choose an option".to_string()}
///     on_change={Callback::new(move |v| selected.set(v))}
/// />
/// ```
component Select(
    /// Currently selected value
    value?: String,
    /// Available options
    options: Vec<SelectOption>,
    /// Placeholder text when no value is selected
    placeholder?: String,
    /// Select size
    size?: SelectSize,
    /// Select variant
    variant?: SelectVariant,
    /// Whether the select is disabled
    disabled?: bool,
    /// Whether the select is required
    required?: bool,
    /// Whether the select has an error state
    error?: bool,
    /// Callback when selection changes
    on_change?: Callback<String>,
    /// Callback when select receives focus
    on_focus?: Callback<()>,
    /// Callback when select loses focus
    on_blur?: Callback<()>,
    /// Additional CSS class
    css_class?: String,
) {
    let value = value.unwrap_or(String::new());
    let size = size.unwrap_or(SelectSize::default());
    let variant = variant.unwrap_or(SelectVariant::default());
    let disabled = disabled.unwrap_or(false);
    let required = required.unwrap_or(false);
    let error = error.unwrap_or(false);

    let is_focused = signal(false);
    let select_style = get_select_style(
        variant,
        size,
        disabled,
        error,
        is_focused.get(),
    );
    let extra_class = css_class.unwrap_or_default();

    render {
        <div class={format!("select-wrapper {}", extra_class)} style={styles::wrapper()}>
            <select
                class="select"
                style={select_style}
                disabled={disabled}
                required={required}
                on:change={|e: InputEvent| {
                    if let Some(ref callback) = on_change {
                        callback.call(e.value());
                    }
                }}
                on:focus={|_: FocusEvent| {
                    is_focused.set(true);
                    if let Some(ref callback) = on_focus {
                        callback.call(());
                    }
                }}
                on:blur={|_: FocusEvent| {
                    is_focused.set(false);
                    if let Some(ref callback) = on_blur {
                        callback.call(());
                    }
                }}
            >
                // Placeholder option
                @if let Some(ref placeholder) = placeholder {
                    <option
                        value=""
                        disabled={true}
                        selected={value.is_empty()}
                        style={styles::placeholder_option()}
                    >
                        {placeholder.clone()}
                    </option>
                }

                // Options
                @for opt in options.iter() {
                    <option
                        value={opt.value.clone()}
                        disabled={opt.disabled}
                        selected={value == opt.value}
                    >
                        {opt.label.clone()}
                    </option>
                }
            </select>

            // Chevron icon
            <div class="select-icon" style={styles::icon()}>
                <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                >
                    <path d="M6 9l6 6 6-6" />
                </svg>
            </div>
        </div>
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
component LabeledSelect(
    /// Label text
    label: String,
    /// Optional helper text
    helper?: String,
    /// Optional error message
    error_message?: String,
    /// Whether the field is required
    required?: bool,
    /// The select element
    children: Element,
) {
    let required = required.unwrap_or(false);

    render {
        <div class="labeled-select" style={label_styles::wrapper()}>
            <label style={label_styles::label()}>
                {label.clone()}
                @if required {
                    <span style={label_styles::required()}>" *"</span>
                }
            </label>

            {children}

            @if let Some(ref error) = error_message {
                <span style={label_styles::error_text()}>{error.clone()}</span>
            } else if let Some(ref helper) = helper {
                <span style={label_styles::helper_text()}>{helper.clone()}</span>
            }
        </div>
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
