//! ShadowEditor component for editing box-shadow design tokens.

use rsc::prelude::*;

use super::{Input, InputSize};

/// Parsed shadow value.
#[derive(Debug, Clone, Default)]
pub struct ShadowValue {
    pub x: f64,
    pub y: f64,
    pub blur: f64,
    pub spread: f64,
    pub color: String,
    pub inset: bool,
}

impl ShadowValue {
    pub fn new(x: f64, y: f64, blur: f64, spread: f64, color: &str) -> Self {
        Self {
            x,
            y,
            blur,
            spread,
            color: color.to_string(),
            inset: false,
        }
    }

    pub fn inset(mut self) -> Self {
        self.inset = true;
        self
    }

    pub fn to_css(&self) -> String {
        let inset = if self.inset { "inset " } else { "" };
        format!(
            "{}{}px {}px {}px {}px {}",
            inset, self.x, self.y, self.blur, self.spread, self.color
        )
    }

    pub fn from_css(css: &str) -> Option<Self> {
        let css = css.trim();
        let (inset, rest) = if css.starts_with("inset") {
            (true, css.strip_prefix("inset").unwrap().trim())
        } else {
            (false, css)
        };

        // Simple parsing - assumes format: Xpx Ypx Blur Spread Color
        let parts: Vec<&str> = rest.split_whitespace().collect();
        if parts.len() < 4 {
            return None;
        }

        let parse_px = |s: &str| -> Option<f64> {
            s.trim_end_matches("px").parse().ok()
        };

        let x = parse_px(parts[0])?;
        let y = parse_px(parts[1])?;
        let blur = parse_px(parts[2])?;
        let spread = if parts.len() > 4 {
            parse_px(parts[3])?
        } else {
            0.0
        };
        let color_idx = if parts.len() > 4 { 4 } else { 3 };
        let color = parts[color_idx..].join(" ");

        Some(ShadowValue {
            x,
            y,
            blur,
            spread,
            color,
            inset,
        })
    }
}

/// ShadowEditor component props.
#[derive(Props)]
pub struct ShadowEditorProps {
    /// Current shadow value (CSS format)
    pub value: String,
    /// Label for the shadow
    #[prop(default)]
    pub label: Option<String>,
    /// Whether the editor is disabled
    #[prop(default)]
    pub disabled: bool,
    /// Callback when value changes
    #[prop(default)]
    pub on_change: Option<Callback<String>>,
}

