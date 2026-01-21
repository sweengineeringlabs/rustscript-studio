//! Panel component - collapsible content section.

use rsc::prelude::*;

use super::Icon;

/// Panel component.
component Panel(
    title: &'static str,
    icon?: String,
    collapsible?: bool,
    default_open?: bool,
    children: Element,
) {
    let collapsible = collapsible.unwrap_or(true);
    let default_open = default_open.unwrap_or(true);

    let is_open = signal(default_open);

    render {
        <div class="panel" style={styles::container()}>
            // Header
            <div
                class="panel-header"
                style={styles::header()}
                on:click={|| {
                    if collapsible {
                        is_open.update(|v| *v = !*v);
                    }
                }}
            >
                <div class="panel-header-left" style={styles::header_left()}>
                    @if let Some(ref icon) = icon {
                        <Icon name={icon.clone()} size={16} />
                    }
                    <span class="panel-title" style={styles::title()}>
                        {title}
                    </span>
                </div>

                @if collapsible {
                    <div
                        class="panel-toggle"
                        style={styles::toggle(is_open.get())}
                    >
                        <Icon name={"chevron-down".to_string()} size={16} />
                    </div>
                }
            </div>

            // Content
            @if is_open.get() {
                <div class="panel-content" style={styles::content()}>
                    {children}
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
            background: var(--color-surface);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: var(--spacing-sm) var(--spacing-md);
            cursor: pointer;
            user-select: none;
        "#
    }

    pub fn header_left() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
        "#
    }

    pub fn title() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-semibold);
            text-transform: uppercase;
            color: var(--color-text-secondary);
        "#
    }

    pub fn toggle(is_open: bool) -> String {
        let rotation = if is_open { "0" } else { "-90" };
        format!(
            r#"
                transform: rotate({}deg);
                transition: var(--transition-fast);
                color: var(--color-text-secondary);
            "#,
            rotation
        )
    }

    pub fn content() -> &'static str {
        r#"
            padding: var(--spacing-sm) var(--spacing-md);
        "#
    }
}
