//! Modal/Dialog component for overlays and confirmations.

use rsc::prelude::*;

use super::{Button, ButtonVariant};

/// Modal size.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ModalSize {
    Sm,
    #[default]
    Md,
    Lg,
    Xl,
    Full,
}

/// Modal component props.
#[derive(Props)]
pub struct ModalProps {
    /// Whether the modal is open
    pub is_open: bool,
    /// Modal title
    #[prop(default)]
    pub title: Option<String>,
    /// Modal size
    #[prop(default)]
    pub size: ModalSize,
    /// Whether clicking the overlay closes the modal
    #[prop(default = true)]
    pub close_on_overlay_click: bool,
    /// Whether pressing Escape closes the modal
    #[prop(default = true)]
    pub close_on_escape: bool,
    /// Whether to show the close button
    #[prop(default = true)]
    pub show_close_button: bool,
    /// Callback when modal should close
    #[prop(default)]
    pub on_close: Option<Callback<()>>,
    /// Modal content
    pub children: Element,
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
pub fn Modal(props: ModalProps) -> Element {
    if !props.is_open {
        return rsx! {};
    }

    let on_overlay_click = {
        let on_close = props.on_close.clone();
        let close_on_overlay = props.close_on_overlay_click;
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
        let on_close = props.on_close.clone();
        move |_: MouseEvent| {
            if let Some(ref callback) = on_close {
                callback.call(());
            }
        }
    };

    let on_key_down = {
        let on_close = props.on_close.clone();
        let close_on_escape = props.close_on_escape;
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
            class="modal-overlay",
            style=styles::overlay(),
            on:click=on_overlay_click,
            on:keydown=on_key_down,
            tabindex="-1",
        ) {
            div(
                class="modal-content",
                style=styles::content(props.size),
                on:click=on_content_click,
                role="dialog",
                aria-modal="true",
            ) {
                // Header
                if props.title.is_some() || props.show_close_button {
                    div(class="modal-header", style=styles::header()) {
                        if let Some(ref title) = props.title {
                            h2(style=styles::title()) { { title.clone() } }
                        }
                        if props.show_close_button {
                            button(
                                class="modal-close",
                                style=styles::close_button(),
                                on:click=on_close_click,
                                aria-label="Close",
                            ) {
                                svg(
                                    width="20",
                                    height="20",
                                    viewBox="0 0 24 24",
                                    fill="none",
                                    stroke="currentColor",
                                    stroke-width="2",
                                ) {
                                    path(d="M18 6L6 18M6 6l12 12")
                                }
                            }
                        }
                    }
                }

                // Body
                div(class="modal-body", style=styles::body()) {
                    { props.children }
                }
            }
        }
    }
}

/// Confirmation dialog props.
#[derive(Props)]
pub struct ConfirmDialogProps {
    /// Whether the dialog is open
    pub is_open: bool,
    /// Dialog title
    pub title: String,
    /// Confirmation message
    pub message: String,
    /// Confirm button text
    #[prop(default = "Confirm".to_string())]
    pub confirm_text: String,
    /// Cancel button text
    #[prop(default = "Cancel".to_string())]
    pub cancel_text: String,
    /// Whether the action is destructive (shows red confirm button)
    #[prop(default = false)]
    pub destructive: bool,
    /// Callback when confirmed
    #[prop(default)]
    pub on_confirm: Option<Callback<()>>,
    /// Callback when cancelled
    #[prop(default)]
    pub on_cancel: Option<Callback<()>>,
}

/// Pre-built confirmation dialog.
#[component]
pub fn ConfirmDialog(props: ConfirmDialogProps) -> Element {
    let on_confirm = {
        let callback = props.on_confirm.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    let on_cancel = {
        let callback = props.on_cancel.clone();
        move |_| {
            if let Some(ref cb) = callback {
                cb.call(());
            }
        }
    };

    rsx! {
        Modal {
            is_open: props.is_open,
            title: Some(props.title.clone()),
            size: ModalSize::Sm,
            on_close: props.on_cancel.clone(),
            children: rsx! {
                p(style=styles::message()) { { props.message.clone() } }
                div(style=styles::actions()) {
                    Button {
                        variant: ButtonVariant::Secondary,
                        on_click: Callback::new(on_cancel),
                        children: rsx! { { props.cancel_text.clone() } }
                    }
                    Button {
                        variant: if props.destructive { ButtonVariant::Danger } else { ButtonVariant::Primary },
                        on_click: Callback::new(on_confirm),
                        children: rsx! { { props.confirm_text.clone() } }
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
