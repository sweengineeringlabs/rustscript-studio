//! Zoom controls component for flow canvas.

use rsc::prelude::*;

use super::Button;

/// ZoomControls component for controlling canvas zoom level.
///
/// ## Example
/// ```rust,ignore
/// ZoomControls {
///     zoom: canvas.get().viewport.transform.zoom,
///     on_zoom_in: Callback::new(move |_| canvas.update(|c| c.viewport.zoom_in(1.2))),
///     on_zoom_out: Callback::new(move |_| canvas.update(|c| c.viewport.zoom_out(1.2))),
///     on_zoom_reset: Callback::new(move |_| canvas.update(|c| c.viewport.reset())),
///     on_fit_view: Callback::new(move |_| fit_to_view()),
/// }
/// ```
#[component]
pub fn ZoomControls(
    /// Current zoom level (0.0 to 1.0 scale)
    zoom: f64,
    /// Minimum zoom level
    min_zoom: Option<f64>,
    /// Maximum zoom level
    max_zoom: Option<f64>,
    /// Whether to show the zoom percentage
    show_percentage: Option<bool>,
    /// Whether controls are disabled
    disabled: Option<bool>,
    /// Callback for zoom in
    on_zoom_in: Option<Callback<()>>,
    /// Callback for zoom out
    on_zoom_out: Option<Callback<()>>,
    /// Callback for zoom reset (fit to view)
    on_zoom_reset: Option<Callback<()>>,
    /// Callback for fit to view
    on_fit_view: Option<Callback<()>>,
) -> Element {
    let min_zoom = min_zoom.unwrap_or(0.1);
    let max_zoom = max_zoom.unwrap_or(4.0);
    let show_percentage = show_percentage.unwrap_or(true);
    let disabled = disabled.unwrap_or(false);
    let zoom_percentage = (zoom * 100.0).round() as i32;

    let on_zoom_in_click = {
        let callback = on_zoom_in.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    let on_zoom_out_click = {
        let callback = on_zoom_out.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    let on_reset_click = {
        let callback = on_zoom_reset.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    let on_fit_click = {
        let callback = on_fit_view.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    let can_zoom_in = zoom < max_zoom;
    let can_zoom_out = zoom > min_zoom;

    rsx! {
        div(class: "zoom-controls", style: styles::container()) {
            // Zoom out button
            button(
                class: "zoom-control-btn",
                style: styles::button(disabled || !can_zoom_out),
                disabled: disabled || !can_zoom_out,
                onclick: on_zoom_out_click,
                title: "Zoom out (-)",
            ) {
                svg(width: "16", height: "16", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke-width: "2") {
                    path(d: "M5 12h14")
                }
            }

            // Zoom percentage / Reset button
            if show_percentage {
                button(
                    class: "zoom-control-percentage",
                    style: styles::percentage_button(disabled),
                    disabled: disabled,
                    onclick: on_reset_click,
                    title: "Reset zoom (0)",
                ) {
                    { format!("{}%", zoom_percentage) }
                }
            }

            // Zoom in button
            button(
                class: "zoom-control-btn",
                style: styles::button(disabled || !can_zoom_in),
                disabled: disabled || !can_zoom_in,
                onclick: on_zoom_in_click,
                title: "Zoom in (+)",
            ) {
                svg(width: "16", height: "16", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke-width: "2") {
                    path(d: "M12 5v14M5 12h14")
                }
            }

            // Separator
            div(class: "zoom-control-separator", style: styles::separator())

            // Fit to view button
            button(
                class: "zoom-control-btn",
                style: styles::button(disabled),
                disabled: disabled,
                onclick: on_fit_click,
                title: "Fit to view",
            ) {
                svg(width: "16", height: "16", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke-width: "2") {
                    path(d: "M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7")
                }
            }
        }
    }
}

mod styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-xs);
            padding: var(--spacing-xs);
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-md);
        "#
    }

    pub fn button(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        let cursor = if disabled { "not-allowed" } else { "pointer" };
        format!(
            r#"
                display: flex;
                align-items: center;
                justify-content: center;
                width: 32px;
                height: 32px;
                background: transparent;
                border: none;
                border-radius: var(--radius-md);
                color: var(--color-text-secondary);
                cursor: {cursor};
                opacity: {opacity};
                transition: var(--transition-fast);
            "#,
            cursor = cursor,
            opacity = opacity,
        )
    }

    pub fn percentage_button(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        let cursor = if disabled { "not-allowed" } else { "pointer" };
        format!(
            r#"
                min-width: 48px;
                height: 32px;
                padding: 0 var(--spacing-sm);
                background: transparent;
                border: none;
                border-radius: var(--radius-md);
                color: var(--color-text-primary);
                font-size: var(--font-size-sm);
                font-weight: var(--font-weight-medium);
                cursor: {cursor};
                opacity: {opacity};
                transition: var(--transition-fast);
            "#,
            cursor = cursor,
            opacity = opacity,
        )
    }

    pub fn separator() -> &'static str {
        r#"
            width: 1px;
            height: 20px;
            background: var(--color-border);
            margin: 0 var(--spacing-xs);
        "#
    }
}
