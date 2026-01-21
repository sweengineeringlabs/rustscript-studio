//! Tooltip component for hover hints.

use rsc::prelude::*;

/// Tooltip placement.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TooltipPlacement {
    Top,
    Bottom,
    Left,
    Right,
}

impl Default for TooltipPlacement {
    fn default() -> Self {
        TooltipPlacement::Top
    }
}

/// Tooltip component that shows on hover.
///
/// ## Example
/// ```rust,ignore
/// <Tooltip content={"Click to save".to_string()} placement={TooltipPlacement::Top}>
///     <Button on_click={save}>Save</Button>
/// </Tooltip>
/// ```
component Tooltip(
    /// Tooltip content text
    content: String,
    /// Tooltip placement
    placement?: TooltipPlacement,
    /// Delay before showing tooltip (ms)
    delay?: u32,
    /// Whether the tooltip is disabled
    disabled?: bool,
    /// The element to wrap with tooltip
    children: Element,
) {
    let placement = placement.unwrap_or(TooltipPlacement::default());
    let delay = delay.unwrap_or(300);
    let disabled = disabled.unwrap_or(false);

    let is_visible = signal(false);
    let timeout_id = signal(None::<i32>);

    render {
        <div
            class="tooltip-wrapper"
            style={styles::wrapper()}
            on:mouseenter={|| {
                if !disabled {
                    // In a real implementation, we'd use setTimeout
                    // For now, show immediately (delay would be handled by JS interop)
                    is_visible.set(true);
                }
            }}
            on:mouseleave={|| {
                is_visible.set(false);
            }}
            on:focus={|| {
                if !disabled {
                    is_visible.set(true);
                }
            }}
            on:blur={|| {
                is_visible.set(false);
            }}
        >
            {children}

            @if is_visible.get() && !disabled {
                <div
                    class="tooltip"
                    style={styles::tooltip(placement)}
                    role="tooltip"
                >
                    {content.clone()}
                    <div class="tooltip-arrow" style={styles::arrow(placement)} />
                </div>
            }
        </div>
    }
}

mod styles {
    use super::TooltipPlacement;

    pub fn wrapper() -> &'static str {
        r#"
            position: relative;
            display: inline-block;
        "#
    }

    pub fn tooltip(placement: TooltipPlacement) -> String {
        let (position, transform) = match placement {
            TooltipPlacement::Top => (
                "bottom: 100%; left: 50%; margin-bottom: 8px;",
                "translateX(-50%)",
            ),
            TooltipPlacement::Bottom => (
                "top: 100%; left: 50%; margin-top: 8px;",
                "translateX(-50%)",
            ),
            TooltipPlacement::Left => (
                "right: 100%; top: 50%; margin-right: 8px;",
                "translateY(-50%)",
            ),
            TooltipPlacement::Right => (
                "left: 100%; top: 50%; margin-left: 8px;",
                "translateY(-50%)",
            ),
        };

        format!(
            r#"
                position: absolute;
                {position}
                transform: {transform};
                padding: var(--spacing-xs) var(--spacing-sm);
                background: var(--color-bg-elevated);
                color: var(--color-text-primary);
                font-size: var(--font-size-sm);
                border-radius: var(--radius-md);
                box-shadow: var(--shadow-lg);
                white-space: nowrap;
                z-index: 1000;
                pointer-events: none;
                animation: fadeIn 0.15s ease;
            "#,
            position = position,
            transform = transform,
        )
    }

    pub fn arrow(placement: TooltipPlacement) -> String {
        let position = match placement {
            TooltipPlacement::Top => "top: 100%; left: 50%; transform: translateX(-50%); border-color: var(--color-bg-elevated) transparent transparent transparent;",
            TooltipPlacement::Bottom => "bottom: 100%; left: 50%; transform: translateX(-50%); border-color: transparent transparent var(--color-bg-elevated) transparent;",
            TooltipPlacement::Left => "left: 100%; top: 50%; transform: translateY(-50%); border-color: transparent transparent transparent var(--color-bg-elevated);",
            TooltipPlacement::Right => "right: 100%; top: 50%; transform: translateY(-50%); border-color: transparent var(--color-bg-elevated) transparent transparent;",
        };

        format!(
            r#"
                position: absolute;
                {position}
                width: 0;
                height: 0;
                border-width: 6px;
                border-style: solid;
            "#,
            position = position,
        )
    }
}
