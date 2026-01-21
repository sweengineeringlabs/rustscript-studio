//! Preset layout editor component.
//! Allows configuring activity bar, sidebar, and bottom panel for a preset.

use rsc::prelude::*;

use rsc_studio::entity::{LayoutConfig, LayoutVariant, Position, ActivityBarConfig, SidebarConfig, BottomPanelConfig};

use super::{Select, SelectOption, Switch, Input, Icon};

/// Preset layout editor component.
///
/// Allows editing the layout configuration of a preset including:
/// - Layout variant (IDE, Tabs, Minimal, Custom)
/// - Activity bar configuration
/// - Sidebar configuration
/// - Bottom panel configuration
component PresetLayoutEditor(
    layout: LayoutConfig,
    on_change: Callback<LayoutConfig>,
) {
    // Expand/collapse state for sections
    let activity_expanded = signal(true);
    let sidebar_expanded = signal(true);
    let bottom_panel_expanded = signal(true);

    // Layout variant options
    let variant_options = vec![
        SelectOption::new("ide", "IDE"),
        SelectOption::new("tabs", "Tabs"),
        SelectOption::new("minimal", "Minimal"),
        SelectOption::new("custom", "Custom"),
    ];

    // Position options
    let position_options = vec![
        SelectOption::new("left", "Left"),
        SelectOption::new("right", "Right"),
    ];

    let variant_value = match layout.variant {
        LayoutVariant::Ide => "ide",
        LayoutVariant::Tabs => "tabs",
        LayoutVariant::Minimal => "minimal",
        LayoutVariant::Custom => "custom",
    };

    // Handler for variant change
    let on_variant_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |v: String| {
            let mut new_layout = layout.clone();
            new_layout.variant = match v.as_str() {
                "ide" => LayoutVariant::Ide,
                "tabs" => LayoutVariant::Tabs,
                "minimal" => LayoutVariant::Minimal,
                _ => LayoutVariant::Custom,
            };
            on_change.call(new_layout);
        }
    };

    // Activity bar handlers
    let activity_bar = layout.activity_bar.clone().unwrap_or_default();
    let on_activity_visible_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |visible: bool| {
            let mut new_layout = layout.clone();
            let mut config = new_layout.activity_bar.clone().unwrap_or_default();
            config.visible = visible;
            new_layout.activity_bar = Some(config);
            on_change.call(new_layout);
        }
    };

    let on_activity_position_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |pos: String| {
            let mut new_layout = layout.clone();
            let mut config = new_layout.activity_bar.clone().unwrap_or_default();
            config.position = match pos.as_str() {
                "right" => Position::Right,
                _ => Position::Left,
            };
            new_layout.activity_bar = Some(config);
            on_change.call(new_layout);
        }
    };

    // Sidebar handlers
    let sidebar = layout.sidebar.clone().unwrap_or_default();
    let on_sidebar_visible_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |visible: bool| {
            let mut new_layout = layout.clone();
            let mut config = new_layout.sidebar.clone().unwrap_or_default();
            config.visible = visible;
            new_layout.sidebar = Some(config);
            on_change.call(new_layout);
        }
    };

    let on_sidebar_position_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |pos: String| {
            let mut new_layout = layout.clone();
            let mut config = new_layout.sidebar.clone().unwrap_or_default();
            config.position = match pos.as_str() {
                "right" => Position::Right,
                _ => Position::Left,
            };
            new_layout.sidebar = Some(config);
            on_change.call(new_layout);
        }
    };

    let on_sidebar_width_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |width: String| {
            if let Ok(w) = width.parse::<u32>() {
                let mut new_layout = layout.clone();
                let mut config = new_layout.sidebar.clone().unwrap_or_default();
                config.width = w;
                new_layout.sidebar = Some(config);
                on_change.call(new_layout);
            }
        }
    };

    // Bottom panel handlers
    let bottom_panel = layout.bottom_panel.clone().unwrap_or_default();
    let on_bottom_visible_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |visible: bool| {
            let mut new_layout = layout.clone();
            let mut config = new_layout.bottom_panel.clone().unwrap_or_default();
            config.visible = visible;
            new_layout.bottom_panel = Some(config);
            on_change.call(new_layout);
        }
    };

    let on_bottom_height_change = {
        let layout = layout.clone();
        let on_change = on_change.clone();
        move |height: String| {
            if let Ok(h) = height.parse::<u32>() {
                let mut new_layout = layout.clone();
                let mut config = new_layout.bottom_panel.clone().unwrap_or_default();
                config.height = h;
                new_layout.bottom_panel = Some(config);
                on_change.call(new_layout);
            }
        }
    };

    render {
        <div class="preset-layout-editor" style={styles::container()}>
            // Layout variant selector
            <div class="layout-section" style={styles::section()}>
                <div class="section-header" style={styles::section_header()}>
                    <Icon name={"layout".to_string()} size={16} />
                    <span>Layout Variant</span>
                </div>
                <Select
                    value={Some(variant_value.to_string())}
                    options={variant_options}
                    on_change={Some(Callback::new(on_variant_change))}
                />
            </div>

            // Activity Bar section
            <div class="layout-section" style={styles::section()}>
                <div
                    class="section-header clickable"
                    style={styles::section_header_clickable()}
                    on:click={move |_| activity_expanded.update(|v| *v = !*v)}
                >
                    <Icon
                        name={if activity_expanded.get() { "chevron-down".to_string() } else { "chevron-right".to_string() }}
                        size={14}
                    />
                    <Icon name={"sidebar".to_string()} size={16} />
                    <span>Activity Bar</span>
                    <div style="flex: 1;" />
                    <Switch
                        checked={Some(activity_bar.visible)}
                        on_change={Some(Callback::new(on_activity_visible_change))}
                    />
                </div>

                @if activity_expanded.get() && activity_bar.visible {
                    <div class="section-content" style={styles::section_content()}>
                        <div class="form-row" style={styles::form_row()}>
                            <label style={styles::label()}>Position</label>
                            <Select
                                value={Some(match activity_bar.position {
                                    Position::Left => "left".to_string(),
                                    Position::Right => "right".to_string(),
                                    _ => "left".to_string(),
                                })}
                                options={position_options.clone()}
                                on_change={Some(Callback::new(on_activity_position_change))}
                            />
                        </div>
                    </div>
                }
            </div>

            // Sidebar section
            <div class="layout-section" style={styles::section()}>
                <div
                    class="section-header clickable"
                    style={styles::section_header_clickable()}
                    on:click={move |_| sidebar_expanded.update(|v| *v = !*v)}
                >
                    <Icon
                        name={if sidebar_expanded.get() { "chevron-down".to_string() } else { "chevron-right".to_string() }}
                        size={14}
                    />
                    <Icon name={"columns".to_string()} size={16} />
                    <span>Sidebar</span>
                    <div style="flex: 1;" />
                    <Switch
                        checked={Some(sidebar.visible)}
                        on_change={Some(Callback::new(on_sidebar_visible_change))}
                    />
                </div>

                @if sidebar_expanded.get() && sidebar.visible {
                    <div class="section-content" style={styles::section_content()}>
                        <div class="form-row" style={styles::form_row()}>
                            <label style={styles::label()}>Position</label>
                            <Select
                                value={Some(match sidebar.position {
                                    Position::Left => "left".to_string(),
                                    Position::Right => "right".to_string(),
                                    _ => "left".to_string(),
                                })}
                                options={position_options.clone()}
                                on_change={Some(Callback::new(on_sidebar_position_change))}
                            />
                        </div>
                        <div class="form-row" style={styles::form_row()}>
                            <label style={styles::label()}>Width (px)</label>
                            <Input
                                value={sidebar.width.to_string()}
                                input_type={Some(crate::components::InputType::Number)}
                                on_change={{
                                    let on_sidebar_width_change = on_sidebar_width_change.clone();
                                    move |v: String| on_sidebar_width_change(v)
                                }}
                            />
                        </div>
                    </div>
                }
            </div>

            // Bottom Panel section
            <div class="layout-section" style={styles::section()}>
                <div
                    class="section-header clickable"
                    style={styles::section_header_clickable()}
                    on:click={move |_| bottom_panel_expanded.update(|v| *v = !*v)}
                >
                    <Icon
                        name={if bottom_panel_expanded.get() { "chevron-down".to_string() } else { "chevron-right".to_string() }}
                        size={14}
                    />
                    <Icon name={"terminal".to_string()} size={16} />
                    <span>Bottom Panel</span>
                    <div style="flex: 1;" />
                    <Switch
                        checked={Some(bottom_panel.visible)}
                        on_change={Some(Callback::new(on_bottom_visible_change))}
                    />
                </div>

                @if bottom_panel_expanded.get() && bottom_panel.visible {
                    <div class="section-content" style={styles::section_content()}>
                        <div class="form-row" style={styles::form_row()}>
                            <label style={styles::label()}>Height (px)</label>
                            <Input
                                value={bottom_panel.height.to_string()}
                                input_type={Some(crate::components::InputType::Number)}
                                on_change={{
                                    let on_bottom_height_change = on_bottom_height_change.clone();
                                    move |v: String| on_bottom_height_change(v)
                                }}
                            />
                        </div>
                    </div>
                }
            </div>

            // Layout preview
            <div class="layout-preview" style={styles::preview_container()}>
                <div class="preview-label" style={styles::preview_label()}>
                    <Icon name={"eye".to_string()} size={14} />
                    <span>Preview</span>
                </div>
                <LayoutPreview
                    layout={layout.clone()}
                />
            </div>
        </div>
    }
}

