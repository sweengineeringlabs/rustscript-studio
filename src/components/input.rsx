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
/// Input(
///     value: name.get(),
///     placeholder: Some("Enter your name".to_string()),
///     on_change: Some(Callback::new(move |v| name.set(v))),
/// )
/// ```
#[component]
pub fn Input(
    value: Option<String>,
    input_type: Option<InputType>,
    size: Option<InputSize>,
    variant: Option<InputVariant>,
    placeholder: Option<String>,
    disabled: Option<bool>,
    readonly: Option<bool>,
    required: Option<bool>,
    error: Option<bool>,
    min: Option<f64>,
    max: Option<f64>,
    step: Option<f64>,
    maxlength: Option<u32>,
    on_change: Option<Callback<String>>,
    on_focus: Option<Callback<()>>,
    on_blur: Option<Callback<()>>,
    on_submit: Option<Callback<String>>,
    class: Option<String>,
    autofocus: Option<bool>,
) -> Element {
    let value = value.unwrap_or(String::new());
    let input_type = input_type.unwrap_or(InputType::Text);
    let size = size.unwrap_or(InputSize::Md);
    let variant = variant.unwrap_or(InputVariant::Outline);
    let disabled = disabled.unwrap_or(false);
    let readonly = readonly.unwrap_or(false);
    let required = required.unwrap_or(false);
    let error = error.unwrap_or(false);
    let autofocus = autofocus.unwrap_or(false);

    let (is_focused, set_focused) = use_state(false);
    let style = get_input_style(variant, size, disabled, error, is_focused);
    let extra_class = class.unwrap_or_default();

    let handle_input = {
        let on_change = on_change.clone();
        move |e: InputEvent| {
            if let Some(ref callback) = on_change {
                callback.call(e.value());
            }
        }
    };

    let handle_focus = {
        let on_focus_cb = on_focus.clone();
        move |_: FocusEvent| {
            set_focused(true);
            if let Some(ref callback) = on_focus_cb {
                callback.call(());
            }
        }
    };

    let handle_blur = {
        let on_blur_cb = on_blur.clone();
        move |_: FocusEvent| {
            set_focused(false);
            if let Some(ref callback) = on_blur_cb {
                callback.call(());
            }
        }
    };

    let handle_keydown = {
        let on_submit = on_submit.clone();
        let value = value.clone();
        move |e: KeyboardEvent| {
            if e.key() == "Enter" {
                if let Some(ref callback) = on_submit {
                    callback.call(value.clone());
                }
            }
        }
    };

    rsx! {
        input(
            class: format!("input {}", extra_class),
            style: style,
            type: input_type.as_str(),
            value: value.clone(),
            placeholder: placeholder.clone().unwrap_or_default(),
            disabled: disabled,
            readonly: readonly,
            required: required,
            autofocus: autofocus,
            min: min.map(|v| v.to_string()).unwrap_or_default(),
            max: max.map(|v| v.to_string()).unwrap_or_default(),
            step: step.map(|v| v.to_string()).unwrap_or_default(),
            maxlength: maxlength.map(|v| v.to_string()).unwrap_or_default(),
            oninput: handle_input,
            onfocus: handle_focus,
            onblur: handle_blur,
            onkeydown: handle_keydown
        )
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
#[component]
pub fn LabeledInput(
    label: String,
    helper: Option<String>,
    error_message: Option<String>,
    required: Option<bool>,
    children: Element,
) -> Element {
    let required = required.unwrap_or(false);

    rsx! {
        div(class: "labeled-input", style: styles::wrapper()) {
            label(style: styles::label()) {
                {label.clone()}
                if required {
                    span(style: styles::required()) { " *" }
                }
            }

            {children}

            if let Some(ref error) = error_message {
                span(style: styles::error_text()) { {error.clone()} }
            } else if let Some(ref helper_text) = helper {
                span(style: styles::helper_text()) { {helper_text.clone()} }
            }
        }
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
