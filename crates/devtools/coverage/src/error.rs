//! Error types for code coverage operations.

use thiserror::Error;

/// Errors that can occur during coverage operations.
#[derive(Debug, Error)]
pub enum CoverageError {
    /// Failed to parse coverage map JSON.
    #[error("failed to parse coverage map: {0}")]
    ParseError(String),

    /// Invalid probe ID encountered.
    #[error("invalid probe ID: {0}")]
    InvalidProbeId(u64),

    /// Failed to read source file.
    #[error("failed to read source file '{path}': {source}")]
    SourceFileError {
        path: String,
        #[source]
        source: std::io::Error,
    },

    /// Failed to write report.
    #[error("failed to write report to '{path}': {source}")]
    WriteError {
        path: String,
        #[source]
        source: std::io::Error,
    },

    /// Coverage map not found for file.
    #[error("no coverage map found for file: {0}")]
    NoMapForFile(String),

    /// JSON serialization error.
    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),

    /// I/O error.
    #[error("I/O error: {0}")]
    IoError(#[from] std::io::Error),
}

/// Result type for coverage operations.
pub type Result<T> = std::result::Result<T, CoverageError>;
