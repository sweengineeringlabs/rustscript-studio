//! Checkbox component with label support.

use rsc::prelude::*;

/// Checkbox size.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum CheckboxSize {
    Sm,
    #[default]
    Md,
    Lg,
}

/// Checkbox component props.
#[derive(Props)]
pub struct CheckboxProps {
    /// Whether the checkbox is checked
    #[prop(default)]
    pub checked: bool,
    /// Whether the checkbox is in indeterminate state
    #[prop(default)]
    pub indeterminate: bool,
    /// Checkbox size
    #[prop(default)]
    pub size: CheckboxSize,
    /// Whether the checkbox is disabled
    #[prop(default)]
    pub disabled: bool,
    /// Whether the checkbox has an error state
    #[prop(default)]
    pub error: bool,
    /// Optional label text
    #[prop(default)]
    pub label: Option<String>,
    /// Optional description text below the label
    #[prop(default)]
    pub description: Option<String>,
    /// Callback when checkbox state changes
    #[prop(default)]
    pub on_change: Option<Callback<bool>>,
    /// Additional CSS class
    #[prop(default)]
    pub class: Option<String>,
}

/// Checkbox component with custom styling.
///
/// ## Example
/// ```rust,ignore
/// Checkbox {
///     checked: is_enabled.get(),
///     label: Some("Enable notifications".to_string()),
///     description: Some("Receive email updates".to_string()),
///     on_change: Callback::new(move |v| is_enabled.set(v)),
/// }
/// ```
#[component]
pub fn Checkbox(props: CheckboxProps) -> Element {
    let is_focused = use_signal(|| false);
    let class = props.class.clone().unwrap_or_default();

    let on_change = {
        let on_change = props.on_change.clone();
        let checked = props.checked;
        move |_: InputEvent| {
            if let Some(ref callback) = on_change {
                callback.call(!checked);
            }
        }
    };

    let on_focus = move |_: FocusEvent| {
        is_focused.set(true);
    };

    let on_blur = move |_: FocusEvent| {
        is_focused.set(false);
    };

    let on_click = {
        let on_change = props.on_change.clone();
        let checked = props.checked;
        let disabled = props.disabled;
        move |_: MouseEvent| {
            if !disabled {
                if let Some(ref callback) = on_change {
                    callback.call(!checked);
                }
            }
        }
    };

    rsx! {
        label(
            class=format!("checkbox-wrapper {}", class),
            style=styles::wrapper(props.disabled),
            on:click=on_click,
        ) {
            // Hidden native checkbox for accessibility
            input(
                type="checkbox",
                checked=props.checked,
                disabled=props.disabled,
                style=styles::hidden_input(),
                on:change=on_change,
                on:focus=on_focus,
                on:blur=on_blur,
            )

            // Custom checkbox visual
            div(
                class="checkbox-box",
                style=styles::box_style(
                    props.size,
                    props.checked,
                    props.indeterminate,
                    props.disabled,
                    props.error,
                    is_focused.get(),
                ),
            ) {
                if props.checked {
                    // Checkmark icon
                    svg(
                        viewBox="0 0 24 24",
                        fill="none",
                        stroke="currentColor",
                        stroke-width="3",
                        style=styles::icon(props.size),
                    ) {
                        path(d="M5 12l5 5L20 7")
                    }
                } else if props.indeterminate {
                    // Indeterminate line
                    svg(
                        viewBox="0 0 24 24",
                        fill="none",
                        stroke="currentColor",
                        stroke-width="3",
                        style=styles::icon(props.size),
                    ) {
                        path(d="M5 12h14")
                    }
                }
            }

            // Label and description
            if props.label.is_some() || props.description.is_some() {
                div(class="checkbox-content", style=styles::content()) {
                    if let Some(ref label) = props.label {
                        span(class="checkbox-label", style=styles::label(props.size, props.disabled)) {
                            { label.clone() }
                        }
                    }
                    if let Some(ref description) = props.description {
                        span(class="checkbox-description", style=styles::description(props.disabled)) {
                            { description.clone() }
                        }
                    }
                }
            }
        }
    }
}

mod styles {
    use super::CheckboxSize;

