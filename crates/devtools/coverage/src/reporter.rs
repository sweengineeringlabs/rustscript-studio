//! Coverage reporter trait and utilities.

use crate::error::Result;
use crate::report::CoverageReport;
use std::path::Path;

/// Trait for generating coverage reports in various formats.
pub trait CoverageReporter {
    /// Generates a report string from coverage data.
    fn report(&self, reports: &[CoverageReport]) -> Result<String>;

    /// Writes the report to a file.
    fn write_to_file(&self, reports: &[CoverageReport], path: &Path) -> Result<()> {
        let content = self.report(reports)?;
        std::fs::write(path, content).map_err(|e| crate::error::CoverageError::WriteError {
            path: path.display().to_string(),
            source: e,
        })
    }

    /// Returns the default file extension for this report format.
    fn extension(&self) -> &'static str;

    /// Returns the format name (e.g., "lcov", "json", "html").
    fn format_name(&self) -> &'static str;
}

/// Helper to escape HTML special characters.
pub fn escape_html(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}

/// Formats a percentage with one decimal place.
pub fn format_percent(value: f64) -> String {
    format!("{:.1}%", value)
}

/// Returns a color class based on coverage percentage.
pub fn coverage_color_class(percent: f64) -> &'static str {
    if percent >= 80.0 {
        "high"
    } else if percent >= 50.0 {
        "medium"
    } else {
        "low"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_escape_html() {
        assert_eq!(escape_html("<script>"), "&lt;script&gt;");
        assert_eq!(escape_html("a & b"), "a &amp; b");
        assert_eq!(escape_html("\"quoted\""), "&quot;quoted&quot;");
    }

    #[test]
    fn test_format_percent() {
        assert_eq!(format_percent(75.0), "75.0%");
        assert_eq!(format_percent(100.0), "100.0%");
        assert_eq!(format_percent(33.333), "33.3%");
    }

    #[test]
    fn test_coverage_color_class() {
        assert_eq!(coverage_color_class(100.0), "high");
        assert_eq!(coverage_color_class(80.0), "high");
        assert_eq!(coverage_color_class(79.9), "medium");
        assert_eq!(coverage_color_class(50.0), "medium");
        assert_eq!(coverage_color_class(49.9), "low");
        assert_eq!(coverage_color_class(0.0), "low");
    }
}
