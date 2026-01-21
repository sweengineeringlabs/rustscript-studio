//! Settings page.

use rsc::prelude::*;

use crate::components::{Button, ButtonVariant, Icon, Panel};
use crate::hooks::{StudioStore, Theme};

/// Settings page props.
#[derive(Props)]
pub struct SettingsPageProps {
    pub store: StudioStore,
}

/// Settings page.
#[component]
pub fn SettingsPage(props: SettingsPageProps) -> Element {
    rsx! {
        div(class="settings-page", style=styles::container()) {
            div(class="settings-content", style=styles::content()) {
                // General settings
                GeneralSettings {}

                // Appearance settings
                AppearanceSettings { store: props.store.clone() }

                // Export settings
                ExportSettings { store: props.store.clone() }

                // About section
                AboutSection {}
            }
        }
    }
}

/// General settings section.
#[component]
fn GeneralSettings() -> Element {
    rsx! {
        section(class="settings-section", style=styles::section()) {
            h2(style=styles::section_title()) { "General" }

            div(class="setting-item", style=styles::setting_item()) {
                div(class="setting-info") {
                    label(style=styles::setting_label()) { "Auto-save" }
                    p(style=styles::setting_description()) {
                        "Automatically save changes to workflows and tokens"
                    }
                }
                input(
                    type="checkbox",
                    checked=true,
                    style=styles::checkbox(),
                )
            }

            div(class="setting-item", style=styles::setting_item()) {
                div(class="setting-info") {
                    label(style=styles::setting_label()) { "Show grid" }
                    p(style=styles::setting_description()) {
                        "Display grid lines in the canvas"
                    }
                }
                input(
                    type="checkbox",
                    checked=true,
                    style=styles::checkbox(),
                )
            }

            div(class="setting-item", style=styles::setting_item()) {
                div(class="setting-info") {
                    label(style=styles::setting_label()) { "Snap to grid" }
                    p(style=styles::setting_description()) {
                        "Snap nodes to grid when dragging"
                    }
                }
                input(
                    type="checkbox",
                    checked=false,
                    style=styles::checkbox(),
                )
            }
        }
    }
}

/// Appearance settings section.
#[derive(Props)]
struct AppearanceSettingsProps {
    store: StudioStore,
}

#[component]
fn AppearanceSettings(props: AppearanceSettingsProps) -> Element {
    let current_theme = props.store.theme();

    rsx! {
        section(class="settings-section", style=styles::section()) {
            h2(style=styles::section_title()) { "Appearance" }

            div(class="setting-item", style=styles::setting_item()) {
                div(class="setting-info") {
                    label(style=styles::setting_label()) { "Theme" }
                    p(style=styles::setting_description()) {
                        "Choose your preferred color theme"
                    }
                }
                select(
                    style=styles::select(),
                    on:change=move |e: Event<FormData>| {
                        let theme = match e.value().as_str() {
                            "light" => Theme::Light,
                            "dark" => Theme::Dark,
                            _ => Theme::System,
                        };
                        props.store.set_theme(theme);
                    },
                ) {
                    option(value="system", selected=current_theme == Theme::System) {
                        "System"
                    }
                    option(value="light", selected=current_theme == Theme::Light) {
                        "Light"
                    }
                    option(value="dark", selected=current_theme == Theme::Dark) {
                        "Dark"
                    }
                }
            }

            div(class="setting-item", style=styles::setting_item()) {
                div(class="setting-info") {
                    label(style=styles::setting_label()) { "Font size" }
                    p(style=styles::setting_description()) {
                        "Adjust the UI font size"
                    }
                }
                select(style=styles::select()) {
                    option(value="small") { "Small" }
                    option(value="medium", selected=true) { "Medium" }
                    option(value="large") { "Large" }
                }
            }
        }
    }
}

/// Export settings section.
#[derive(Props)]
struct ExportSettingsProps {
    store: StudioStore,
}