    pub fn wrapper(disabled: bool) -> String {
        let cursor = if disabled { "not-allowed" } else { "pointer" };
        format!(
            r#"
                display: inline-flex;
                align-items: flex-start;
                gap: var(--spacing-sm);
                cursor: {cursor};
                user-select: none;
            "#,
            cursor = cursor,
        )
    }

    pub fn hidden_input() -> &'static str {
        r#"
            position: absolute;
            opacity: 0;
            width: 0;
            height: 0;
            pointer-events: none;
        "#
    }

    pub fn box_style(
        size: CheckboxSize,
        checked: bool,
        indeterminate: bool,
        disabled: bool,
        error: bool,
        focused: bool,
    ) -> String {
        let (box_size, border_radius) = match size {
            CheckboxSize::Sm => ("16px", "var(--radius-sm)"),
            CheckboxSize::Md => ("20px", "var(--radius-md)"),
            CheckboxSize::Lg => ("24px", "var(--radius-md)"),
        };

        let bg_color = if checked || indeterminate {
            if disabled {
                "var(--color-primary-disabled)"
            } else {
                "var(--color-primary)"
            }
        } else {
            "var(--color-surface)"
        };

        let border_color = if error {
            "var(--color-error)"
        } else if checked || indeterminate {
            bg_color
        } else if focused {
            "var(--color-primary)"
        } else {
            "var(--color-border)"
        };

        let text_color = if checked || indeterminate {
            "var(--color-text-inverse)"
        } else {
            "transparent"
        };

        let opacity = if disabled { "0.5" } else { "1" };

        let focus_shadow = if focused && !disabled {
            "box-shadow: 0 0 0 2px var(--color-primary-alpha);"
        } else {
            ""
        };

        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                width: {box_size};
                height: {box_size};
                min-width: {box_size};
                min-height: {box_size};
                background: {bg_color};
                border: 2px solid {border_color};
                border-radius: {border_radius};
                color: {text_color};
                opacity: {opacity};
                transition: var(--transition-fast);
                {focus_shadow}
            "#,
            box_size = box_size,
            border_radius = border_radius,
            bg_color = bg_color,
            border_color = border_color,
            text_color = text_color,
            opacity = opacity,
            focus_shadow = focus_shadow,
        )
    }

    pub fn icon(size: CheckboxSize) -> String {
        let icon_size = match size {
            CheckboxSize::Sm => "12px",
            CheckboxSize::Md => "14px",
            CheckboxSize::Lg => "16px",
        };
        format!(
            r#"
                width: {icon_size};
                height: {icon_size};
            "#,
            icon_size = icon_size,
        )
    }

    pub fn content() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: 2px;
            padding-top: 2px;
        "#
    }

    pub fn label(size: CheckboxSize, disabled: bool) -> String {
        let font_size = match size {
            CheckboxSize::Sm => "var(--font-size-sm)",
            CheckboxSize::Md => "var(--font-size-base)",
            CheckboxSize::Lg => "var(--font-size-lg)",
        };
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                font-size: {font_size};
                font-weight: var(--font-weight-medium);
                color: var(--color-text-primary);
                opacity: {opacity};
            "#,
            font_size = font_size,
            opacity = opacity,
        )
    }

    pub fn description(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                font-size: var(--font-size-sm);
                color: var(--color-text-secondary);
                opacity: {opacity};
            "#,
            opacity = opacity,
        )
    }
}

/// Switch component (toggle variant of checkbox).
#[derive(Props)]
pub struct SwitchProps {
    /// Whether the switch is on
    #[prop(default)]
    pub checked: bool,
    /// Switch size
    #[prop(default)]
    pub size: CheckboxSize,
    /// Whether the switch is disabled
    #[prop(default)]
    pub disabled: bool,
    /// Optional label text
    #[prop(default)]
    pub label: Option<String>,
    /// Callback when switch state changes
    #[prop(default)]
    pub on_change: Option<Callback<bool>>,
    /// Additional CSS class
    #[prop(default)]
    pub class: Option<String>,
}

