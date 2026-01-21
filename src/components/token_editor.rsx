//! Token editor component for visual CSS token editing.

use rsc::prelude::*;

use rsc_studio::designer::css::{DesignTokens, TokenCategory, TokenValue};
use super::Icon;

/// Token editor component props.
#[derive(Props)]
pub struct TokenEditorProps {
    pub tokens: Signal<DesignTokens>,
    pub category: TokenCategory,
    #[prop(into)]
    pub on_change: Callback<(String, TokenValue)>,
}

/// Token editor component.
#[component]
pub fn TokenEditor(props: TokenEditorProps) -> Element {
    let tokens = props.tokens.get();

    let items: Vec<(String, TokenValue)> = match props.category {
        TokenCategory::Colors => tokens
            .colors
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Spacing => tokens
            .spacing
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Radius => tokens
            .radius
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Shadows => tokens
            .shadows
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
        TokenCategory::Typography => tokens
            .typography
            .fonts
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect(),
    };

    rsx! {
        div(class="token-editor", style=styles::container()) {
            for (name, value) in items {
                TokenRow {
                    name: name.clone(),
                    value: value.clone(),
                    category: props.category,
                    on_change: props.on_change.clone(),
                }
            }
        }
    }
}

#[derive(Props)]
struct TokenRowProps {
    name: String,
    value: TokenValue,
    category: TokenCategory,
    #[prop(into)]
    on_change: Callback<(String, TokenValue)>,
}

#[component]
fn TokenRow(props: TokenRowProps) -> Element {
    let expanded = use_signal(|| false);

    rsx! {
        div(class="token-row", style=styles::row()) {
            // Token name and preview
            div(
                class="token-header",
                style=styles::row_header(),
                on:click=move |_| expanded.update(|v| *v = !*v),
            ) {
                match props.category {
                    TokenCategory::Colors => {
                        ColorPreview { value: props.value.clone() }
                    }
                    _ => {
                        Icon { name: "hash".to_string(), size: 16 }
                    }
                }

                span(class="token-name", style=styles::token_name()) {
                    { props.name.clone() }
                }

                span(class="token-value-preview", style=styles::value_preview()) {
                    { format_value_preview(&props.value) }
                }

                Icon {
                    name: if expanded.get() { "chevron-up" } else { "chevron-down" }.to_string(),
                    size: 16,
                }
            }

            // Expanded editor
            if expanded.get() {
                div(class="token-editor-content", style=styles::editor_content()) {
                    match props.value.clone() {
                        TokenValue::Simple(v) => {
                            SimpleValueEditor {
                                name: props.name.clone(),
                                value: v,
                                category: props.category,
                                on_change: props.on_change.clone(),
                            }
                        }
                        TokenValue::Adaptive { light, dark } => {
                            AdaptiveValueEditor {
                                name: props.name.clone(),
                                light: light,
                                dark: dark,
                                category: props.category,
                                on_change: props.on_change.clone(),
                            }
                        }
                        TokenValue::Scale(scale) => {
                            ScaleValueEditor {
                                name: props.name.clone(),
                                scale: scale,
                                on_change: props.on_change.clone(),
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Color preview swatch.
#[derive(Props)]
struct ColorPreviewProps {
    value: TokenValue,
}

#[component]
fn ColorPreview(props: ColorPreviewProps) -> Element {
    let color = match &props.value {
        TokenValue::Simple(v) => v.clone(),
        TokenValue::Adaptive { light, .. } => light.clone(),
        TokenValue::Scale(s) => s.values().next().cloned().unwrap_or_default(),
    };

    rsx! {
        div(
            class="color-preview",
            style=styles::color_swatch(&color),
        )
    }
}

/// Simple value editor (single input).
#[derive(Props)]
struct SimpleValueEditorProps {
    name: String,
    value: String,
    category: TokenCategory,
    #[prop(into)]
    on_change: Callback<(String, TokenValue)>,
}

#[component]
fn SimpleValueEditor(props: SimpleValueEditorProps) -> Element {
    let value = use_signal(|| props.value.clone());

    rsx! {
        div(class="simple-editor", style=styles::simple_editor()) {
            if props.category == TokenCategory::Colors {
                input(
                    type="color",
                    value=value.get(),
                    style=styles::color_input(),
                    on:change=move |e: Event<FormData>| {
                        let new_val = e.value();
                        value.set(new_val.clone());
                        props.on_change.call((
                            props.name.clone(),
                            TokenValue::Simple(new_val),
                        ));
                    },
                )
            }

            input(
                type="text",
                value=value.get(),
                style=styles::text_input(),
                on:change=move |e: Event<FormData>| {
                    let new_val = e.value();
                    value.set(new_val.clone());
                    props.on_change.call((
                        props.name.clone(),
                        TokenValue::Simple(new_val),
                    ));
                },
            )
        }
    }
}

/// Adaptive value editor (light/dark inputs).
#[derive(Props)]
struct AdaptiveValueEditorProps {
    name: String,
    light: String,
    dark: String,
    category: TokenCategory,
    #[prop(into)]
    on_change: Callback<(String, TokenValue)>,
}

#[component]
fn AdaptiveValueEditor(props: AdaptiveValueEditorProps) -> Element {
    let light = use_signal(|| props.light.clone());
    let dark = use_signal(|| props.dark.clone());

    let emit_change = move || {
        props.on_change.call((
            props.name.clone(),
            TokenValue::Adaptive {
                light: light.get(),
                dark: dark.get(),
            },
        ));
    };

    rsx! {
        div(class="adaptive-editor", style=styles::adaptive_editor()) {
            div(class="mode-row") {
                Icon { name: "sun".to_string(), size: 16 }
                label { "Light" }
                input(
                    type="text",
                    value=light.get(),
                    style=styles::text_input(),
                    on:change=move |e: Event<FormData>| {
                        light.set(e.value());
                        emit_change();
                    },
                )
            }

            div(class="mode-row") {
                Icon { name: "moon".to_string(), size: 16 }
                label { "Dark" }
                input(
                    type="text",
                    value=dark.get(),
                    style=styles::text_input(),
                    on:change=move |e: Event<FormData>| {
                        dark.set(e.value());
                        emit_change();
                    },
                )
            }
        }
    }
}

/// Scale value editor.
#[derive(Props)]
struct ScaleValueEditorProps {
    name: String,
    scale: indexmap::IndexMap<String, String>,
    #[prop(into)]
    on_change: Callback<(String, TokenValue)>,
}

#[component]
fn ScaleValueEditor(props: ScaleValueEditorProps) -> Element {
    rsx! {
        div(class="scale-editor", style=styles::scale_editor()) {
            for (key, value) in props.scale.iter() {
                div(class="scale-row", style=styles::scale_row()) {
                    span(class="scale-key") { { key.clone() } }
                    input(
                        type="text",
                        value=value.clone(),
                        style=styles::text_input(),
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
