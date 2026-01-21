//! Checkbox component with label support.

use rsc::prelude::*;

/// Checkbox size.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CheckboxSize {
    Sm,
    Md,
    Lg,
}

impl Default for CheckboxSize {
    fn default() -> Self {
        CheckboxSize::Md
    }
}

/// Checkbox component with custom styling.
///
/// ## Example
/// ```rust,ignore
/// Checkbox(
///     checked: is_enabled.get(),
///     label: Some("Enable notifications".to_string()),
///     description: Some("Receive email updates".to_string()),
///     on_change: Some(Callback::new(move |v| is_enabled.set(v))),
/// )
/// ```
#[component]
pub fn Checkbox(
    checked: Option<bool>,
    indeterminate: Option<bool>,
    size: Option<CheckboxSize>,
    disabled: Option<bool>,
    error: Option<bool>,
    label: Option<String>,
    description: Option<String>,
    on_change: Option<Callback<bool>>,
    class: Option<String>,
) -> Element {
    let checked = checked.unwrap_or(false);
    let indeterminate = indeterminate.unwrap_or(false);
    let size = size.unwrap_or(CheckboxSize::Md);
    let disabled = disabled.unwrap_or(false);
    let error = error.unwrap_or(false);

    let (is_focused, set_focused) = use_state(false);
    let extra_class = class.unwrap_or_default();

    let handle_change = {
        let on_change = on_change.clone();
        move |_: InputEvent| {
            if let Some(ref callback) = on_change {
                callback.call(!checked);
            }
        }
    };

    let handle_focus = move |_: FocusEvent| {
        set_focused(true);
    };

    let handle_blur = move |_: FocusEvent| {
        set_focused(false);
    };

    let handle_click = {
        let on_change = on_change.clone();
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
            class: format!("checkbox-wrapper {}", extra_class),
            style: styles::wrapper(disabled),
            onclick: handle_click
        ) {
            // Hidden native checkbox for accessibility
            input(
                type: "checkbox",
                checked: checked,
                disabled: disabled,
                style: styles::hidden_input(),
                onchange: handle_change,
                onfocus: handle_focus,
                onblur: handle_blur
            )

            // Custom checkbox visual
            div(
                class: "checkbox-box",
                style: styles::box_style(size, checked, indeterminate, disabled, error, is_focused)
            ) {
                if checked {
                    // Checkmark icon
                    svg(
                        viewBox: "0 0 24 24",
                        fill: "none",
                        stroke: "currentColor",
                        stroke_width: "3",
                        style: styles::icon(size)
                    ) {
                        path(d: "M5 12l5 5L20 7")
                    }
                } else if indeterminate {
                    // Indeterminate line
                    svg(
                        viewBox: "0 0 24 24",
                        fill: "none",
                        stroke: "currentColor",
                        stroke_width: "3",
                        style: styles::icon(size)
                    ) {
                        path(d: "M5 12h14")
                    }
                }
            }

            // Label and description
            if label.is_some() || description.is_some() {
                div(class: "checkbox-content", style: styles::content()) {
                    if let Some(ref lbl) = label {
                        span(class: "checkbox-label", style: styles::label(size, disabled)) {
                            {lbl.clone()}
                        }
                    }
                    if let Some(ref desc) = description {
                        span(class: "checkbox-description", style: styles::description(disabled)) {
                            {desc.clone()}
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
                cursor: {};
                user-select: none;
            "#,
            cursor
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
                width: {};
                height: {};
            "#,
            icon_size, icon_size
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
                font-size: {};
                font-weight: var(--font-weight-medium);
                color: var(--color-text-primary);
                opacity: {};
            "#,
            font_size, opacity
        )
    }

    pub fn description(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                font-size: var(--font-size-sm);
                color: var(--color-text-secondary);
                opacity: {};
            "#,
            opacity
        )
    }
}

/// Switch component (toggle style).
///
/// ## Example
/// ```rust,ignore
/// Switch(
///     checked: dark_mode.get(),
///     label: Some("Dark mode".to_string()),
///     on_change: Some(Callback::new(move |v| dark_mode.set(v))),
/// )
/// ```
#[component]
pub fn Switch(
    checked: Option<bool>,
    size: Option<CheckboxSize>,
    disabled: Option<bool>,
    label: Option<String>,
    on_change: Option<Callback<bool>>,
    class: Option<String>,
) -> Element {
    let checked = checked.unwrap_or(false);
    let size = size.unwrap_or(CheckboxSize::Md);
    let disabled = disabled.unwrap_or(false);

    let (is_focused, set_focused) = use_state(false);
    let extra_class = class.unwrap_or_default();

    let handle_click = {
        let on_change = on_change.clone();
        move |_: MouseEvent| {
            if !disabled {
                if let Some(ref callback) = on_change {
                    callback.call(!checked);
                }
            }
        }
    };

    let handle_focus = move |_: FocusEvent| {
        set_focused(true);
    };

    let handle_blur = move |_: FocusEvent| {
        set_focused(false);
    };

    rsx! {
        label(
            class: format!("switch-wrapper {}", extra_class),
            style: switch_styles::wrapper(disabled),
            onclick: handle_click
        ) {
            // Hidden native checkbox for accessibility
            input(
                type: "checkbox",
                checked: checked,
                disabled: disabled,
                style: styles::hidden_input(),
                onfocus: handle_focus,
                onblur: handle_blur
            )

            // Switch track
            div(
                class: "switch-track",
                style: switch_styles::track(size, checked, disabled, is_focused)
            ) {
                // Switch thumb
                div(
                    class: "switch-thumb",
                    style: switch_styles::thumb(size, checked)
                )
            }

            // Label
            if let Some(ref lbl) = label {
                span(class: "switch-label", style: switch_styles::label(size, disabled)) {
                    {lbl.clone()}
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
                cursor: {};
                user-select: none;
            "#,
            cursor
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
                font-size: {};
                font-weight: var(--font-weight-medium);
                color: var(--color-text-primary);
                opacity: {};
            "#,
            font_size, opacity
        )
    }
}
