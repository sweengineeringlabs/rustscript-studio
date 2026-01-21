//! Modal/Dialog component for overlays and confirmations.

use rsc::prelude::*;

use super::{Button, ButtonVariant};

/// Modal size.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModalSize {
    Sm,
    Md,
    Lg,
    Xl,
    Full,
}

impl Default for ModalSize {
    fn default() -> Self {
        ModalSize::Md
    }
}

/// Modal component for dialogs and overlays.
///
/// ## Example
/// ```rust,ignore
/// Modal {
///     is_open: show_modal.get(),
///     title: Some("Confirm Action".to_string()),
///     on_close: Callback::new(move |_| show_modal.set(false)),
///     children: rsx! {
///         p { "Are you sure you want to proceed?" }
///     }
/// }
/// ```
#[component]
pub fn Modal(
    /// Whether the modal is open
    is_open: bool,
    /// Modal title
    title: Option<String>,
    /// Modal size
    size: Option<ModalSize>,
    /// Whether clicking the overlay closes the modal
    close_on_overlay_click: Option<bool>,
    /// Whether pressing Escape closes the modal
    close_on_escape: Option<bool>,
    /// Whether to show the close button
    show_close_button: Option<bool>,
    /// Callback when modal should close
    on_close: Option<Callback<()>>,
    /// Modal content
    children: Element,
) -> Element {
    let size = size.unwrap_or(ModalSize::default());
    let close_on_overlay_click = close_on_overlay_click.unwrap_or(true);
    let close_on_escape = close_on_escape.unwrap_or(true);
    let show_close_button = show_close_button.unwrap_or(true);

    if !is_open {
        return rsx! {};
    }

    let on_overlay_click = {
        let on_close = on_close.clone();
        let close_on_overlay = close_on_overlay_click;
        move |_: MouseEvent| {
            if close_on_overlay {
                if let Some(ref callback) = on_close {
                    callback.call(());
                }
            }
        }
    };

    let on_content_click = move |e: MouseEvent| {
        e.stop_propagation();
    };

    let on_close_click = {
        let on_close = on_close.clone();
        move |_: MouseEvent| {
            if let Some(ref callback) = on_close {
                callback.call(());
            }
        }
    };

    let on_key_down = {
        let on_close = on_close.clone();
        let close_on_escape = close_on_escape;
        move |e: KeyboardEvent| {
            if close_on_escape && e.key() == "Escape" {
                if let Some(ref callback) = on_close {
                    callback.call(());
                }
            }
        }
    };

    rsx! {
        div(
            class: "modal-overlay",
            style: styles::overlay(),
            onclick: on_overlay_click,
            onkeydown: on_key_down,
            tabindex: "-1",
        ) {
            div(
                class: "modal-content",
                style: styles::content(size),
                onclick: on_content_click,
                role: "dialog",
                aria-modal: "true",
            ) {
                // Header
                if title.is_some() || show_close_button {
                    div(class: "modal-header", style: styles::header()) {
                        if let Some(ref title) = title {
                            h2(style: styles::title()) { { title.clone() } }
                        }
                        if show_close_button {
                            button(
                                class: "modal-close",
                                style: styles::close_button(),
                                onclick: on_close_click,
                                aria-label: "Close",
                            ) {
                                svg(
                                    width: "20",
                                    height: "20",
                                    viewBox: "0 0 24 24",
                                    fill: "none",
                                    stroke: "currentColor",
                                    stroke-width: "2",
                                ) {
                                    path(d: "M18 6L6 18M6 6l12 12")
                                }
                            }
                        }
                    }
                }

                // Body
                div(class: "modal-body", style: styles::body()) {
                    { children }
                }
            }
        }
    }
}

/// Pre-built confirmation dialog.
#[component]
pub fn ConfirmDialog(
    /// Whether the dialog is open
    is_open: bool,
    /// Dialog title
    title: String,
    /// Confirmation message
    message: String,
    /// Confirm button text
    confirm_text: Option<String>,
    /// Cancel button text
    cancel_text: Option<String>,
    /// Whether the action is destructive (shows red confirm button)
    destructive: Option<bool>,
    /// Callback when confirmed
    on_confirm: Option<Callback<()>>,
    /// Callback when cancelled
    on_cancel: Option<Callback<()>>,
) -> Element {
    let confirm_text = confirm_text.unwrap_or("Confirm".to_string());
    let cancel_text = cancel_text.unwrap_or("Cancel".to_string());
    let destructive = destructive.unwrap_or(false);

    let on_confirm_handler = {
        let callback = on_confirm.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    let on_cancel_handler = {
        let callback = on_cancel.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    rsx! {
        Modal {
            is_open: is_open,
            title: Some(title.clone()),
            size: ModalSize::Sm,
            on_close: on_cancel.clone(),
            children: rsx! {
                p(style: styles::message()) { { message.clone() } }
                div(style: styles::actions()) {
                    Button {
                        variant: ButtonVariant::Secondary,
                        on_click: Callback::new(on_cancel_handler),
                        children: rsx! { { cancel_text.clone() } }
                    }
                    Button {
                        variant: if destructive { ButtonVariant::Danger } else { ButtonVariant::Primary },
                        on_click: Callback::new(on_confirm_handler),
                        children: rsx! { { confirm_text.clone() } }
                    }
                }
            }
        }
    }
}

mod styles {
    use super::ModalSize;

    pub fn overlay() -> &'static str {
        r#"
            position: fixed;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            background: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(2px);
            z-index: 1000;
            animation: fadeIn 0.15s ease;
        "#
    }

    pub fn content(size: ModalSize) -> String {
        let width = match size {
            ModalSize::Sm => "400px",
            ModalSize::Md => "500px",
            ModalSize::Lg => "640px",
            ModalSize::Xl => "800px",
            ModalSize::Full => "calc(100vw - 64px)",
        };
        let max_height = match size {
            ModalSize::Full => "calc(100vh - 64px)",
            _ => "calc(100vh - 128px)",
        };
        format!(
            r#"
                width: {width};
                max-width: calc(100vw - 32px);
                max-height: {max_height};
                background: var(--color-surface);
                border-radius: var(--radius-lg);
                box-shadow: var(--shadow-xl);
                display: flex;
                flex-direction: column;
                animation: slideUp 0.2s ease;
            "#,
            width = width,
            max_height = max_height,
        )
    }

    pub fn header() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: var(--spacing-md) var(--spacing-lg);
            border-bottom: 1px solid var(--color-border);
        "#
    }

    pub fn title() -> &'static str {
        r#"
            margin: 0;
            font-size: var(--font-size-lg);
            font-weight: var(--font-weight-semibold);
            color: var(--color-text-primary);
        "#
    }

    pub fn close_button() -> &'static str {
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
            cursor: pointer;
            transition: var(--transition-fast);
        "#
    }

    pub fn body() -> &'static str {
        r#"
            padding: var(--spacing-lg);
            overflow-y: auto;
            flex: 1;
        "#
    }

    pub fn message() -> &'static str {
        r#"
            margin: 0 0 var(--spacing-lg) 0;
            color: var(--color-text-secondary);
            line-height: var(--line-height-relaxed);
        "#
    }

    pub fn actions() -> &'static str {
        r#"
            display: flex;
            justify-content: flex-end;
            gap: var(--spacing-sm);
        "#
    }
}