/// Visual preview of the layout configuration.
component LayoutPreview(layout: LayoutConfig) {
    let activity_bar = layout.activity_bar.clone().unwrap_or_default();
    let sidebar = layout.sidebar.clone().unwrap_or_default();
    let bottom_panel = layout.bottom_panel.clone().unwrap_or_default();

    let activity_on_left = activity_bar.visible && activity_bar.position == Position::Left;
    let activity_on_right = activity_bar.visible && activity_bar.position == Position::Right;
    let sidebar_on_left = sidebar.visible && sidebar.position == Position::Left;
    let sidebar_on_right = sidebar.visible && sidebar.position == Position::Right;

    render {
        <div class="layout-preview-box" style={styles::preview_box()}>
            // Top row (header)
            <div style={styles::preview_header()} />

            // Middle row (activity bar, sidebar, main, sidebar right, activity bar right)
            <div style={styles::preview_middle()}>
                @if activity_on_left {
                    <div style={styles::preview_activity_bar()} />
                }

                @if sidebar_on_left {
                    <div style={styles::preview_sidebar()} />
                }

                <div style={styles::preview_main()} />

                @if sidebar_on_right {
                    <div style={styles::preview_sidebar()} />
                }

                @if activity_on_right {
                    <div style={styles::preview_activity_bar()} />
                }
            </div>

            // Bottom panel
            @if bottom_panel.visible {
                <div style={styles::preview_bottom_panel()} />
            }
        </div>
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-md);
        "#
    }

    pub fn section() -> &'static str {
        r#"
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            overflow: hidden;
        "#
    }

    pub fn section_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-bg-tertiary);
            font-weight: var(--font-weight-medium);
            font-size: var(--font-size-sm);
        "#
    }

    pub fn section_header_clickable() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-bg-tertiary);
            font-weight: var(--font-weight-medium);
            font-size: var(--font-size-sm);
            cursor: pointer;
            transition: background 0.15s ease;
        "#
    }

    pub fn section_content() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
            padding: var(--spacing-md);
        "#
    }

    pub fn form_row() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: var(--spacing-md);
        "#
    }

    pub fn label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
            min-width: 80px;
        "#
    }

    pub fn preview_container() -> &'static str {
        r#"
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            padding: var(--spacing-md);
        "#
    }

    pub fn preview_label() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-secondary);
            margin-bottom: var(--spacing-sm);
        "#
    }

    pub fn preview_box() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            height: 120px;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
            overflow: hidden;
        "#
    }

    pub fn preview_header() -> &'static str {
        r#"
            height: 20px;
            background: var(--color-bg-tertiary);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn preview_middle() -> &'static str {
        r#"
            display: flex;
            flex: 1;
        "#
    }

    pub fn preview_activity_bar() -> &'static str {
        r#"
            width: 24px;
            background: var(--color-primary);
            opacity: 0.6;
        "#
    }

    pub fn preview_sidebar() -> &'static str {
        r#"
            width: 50px;
            background: var(--color-bg-secondary);
            border-right: 1px solid var(--color-border);
        "#
    }

    pub fn preview_main() -> &'static str {
        r#"
            flex: 1;
            background: var(--color-surface);
        "#
    }

    pub fn preview_bottom_panel() -> &'static str {
        r#"
            height: 30px;
            background: var(--color-bg-secondary);
            border-top: 1px solid var(--color-border);
        "#
    }
}
