//! Navigation preview component - simulate and preview navigation flows.
//!
//! Allows users to preview how their workflow/context/preset navigation will work:
//! - Visual breadcrumb showing current path
//! - Interactive navigation through the hierarchy
//! - Live preview of preset layouts
//! - Hot reload on store changes

use rsc::prelude::*;

use rsc_studio::entity::{Workflow, Context, Preset, LayoutConfig, LayoutVariant, Position};
use crate::hooks::StudioStore;
use crate::components::{Button, ButtonVariant, ButtonSize, Icon};

/// Navigation state in the preview.
#[derive(Clone, Default)]
struct PreviewState {
    workflow_id: Option<String>,
    context_id: Option<String>,
    preset_id: Option<String>,
}

/// Navigation preview component.
component NavigationPreview(
    store: StudioStore,
    /// Optional callback when preview state changes
    on_state_change?: Callback<(Option<String>, Option<String>, Option<String>)>,
) {
    let preview_state = signal(PreviewState::default());
    let show_layout_preview = signal(true);

    // Get current entities based on state
    let workflows = store.workflows();
    let current_workflow = preview_state.get().workflow_id.as_ref()
        .and_then(|id| workflows.iter().find(|w| &w.id == id).cloned());
    let current_context = current_workflow.as_ref()
        .and_then(|wf| preview_state.get().context_id.as_ref()
            .and_then(|id| wf.contexts.get(id).cloned()));
    let current_preset = current_context.as_ref()
        .and_then(|ctx| preview_state.get().preset_id.as_ref()
            .and_then(|id| ctx.presets.get(id).cloned()));

    // Notify parent of state changes
    let notify_change = {
        let preview_state = preview_state.clone();
        let on_state_change = on_state_change.clone();
        move || {
            if let Some(ref callback) = on_state_change {
                let state = preview_state.get();
                callback.call((state.workflow_id.clone(), state.context_id.clone(), state.preset_id.clone()));
            }
        }
    };

    // Navigate to workflow
    let select_workflow = {
        let preview_state = preview_state.clone();
        let notify_change = notify_change.clone();
        move |id: String| {
            preview_state.update(|s| {
                s.workflow_id = Some(id);
                s.context_id = None;
                s.preset_id = None;
            });
            notify_change();
        }
    };

    // Navigate to context
    let select_context = {
        let preview_state = preview_state.clone();
        let notify_change = notify_change.clone();
        move |id: String| {
            preview_state.update(|s| {
                s.context_id = Some(id);
                s.preset_id = None;
            });
            notify_change();
        }
    };

    // Navigate to preset
    let select_preset = {
        let preview_state = preview_state.clone();
        let notify_change = notify_change.clone();
        move |id: String| {
            preview_state.update(|s| {
                s.preset_id = Some(id);
            });
            notify_change();
        }
    };

    // Go back one level
    let go_back = {
        let preview_state = preview_state.clone();
        let notify_change = notify_change.clone();
        move |_| {
            preview_state.update(|s| {
                if s.preset_id.is_some() {
                    s.preset_id = None;
                } else if s.context_id.is_some() {
                    s.context_id = None;
                } else if s.workflow_id.is_some() {
                    s.workflow_id = None;
                }
            });
            notify_change();
        }
    };

    // Reset to beginning
    let reset = {
        let preview_state = preview_state.clone();
        let notify_change = notify_change.clone();
        move |_| {
            preview_state.set(PreviewState::default());
            notify_change();
        }
    };

    render {
        <div class="navigation-preview" style={styles::container()}>
            // Header
            <div class="preview-header" style={styles::header()}>
                <div style="display: flex; align-items: center; gap: var(--spacing-sm);">
                    <Icon name={"play-circle".to_string()} size={20} />
                    <h3 style={styles::title()}>Navigation Preview</h3>
                </div>
                <div style="display: flex; gap: var(--spacing-xs);">
                    <Button
                        variant={ButtonVariant::Ghost}
                        size={ButtonSize::Sm}
                        onclick={{
                            let show_layout_preview = show_layout_preview.clone();
                            move |_| show_layout_preview.update(|v| *v = !*v)
                        }}
                    >
                        <Icon
                            name={if show_layout_preview.get() { "eye".to_string() } else { "eye-off".to_string() }}
                            size={16}
                        />
                    </Button>
                    <Button
                        variant={ButtonVariant::Ghost}
                        size={ButtonSize::Sm}
                        onclick={Callback::new(reset.clone())}
                    >
                        <Icon name={"refresh-cw".to_string()} size={16} />
                    </Button>
                </div>
            </div>

            // Breadcrumb navigation
            <div class="preview-breadcrumb" style={styles::breadcrumb()}>
                <span
                    class="breadcrumb-item"
                    style={styles::breadcrumb_item(preview_state.get().workflow_id.is_none())}
                    on:click={{
                        let reset = reset.clone();
                        move |_| reset(())
                    }}
                >
                    <Icon name={"home".to_string()} size={14} />
                    Workflows
                </span>

                @if let Some(ref wf) = current_workflow {
                    <span style={styles::breadcrumb_separator()}>/</span>
                    <span
                        class="breadcrumb-item"
                        style={styles::breadcrumb_item(preview_state.get().context_id.is_none())}
                        on:click={{
                            let id = wf.id.clone();
                            let select_workflow = select_workflow.clone();
                            move |_| select_workflow(id.clone())
                        }}
                    >
                        <Icon name={"git-branch".to_string()} size={14} />
                        {wf.name.clone()}
                    </span>
                }

                @if let Some(ref ctx) = current_context {
                    <span style={styles::breadcrumb_separator()}>/</span>
                    <span
                        class="breadcrumb-item"
                        style={styles::breadcrumb_item(preview_state.get().preset_id.is_none())}
                        on:click={{
                            let id = ctx.id.clone();
                            let select_context = select_context.clone();
                            move |_| select_context(id.clone())
                        }}
                    >
                        <Icon name={"layers".to_string()} size={14} />
                        {ctx.name.clone()}
                    </span>
                }

                @if let Some(ref preset) = current_preset {
                    <span style={styles::breadcrumb_separator()}>/</span>
                    <span
                        class="breadcrumb-item"
                        style={styles::breadcrumb_item(true)}
                    >
                        <Icon name={"layout".to_string()} size={14} />
                        {preset.name.clone()}
                    </span>
                }
            </div>

            // Content area
            <div class="preview-content" style={styles::content()}>
                // Show items to navigate to
                @if preview_state.get().workflow_id.is_none() {
                    // Show workflows
                    <NavigationList
                        title={"Select a Workflow".to_string()}
                        items={workflows.iter().map(|w| NavigationItem {
                            id: w.id.clone(),
                            name: w.name.clone(),
                            description: w.description.clone(),
                            icon: w.icon.clone().unwrap_or_else(|| "git-branch".to_string()),
                            item_type: ItemType::Workflow,
                        }).collect()}
                        on_select={Callback::new(select_workflow.clone())}
                    />
                } else if preview_state.get().context_id.is_none() {
                    // Show contexts in selected workflow
                    @if let Some(ref wf) = current_workflow {
                        <NavigationList
                            title={format!("Contexts in '{}'", wf.name)}
                            items={wf.contexts.values().map(|c| NavigationItem {
                                id: c.id.clone(),
                                name: c.name.clone(),
                                description: c.description.clone(),
                                icon: c.icon.clone().unwrap_or_else(|| "layers".to_string()),
                                item_type: ItemType::Context,
                            }).collect()}
                            on_select={Callback::new(select_context.clone())}
                        />
                    }
                } else if preview_state.get().preset_id.is_none() {
                    // Show presets in selected context
                    @if let Some(ref ctx) = current_context {
                        <NavigationList
                            title={format!("Presets in '{}'", ctx.name)}
                            items={ctx.presets.values().map(|p| NavigationItem {
                                id: p.id.clone(),
                                name: p.name.clone(),
                                description: p.description.clone(),
                                icon: "layout".to_string(),
                                item_type: ItemType::Preset,
                            }).collect()}
                            on_select={Callback::new(select_preset.clone())}
                        />
                    }
                } else {
                    // Show preset details and layout preview
                    @if let Some(ref preset) = current_preset {
                        <PresetPreview
                            preset={preset.clone()}
                            show_layout={show_layout_preview.get()}
                        />
                    }
                }

                // Back button when not at root
                @if preview_state.get().workflow_id.is_some() {
                    <div style={styles::back_button_container()}>
                        <Button
                            variant={ButtonVariant::Secondary}
                            size={ButtonSize::Sm}
                            onclick={Callback::new(go_back)}
                        >
                            <Icon name={"arrow-left".to_string()} />
                            Back
                        </Button>
                    </div>
                }
            </div>

            // Status bar
            <div class="preview-status" style={styles::status()}>
                <span>
                    {format!("{} workflows • {} contexts • {} presets",
                        workflows.len(),
                        workflows.iter().map(|w| w.contexts.len()).sum::<usize>(),
                        workflows.iter().flat_map(|w| w.contexts.values().map(|c| c.presets.len())).sum::<usize>()
                    )}
                </span>
            </div>
        </div>
    }
}

