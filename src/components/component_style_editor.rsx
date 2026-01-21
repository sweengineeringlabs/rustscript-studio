//! Component style editor for visual CSS component styling.

use rsc::prelude::*;

use rsc_studio::designer::css::{
    ComponentStyle, ComponentStyles, ComponentType, StyleProperties,
    StateVariant, Breakpoint,
};
use super::{Icon, Input, Select, SelectOption, Tabs, Tab, Button, ButtonVariant, ButtonSize};

/// Component style editor.
#[component]
pub fn ComponentStyleEditor(
    styles: Signal<ComponentStyles>,
    on_change: Callback<(String, ComponentStyle)>,
) -> Element {
    let selected_component = use_signal(|| ComponentType::Button);
    let selected_state = use_signal(|| StateVariant::Default);
    let selected_breakpoint = use_signal(|| Breakpoint::Base);
    let active_tab = use_signal(|| "states".to_string());

    let component_name = selected_component.get().label().to_lowercase();
    let current_style = styles.get().get(&component_name).cloned().unwrap_or_default();

    // Get properties for the current state/breakpoint
    let current_props = if active_tab.get() == "states" {
        if selected_state.get() == StateVariant::Default {
            current_style.base.clone()
        } else {
            current_style.states.get(&selected_state.get()).cloned().unwrap_or_default()
        }
    } else {
        current_style.breakpoints.get(&selected_breakpoint.get()).cloned().unwrap_or_default()
    };

    let on_property_change = {
        let styles = styles.clone();
        let selected_component = selected_component.clone();
        let selected_state = selected_state.clone();
        let selected_breakpoint = selected_breakpoint.clone();
        let active_tab = active_tab.clone();
        let on_change = on_change.clone();
        move |(prop_name, value): (String, Option<String>)| {
            let component_name = selected_component.get().label().to_lowercase();
            let mut style = styles.get().get(&component_name).cloned().unwrap_or_default();

            if active_tab.get() == "states" {
                if selected_state.get() == StateVariant::Default {
                    style.base.set(&prop_name, value);
                } else {
                    let state_props = style.states.entry(selected_state.get()).or_default();
                    state_props.set(&prop_name, value);
                }
            } else {
                let bp_props = style.breakpoints.entry(selected_breakpoint.get()).or_default();
                bp_props.set(&prop_name, value);
            }

            on_change.call((component_name, style));
        }
    };

    rsx! {
        div(class: "component-style-editor", style: editor_styles::container()) {
            // Component selector
            div(class: "component-selector", style: editor_styles::component_selector()) {
                h3(style: editor_styles::section_title()) { "Components" }
                div(class: "component-list", style: editor_styles::component_list()) {
                    for ct in ComponentType::all() {
                        ComponentTypeItem {
                            component_type: *ct,
                            selected: selected_component.get() == *ct,
                            onclick: {
                                let selected_component = selected_component.clone();
                                move |_| selected_component.set(*ct)
                            },
                        }
                    }
                }
            }

            // Style editor
            div(class: "style-editor", style: editor_styles::style_editor()) {
                // Header
                div(class: "editor-header", style: editor_styles::editor_header()) {
                    Icon { name: selected_component.get().icon().to_string(), size: 20 }
                    h3(style: editor_styles::editor_title()) {
                        { selected_component.get().label() }
                    }
                }

                // State/Breakpoint tabs
                div(class: "mode-tabs", style: editor_styles::mode_tabs()) {
                    Tabs {
                        tabs: vec![
                            Tab { id: "states".to_string(), label: "States".to_string(), icon: Some("mouse-pointer".to_string()) },
                            Tab { id: "responsive".to_string(), label: "Responsive".to_string(), icon: Some("monitor".to_string()) },
                        ],
                        active: active_tab.clone(),
                        onchange: {
                            let active_tab = active_tab.clone();
                            move |id: String| active_tab.set(id)
                        },
                    }
                }

                // State variants or Breakpoint selector
                if active_tab.get() == "states" {
                    div(class: "state-selector", style: editor_styles::variant_selector()) {
                        for state in StateVariant::all() {
                            StateVariantButton {
                                state: *state,
                                selected: selected_state.get() == *state,
                                onclick: {
                                    let selected_state = selected_state.clone();
                                    move |_| selected_state.set(*state)
                                },
                            }
                        }
                    }
                } else {
                    div(class: "breakpoint-selector", style: editor_styles::variant_selector()) {
                        for bp in Breakpoint::all() {
                            BreakpointButton {
                                breakpoint: *bp,
                                selected: selected_breakpoint.get() == *bp,
                                onclick: {
                                    let selected_breakpoint = selected_breakpoint.clone();
                                    move |_| selected_breakpoint.set(*bp)
                                },
                            }
                        }
                    }
                }

                // Property editors
                div(class: "property-editors", style: editor_styles::property_editors()) {
                    PropertySection {
                        title: "Layout".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("display", "Display", vec!["flex", "block", "inline-flex", "grid", "none"]),
                            ("flex-direction", "Direction", vec!["row", "column", "row-reverse", "column-reverse"]),
                            ("align-items", "Align", vec!["stretch", "center", "flex-start", "flex-end", "baseline"]),
                            ("justify-content", "Justify", vec!["flex-start", "center", "flex-end", "space-between", "space-around"]),
                            ("gap", "Gap", vec![]),
                        ],
                    }

                    PropertySection {
                        title: "Spacing".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("padding", "Padding", vec![]),
                            ("margin", "Margin", vec![]),
                        ],
                    }

                    PropertySection {
                        title: "Sizing".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("width", "Width", vec![]),
                            ("height", "Height", vec![]),
                            ("min-width", "Min W", vec![]),
                            ("max-width", "Max W", vec![]),
                        ],
                    }

                    PropertySection {
                        title: "Colors".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("color", "Text", vec![]),
                            ("background", "Background", vec![]),
                            ("border-color", "Border", vec![]),
                        ],
                    }

                    PropertySection {
                        title: "Border".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("border-width", "Width", vec![]),
                            ("border-style", "Style", vec!["none", "solid", "dashed", "dotted"]),
                            ("border-radius", "Radius", vec![]),
                        ],
                    }

                    PropertySection {
                        title: "Typography".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("font-size", "Size", vec![]),
                            ("font-weight", "Weight", vec!["400", "500", "600", "700"]),
                            ("line-height", "Line H", vec![]),
                        ],
                    }

                    PropertySection {
                        title: "Effects".to_string(),
                        properties: current_props.clone(),
                        on_change: on_property_change.clone(),
                        fields: vec![
                            ("box-shadow", "Shadow", vec![]),
                            ("opacity", "Opacity", vec![]),
                            ("cursor", "Cursor", vec!["default", "pointer", "not-allowed", "text"]),
                            ("transition", "Transition", vec![]),
                        ],
                    }
                }
            }

            // Live preview
            div(class: "component-preview", style: editor_styles::component_preview()) {
                h3(style: editor_styles::section_title()) { "Preview" }
                ComponentPreviewPane {
                    component_type: selected_component.get(),
                    style: current_style.clone(),
                    active_state: if active_tab.get() == "states" { Some(selected_state.get()) } else { None },
                }

                // CSS Output
                div(class: "css-output", style: editor_styles::css_output()) {
                    h4(style: editor_styles::css_output_title()) { "Generated CSS" }
                    pre(style: editor_styles::css_code()) {
                        code { { generate_component_css(&component_name, &current_style) } }
                    }
                }
            }
        }
    }
}

