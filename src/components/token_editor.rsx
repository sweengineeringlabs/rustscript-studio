//! Token editor component for visual CSS token editing.

use rsc::prelude::*;

use rsc_studio::designer::css::{DesignTokens, TokenCategory, TokenValue};
use super::Icon;

/// Token editor component.
#[component]
pub fn TokenEditor(
    tokens: Signal<DesignTokens>,
    category: TokenCategory,
    on_change: Callback<(String, TokenValue)>,
) -> Element {
    let tokens_data = tokens.get();

    let items: Vec<(String, TokenValue)> = match category {
        TokenCategory::Colors => tokens_data
            .colors
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Spacing => tokens_data
            .spacing
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Radius => tokens_data
            .radius
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Shadows => tokens_data
            .shadows
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Typography => tokens_data
            .typography
            .fonts
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
    };

    rsx! {
        div(class: "token-editor", style: styles::container()) {
            for (name, value) in items {
                TokenRow {
                    name: name.clone(),
                    value: value.clone(),
                    category: category,
                    on_change: on_change.clone(),
                }
            }
        }
    }
}

#[component]
fn TokenRow(
    name: String,
    value: TokenValue,
    category: TokenCategory,
    on_change: Callback<(String, TokenValue)>,
) -> Element {
    let expanded = use_signal(|| false);

    rsx! {
        div(class: "token-row", style: styles::row()) {
            // Token name and preview
            div(
                class: "token-header",
                style: styles::row_header(),
                onclick: move |_| expanded.update(|v| *v = !*v),
            ) {
                match category {
                    TokenCategory::Colors => {
                        ColorPreview { value: value.clone() }
                    }
                    _ => {
                        Icon { name: "hash".to_string(), size: 16 }
                    }
                }

                span(class: "token-name", style: styles::token_name()) {
                    { name.clone() }
                }

                span(class: "token-value-preview", style: styles::value_preview()) {
                    { format_value_preview(&value) }
                }

                Icon {
                    name: if expanded.get() { "chevron-up" } else { "chevron-down" }.to_string(),
                    size: 16,
                }
            }

            // Expanded editor
            if expanded.get() {
                div(class: "token-editor-content", style: styles::editor_content()) {
                    match value.clone() {
                        TokenValue::Simple(v) => {
                            SimpleValueEditor {
                                name: name.clone(),
                                value: v,
                                category: category,
                                on_change: on_change.clone(),
                            }
                        }
                        TokenValue::Adaptive { light, dark } => {
                            AdaptiveValueEditor {
                                name: name.clone(),
                                light: light,
                                dark: dark,
                                category: category,
                                on_change: on_change.clone(),
                            }
                        }
                        TokenValue::Scale(scale) => {
                            ScaleValueEditor {
                                name: name.clone(),
                                scale: scale,
                                on_change: on_change.clone(),
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Color preview swatch.
#[component]
fn ColorPreview(value: TokenValue) -> Element {
    let color = match &value {
        TokenValue::Simple(v) => v.clone(),
        TokenValue::Adaptive { light, .. } => light.clone(),
        TokenValue::Scale(s) => s.values().next().cloned().unwrap_or_default(),
    };

    rsx! {
        div(
            class: "color-preview",
            style: styles::color_swatch(&color),
        )
    }
}

/// Simple value editor (single input).
#[component]
fn SimpleValueEditor(
    name: String,
    value: String,
    category: TokenCategory,
    on_change: Callback<(String, TokenValue)>,
) -> Element {
    let value_signal = use_signal(|| value.clone());

    rsx! {
        div(class: "simple-editor", style: styles::simple_editor()) {
            if category == TokenCategory::Colors {
                input(
                    type: "color",
                    value: value_signal.get(),
                    style: styles::color_input(),
                    onchange: move |e: Event<FormData>| {
                        let new_val = e.value();
                        value_signal.set(new_val.clone());
                        on_change.call((
                            name.clone(),
                            TokenValue::Simple(new_val),
                        ));
                    },
                )
            }

            input(
                type: "text",
                value: value_signal.get(),
                style: styles::text_input(),
                onchange: move |e: Event<FormData>| {
                    let new_val = e.value();
                    value_signal.set(new_val.clone());
                    on_change.call((
                        name.clone(),
                        TokenValue::Simple(new_val),
                    ));
                },
            )
        }
    }
}

/// Adaptive value editor (light/dark inputs).
#[component]
fn AdaptiveValueEditor(
    name: String,
    light: String,
    dark: String,
    category: TokenCategory,
    on_change: Callback<(String, TokenValue)>,
) -> Element {
    let light_signal = use_signal(|| light.clone());
    let dark_signal = use_signal(|| dark.clone());

    let emit_change = move || {
        on_change.call((
            name.clone(),
            TokenValue::Adaptive {
                light: light_signal.get(),
                dark: dark_signal.get(),
            },
        ));
    };

    rsx! {
        div(class: "adaptive-editor", style: styles::adaptive_editor()) {
            div(class: "mode-row") {
                Icon { name: "sun".to_string(), size: 16 }
                label { "Light" }
                input(
                    type: "text",
                    value: light_signal.get(),
                    style: styles::text_input(),
                    onchange: move |e: Event<FormData>| {
                        light_signal.set(e.value());
                        emit_change();
                    },
                )
            }

            div(class: "mode-row") {
                Icon { name: "moon".to_string(), size: 16 }
                label { "Dark" }
                input(
                    type: "text",
                    value: dark_signal.get(),
                    style: styles::text_input(),
                    onchange: move |e: Event<FormData>| {
                        dark_signal.set(e.value());
                        emit_change();
                    },
                )
            }
        }
    }
}

/// Scale value editor.
#[component]
fn ScaleValueEditor(
    name: String,
    scale: indexmap::IndexMap<String, String>,
    on_change: Callback<(String, TokenValue)>,
) -> Element {
    rsx! {
        div(class: "scale-editor", style: styles::scale_editor()) {
            for (key, value) in scale.iter() {
                div(class: "scale-row", style: styles::scale_row()) {
                    span(class: "scale-key") { { key.clone() } }
                    input(
                        type: "text",
                        value: value.clone(),
                        style: styles::text_input(),
                    )
                }
            }
        }
    }
}

fn format_value_preview(value: &TokenValue) -> String {
    match value {
        TokenValue::Simple(v) => v.clone(),
        TokenValue::Adaptive { light, .. } => format!("{} (adaptive)", light),
        TokenValue::Scale(s) => format!("{} values", s.len()),
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn row() -> &'static str {
        r#"
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            overflow: hidden;
        "#
    }

    pub fn row_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn token_name() -> &'static str {
        r#"
            font-weight: var(--font-weight-medium);
            color: var(--color-text-primary);
        "#
    }

    pub fn value_preview() -> &'static str {
        r#"
            flex: 1;
            text-align: right;
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn editor_content() -> &'static str {
        r#"
            padding: var(--spacing-md);
            border-top: 1px solid var(--color-border);
            background: var(--color-bg-secondary);
        "#
    }

    pub fn color_swatch(color: &str) -> String {
        format!(
            r#"
                width: 24px;
                height: 24px;
                border-radius: var(--radius-sm);
                border: 1px solid var(--color-border);
                background: {};
            "#,
            color
        )
    }

    pub fn simple_editor() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
        "#
    }

    pub fn color_input() -> &'static str {
        r#"
            width: 48px;
            height: 32px;
            padding: 0;
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
            cursor: pointer;
        "#
    }

    pub fn text_input() -> &'static str {
        r#"
            flex: 1;
            height: 32px;
            padding: 0 var(--spacing-sm);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
            color: var(--color-text-primary);
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
        "#
    }

    pub fn adaptive_editor() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }

    pub fn scale_editor() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn scale_row() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
        "#
    }
}
