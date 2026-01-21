//! Context menu component for right-click menus.

use rsc::prelude::*;

/// Menu item type.
#[derive(Debug, Clone)]
pub enum MenuItem {
    /// Regular action item
    Action {
        id: String,
        label: String,
        icon: Option<String>,
        shortcut: Option<String>,
        disabled: bool,
    },
    /// Separator line
    Separator,
    /// Submenu with nested items
    Submenu {
        id: String,
        label: String,
        icon: Option<String>,
        items: Vec<MenuItem>,
    },
}

impl MenuItem {
    pub fn action(id: impl Into<String>, label: impl Into<String>) -> Self {
        MenuItem::Action {
            id: id.into(),
            label: label.into(),
            icon: None,
            shortcut: None,
            disabled: false,
        }
    }

    pub fn with_icon(mut self, icon: impl Into<String>) -> Self {
        if let MenuItem::Action { icon: ref mut i, .. } = self {
            *i = Some(icon.into());
        }
        self
    }

    pub fn with_shortcut(mut self, shortcut: impl Into<String>) -> Self {
        if let MenuItem::Action { shortcut: ref mut s, .. } = self {
            *s = Some(shortcut.into());
        }
        self
    }

    pub fn disabled(mut self) -> Self {
        if let MenuItem::Action { disabled: ref mut d, .. } = self {
            *d = true;
        }
        self
    }

    pub fn separator() -> Self {
        MenuItem::Separator
    }

    pub fn submenu(id: impl Into<String>, label: impl Into<String>, items: Vec<MenuItem>) -> Self {
        MenuItem::Submenu {
            id: id.into(),
            label: label.into(),
            icon: None,
            items,
        }
    }
}

/// Context menu props.
#[derive(Props)]
pub struct ContextMenuProps {
    /// Whether the menu is visible
    pub is_open: bool,
    /// X position in pixels
    pub x: f64,
    /// Y position in pixels
    pub y: f64,
    /// Menu items
    pub items: Vec<MenuItem>,
    /// Callback when an item is selected (receives item id)
    #[prop(default)]
    pub on_select: Option<Callback<String>>,
    /// Callback when menu should close
    #[prop(default)]
    pub on_close: Option<Callback<()>>,
}

/// Context menu component.
///
/// ## Example
/// ```rust,ignore
/// ContextMenu {
///     is_open: menu_open.get(),
///     x: menu_pos.get().0,
///     y: menu_pos.get().1,
///     items: vec![
///         MenuItem::action("cut", "Cut").with_shortcut("Ctrl+X"),
///         MenuItem::action("copy", "Copy").with_shortcut("Ctrl+C"),
///         MenuItem::separator(),
///         MenuItem::action("delete", "Delete").with_icon("trash"),
///     ],
///     on_select: Callback::new(move |id| handle_action(id)),
///     on_close: Callback::new(move |_| menu_open.set(false)),
/// }
/// ```
#[component]
pub fn ContextMenu(props: ContextMenuProps) -> Element {
    if !props.is_open {
        return rsx! {};
    }

    let on_overlay_click = {
        let on_close = props.on_close.clone();
        move |_: MouseEvent| {
            if let Some(ref callback) = on_close {
                callback.call(());
            }
        }
    };

    let on_menu_click = move |e: MouseEvent| {
        e.stop_propagation();
    };

    let on_key_down = {
        let on_close = props.on_close.clone();
        move |e: KeyboardEvent| {
            if e.key() == "Escape" {
                if let Some(ref callback) = on_close {
                    callback.call(());
                }
            }
        }
    };

    rsx! {
        div(
            class="context-menu-overlay",
            style=styles::overlay(),
            on:click=on_overlay_click,
            on:contextmenu=on_overlay_click,
            on:keydown=on_key_down,
            tabindex="-1",
        ) {
            div(
                class="context-menu",
                style=styles::menu(props.x, props.y),
                on:click=on_menu_click,
                role="menu",
            ) {
                for item in props.items.iter() {
                    ContextMenuItem {
                        item: item.clone(),
                        on_select: props.on_select.clone(),
                        on_close: props.on_close.clone(),
                    }
                }
            }
        }
    }
}

#[derive(Props)]
struct ContextMenuItemProps {
    item: MenuItem,
    #[prop(default)]
    on_select: Option<Callback<String>>,
    #[prop(default)]
    on_close: Option<Callback<()>>,
}