/// Component type list item.
#[component]
fn ComponentTypeItem(
    component_type: ComponentType,
    selected: bool,
    onclick: Callback<()>,
) -> Element {
    rsx! {
        div(
            class: format!("component-item {}", if selected { "selected" } else { "" }),
            style: editor_styles::component_item(selected),
            onclick: move |_| onclick.call(()),
        ) {
            Icon { name: component_type.icon().to_string(), size: 16 }
            span { { component_type.label() } }
        }
    }
}

/// State variant button.
#[component]
fn StateVariantButton(
    state: StateVariant,
    selected: bool,
    onclick: Callback<()>,
) -> Element {
    rsx! {
        button(
            class: format!("variant-btn {}", if selected { "selected" } else { "" }),
            style: editor_styles::variant_button(selected),
            onclick: move |_| onclick.call(()),
        ) {
            { state.label() }
        }
    }
}

/// Breakpoint button.
#[component]
fn BreakpointButton(
    breakpoint: Breakpoint,
    selected: bool,
    onclick: Callback<()>,
) -> Element {
    let min_width = breakpoint.min_width();

    rsx! {
        button(
            class: format!("variant-btn {}", if selected { "selected" } else { "" }),
            style: editor_styles::variant_button(selected),
            onclick: move |_| onclick.call(()),
        ) {
            span { { breakpoint.label() } }
            if let Some(w) = min_width {
                span(style: "font-size: 10px; opacity: 0.7;") {
                    { format!("{}px", w) }
                }
            }
        }
    }
}