#[derive(Clone, Copy, PartialEq)]
enum ItemType {
    Workflow,
    Context,
    Preset,
}

#[derive(Clone)]
struct NavigationItem {
    id: String,
    name: String,
    description: Option<String>,
    icon: String,
    item_type: ItemType,
}

/// Navigation list for selecting items.
component NavigationList(
    title: String,
    items: Vec<NavigationItem>,
    on_select: Callback<String>,
) {
    render {
        <div class="navigation-list" style={list_styles::container()}>
            <h4 style={list_styles::title()}>{title}</h4>

            @if items.is_empty() {
                <div class="empty-list" style={list_styles::empty()}>
                    <Icon name={"inbox".to_string()} size={32} />
                    <p>No items available</p>
                </div>
            } else {
                <div class="list-items" style={list_styles::items()}>
                    @for item in items {
                        <div
                            class="list-item"
                            style={list_styles::item(item.item_type)}
                            on:click={{
                                let id = item.id.clone();
                                let on_select = on_select.clone();
                                move |_| on_select.call(id.clone())
                            }}
                        >
                            <div class="item-icon" style={list_styles::item_icon(item.item_type)}>
                                <Icon name={item.icon.clone()} size={20} />
                            </div>
                            <div class="item-content" style={list_styles::item_content()}>
                                <span class="item-name" style={list_styles::item_name()}>
                                    {item.name.clone()}
                                </span>
                                @if let Some(ref desc) = item.description {
                                    <span class="item-description" style={list_styles::item_description()}>
                                        {desc.clone()}
                                    </span>
                                }
                            </div>
                            <Icon name={"chevron-right".to_string()} size={16} />
                        </div>
                    }
                </div>
            }
        </div>
    }
}

