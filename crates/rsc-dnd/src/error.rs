//! Error types for rsc-dnd.

use thiserror::Error;

/// Result type for DnD operations.
pub type DndResult<T> = Result<T, DndError>;

/// DnD error types.
#[derive(Debug, Error)]
pub enum DndError {
    /// Element not found.
    #[error("Element not found: {0}")]
    ElementNotFound(String),

    /// Invalid drop target.
    #[error("Invalid drop target: {0}")]
    InvalidDropTarget(String),

    /// Operation not allowed.
    #[error("Operation not allowed: {0}")]
    NotAllowed(String),
}
