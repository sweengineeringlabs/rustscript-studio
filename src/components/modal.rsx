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
/// <Modal
///     is_open={show_modal.get()}
///     title={"Confirm Action".to_string()}
///     on_close={Callback::new(move |_| show_modal.set(false))}
/// >
///     <p>Are you sure you want to proceed?</p>
/// </Modal>
/// ```
component Modal(
    /// Whether the modal is open
    is_open: bool,
    /// Modal title
    title?: String,
    /// Modal size
    size?: ModalSize,
    /// Whether clicking the overlay closes the modal
    close_on_overlay_click?: bool,
    /// Whether pressing Escape closes the modal
    close_on_escape?: bool,
    /// Whether to show the close button
    show_close_button?: bool,
    /// Callback when modal should close
    on_close?: Callback<()>,
    /// Modal content
    children: Element,
) {
    let size = size.unwrap_or(ModalSize::default());
    let close_on_overlay_click = close_on_overlay_click.unwrap_or(true);
    let close_on_escape = close_on_escape.unwrap_or(true);
    let show_close_button = show_close_button.unwrap_or(true);

    @if !is_open {
        return render {};
    }

    render {
        <div
            class="modal-overlay"
            style={styles::overlay()}
            on:click={|_: MouseEvent| {
                if close_on_overlay_click {
                    if let Some(ref callback) = on_close {
                        callback.call(());
                    }
                }
            }}
            on:keydown={|e: KeyboardEvent| {
                if close_on_escape && e.key() == "Escape" {
                    if let Some(ref callback) = on_close {
                        callback.call(());
                    }
                }
            }}
            tabindex="-1"
        >
            <div
                class="modal-content"
                style={styles::content(size)}
                on:click={|e: MouseEvent| {
                    e.stop_propagation();
                }}
                role="dialog"
                aria-modal="true"
            >
                // Header
                @if title.is_some() || show_close_button {
                    <div class="modal-header" style={styles::header()}>
                        @if let Some(ref title) = title {
                            <h2 style={styles::title()}>{title.clone()}</h2>
                        }
                        @if show_close_button {
                            <button
                                class="modal-close"
                                style={styles::close_button()}
                                on:click={|_: MouseEvent| {
                                    if let Some(ref callback) = on_close {
                                        callback.call(());
                                    }
                                }}
                                aria-label="Close"
                            >
                                <svg
                                    width="20"
                                    height="20"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                >
                                    <path d="M18 6L6 18M6 6l12 12" />
                                </svg>
                            </button>
                        }
                    </div>
                }

                // Body
                <div class="modal-body" style={styles::body()}>
                    {children}
                </div>
            </div>
        </div>
    }
}

/// Pre-built confirmation dialog.
component ConfirmDialog(
    /// Whether the dialog is open
    is_open: bool,
    /// Dialog title
    title: String,
    /// Confirmation message
    message: String,
    /// Confirm button text
    confirm_text?: String,
    /// Cancel button text
    cancel_text?: String,
    /// Whether the action is destructive (shows red confirm button)
    destructive?: bool,
    /// Callback when confirmed
    on_confirm?: Callback<()>,
    /// Callback when cancelled
    on_cancel?: Callback<()>,
) {
    let confirm_text = confirm_text.unwrap_or("Confirm".to_string());
    let cancel_text = cancel_text.unwrap_or("Cancel".to_string());
    let destructive = destructive.unwrap_or(false);

    render {
        <Modal
            is_open={is_open}
            title={title.clone()}
            size={ModalSize::Sm}
            on_close={on_cancel.clone()}
        >
            <p style={styles::message()}>{message.clone()}</p>
            <div style={styles::actions()}>
                <Button
                    variant={ButtonVariant::Secondary}
                    on_click={Callback::new(|| {
                        if let Some(ref cb) = on_cancel {
                            cb.call(());
                        }
                    })}
                >
                    {cancel_text.clone()}
                </Button>
                <Button
                    variant={if destructive { ButtonVariant::Danger } else { ButtonVariant::Primary }}
                    on_click={Callback::new(|| {
                        if let Some(ref cb) = on_confirm {
                            cb.call(());
                        }
                    })}
                >
                    {confirm_text.clone()}
                </Button>
            </div>
        </Modal>
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
