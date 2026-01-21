//! CSS designer page - visual design token editor.

use rsc::prelude::*;

use rsc_studio::designer::css::{TokenCategory, TokenValue, PreviewMode};

use crate::components::{TokenEditor, Toolbar, ToolbarGroup, ToolbarButton, ToolbarDivider, Button, ButtonVariant, Icon, Tabs, Tab};
use crate::hooks::StudioStore;

/// CSS designer page props.
#[derive(Props)]
pub struct CssDesignerPageProps {
    pub store: StudioStore,
}

/// CSS designer page.
#[component]
pub fn CssDesignerPage(props: CssDesignerPageProps) -> Element {
    let selected_category = use_signal(|| TokenCategory::Colors);
    let preview_mode = use_signal(|| PreviewMode::Both);
    let tokens = props.store.design_tokens();

    let categories = vec![
        Tab {
            id: "colors".to_string(),
            label: "Colors".to_string(),
            icon: Some("palette".to_string()),
        },
        Tab {
            id: "spacing".to_string(),
            label: "Spacing".to_string(),
            icon: Some("maximize".to_string()),
        },
        Tab {
            id: "radius".to_string(),
            label: "Radius".to_string(),
            icon: Some("circle".to_string()),
        },
        Tab {
            id: "shadows".to_string(),
            label: "Shadows".to_string(),
            icon: Some("layers".to_string()),
        },
        Tab {
            id: "typography".to_string(),
            label: "Typography".to_string(),
            icon: Some("type".to_string()),
        },
    ];

    let active_tab = use_signal(|| "colors".to_string());

    // Update selected category when tab changes
    let on_tab_change = move |id: String| {
        active_tab.set(id.clone());
        let category = match id.as_str() {
            "colors" => TokenCategory::Colors,
            "spacing" => TokenCategory::Spacing,
            "radius" => TokenCategory::Radius,
            "shadows" => TokenCategory::Shadows,
            "typography" => TokenCategory::Typography,
            _ => TokenCategory::Colors,
        };
        selected_category.set(category);
    };

    let on_token_change = {
        let store = props.store.clone();
        move |(path, value): (String, TokenValue)| {
            let full_path = format!("{}.{}", active_tab.get(), path);
            store.update_token(&full_path, value);
        }
    };

    rsx! {
        div(class="css-designer-page", style=styles::container()) {
            // Toolbar
            Toolbar {
                ToolbarGroup {
                    ToolbarButton {
                        icon: "sun".to_string(),
                        label: Some("Light".to_string()),
                        active: preview_mode.get() == PreviewMode::Light,
                        on_click: move |_| preview_mode.set(PreviewMode::Light),
                    }
                    ToolbarButton {
                        icon: "moon".to_string(),
                        label: Some("Dark".to_string()),
                        active: preview_mode.get() == PreviewMode::Dark,
                        on_click: move |_| preview_mode.set(PreviewMode::Dark),
                    }
                    ToolbarButton {
                        icon: "columns".to_string(),
                        label: Some("Both".to_string()),
                        active: preview_mode.get() == PreviewMode::Both,
                        on_click: move |_| preview_mode.set(PreviewMode::Both),
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "download".to_string(),
                        label: Some("Export".to_string()),
                        on_click: move |_| {
                            // Export tokens to YAML
                        },
                    }
                    ToolbarButton {
                        icon: "upload".to_string(),
                        label: Some("Import".to_string()),
                        on_click: move |_| {
                            // Import tokens from YAML
                        },
                    }
                }
            }

            // Main content area
            div(class="css-designer-content", style=styles::content()) {
                // Token editor panel
                div(class="token-panel", style=styles::token_panel()) {
                    Tabs {
                        tabs: categories,
                        active: active_tab.clone(),
                        on_change: on_tab_change,
                    }

                    div(class="token-list", style=styles::token_list()) {
                        TokenEditor {
                            tokens: tokens.clone(),
                            category: selected_category.get(),
                            on_change: on_token_change,
                        }
                    }
                }

                // Preview panel
                div(class="preview-panel", style=styles::preview_panel()) {
                    h3(style=styles::preview_title()) { "Preview" }

                    match preview_mode.get() {
                        PreviewMode::Light => {
                            PreviewPane {
                                mode: PreviewMode::Light,
                                tokens: tokens.clone(),
                            }
                        }
                        PreviewMode::Dark => {
                            PreviewPane {
                                mode: PreviewMode::Dark,
                                tokens: tokens.clone(),
                            }
                        }
                        PreviewMode::Both => {
                            div(class="preview-split", style=styles::preview_split()) {
                                PreviewPane {
                                    mode: PreviewMode::Light,
                                    tokens: tokens.clone(),
                                }
                                PreviewPane {
                                    mode: PreviewMode::Dark,
                                    tokens: tokens.clone(),
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Preview pane component.
#[derive(Props)]
struct PreviewPaneProps {
    mode: PreviewMode,
    tokens: Signal<rsc_studio::designer::css::DesignTokens>,
}

#[component]
fn PreviewPane(props: PreviewPaneProps) -> Element {
    let mode_label = match props.mode {
        PreviewMode::Light => "Light Mode",
        PreviewMode::Dark => "Dark Mode",
        PreviewMode::Both => "Preview",
    };

    let bg_class = match props.mode {
        PreviewMode::Light => "light",
        PreviewMode::Dark => "dark",
        PreviewMode::Both => "light",
    };

    rsx! {
        div(class=format!("preview-pane preview-pane-{}", bg_class), style=styles::preview_pane(&props.mode)) {
            span(class="preview-mode-label", style=styles::mode_label()) {
                { mode_label }
            }

            // Sample UI elements
            div(class="preview-elements", style=styles::preview_elements()) {
                // Buttons
                div(class="preview-section") {
                    h4 { "Buttons" }
                    div(style=styles::preview_row()) {
                        button(style=styles::sample_button_primary()) { "Primary" }
                        button(style=styles::sample_button_secondary()) { "Secondary" }
                        button(style=styles::sample_button_ghost()) { "Ghost" }
                    }
                }

                // Colors
                div(class="preview-section") {
                    h4 { "Color Swatches" }
                    div(style=styles::color_swatches()) {
                        div(style=styles::swatch("var(--color-primary)"))
                        div(style=styles::swatch("var(--color-success)"))
                        div(style=styles::swatch("var(--color-warning)"))
                        div(style=styles::swatch("var(--color-error)"))
                    }
                }

                // Card
                div(class="preview-section") {
                    h4 { "Card" }
                    div(style=styles::sample_card()) {
                        h5 { "Card Title" }
                        p { "This is a sample card component." }
                    }
                }

                // Input
                div(class="preview-section") {
                    h4 { "Input" }
                    input(
                        type="text",
                        placeholder="Sample input...",
                        style=styles::sample_input(),
                    )
                }
            }
        }
    }
}

mod styles {
    use rsc_studio::designer::css::PreviewMode;

    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            height: 100%;
        "#
    }

    pub fn content() -> &'static str {
        r#"
            flex: 1;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: var(--spacing-md);
            padding: var(--spacing-md);
            overflow: hidden;
        "#
    }

    pub fn token_panel() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        "#
    }

    pub fn token_list() -> &'static str {
        r#"
            flex: 1;
            overflow-y: auto;
            padding: var(--spacing-md);
        "#
    }

    pub fn preview_panel() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        "#
    }

    pub fn preview_title() -> &'static str {
        r#"
            margin: 0;
            padding: var(--spacing-sm) var(--spacing-md);
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-semibold);
            text-transform: uppercase;
            color: var(--color-text-secondary);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn preview_split() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: 1fr 1fr;
            flex: 1;
        "#
    }

    pub fn preview_pane(mode: &PreviewMode) -> String {
        let bg = match mode {
            PreviewMode::Light => "#ffffff",
            PreviewMode::Dark => "#0f172a",
            PreviewMode::Both => "#ffffff",
        };

        let color = match mode {
            PreviewMode::Light => "#0f172a",
            PreviewMode::Dark => "#f8fafc",
            PreviewMode::Both => "#0f172a",
        };

        format!(
            r#"
                flex: 1;
                padding: var(--spacing-md);
                background: {};
                color: {};
                overflow-y: auto;
            "#,
            bg, color
        )
    }

    pub fn mode_label() -> &'static str {
        r#"
            display: block;
            font-size: var(--font-size-xs);
            font-weight: var(--font-weight-semibold);
            text-transform: uppercase;
            margin-bottom: var(--spacing-md);
            opacity: 0.5;
        "#
    }

    pub fn preview_elements() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-lg);
        "#
    }

    pub fn preview_row() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-sm);
        "#
    }

    pub fn sample_button_primary() -> &'static str {
        r#"
            padding: 8px 16px;
            background: var(--color-primary, #3b82f6);
            color: white;
            border: none;
            border-radius: var(--radius-md, 6px);
            cursor: pointer;
        "#
    }

    pub fn sample_button_secondary() -> &'static str {
        r#"
            padding: 8px 16px;
            background: transparent;
            color: inherit;
            border: 1px solid var(--color-border, #e2e8f0);
            border-radius: var(--radius-md, 6px);
            cursor: pointer;
        "#
    }

    pub fn sample_button_ghost() -> &'static str {
        r#"
            padding: 8px 16px;
            background: transparent;
            color: inherit;
            border: none;
            border-radius: var(--radius-md, 6px);
            cursor: pointer;
            opacity: 0.7;
        "#
    }

    pub fn color_swatches() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-sm);
        "#
    }

    pub fn swatch(color: &str) -> String {
        format!(
            r#"
                width: 40px;
                height: 40px;
                border-radius: var(--radius-md, 6px);
                background: {};
                border: 1px solid rgba(0, 0, 0, 0.1);
            "#,
            color
        )
    }

    pub fn sample_card() -> &'static str {
        r#"
            padding: var(--spacing-md, 16px);
            background: var(--color-surface, inherit);
            border: 1px solid var(--color-border, #e2e8f0);
            border-radius: var(--radius-lg, 8px);
            box-shadow: var(--shadow-sm, 0 1px 2px rgba(0,0,0,0.05));
        "#
    }

    pub fn sample_input() -> &'static str {
        r#"
            width: 100%;
            padding: 8px 12px;
            background: inherit;
            color: inherit;
            border: 1px solid var(--color-border, #e2e8f0);
            border-radius: var(--radius-md, 6px);
        "#
    }
}