#[component]
fn ExportSettings(props: ExportSettingsProps) -> Element {
    rsx! {
        section(class="settings-section", style=styles::section()) {
            h2(style=styles::section_title()) { "Export" }

            div(class="setting-item", style=styles::setting_item()) {
                div(class="setting-info") {
                    label(style=styles::setting_label()) { "Export format" }
                    p(style=styles::setting_description()) {
                        "Choose the default export format for design tokens"
                    }
                }
                select(style=styles::select()) {
                    option(value="yaml", selected=true) { "YAML" }
                    option(value="json") { "JSON" }
                    option(value="css") { "CSS Variables" }
                    option(value="scss") { "SCSS" }
                }
            }

            div(class="export-actions", style=styles::export_actions()) {
                Button {
                    variant: ButtonVariant::Primary,
                    on_click: move |_| {
                        // Export workflows
                    },
                } {
                    Icon { name: "download".to_string() }
                    "Export Workflows"
                }

                Button {
                    variant: ButtonVariant::Secondary,
                    on_click: move |_| {
                        // Export tokens
                    },
                } {
                    Icon { name: "download".to_string() }
                    "Export Tokens"
                }
            }
        }
    }
}

/// About section.
#[component]
fn AboutSection() -> Element {
    rsx! {
        section(class="settings-section", style=styles::section()) {
            h2(style=styles::section_title()) { "About" }

            div(class="about-content", style=styles::about_content()) {
                div(class="about-logo", style=styles::about_logo()) {
                    Icon { name: "code".to_string(), size: 48 }
                }

                h3(style=styles::about_title()) { "RustScript Studio" }
                p(style=styles::about_version()) { "Version 0.1.0" }
                p(style=styles::about_description()) {
                    "Visual IDE for RustScript - Design navigation flows and CSS visually."
                }

                div(class="about-links", style=styles::about_links()) {
                    a(href="#", style=styles::about_link()) {
                        Icon { name: "book".to_string(), size: 16 }
                        "Documentation"
                    }
                    a(href="#", style=styles::about_link()) {
                        Icon { name: "github".to_string(), size: 16 }
                        "GitHub"
                    }
                }
            }
        }
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            height: 100%;
            overflow-y: auto;
        "#
    }

    pub fn content() -> &'static str {
        r#"
            max-width: 800px;
            margin: 0 auto;
            padding: var(--spacing-xl);
        "#
    }

    pub fn section() -> &'static str {
        r#"
            margin-bottom: var(--spacing-2xl);
        "#
    }

    pub fn section_title() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-lg);
            font-size: var(--font-size-xl);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-primary);
        "#
    }

    pub fn setting_item() -> &'static str {
        r#"
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            padding: var(--spacing-md);
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            margin-bottom: var(--spacing-sm);
        "#
    }

    pub fn setting_label() -> &'static str {
        r#"
            display: block;
            font-weight: var(--font-weight-medium);
            color: var(--color-text-primary);
            margin-bottom: var(--spacing-xs);
        "#
    }

    pub fn setting_description() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn checkbox() -> &'static str {
        r#"
            width: 20px;
            height: 20px;
            cursor: pointer;
        "#
    }

    pub fn select() -> &'static str {
        r#"
            min-width: 150px;
            padding: var(--spacing-sm) var(--spacing-md);
            font-size: var(--font-size-sm);
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            cursor: pointer;
        "#
    }

    pub fn export_actions() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-md);
            margin-top: var(--spacing-md);
        "#
    }

    pub fn about_content() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            padding: var(--spacing-xl);
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
        "#
    }

    pub fn about_logo() -> &'static str {
        r#"
            color: var(--color-primary);
            margin-bottom: var(--spacing-md);
        "#
    }

    pub fn about_title() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-xs);
            font-size: var(--font-size-2xl);
        "#
    }

    pub fn about_version() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-md);
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn about_description() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-lg);
            max-width: 400px;
            color: var(--color-text-secondary);
        "#
    }

    pub fn about_links() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-lg);
        "#
    }

    pub fn about_link() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            color: var(--color-primary);
            text-decoration: none;
        "#
    }
}
