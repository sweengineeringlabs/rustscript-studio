//! CSS designer page - visual design token editor.

use rsc::prelude::*;

use rsc_studio::designer::css::{TokenCategory, TokenValue, PreviewMode};

use crate::components::{TokenEditor, Toolbar, ToolbarGroup, ToolbarButton, ToolbarDivider, Button, ButtonVariant, ButtonSize, Icon, Tabs, Tab, Input, Modal, ModalSize};
use crate::hooks::StudioStore;

/// CSS designer page.
#[component]
pub fn CssDesignerPage(store: StudioStore) -> Element {
    let selected_category = use_signal(|| TokenCategory::Colors);
    let preview_mode = use_signal(|| PreviewMode::Both);
    let tokens = store.design_tokens();
    let show_add_token_modal = use_signal(|| false);
    let new_token_name = use_signal(String::new);
    let new_token_value = use_signal(String::new);
    let show_css_output = use_signal(|| false);

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
        Tab {
            id: "transitions".to_string(),
            label: "Transitions".to_string(),
            icon: Some("zap".to_string()),
        },
        Tab {
            id: "z-index".to_string(),
            label: "Z-Index".to_string(),
            icon: Some("layers".to_string()),
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
            "transitions" => TokenCategory::Transitions,
            "z-index" => TokenCategory::ZIndex,
            _ => TokenCategory::Colors,
        };
        selected_category.set(category);
    };

    let on_token_change = {
        let store = store.clone();
        move |(path, value): (String, TokenValue)| {
            let full_path = format!("{}.{}", active_tab.get(), path);
            store.update_token(&full_path, value);
        }
    };

    // Add token handler
    let on_add_token = {
        let store = store.clone();
        let active_tab = active_tab.clone();
        let new_token_name = new_token_name.clone();
        let new_token_value = new_token_value.clone();
        let show_add_token_modal = show_add_token_modal.clone();
        move |_| {
            let name = new_token_name.get();
            let value = new_token_value.get();
            if !name.is_empty() && !value.is_empty() {
                store.add_token(&active_tab.get(), &name, TokenValue::Simple(value));
                new_token_name.set(String::new());
                new_token_value.set(String::new());
                show_add_token_modal.set(false);
            }
        }
    };

    rsx! {
        div(class: "css-designer-page", style: styles::container()) {
            // Toolbar
            Toolbar {
                ToolbarGroup {
                    ToolbarButton {
                        icon: "plus".to_string(),
                        label: Some("Add Token".to_string()),
                        onclick: {
                            let show_add_token_modal = show_add_token_modal.clone();
                            move |_| show_add_token_modal.set(true)
                        },
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "sun".to_string(),
                        label: Some("Light".to_string()),
                        active: preview_mode.get() == PreviewMode::Light,
                        onclick: move |_| preview_mode.set(PreviewMode::Light),
                    }
                    ToolbarButton {
                        icon: "moon".to_string(),
                        label: Some("Dark".to_string()),
                        active: preview_mode.get() == PreviewMode::Dark,
                        onclick: move |_| preview_mode.set(PreviewMode::Dark),
                    }
                    ToolbarButton {
                        icon: "columns".to_string(),
                        label: Some("Both".to_string()),
                        active: preview_mode.get() == PreviewMode::Both,
                        onclick: move |_| preview_mode.set(PreviewMode::Both),
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "code".to_string(),
                        label: Some("CSS Output".to_string()),
                        active: show_css_output.get(),
                        onclick: {
                            let show_css_output = show_css_output.clone();
                            move |_| show_css_output.update(|v| *v = !*v)
                        },
                    }
                }

                ToolbarDivider {}

                ToolbarGroup {
                    ToolbarButton {
                        icon: "download".to_string(),
                        label: Some("Export".to_string()),
                        onclick: move |_| {
                            // Export tokens to YAML
                        },
                    }
                    ToolbarButton {
                        icon: "upload".to_string(),
                        label: Some("Import".to_string()),
                        onclick: move |_| {
                            // Import tokens from YAML
                        },
                    }
                }
            }

            // Main content area
            div(class: "css-designer-content", style: styles::content()) {
                // Token editor panel
                div(class: "token-panel", style: styles::token_panel()) {
                    Tabs {
                        tabs: categories,
                        active: active_tab.clone(),
                        onchange: on_tab_change,
                    }

                    div(class: "token-list", style: styles::token_list()) {
                        TokenEditor {
                            tokens: tokens.clone(),
                            category: selected_category.get(),
                            onchange: on_token_change,
                        }
                    }
                }

                // Preview panel
                div(class: "preview-panel", style: styles::preview_panel()) {
                    h3(style: styles::preview_title()) { "Preview" }

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
                            div(class: "preview-split", style: styles::preview_split()) {
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

                // CSS Output panel (collapsible)
                if show_css_output.get() {
                    CssOutputPanel {
                        store: store.clone(),
                    }
                }
            }

            // Add Token Modal
            if show_add_token_modal.get() {
                Modal {
                    title: format!("Add {} Token", active_tab.get()).to_string(),
                    size: ModalSize::Sm,
                    on_close: {
                        let show_add_token_modal = show_add_token_modal.clone();
                        move |_| show_add_token_modal.set(false)
                    },
                } {
                    div(style: styles::modal_content()) {
                        div(style: styles::form_field()) {
                            label(style: styles::form_label()) { "Token Name" }
                            Input {
                                value: new_token_name.get(),
                                placeholder: Some("e.g., primary, lg, base".to_string()),
                                onchange: {
                                    let new_token_name = new_token_name.clone();
                                    Callback::new(move |v: String| new_token_name.set(v))
                                },
                            }
                        }
                        div(style: styles::form_field()) {
                            label(style: styles::form_label()) { "Token Value" }
                            Input {
                                value: new_token_value.get(),
                                placeholder: Some(match selected_category.get() {
                                    TokenCategory::Colors => "#3b82f6",
                                    TokenCategory::Spacing => "1rem",
                                    TokenCategory::Radius => "8px",
                                    TokenCategory::Shadows => "0 2px 4px rgba(0,0,0,0.1)",
                                    TokenCategory::Typography => "16px",
                                    TokenCategory::Transitions => "0.15s ease",
                                    TokenCategory::ZIndex => "100",
                                }.to_string()),
                                onchange: {
                                    let new_token_value = new_token_value.clone();
                                    Callback::new(move |v: String| new_token_value.set(v))
                                },
                            }
                        }
                        div(style: styles::modal_actions()) {
                            Button {
                                variant: ButtonVariant::Secondary,
                                size: ButtonSize::Sm,
                                onclick: {
                                    let show_add_token_modal = show_add_token_modal.clone();
                                    move |_| show_add_token_modal.set(false)
                                },
                            } { "Cancel" }
                            Button {
                                variant: ButtonVariant::Primary,
                                size: ButtonSize::Sm,
                                onclick: on_add_token,
                            } { "Add Token" }
                        }
                    }
                }
            }
        }
    }
}

/// CSS Output panel component.
#[component]
fn CssOutputPanel(store: StudioStore) -> Element {
    let css = store.get_generated_css();

    rsx! {
        div(class: "css-output-panel", style: styles::css_output_panel()) {
            div(class: "css-output-header", style: styles::css_output_header()) {
                Icon { name: "code".to_string(), size: 16 }
                span { "Generated CSS" }
            }
            pre(style: styles::css_output_code()) {
                code { { css } }
            }
        }
    }
}

/// Preview pane component.
#[component]
fn PreviewPane(mode: PreviewMode, tokens: Signal<rsc_studio::designer::css::DesignTokens>) -> Element {
    let mode_label = match mode {
        PreviewMode::Light => "Light Mode",
        PreviewMode::Dark => "Dark Mode",
        PreviewMode::Both => "Preview",
    };

    let bg_class = match mode {
        PreviewMode::Light => "light",
        PreviewMode::Dark => "dark",
        PreviewMode::Both => "light",
    };

    rsx! {
        div(class: format!("preview-pane preview-pane-{}", bg_class), style: styles::preview_pane(&mode)) {
            span(class: "preview-mode-label", style: styles::mode_label()) {
                { mode_label }
            }

            // Sample UI elements
            div(class: "preview-elements", style: styles::preview_elements()) {
                // Buttons
                div(class: "preview-section") {
                    h4 { "Buttons" }
                    div(style: styles::preview_row()) {
                        button(style: styles::sample_button_primary()) { "Primary" }
                        button(style: styles::sample_button_secondary()) { "Secondary" }
                        button(style: styles::sample_button_ghost()) { "Ghost" }
                    }
                }

                // Colors
                div(class: "preview-section") {
                    h4 { "Color Swatches" }
                    div(style: styles::color_swatches()) {
                        div(style: styles::swatch("var(--color-primary)"))
                        div(style: styles::swatch("var(--color-success)"))
                        div(style: styles::swatch("var(--color-warning)"))
                        div(style: styles::swatch("var(--color-error)"))
                    }
                }

                // Card
                div(class: "preview-section") {
                    h4 { "Card" }
                    div(style: styles::sample_card()) {
                        h5 { "Card Title" }
                        p { "This is a sample card component." }
                    }
                }

                // Input
                div(class: "preview-section") {
                    h4 { "Input" }
                    input(
                        type: "text",
                        placeholder: "Sample input...",
                        style: styles::sample_input(),
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

    pub fn modal_content() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-md);
        "#
    }

    pub fn form_field() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn form_label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-secondary);
        "#
    }

    pub fn modal_actions() -> &'static str {
        r#"
            display: flex;
            justify-content: flex-end;
            gap: var(--spacing-sm);
            margin-top: var(--spacing-md);
        "#
    }

    pub fn css_output_panel() -> &'static str {
        r#"
            width: 400px;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        "#
    }

    pub fn css_output_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
        "#
    }

    pub fn css_output_code() -> &'static str {
        r#"
            flex: 1;
            margin: 0;
            padding: var(--spacing-md);
            background: var(--color-bg-tertiary);
            font-family: var(--font-mono);
            font-size: var(--font-size-xs);
            line-height: 1.6;
            overflow: auto;
            white-space: pre-wrap;
        "#
    }
}