/// Preset preview with layout visualization.
component PresetPreview(preset: Preset, show_layout: bool) {
    let layout = &preset.layout;

    render {
        <div class="preset-preview" style={preset_styles::container()}>
            // Preset info
            <div class="preset-info" style={preset_styles::info()}>
                <h4 style={preset_styles::name()}>
                    <Icon name={"layout".to_string()} size={20} />
                    {preset.name.clone()}
                </h4>
                @if let Some(ref desc) = preset.description {
                    <p style={preset_styles::description()}>{desc.clone()}</p>
                }
            </div>

            // Layout configuration details
            <div class="preset-config" style={preset_styles::config()}>
                <h5 style={preset_styles::config_title()}>Layout Configuration</h5>

                // Activity Bar
                <div class="config-row" style={preset_styles::config_row()}>
                    <span style={preset_styles::config_label()}>Activity Bar</span>
                    <span style={preset_styles::config_value(layout.activity_bar.visible)}>
                        @if layout.activity_bar.visible {
                            {format!("{:?}", layout.activity_bar.position)}
                        } else {
                            Hidden
                        }
                    </span>
                </div>

                // Sidebar
                <div class="config-row" style={preset_styles::config_row()}>
                    <span style={preset_styles::config_label()}>Sidebar</span>
                    <span style={preset_styles::config_value(layout.sidebar.visible)}>
                        @if layout.sidebar.visible {
                            {format!("{:?} ({}px)", layout.sidebar.position, layout.sidebar.width)}
                        } else {
                            Hidden
                        }
                    </span>
                </div>

                // Bottom Panel
                <div class="config-row" style={preset_styles::config_row()}>
                    <span style={preset_styles::config_label()}>Bottom Panel</span>
                    <span style={preset_styles::config_value(layout.bottom_panel.visible)}>
                        @if layout.bottom_panel.visible {
                            {format!("{}px", layout.bottom_panel.height)}
                        } else {
                            Hidden
                        }
                    </span>
                </div>
            </div>

            // Visual layout preview
            @if show_layout {
                <div class="layout-preview" style={preset_styles::layout_container()}>
                    <h5 style={preset_styles::config_title()}>Layout Preview</h5>
                    <LayoutPreviewVisual
                        layout={layout.clone()}
                    />
                </div>
            }
        </div>
    }
}