#[component]
fn ContextMenuItem(props: ContextMenuItemProps) -> Element {
    match &props.item {
        MenuItem::Action { id, label, icon, shortcut, disabled } => {
            let on_click = {
                let id = id.clone();
                let disabled = *disabled;
                let on_select = props.on_select.clone();
                let on_close = props.on_close.clone();
                move |_: MouseEvent| {
                    if !disabled {
                        if let Some(ref callback) = on_select {
                            callback.call(id.clone());
                        }
                        if let Some(ref callback) = on_close {
                            callback.call(());
                        }
                    }
                }
            };

            rsx! {
                div(
                    class="context-menu-item",
                    style=styles::item(*disabled),
                    on:click=on_click,
                    role="menuitem",
                    aria-disabled=disabled.to_string(),
                ) {
                    if let Some(ref icon_name) = icon {
                        span(class="context-menu-icon", style=styles::icon()) {
                            { icon_name.clone() }
                        }
                    }
                    span(class="context-menu-label", style=styles::label()) {
                        { label.clone() }
                    }
                    if let Some(ref shortcut_text) = shortcut {
                        span(class="context-menu-shortcut", style=styles::shortcut()) {
                            { shortcut_text.clone() }
                        }
                    }
                }
            }
        }
        MenuItem::Separator => {
            rsx! {
                div(class="context-menu-separator", style=styles::separator(), role="separator")
            }
        }
        MenuItem::Submenu { id, label, icon, items } => {
            let is_open = use_signal(|| false);

            rsx! {
                div(
                    class="context-menu-submenu",
                    style=styles::submenu_wrapper(),
                    on:mouseenter=move |_| is_open.set(true),
                    on:mouseleave=move |_| is_open.set(false),
                ) {
                    div(class="context-menu-item", style=styles::item(false), role="menuitem") {
                        if let Some(ref icon_name) = icon {
                            span(class="context-menu-icon", style=styles::icon()) {
                                { icon_name.clone() }
                            }
                        }
                        span(class="context-menu-label", style=styles::label()) {
                            { label.clone() }
                        }
                        span(class="context-menu-chevron", style=styles::chevron()) {
                            "›"
                        }
                    }
                    if is_open.get() {
                        div(class="context-menu-submenu-content", style=styles::submenu_content()) {
                            for item in items.iter() {
                                ContextMenuItem {
                                    item: item.clone(),
                                    on_select: props.on_select.clone(),
                                    on_close: props.on_close.clone(),
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

mod styles {
    pub fn overlay() -> &'static str {
        r#"
            position: fixed;
            inset: 0;
            z-index: 1000;
        "#
    }

    pub fn menu(x: f64, y: f64) -> String {
        format!(
            r#"
                position: fixed;
                left: {x}px;
                top: {y}px;
                min-width: 180px;
                background: var(--color-surface);
                border: 1px solid var(--color-border);
                border-radius: var(--radius-lg);
                box-shadow: var(--shadow-xl);
                padding: var(--spacing-xs) 0;
                animation: fadeIn 0.1s ease;
            "#,
            x = x,
            y = y,
        )
    }

    pub fn item(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        let cursor = if disabled { "not-allowed" } else { "pointer" };
        format!(
            r#"
                display: flex;
                align-items: center;
                gap: var(--spacing-sm);
                padding: var(--spacing-xs) var(--spacing-md);
                opacity: {opacity};
                cursor: {cursor};
                transition: var(--transition-fast);
            "#,
            opacity = opacity,
            cursor = cursor,
        )
    }

    pub fn icon() -> &'static str {
        r#"
            width: 16px;
            height: 16px;
            color: var(--color-text-secondary);
        "#
    }

    pub fn label() -> &'static str {
        r#"
            flex: 1;
            font-size: var(--font-size-sm);
            color: var(--color-text-primary);
        "#
    }

    pub fn shortcut() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            color: var(--color-text-muted);
            font-family: var(--font-mono);
        "#
    }

    pub fn chevron() -> &'static str {
        r#"
            font-size: var(--font-size-base);
            color: var(--color-text-secondary);
        "#
    }

    pub fn separator() -> &'static str {
        r#"
            height: 1px;
            background: var(--color-border);
            margin: var(--spacing-xs) 0;
        "#
    }

    pub fn submenu_wrapper() -> &'static str {
        r#"
            position: relative;
        "#
    }

    pub fn submenu_content() -> &'static str {
        r#"
            position: absolute;
            left: 100%;
            top: 0;
            min-width: 160px;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-xl);
            padding: var(--spacing-xs) 0;
        "#
    }
}