/// Switch component (toggle style).
///
/// ## Example
/// ```rust,ignore
/// Switch {
///     checked: dark_mode.get(),
///     label: Some("Dark mode".to_string()),
///     on_change: Callback::new(move |v| dark_mode.set(v)),
/// }
/// ```
#[component]
pub fn Switch(props: SwitchProps) -> Element {
    let is_focused = use_signal(|| false);
    let class = props.class.clone().unwrap_or_default();

    let on_click = {
        let on_change = props.on_change.clone();
        let checked = props.checked;
        let disabled = props.disabled;
        move |_: MouseEvent| {
            if !disabled {
                if let Some(ref callback) = on_change {
                    callback.call(!checked);
                }
            }
        }
    };

    let on_focus = move |_: FocusEvent| {
        is_focused.set(true);
    };

    let on_blur = move |_: FocusEvent| {
        is_focused.set(false);
    };

    rsx! {
        label(
            class=format!("switch-wrapper {}", class),
            style=switch_styles::wrapper(props.disabled),
            on:click=on_click,
        ) {
            // Hidden native checkbox for accessibility
            input(
                type="checkbox",
                checked=props.checked,
                disabled=props.disabled,
                style=styles::hidden_input(),
                on:focus=on_focus,
                on:blur=on_blur,
            )

            // Switch track
            div(
                class="switch-track",
                style=switch_styles::track(props.size, props.checked, props.disabled, is_focused.get()),
            ) {
                // Switch thumb
                div(
                    class="switch-thumb",
                    style=switch_styles::thumb(props.size, props.checked),
                )
            }

            // Label
            if let Some(ref label) = props.label {
                span(class="switch-label", style=switch_styles::label(props.size, props.disabled)) {
                    { label.clone() }
                }
            }
        }
    }
}

mod switch_styles {
    use super::CheckboxSize;

    pub fn wrapper(disabled: bool) -> String {
        let cursor = if disabled { "not-allowed" } else { "pointer" };
        format!(
            r#"
                display: inline-flex;
                align-items: center;
                gap: var(--spacing-sm);
                cursor: {cursor};
                user-select: none;
            "#,
            cursor = cursor,
        )
    }

    pub fn track(size: CheckboxSize, checked: bool, disabled: bool, focused: bool) -> String {
        let (width, height) = match size {
            CheckboxSize::Sm => ("32px", "18px"),
            CheckboxSize::Md => ("40px", "22px"),
            CheckboxSize::Lg => ("48px", "26px"),
        };

        let bg_color = if checked {
            if disabled { "var(--color-primary-disabled)" } else { "var(--color-primary)" }
        } else {
            "var(--color-bg-tertiary)"
        };

        let opacity = if disabled { "0.5" } else { "1" };
        let focus_shadow = if focused && !disabled {
            "box-shadow: 0 0 0 2px var(--color-primary-alpha);"
        } else {
            ""
        };

        format!(
            r#"
                position: relative;
                width: {width};
                height: {height};
                background: {bg_color};
                border-radius: 9999px;
                opacity: {opacity};
                transition: var(--transition-fast);
                {focus_shadow}
            "#,
            width = width,
            height = height,
            bg_color = bg_color,
            opacity = opacity,
            focus_shadow = focus_shadow,
        )
    }

    pub fn thumb(size: CheckboxSize, checked: bool) -> String {
        let thumb_size = match size {
            CheckboxSize::Sm => "14px",
            CheckboxSize::Md => "18px",
            CheckboxSize::Lg => "22px",
        };

        let offset = "2px";
        let translate = if checked {
            match size {
                CheckboxSize::Sm => "14px",
                CheckboxSize::Md => "18px",
                CheckboxSize::Lg => "22px",
            }
        } else {
            "0"
        };

        format!(
            r#"
                position: absolute;
                top: {offset};
                left: {offset};
                width: {thumb_size};
                height: {thumb_size};
                background: var(--color-surface);
                border-radius: 50%;
                box-shadow: var(--shadow-sm);
                transform: translateX({translate});
                transition: var(--transition-fast);
            "#,
            offset = offset,
            thumb_size = thumb_size,
            translate = translate,
        )
    }

    pub fn label(size: CheckboxSize, disabled: bool) -> String {
        let font_size = match size {
            CheckboxSize::Sm => "var(--font-size-sm)",
            CheckboxSize::Md => "var(--font-size-base)",
            CheckboxSize::Lg => "var(--font-size-lg)",
        };
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                font-size: {font_size};
                font-weight: var(--font-weight-medium);
                color: var(--color-text-primary);
                opacity: {opacity};
            "#,
            font_size = font_size,
            opacity = opacity,
        )
    }
}