/// Visual representation of a layout configuration.
component LayoutPreviewVisual(layout: LayoutConfig) {
    // Determine the flex direction based on activity bar and sidebar positions
    let activity_bar_left = layout.activity_bar.visible &&
        matches!(layout.activity_bar.position, Position::Left);
    let activity_bar_right = layout.activity_bar.visible &&
        matches!(layout.activity_bar.position, Position::Right);
    let sidebar_left = layout.sidebar.visible &&
        matches!(layout.sidebar.position, Position::Left);
    let sidebar_right = layout.sidebar.visible &&
        matches!(layout.sidebar.position, Position::Right);

    render {
        <div class="layout-visual" style={visual_styles::container()}>
            // Header area
            <div style={visual_styles::header()}>
                <span style={visual_styles::header_text()}>Header</span>
            </div>

            // Main content row
            <div style={visual_styles::main_row()}>
                // Activity bar (left)
                @if activity_bar_left {
                    <div style={visual_styles::activity_bar()}>
                        <div style={visual_styles::activity_icon()} />
                        <div style={visual_styles::activity_icon()} />
                        <div style={visual_styles::activity_icon()} />
                    </div>
                }

                // Sidebar (left)
                @if sidebar_left {
                    <div style={visual_styles::sidebar(layout.sidebar.width as f64 / 300.0 * 100.0)}>
                        <span style={visual_styles::sidebar_text()}>Sidebar</span>
                    </div>
                }

                // Main content area
                <div style={visual_styles::main_content()}>
                    <span style={visual_styles::main_text()}>Main Content</span>
                </div>

                // Sidebar (right)
                @if sidebar_right {
                    <div style={visual_styles::sidebar(layout.sidebar.width as f64 / 300.0 * 100.0)}>
                        <span style={visual_styles::sidebar_text()}>Sidebar</span>
                    </div>
                }

                // Activity bar (right)
                @if activity_bar_right {
                    <div style={visual_styles::activity_bar()}>
                        <div style={visual_styles::activity_icon()} />
                        <div style={visual_styles::activity_icon()} />
                        <div style={visual_styles::activity_icon()} />
                    </div>
                }
            </div>

            // Bottom panel
            @if layout.bottom_panel.visible {
                <div style={visual_styles::bottom_panel(layout.bottom_panel.height as f64 / 300.0 * 100.0)}>
                    <span style={visual_styles::panel_text()}>Bottom Panel</span>
                </div>
            }
        </div>
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            height: 100%;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
        "#
    }

    pub fn header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-base);
            font-weight: var(--font-weight-semibold);
        "#
    }

    pub fn breadcrumb() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-bg-tertiary);
            border-bottom: 1px solid var(--color-border);
            font-size: var(--font-size-sm);
            overflow-x: auto;
        "#
    }

    pub fn breadcrumb_item(is_current: bool) -> String {
        format!(
            r#"
                display: flex;
                align-items: center;
                gap: var(--spacing-xs);
                padding: var(--spacing-xs) var(--spacing-sm);
                border-radius: var(--radius-sm);
                cursor: pointer;
                transition: background 0.15s ease;
                font-weight: {};
                color: {};
            "#,
            if is_current { "var(--font-weight-semibold)" } else { "var(--font-weight-normal)" },
            if is_current { "var(--color-text-primary)" } else { "var(--color-text-secondary)" }
        )
    }

    pub fn breadcrumb_separator() -> &'static str {
        r#"
            color: var(--color-text-tertiary);
        "#
    }

    pub fn content() -> &'static str {
        r#"
            flex: 1;
            padding: var(--spacing-md);
            overflow-y: auto;
        "#
    }

    pub fn back_button_container() -> &'static str {
        r#"
            margin-top: var(--spacing-lg);
            padding-top: var(--spacing-md);
            border-top: 1px solid var(--color-border);
        "#
    }

    pub fn status() -> &'static str {
        r#"
            padding: var(--spacing-xs) var(--spacing-md);
            background: var(--color-bg-secondary);
            border-top: 1px solid var(--color-border);
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
        "#
    }
}