/// ShadowEditor component for editing box-shadow values.
///
/// ## Example
/// ```rust,ignore
/// ShadowEditor {
///     value: shadow.get(),
///     label: Some("Card Shadow".to_string()),
///     on_change: Callback::new(move |v| shadow.set(v)),
/// }
/// ```
#[component]
pub fn ShadowEditor(props: ShadowEditorProps) -> Element {
    let shadow = use_signal(|| ShadowValue::from_css(&props.value).unwrap_or_default());

    let emit_change = {
        let on_change = props.on_change.clone();
        move |new_shadow: ShadowValue| {
            shadow.set(new_shadow.clone());
            if let Some(ref callback) = on_change {
                callback.call(new_shadow.to_css());
            }
        }
    };

    let on_x_change = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Ok(x) = e.value().parse::<f64>() {
                let mut s = shadow.get();
                s.x = x;
                emit_change(s);
            }
        }
    };

    let on_y_change = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Ok(y) = e.value().parse::<f64>() {
                let mut s = shadow.get();
                s.y = y;
                emit_change(s);
            }
        }
    };

    let on_blur_change = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Ok(blur) = e.value().parse::<f64>() {
                let mut s = shadow.get();
                s.blur = blur;
                emit_change(s);
            }
        }
    };

    let on_spread_change = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Ok(spread) = e.value().parse::<f64>() {
                let mut s = shadow.get();
                s.spread = spread;
                emit_change(s);
            }
        }
    };

    let on_color_change = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            let mut s = shadow.get();
            s.color = e.value();
            emit_change(s);
        }
    };

    let on_inset_change = {
        let emit_change = emit_change.clone();
        move |_: InputEvent| {
            let mut s = shadow.get();
            s.inset = !s.inset;
            emit_change(s);
        }
    };

    let current = shadow.get();

    rsx! {
        div(class="shadow-editor", style=styles::container(props.disabled)) {
            // Label
            if let Some(ref label) = props.label {
                label(class="shadow-editor-label", style=styles::label()) {
                    { label.clone() }
                }
            }

            // Preview
            div(class="shadow-editor-preview", style=styles::preview_container()) {
                div(class="shadow-editor-preview-box", style=styles::preview_box(&current))
            }

            // Controls grid
            div(class="shadow-editor-controls", style=styles::controls()) {
                // X offset
                div(class="shadow-editor-field", style=styles::field()) {
                    label(style=styles::field_label()) { "X" }
                    input(
                        type="number",
                        value=current.x.to_string(),
                        disabled=props.disabled,
                        style=styles::number_input(),
                        on:input=on_x_change,
                    )
                }

                // Y offset
                div(class="shadow-editor-field", style=styles::field()) {
                    label(style=styles::field_label()) { "Y" }
                    input(
                        type="number",
                        value=current.y.to_string(),
                        disabled=props.disabled,
                        style=styles::number_input(),
                        on:input=on_y_change,
                    )
                }

                // Blur
                div(class="shadow-editor-field", style=styles::field()) {
                    label(style=styles::field_label()) { "Blur" }
                    input(
                        type="number",
                        min="0",
                        value=current.blur.to_string(),
                        disabled=props.disabled,
                        style=styles::number_input(),
                        on:input=on_blur_change,
                    )
                }

                // Spread
                div(class="shadow-editor-field", style=styles::field()) {
                    label(style=styles::field_label()) { "Spread" }
                    input(
                        type="number",
                        value=current.spread.to_string(),
                        disabled=props.disabled,
                        style=styles::number_input(),
                        on:input=on_spread_change,
                    )
                }
            }

            // Color input
            div(class="shadow-editor-color", style=styles::color_row()) {
                label(style=styles::field_label()) { "Color" }
                input(
                    type="text",
                    value=current.color.clone(),
                    disabled=props.disabled,
                    style=styles::color_input(),
                    on:input=on_color_change,
                )
            }

            // Inset toggle
            div(class="shadow-editor-inset", style=styles::inset_row()) {
                label(style=styles::checkbox_label()) {
                    input(
                        type="checkbox",
                        checked=current.inset,
                        disabled=props.disabled,
                        on:change=on_inset_change,
                    )
                    span { "Inset shadow" }
                }
            }

            // CSS output
            div(class="shadow-editor-output", style=styles::output()) {
                code(style=styles::code()) { { current.to_css() } }
            }
        }
    }
}

mod styles {
    use super::ShadowValue;

    pub fn container(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                display: flex;
                flex-direction: column;
                gap: var(--spacing-md);
                opacity: {opacity};
            "#,
            opacity = opacity,
        )
    }

    pub fn label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-primary);
        "#
    }

    pub fn preview_container() -> &'static str {
        r#"
            display: flex;
            justify-content: center;
            padding: var(--spacing-xl);
            background: var(--color-bg-secondary);
            border-radius: var(--radius-md);
        "#
    }

    pub fn preview_box(shadow: &ShadowValue) -> String {
        format!(
            r#"
                width: 80px;
                height: 80px;
                background: var(--color-surface);
                border-radius: var(--radius-md);
                box-shadow: {shadow};
            "#,
            shadow = shadow.to_css(),
        )
    }

    pub fn controls() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: var(--spacing-sm);
        "#
    }

    pub fn field() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn field_label() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
        "#
    }

    pub fn number_input() -> &'static str {
        r#"
            height: 32px;
            padding: 0 var(--spacing-sm);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-surface);
            color: var(--color-text-primary);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
            text-align: center;
        "#
    }

    pub fn color_row() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn color_input() -> &'static str {
        r#"
            height: 32px;
            padding: 0 var(--spacing-sm);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-surface);
            color: var(--color-text-primary);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
        "#
    }

    pub fn inset_row() -> &'static str {
        r#"
            display: flex;
            align-items: center;
        "#
    }

    pub fn checkbox_label() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            font-size: var(--font-size-sm);
            color: var(--color-text-primary);
            cursor: pointer;
        "#
    }

    pub fn output() -> &'static str {
        r#"
            padding: var(--spacing-sm);
            background: var(--color-bg-secondary);
            border-radius: var(--radius-md);
            overflow-x: auto;
        "#
    }

    pub fn code() -> &'static str {
        r#"
            font-family: var(--font-mono);
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
        "#
    }
}
