//! Input component with variants and sizes.

use rsc::prelude::*;

/// Input type.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputType {
    Text,
    Password,
    Email,
    Number,
    Search,
    Url,
    Tel,
}

impl Default for InputType {
    fn default() -> Self {
        InputType::Text
    }
}

impl InputType {
    pub fn as_str(&self) -> &'static str {
        match self {
            InputType::Text => "text",
            InputType::Password => "password",
            InputType::Email => "email",
            InputType::Number => "number",
            InputType::Search => "search",
            InputType::Url => "url",
            InputType::Tel => "tel",
        }
    }
}

/// Input size.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputSize {
    Sm,
    Md,
    Lg,
}

impl Default for InputSize {
    fn default() -> Self {
        InputSize::Md
    }
}

/// Input variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputVariant {
    Outline,
    Filled,
    Flushed,
}

impl Default for InputVariant {
    fn default() -> Self {
        InputVariant::Outline
    }
}

/// Input component.
///
/// ## Example
/// ```rust,ignore
/// <Input
///     value={name.get()}
///     placeholder={"Enter your name".to_string()}
///     on_change={Callback::new(move |v| name.set(v))}
/// />
/// ```
component Input(
    value?: String,
    input_type?: InputType,
    size?: InputSize,
    variant?: InputVariant,
    placeholder?: String,
    disabled?: bool,
    readonly?: bool,
    required?: bool,
    error?: bool,
    min?: f64,
    max?: f64,
    step?: f64,
    maxlength?: u32,
    on_change?: Callback<String>,
    on_focus?: Callback<()>,
    on_blur?: Callback<()>,
    on_submit?: Callback<String>,
    css_class?: String,
    autofocus?: bool,
) {
    let value = value.unwrap_or(String::new());
    let input_type = input_type.unwrap_or(InputType::Text);
    let size = size.unwrap_or(InputSize::Md);
    let variant = variant.unwrap_or(InputVariant::Outline);
    let disabled = disabled.unwrap_or(false);
    let readonly = readonly.unwrap_or(false);
    let required = required.unwrap_or(false);
    let error = error.unwrap_or(false);
    let autofocus = autofocus.unwrap_or(false);

    let is_focused = signal(false);
    let input_style = get_input_style(variant, size, disabled, error, is_focused.get());
    let extra_class = css_class.unwrap_or_default();

    render {
        <input
            class={format!("input {}", extra_class)}
            style={input_style}
            type={input_type.as_str()}
            value={value.clone()}
            placeholder={placeholder.clone().unwrap_or_default()}
            disabled={disabled}
            readonly={readonly}
            required={required}
            autofocus={autofocus}
            min={min.map(|v| v.to_string()).unwrap_or_default()}
            max={max.map(|v| v.to_string()).unwrap_or_default()}
            step={step.map(|v| v.to_string()).unwrap_or_default()}
            maxlength={maxlength.map(|v| v.to_string()).unwrap_or_default()}
            on:input={|e: InputEvent| {
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
            on:keydown={|e: KeyboardEvent| {
                if e.key() == "Enter" {
                    if let Some(ref callback) = on_submit {
                        callback.call(value.clone());
                    }
                }
            }}
        />
    }
}

fn get_input_style(
    variant: InputVariant,
    size: InputSize,
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
    "#;

    let variant_style = match variant {
        InputVariant::Outline => r#"
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
        "#,
        InputVariant::Filled => r#"
            border: 1px solid transparent;
            border-radius: var(--radius-md);
            background: var(--color-bg-secondary);
        "#,
        InputVariant::Flushed => r#"
            border: none;
            border-bottom: 1px solid var(--color-border);
            border-radius: 0;
            background: transparent;
        "#,
    };

    let size_style = match size {
        InputSize::Sm => r#"
            height: 32px;
            padding: 0 var(--spacing-sm);
            font-size: var(--font-size-sm);
        "#,
        InputSize::Md => r#"
            height: 40px;
            padding: 0 var(--spacing-md);
            font-size: var(--font-size-base);
        "#,
        InputSize::Lg => r#"
            height: 48px;
            padding: 0 var(--spacing-lg);
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

/// Labeled input wrapper that provides consistent label, helper text, and error styling.
component LabeledInput(
    label: String,
    helper?: String,
    error_message?: String,
    required?: bool,
    children: Element,
) {
    let required = required.unwrap_or(false);

    render {
        <div class="labeled-input" style={styles::wrapper()}>
            <label style={styles::label()}>
                {label.clone()}
                @if required {
                    <span style={styles::required()}>" *"</span>
                }
            </label>

            {children}

            @if let Some(ref error) = error_message {
                <span style={styles::error_text()}>{error.clone()}</span>
            } else if let Some(ref helper_text) = helper {
                <span style={styles::helper_text()}>{helper_text.clone()}</span>
            }
        </div>
    }
}

mod styles {
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
