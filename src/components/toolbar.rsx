//! Toolbar component for action buttons.

use rsc::prelude::*;

use super::{Button, ButtonVariant, ButtonSize, Icon};

/// Toolbar component.
component Toolbar(children: Element) {
    render {
        <div class="toolbar" style={styles::container()}>
            {children}
        </div>
    }
}

/// Toolbar group for organizing buttons.
component ToolbarGroup(children: Element) {
    render {
        <div class="toolbar-group" style={styles::group()}>
            {children}
        </div>
    }
}

/// Toolbar button.
component ToolbarButton(
    icon: String,
    label?: String,
    active?: bool,
    on_click: Callback<()>,
) {
    let active = active.unwrap_or(false);

    let variant = if active {
        ButtonVariant::Primary
    } else {
        ButtonVariant::Ghost
    };

    render {
        <Button variant={variant} size={ButtonSize::Sm} on_click={on_click.clone()}>
            <Icon name={icon.clone()} size={16} />
            @if let Some(ref label) = label {
                <span>{label.clone()}</span>
            }
        </Button>
    }
}

/// Toolbar divider.
component ToolbarDivider() {
    render {
        <div class="toolbar-divider" style={styles::divider()} />
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm);
            background: var(--color-bg-secondary);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn group() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: 2px;
        "#
    }

    pub fn divider() -> &'static str {
        r#"
            width: 1px;
            height: 24px;
            background: var(--color-border);
            margin: 0 var(--spacing-sm);
        "#
    }
}