mod list_styles {
    use super::ItemType;

    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-md);
        "#
    }

    pub fn title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-secondary);
        "#
    }

    pub fn empty() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: var(--spacing-xl);
            color: var(--color-text-tertiary);
        "#
    }

    pub fn items() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }

    pub fn item(item_type: ItemType) -> String {
        let accent_color = match item_type {
            ItemType::Workflow => "var(--color-primary)",
            ItemType::Context => "var(--color-secondary)",
            ItemType::Preset => "var(--color-accent)",
        };
        format!(
            r#"
                display: flex;
                align-items: center;
                gap: var(--spacing-sm);
                padding: var(--spacing-sm) var(--spacing-md);
                background: var(--color-bg-secondary);
                border: 1px solid var(--color-border);
                border-left: 3px solid {};
                border-radius: var(--radius-md);
                cursor: pointer;
                transition: all 0.15s ease;
            "#,
            accent_color
        )
    }

    pub fn item_icon(item_type: ItemType) -> String {
        let bg_color = match item_type {
            ItemType::Workflow => "var(--color-primary)",
            ItemType::Context => "var(--color-secondary)",
            ItemType::Preset => "var(--color-accent)",
        };
        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                width: 36px;
                height: 36px;
                background: {};
                color: white;
                border-radius: var(--radius-md);
            "#,
            bg_color
        )
    }

    pub fn item_content() -> &'static str {
        r#"
            flex: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        "#
    }

    pub fn item_name() -> &'static str {
        r#"
            font-weight: var(--font-weight-medium);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        "#
    }

    pub fn item_description() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        "#
    }
}

mod preset_styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-lg);
        "#
    }

    pub fn info() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }

    pub fn name() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            margin: 0;
            font-size: var(--font-size-lg);
            font-weight: var(--font-weight-semibold);
        "#
    }

    pub fn description() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn config() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
            padding: var(--spacing-md);
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
        "#
    }

    pub fn config_title() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-sm) 0;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-secondary);
        "#
    }

    pub fn config_row() -> &'static str {
        r#"
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: var(--spacing-xs) 0;
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn config_label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            color: var(--color-text-secondary);
        "#
    }

    pub fn config_value(is_enabled: bool) -> String {
        format!(
            r#"
                font-size: var(--font-size-sm);
                font-weight: var(--font-weight-medium);
                color: {};
            "#,
            if is_enabled { "var(--color-text-primary)" } else { "var(--color-text-tertiary)" }
        )
    }

    pub fn layout_container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }
}

mod visual_styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            height: 200px;
            background: var(--color-bg-tertiary);
            border: 2px solid var(--color-border);
            border-radius: var(--radius-md);
            overflow: hidden;
        "#
    }

    pub fn header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: center;
            height: 24px;
            background: var(--color-primary);
            color: white;
            font-size: 10px;
        "#
    }

    pub fn header_text() -> &'static str {
        r#"
            font-size: 10px;
            opacity: 0.8;
        "#
    }

    pub fn main_row() -> &'static str {
        r#"
            display: flex;
            flex: 1;
        "#
    }

    pub fn activity_bar() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
            width: 32px;
            padding: 6px 0;
            background: var(--color-bg-primary);
            border-right: 1px solid var(--color-border);
        "#
    }

    pub fn activity_icon() -> &'static str {
        r#"
            width: 20px;
            height: 20px;
            background: var(--color-border);
            border-radius: var(--radius-sm);
        "#
    }

    pub fn sidebar(width_percent: f64) -> String {
        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                width: {}%;
                min-width: 60px;
                background: var(--color-bg-secondary);
                border-right: 1px solid var(--color-border);
            "#,
            width_percent.clamp(15.0, 40.0)
        )
    }

    pub fn sidebar_text() -> &'static str {
        r#"
            font-size: 10px;
            color: var(--color-text-tertiary);
        "#
    }

    pub fn main_content() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: center;
            flex: 1;
            background: var(--color-surface);
        "#
    }

    pub fn main_text() -> &'static str {
        r#"
            font-size: 11px;
            color: var(--color-text-secondary);
        "#
    }

    pub fn bottom_panel(height_percent: f64) -> String {
        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                height: {}%;
                min-height: 30px;
                background: var(--color-bg-secondary);
                border-top: 1px solid var(--color-border);
            "#,
            height_percent.clamp(10.0, 30.0)
        )
    }

    pub fn panel_text() -> &'static str {
        r#"
            font-size: 10px;
            color: var(--color-text-tertiary);
        "#
    }
}