/// Property section with multiple fields.
#[component]
fn PropertySection(
    title: String,
    properties: StyleProperties,
    on_change: Callback<(String, Option<String>)>,
    fields: Vec<(&'static str, &'static str, Vec<&'static str>)>,
) -> Element {
    let expanded = use_signal(|| true);

    rsx! {
        div(class: "property-section", style: editor_styles::property_section()) {
            div(
                class: "property-section-header",
                style: editor_styles::property_section_header(),
                onclick: move |_| expanded.update(|v| *v = !*v),
            ) {
                Icon {
                    name: if expanded.get() { "chevron-down" } else { "chevron-right" }.to_string(),
                    size: 14,
                }
                span { { title } }
            }

            if expanded.get() {
                div(class: "property-fields", style: editor_styles::property_fields()) {
                    for (prop_name, label, options) in fields {
                        PropertyField {
                            name: prop_name.to_string(),
                            label: label.to_string(),
                            value: properties.get(prop_name).cloned(),
                            options: options.iter().map(|s| s.to_string()).collect(),
                            on_change: on_change.clone(),
                        }
                    }
                }
            }
        }
    }
}

/// Single property field.
#[component]
fn PropertyField(
    name: String,
    label: String,
    value: Option<String>,
    options: Vec<String>,
    on_change: Callback<(String, Option<String>)>,
) -> Element {
    let local_value = use_signal(|| value.clone().unwrap_or_default());

    rsx! {
        div(class: "property-field", style: editor_styles::property_field()) {
            label(style: editor_styles::property_label()) { { label } }

            if options.is_empty() {
                // Text input
                input(
                    type: "text",
                    value: local_value.get(),
                    placeholder: "inherit",
                    style: editor_styles::property_input(),
                    onchange: {
                        let name = name.clone();
                        let on_change = on_change.clone();
                        move |e: Event<FormData>| {
                            let v = e.value();
                            local_value.set(v.clone());
                            let val = if v.is_empty() { None } else { Some(v) };
                            on_change.call((name.clone(), val));
                        }
                    },
                )
            } else {
                // Select with predefined options
                select(
                    value: local_value.get(),
                    style: editor_styles::property_select(),
                    onchange: {
                        let name = name.clone();
                        let on_change = on_change.clone();
                        move |e: Event<FormData>| {
                            let v = e.value();
                            local_value.set(v.clone());
                            let val = if v.is_empty() || v == "inherit" { None } else { Some(v) };
                            on_change.call((name.clone(), val));
                        }
                    },
                ) {
                    option(value: "") { "inherit" }
                    for opt in &options {
                        option(value: opt.clone(), selected: value.as_ref() == Some(opt)) {
                            { opt.clone() }
                        }
                    }
                }
            }
        }
    }
}

/// Component preview pane.
#[component]
fn ComponentPreviewPane(
    component_type: ComponentType,
    style: ComponentStyle,
    active_state: Option<StateVariant>,
) -> Element {
    let preview_style = generate_preview_style(&style, active_state);

    rsx! {
        div(class: "preview-container", style: editor_styles::preview_container()) {
            match component_type {
                ComponentType::Button => {
                    button(style: preview_style) { "Click Me" }
                }
                ComponentType::Input => {
                    input(
                        type: "text",
                        placeholder: "Enter text...",
                        style: preview_style,
                    )
                }
                ComponentType::Card => {
                    div(style: preview_style) {
                        h4 { "Card Title" }
                        p { "Card content goes here." }
                    }
                }
                ComponentType::Badge => {
                    span(style: preview_style) { "Badge" }
                }
                ComponentType::Alert => {
                    div(style: preview_style) {
                        strong { "Alert: " }
                        span { "This is an alert message." }
                    }
                }
                _ => {
                    div(style: preview_style) {
                        { format!("{} Preview", component_type.label()) }
                    }
                }
            }
        }
    }
}

/// Generate preview style string from component style.
fn generate_preview_style(style: &ComponentStyle, active_state: Option<StateVariant>) -> String {
    let mut css = style.base.to_css();

    if let Some(state) = active_state {
        if state != StateVariant::Default {
            if let Some(state_props) = style.states.get(&state) {
                css.push_str(&state_props.to_css());
            }
        }
    }

    css.replace('\n', " ")
}

/// Generate CSS for a component.
fn generate_component_css(name: &str, style: &ComponentStyle) -> String {
    let mut css = String::new();

    // Base styles
    let base_css = style.base.to_css();
    if !base_css.is_empty() {
        css.push_str(&format!(".{} {{\n{}}}\n", name, base_css));
    }

    // State variants
    for (state, props) in &style.states {
        let state_css = props.to_css();
        if !state_css.is_empty() {
            css.push_str(&format!(
                "\n.{}{} {{\n{}}}\n",
                name,
                state.css_selector(),
                state_css
            ));
        }
    }

    // Breakpoints
    for (bp, props) in &style.breakpoints {
        let bp_css = props.to_css();
        if !bp_css.is_empty() {
            if let Some(min_width) = bp.min_width() {
                css.push_str(&format!(
                    "\n@media (min-width: {}px) {{\n  .{} {{\n{}  }}\n}}\n",
                    min_width,
                    name,
                    bp_css.lines().map(|l| format!("  {}", l)).collect::<Vec<_>>().join("\n")
                ));
            }
        }
    }

    if css.is_empty() {
        format!(".{} {{\n  /* No styles defined */\n}}", name)
    } else {
        css
    }
}

mod editor_styles {
    pub fn container() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: 200px 1fr 300px;
            gap: var(--spacing-md);
            height: 100%;
            overflow: hidden;
        "#
    }

    pub fn component_selector() -> &'static str {
        r#"
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            padding: var(--spacing-md);
            overflow-y: auto;
        "#
    }

    pub fn section_title() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-sm) 0;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-secondary);
            text-transform: uppercase;
        "#
    }

    pub fn component_list() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn component_item(selected: bool) -> String {
        format!(
            r#"
                display: flex;
                align-items: center;
                gap: var(--spacing-sm);
                padding: var(--spacing-sm) var(--spacing-md);
                border-radius: var(--radius-md);
                cursor: pointer;
                transition: var(--transition-fast);
                background: {};
                color: {};
            "#,
            if selected { "var(--color-primary)" } else { "transparent" },
            if selected { "white" } else { "var(--color-text-primary)" }
        )
    }

    pub fn style_editor() -> &'static str {
        r#"
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        "#
    }

    pub fn editor_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-md);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn editor_title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-lg);
            font-weight: var(--font-weight-semibold);
        "#
    }

    pub fn mode_tabs() -> &'static str {
        r#"
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn variant_selector() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-xs);
            padding: var(--spacing-sm) var(--spacing-md);
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
            overflow-x: auto;
        "#
    }

    pub fn variant_button(selected: bool) -> String {
        format!(
            r#"
                display: flex;
                flex-direction: column;
                align-items: center;
                padding: var(--spacing-xs) var(--spacing-sm);
                border: 1px solid {};
                border-radius: var(--radius-sm);
                background: {};
                color: {};
                cursor: pointer;
                font-size: var(--font-size-xs);
                transition: var(--transition-fast);
            "#,
            if selected { "var(--color-primary)" } else { "var(--color-border)" },
            if selected { "var(--color-primary)" } else { "transparent" },
            if selected { "white" } else { "var(--color-text-primary)" }
        )
    }

    pub fn property_editors() -> &'static str {
        r#"
            flex: 1;
            overflow-y: auto;
            padding: var(--spacing-md);
        "#
    }

    pub fn property_section() -> &'static str {
        r#"
            margin-bottom: var(--spacing-md);
        "#
    }

    pub fn property_section_header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-xs) 0;
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-secondary);
            cursor: pointer;
        "#
    }

    pub fn property_fields() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: var(--spacing-sm);
            padding: var(--spacing-sm) 0;
        "#
    }

    pub fn property_field() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: 2px;
        "#
    }

    pub fn property_label() -> &'static str {
        r#"
            font-size: 10px;
            color: var(--color-text-tertiary);
            text-transform: uppercase;
        "#
    }

    pub fn property_input() -> &'static str {
        r#"
            width: 100%;
            padding: var(--spacing-xs);
            font-size: var(--font-size-sm);
            font-family: var(--font-mono);
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
            color: var(--color-text-primary);
        "#
    }

    pub fn property_select() -> &'static str {
        r#"
            width: 100%;
            padding: var(--spacing-xs);
            font-size: var(--font-size-sm);
            background: var(--color-bg-secondary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
            color: var(--color-text-primary);
        "#
    }

    pub fn component_preview() -> &'static str {
        r#"
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            padding: var(--spacing-md);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        "#
    }

    pub fn preview_container() -> &'static str {
        r#"
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: var(--spacing-lg);
            background: var(--color-bg-secondary);
            border: 1px dashed var(--color-border);
            border-radius: var(--radius-md);
            margin-bottom: var(--spacing-md);
        "#
    }

    pub fn css_output() -> &'static str {
        r#"
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 0;
        "#
    }

    pub fn css_output_title() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-xs) 0;
            font-size: var(--font-size-xs);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-secondary);
            text-transform: uppercase;
        "#
    }

    pub fn css_code() -> &'static str {
        r#"
            flex: 1;
            margin: 0;
            padding: var(--spacing-sm);
            background: var(--color-bg-tertiary);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-sm);
            font-family: var(--font-mono);
            font-size: var(--font-size-xs);
            line-height: 1.5;
            overflow: auto;
            white-space: pre;
        "#
    }
}
