//! Error types for rsc-flow.

use thiserror::Error;

/// Result type for flow operations.
pub type FlowResult<T> = Result<T, FlowError>;

/// Flow error types.
#[derive(Debug, Error)]
pub enum FlowError {
    /// Node not found.
    #[error("Node not found: {0}")]
    NodeNotFound(String),

    /// Edge not found.
    #[error("Edge not found: {0}")]
    EdgeNotFound(String),

    /// Invalid connection.
    #[error("Invalid connection: {message}")]
    InvalidConnection { message: String },

    /// Cycle detected in graph.
    #[error("Cycle detected: {0}")]
    CycleDetected(String),

    /// Layout error.
    #[error("Layout error: {0}")]
    LayoutError(String),

    /// Serialization error.
    #[error("Serialization error: {0}")]
    SerializationError(#[from] serde_json::Error),
}

impl FlowError {
    pub fn invalid_connection(message: impl Into<String>) -> Self {
        Self::InvalidConnection {
            message: message.into(),
        }
    }
}
