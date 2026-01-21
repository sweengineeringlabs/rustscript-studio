//! Token preview component for live design token visualization.

use rsc::prelude::*;

/// Token preview category.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PreviewCategory {
    #[default]
    Colors,
    Spacing,
    Typography,
    Shadows,
    Radius,
}

/// Token preview props.
#[derive(Props)]
pub struct TokenPreviewProps {
    /// Which category to preview
    #[prop(default)]
    pub category: PreviewCategory,
    /// Design tokens as CSS variables (for injection)
    #[prop(default)]
    pub tokens: Vec<(String, String)>,
}

/// TokenPreview component for visualizing design tokens in context.
///
/// ## Example
/// ```rust,ignore
/// TokenPreview {
///     category: PreviewCategory::Colors,
///     tokens: vec![
///         ("--color-primary", "#3b82f6"),
///         ("--color-secondary", "#10b981"),
///     ],
/// }
/// ```
#[component]
pub fn TokenPreview(props: TokenPreviewProps) -> Element {
    // Build inline style from tokens
    let token_style = props.tokens.iter()
        .map(|(name, value)| format!("{}: {};", name, value))
        .collect::<Vec<_>>()
        .join(" ");

    rsx! {
        div(class="token-preview", style=styles::container(&token_style)) {
            match props.category {
                PreviewCategory::Colors => rsx! { ColorPreview {} },
                PreviewCategory::Spacing => rsx! { SpacingPreview {} },
                PreviewCategory::Typography => rsx! { TypographyPreview {} },
                PreviewCategory::Shadows => rsx! { ShadowPreview {} },
                PreviewCategory::Radius => rsx! { RadiusPreview {} },
            }
        }
    }
}

#[component]
fn ColorPreview() -> Element {
    rsx! {
        div(class="color-preview", style=styles::preview_grid()) {
            // Primary colors
            div(class="color-preview-section", style=styles::section()) {
                h4(style=styles::section_title()) { "Primary" }
                div(style=styles::color_row()) {
                    div(style=styles::color_swatch("var(--color-primary)"))
                    div(style=styles::color_swatch("var(--color-primary-hover)"))
                }
            }

            // Semantic colors
            div(class="color-preview-section", style=styles::section()) {
                h4(style=styles::section_title()) { "Semantic" }
                div(style=styles::color_row()) {
                    div(style=styles::color_swatch("var(--color-success)"))
                    div(style=styles::color_swatch("var(--color-warning)"))
                    div(style=styles::color_swatch("var(--color-error)"))
                    div(style=styles::color_swatch("var(--color-info)"))
                }
            }

            // Sample card
            div(class="color-preview-card", style=styles::sample_card()) {
                div(style=styles::card_header()) { "Sample Card" }
                p(style=styles::card_body()) {
                    "This card demonstrates how colors work together in a real component."
                }
                div(style=styles::card_actions()) {
                    button(style=styles::primary_button()) { "Primary" }
                    button(style=styles::secondary_button()) { "Secondary" }
                }
            }
        }
    }
}

#[component]
fn SpacingPreview() -> Element {
    let sizes = ["xs", "sm", "md", "lg", "xl", "2xl"];

    rsx! {
        div(class="spacing-preview", style=styles::preview_column()) {
            for size in sizes.iter() {
                div(style=styles::spacing_item()) {
                    span(style=styles::spacing_label()) { { format!("--spacing-{}", size) } }
                    div(style=styles::spacing_bar(*size))
                }
            }

            // Box model preview
            div(style=styles::box_model_preview()) {
                div(style=styles::box_outer()) {
                    span(style=styles::box_label()) { "margin" }
                    div(style=styles::box_inner()) {
                        span(style=styles::box_label()) { "padding" }
                        div(style=styles::box_content()) { "Content" }
                    }
                }
            }
        }
    }
}

#[component]
fn TypographyPreview() -> Element {
    rsx! {
        div(class="typography-preview", style=styles::preview_column()) {
            h1(style=styles::heading_1()) { "Heading 1" }
            h2(style=styles::heading_2()) { "Heading 2" }
            h3(style=styles::heading_3()) { "Heading 3" }
            p(style=styles::body_text()) {
                "Body text demonstrates the default reading experience. "
                strong { "Bold text" }
                " and "
                em { "italic text" }
                " provide emphasis."
            }
            p(style=styles::small_text()) {
                "Small text is used for captions and secondary information."
            }
            code(style=styles::code_text()) { "const code = 'monospace';" }
        }
    }
}

#[component]
fn ShadowPreview() -> Element {
    let shadows = ["sm", "md", "lg", "xl"];

    rsx! {
        div(class="shadow-preview", style=styles::shadow_grid()) {
            for shadow in shadows.iter() {
                div(style=styles::shadow_box(*shadow)) {
                    span { { format!("shadow-{}", shadow) } }
                }
            }
        }
    }
}

