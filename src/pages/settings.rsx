//! Settings page.

use rsc::prelude::*;

use crate::components::{Button, ButtonVariant, Icon, Panel};
use crate::hooks::{StudioStore, Theme};

/// Settings page.
component SettingsPage(store: StudioStore) {
    render {
        <div class="settings-page" style={styles::container()}>
            <div class="settings-content" style={styles::content()}>
                // General settings
                <GeneralSettings />

                // Appearance settings
                <AppearanceSettings store={store.clone()} />

                // Export settings
                <ExportSettings store={store.clone()} />

                // About section
                <AboutSection />
            </div>
        </div>
    }
}

/// General settings section.
component GeneralSettings() {
    render {
        <section class="settings-section" style={styles::section()}>
            <h2 style={styles::section_title()}>General</h2>

            <div class="setting-item" style={styles::setting_item()}>
                <div class="setting-info">
                    <label style={styles::setting_label()}>Auto-save</label>
                    <p style={styles::setting_description()}>
                        Automatically save changes to workflows and tokens
                    </p>
                </div>
                <input
                    type="checkbox"
                    checked={true}
                    style={styles::checkbox()}
                />
            </div>

            <div class="setting-item" style={styles::setting_item()}>
                <div class="setting-info">
                    <label style={styles::setting_label()}>Show grid</label>
                    <p style={styles::setting_description()}>
                        Display grid lines in the canvas
                    </p>
                </div>
                <input
                    type="checkbox"
                    checked={true}
                    style={styles::checkbox()}
                />
            </div>

            <div class="setting-item" style={styles::setting_item()}>
                <div class="setting-info">
                    <label style={styles::setting_label()}>Snap to grid</label>
                    <p style={styles::setting_description()}>
                        Snap nodes to grid when dragging
                    </p>
                </div>
                <input
                    type="checkbox"
                    checked={false}
                    style={styles::checkbox()}
                />
            </div>
        </section>
    }
}

/// Appearance settings section.
component AppearanceSettings(store: StudioStore) {
    let current_theme = store.theme();

    render {
        <section class="settings-section" style={styles::section()}>
            <h2 style={styles::section_title()}>Appearance</h2>

            <div class="setting-item" style={styles::setting_item()}>
                <div class="setting-info">
                    <label style={styles::setting_label()}>Theme</label>
                    <p style={styles::setting_description()}>
                        Choose your preferred color theme
                    </p>
                </div>
                <select
                    style={styles::select()}
                    on:change={|e: InputEvent| {
                        let theme = match e.value().as_str() {
                            "light" => Theme::Light,
                            "dark" => Theme::Dark,
                            _ => Theme::System,
                        };
                        store.set_theme(theme);
                    }}
                >
                    <option value="system" selected={current_theme == Theme::System}>
                        System
                    </option>
                    <option value="light" selected={current_theme == Theme::Light}>
                        Light
                    </option>
                    <option value="dark" selected={current_theme == Theme::Dark}>
                        Dark
                    </option>
                </select>
            </div>

            <div class="setting-item" style={styles::setting_item()}>
                <div class="setting-info">
                    <label style={styles::setting_label()}>Font size</label>
                    <p style={styles::setting_description()}>
                        Adjust the UI font size
                    </p>
                </div>
                <select style={styles::select()}>
                    <option value="small">Small</option>
                    <option value="medium" selected={true}>Medium</option>
                    <option value="large">Large</option>
                </select>
            </div>
        </section>
    }
}

/// Export settings section.
component ExportSettings(store: StudioStore) {
    render {
        <section class="settings-section" style={styles::section()}>
            <h2 style={styles::section_title()}>Export</h2>

            <div class="setting-item" style={styles::setting_item()}>
                <div class="setting-info">
                    <label style={styles::setting_label()}>Export format</label>
                    <p style={styles::setting_description()}>
                        Choose the default export format for design tokens
                    </p>
                </div>
                <select style={styles::select()}>
                    <option value="yaml" selected={true}>YAML</option>
                    <option value="json">JSON</option>
                    <option value="css">CSS Variables</option>
                    <option value="scss">SCSS</option>
                </select>
            </div>

            <div class="export-actions" style={styles::export_actions()}>
                <Button
                    variant={ButtonVariant::Primary}
                    onclick={Callback::new(|| {
                        // Export workflows
                    })}
                >
                    <Icon name={"download".to_string()} />
                    "Export Workflows"
                </Button>

                <Button
                    variant={ButtonVariant::Secondary}
                    onclick={Callback::new(|| {
                        // Export tokens
                    })}
                >
                    <Icon name={"download".to_string()} />
                    "Export Tokens"
                </Button>
            </div>
        </section>
    }
}

/// About section.
component AboutSection() {
    render {
        <section class="settings-section" style={styles::section()}>
            <h2 style={styles::section_title()}>About</h2>

            <div class="about-content" style={styles::about_content()}>
                <div class="about-logo" style={styles::about_logo()}>
                    <Icon name={"code".to_string()} size={48} />
                </div>

                <h3 style={styles::about_title()}>RustScript Studio</h3>
                <p style={styles::about_version()}>Version 0.1.0</p>
                <p style={styles::about_description()}>
                    Visual IDE for RustScript - Design navigation flows and CSS visually.
                </p>

                <div class="about-links" style={styles::about_links()}>
                    <a href="#" style={styles::about_link()}>
                        <Icon name={"book".to_string()} size={16} />
                        "Documentation"
                    </a>
                    <a href="#" style={styles::about_link()}>
                        <Icon name={"github".to_string()} size={16} />
                        "GitHub"
                    </a>
                </div>
            </div>
        </section>
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
