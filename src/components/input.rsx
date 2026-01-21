//! Input component with variants and sizes.

use rsc::prelude::*;

/// Input type.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum InputType {
    #[default]
    Text,
    Password,
    Email,
    Number,
    Search,
    Url,
    Tel,
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
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum InputSize {
    Sm,
    #[default]
    Md,
    Lg,
}

/// Input variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum InputVariant {
    #[default]
    Outline,
    Filled,
    Flushed,
}

/// Input component props.
#[derive(Props)]
pub struct InputProps {
    /// Input value (controlled)
    #[prop(default)]
    pub value: String,
    /// Input type
    #[prop(default)]
    pub input_type: InputType,
    /// Input size
    #[prop(default)]
    pub size: InputSize,
    /// Input variant
    #[prop(default)]
    pub variant: InputVariant,
    /// Placeholder text
    #[prop(default)]
    pub placeholder: Option<String>,
    /// Whether the input is disabled
    #[prop(default)]
    pub disabled: bool,
    /// Whether the input is read-only
    #[prop(default)]
    pub readonly: bool,
    /// Whether the input is required
    #[prop(default)]
    pub required: bool,
    /// Whether the input has an error state
    #[prop(default)]
    pub error: bool,
    /// Minimum value (for number input)
    #[prop(default)]
    pub min: Option<f64>,
    /// Maximum value (for number input)
    #[prop(default)]
    pub max: Option<f64>,
    /// Step value (for number input)
    #[prop(default)]
    pub step: Option<f64>,
    /// Maximum length
    #[prop(default)]
    pub maxlength: Option<u32>,
    /// Callback when value changes
    #[prop(default)]
    pub on_change: Option<Callback<String>>,
    /// Callback when input receives focus
    #[prop(default)]
    pub on_focus: Option<Callback<()>>,
    /// Callback when input loses focus
    #[prop(default)]
    pub on_blur: Option<Callback<()>>,
    /// Callback when Enter is pressed
    #[prop(default)]
    pub on_submit: Option<Callback<String>>,
    /// Additional CSS class
    #[prop(default)]
    pub class: Option<String>,
    /// Autofocus
    #[prop(default)]
    pub autofocus: bool,
}

/// Input component.
///
/// ## Example
/// ```rust,ignore
/// Input {
///     value: name.get(),
///     placeholder: Some("Enter your name".to_string()),
///     on_change: Callback::new(move |v| name.set(v)),
/// }
/// ```
#[component]
pub fn Input(props: InputProps) -> Element {
    let is_focused = use_signal(|| false);
    let style = get_input_style(
        props.variant,
        props.size,
        props.disabled,
        props.error,
        is_focused.get(),
    );
    let class = props.class.clone().unwrap_or_default();

    let on_input = {
        let on_change = props.on_change.clone();
        move |e: InputEvent| {
            if let Some(ref callback) = on_change {
                callback.call(e.value());
            }
        }
    };

    let on_focus = {
        let on_focus_cb = props.on_focus.clone();
        move |_: FocusEvent| {
            is_focused.set(true);
            if let Some(ref callback) = on_focus_cb {
                callback.call(());
            }
        }
    };

    let on_blur = {
        let on_blur_cb = props.on_blur.clone();
        move |_: FocusEvent| {
            is_focused.set(false);
            if let Some(ref callback) = on_blur_cb {
                callback.call(());
            }
        }
    };

    let on_keydown = {
        let on_submit = props.on_submit.clone();
        let value = props.value.clone();
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
            class=format!("input {}", class),
            style=style,
            type=props.input_type.as_str(),
            value=props.value.clone(),
            placeholder=props.placeholder.clone().unwrap_or_default(),
            disabled=props.disabled,
            readonly=props.readonly,
            required=props.required,
            autofocus=props.autofocus,
            min=props.min.map(|v| v.to_string()).unwrap_or_default(),
            max=props.max.map(|v| v.to_string()).unwrap_or_default(),
            step=props.step.map(|v| v.to_string()).unwrap_or_default(),
            maxlength=props.maxlength.map(|v| v.to_string()).unwrap_or_default(),
            on:input=on_input,
            on:focus=on_focus,
            on:blur=on_blur,
            on:keydown=on_keydown,
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

    let hover_style = if !disabled && !error && !focused {
        "border-color: var(--color-border-hover);"
    } else {
        ""
    };

    // Note: hover_style is for CSS hover state, applied via :hover pseudo-class
    // For RSX inline styles, we just combine the base styles
    format!("{} {} {} {}", base, variant_style, size_style, state_style)
}

/// Labeled input wrapper component.
#[derive(Props)]
pub struct LabeledInputProps {
    /// Label text
    pub label: String,
    /// Optional helper text
    #[prop(default)]
    pub helper: Option<String>,
    /// Optional error message
    #[prop(default)]
    pub error_message: Option<String>,
    /// Whether the field is required
    #[prop(default)]
    pub required: bool,
    /// The input element
    pub children: Element,
}

/// Labeled input wrapper that provides consistent label, helper text, and error styling.
#[component]
pub fn LabeledInput(props: LabeledInputProps) -> Element {
    let has_error = props.error_message.is_some();

    rsx! {
        div(class="labeled-input", style=styles::wrapper()) {
            label(style=styles::label()) {
                { props.label.clone() }
                if props.required {
                    span(style=styles::required()) { " *" }
                }
            }

            { props.children }

            if let Some(ref error) = props.error_message {
                span(style=styles::error_text()) { { error.clone() } }
            } else if let Some(ref helper) = props.helper {
                span(style=styles::helper_text()) { { helper.clone() } }
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