#[component]
fn RadiusPreview() -> Element {
    let radii = ["none", "sm", "md", "lg", "xl", "full"];

    rsx! {
        div(class="radius-preview", style=styles::radius_grid()) {
            for radius in radii.iter() {
                div(style=styles::radius_box(*radius)) {
                    span { { *radius } }
                }
            }
        }
    }
}

mod styles {
    pub fn container(token_style: &str) -> String {
        format!(
            r#"
                padding: var(--spacing-lg);
                background: var(--color-bg-secondary);
                border-radius: var(--radius-lg);
                {token_style}
            "#,
            token_style = token_style,
        )
    }

    pub fn preview_grid() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-lg);
        "#
    }

    pub fn preview_column() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-md);
        "#
    }

    pub fn section() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }

    pub fn section_title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-secondary);
        "#
    }

    pub fn color_row() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-sm);
        "#
    }

    pub fn color_swatch(color: &str) -> String {
        format!(
            r#"
                width: 48px;
                height: 48px;
                background: {color};
                border-radius: var(--radius-md);
                border: 1px solid var(--color-border);
            "#,
            color = color,
        )
    }

    pub fn sample_card() -> &'static str {
        r#"
            background: var(--color-surface);
            border-radius: var(--radius-lg);
            overflow: hidden;
            box-shadow: var(--shadow-md);
        "#
    }

    pub fn card_header() -> &'static str {
        r#"
            padding: var(--spacing-md);
            font-weight: var(--font-weight-semibold);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn card_body() -> &'static str {
        r#"
            margin: 0;
            padding: var(--spacing-md);
            color: var(--color-text-secondary);
        "#
    }

    pub fn card_actions() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-sm);
            padding: var(--spacing-md);
            border-top: 1px solid var(--color-border);
        "#
    }

    pub fn primary_button() -> &'static str {
        r#"
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-primary);
            color: white;
            border: none;
            border-radius: var(--radius-md);
            cursor: pointer;
        "#
    }

    pub fn secondary_button() -> &'static str {
        r#"
            padding: var(--spacing-sm) var(--spacing-md);
            background: transparent;
            color: var(--color-text-primary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            cursor: pointer;
        "#
    }

    pub fn spacing_item() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-md);
        "#
    }

    pub fn spacing_label() -> &'static str {
        r#"
            width: 120px;
            font-family: var(--font-mono);
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
        "#
    }

    pub fn spacing_bar(size: &str) -> String {
        format!(
            r#"
                height: 16px;
                width: var(--spacing-{size});
                background: var(--color-primary);
                border-radius: var(--radius-sm);
            "#,
            size = size,
        )
    }

    pub fn box_model_preview() -> &'static str {
        r#"
            margin-top: var(--spacing-lg);
        "#
    }

    pub fn box_outer() -> &'static str {
        r#"
            padding: var(--spacing-md);
            background: rgba(59, 130, 246, 0.2);
            border: 2px dashed var(--color-primary);
            border-radius: var(--radius-md);
            position: relative;
        "#
    }

    pub fn box_inner() -> &'static str {
        r#"
            padding: var(--spacing-md);
            background: rgba(16, 185, 129, 0.2);
            border: 2px dashed var(--color-success);
            border-radius: var(--radius-sm);
            position: relative;
        "#
    }

    pub fn box_content() -> &'static str {
        r#"
            padding: var(--spacing-md);
            background: var(--color-surface);
            border-radius: var(--radius-sm);
            text-align: center;
        "#
    }

    pub fn box_label() -> &'static str {
        r#"
            position: absolute;
            top: 4px;
            left: 8px;
            font-size: var(--font-size-xs);
            color: var(--color-text-muted);
        "#
    }

    pub fn heading_1() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-3xl);
            font-weight: var(--font-weight-bold);
        "#
    }

    pub fn heading_2() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-2xl);
            font-weight: var(--font-weight-semibold);
        "#
    }

    pub fn heading_3() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-xl);
            font-weight: var(--font-weight-medium);
        "#
    }

    pub fn body_text() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-base);
            line-height: var(--line-height-relaxed);
            color: var(--color-text-primary);
        "#
    }

    pub fn small_text() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn code_text() -> &'static str {
        r#"
            display: block;
            padding: var(--spacing-sm);
            background: var(--color-bg-tertiary);
            border-radius: var(--radius-md);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
        "#
    }

    pub fn shadow_grid() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: var(--spacing-lg);
        "#
    }

    pub fn shadow_box(shadow: &str) -> String {
        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                height: 80px;
                background: var(--color-surface);
                border-radius: var(--radius-md);
                box-shadow: var(--shadow-{shadow});
                font-size: var(--font-size-sm);
                color: var(--color-text-secondary);
            "#,
            shadow = shadow,
        )
    }

    pub fn radius_grid() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: var(--spacing-md);
        "#
    }

    pub fn radius_box(radius: &str) -> String {
        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                height: 64px;
                background: var(--color-primary);
                color: white;
                border-radius: var(--radius-{radius});
                font-size: var(--font-size-sm);
            "#,
            radius = radius,
        )
    }
}
