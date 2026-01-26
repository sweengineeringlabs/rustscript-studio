//! JSON format coverage reporter.

use crate::error::Result;
use crate::report::{CoverageReport, CoverageSummary, aggregate_summaries};
use crate::reporter::CoverageReporter;
use serde::Serialize;

/// Reporter that generates JSON format output.
#[derive(Debug, Clone, Default)]
pub struct JsonReporter {
    /// Whether to pretty-print the JSON output.
    pub pretty: bool,
}

impl JsonReporter {
    /// Creates a new JSON reporter with compact output.
    pub fn new() -> Self {
        Self::default()
    }

    /// Creates a new JSON reporter with pretty-printed output.
    pub fn pretty() -> Self {
        Self { pretty: true }
    }
}

/// JSON report structure.
#[derive(Debug, Serialize)]
struct JsonOutput<'a> {
    /// Overall coverage summary.
    summary: &'a CoverageSummary,
    /// Per-file coverage reports.
    files: &'a [CoverageReport],
}

impl CoverageReporter for JsonReporter {
    fn report(&self, reports: &[CoverageReport]) -> Result<String> {
        let summary = aggregate_summaries(reports);
        let output = JsonOutput {
            summary: &summary,
            files: reports,
        };

        let json = if self.pretty {
            serde_json::to_string_pretty(&output)?
        } else {
            serde_json::to_string(&output)?
        };

        Ok(json)
    }

    fn extension(&self) -> &'static str {
        "json"
    }

    fn format_name(&self) -> &'static str {
        "json"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::report::{BranchCoverage, FunctionCoverage, LineCoverage};
    use std::collections::BTreeMap;

    fn create_test_report() -> CoverageReport {
        let mut lines = BTreeMap::new();
        lines.insert(
            10,
            LineCoverage {
                line: 10,
                hit_count: 5,
                covered: true,
            },
        );

        CoverageReport {
            file: "src/main.rsx".to_string(),
            lines,
            functions: vec![FunctionCoverage {
                name: "main".to_string(),
                start_line: 10,
                end_line: 20,
                hit_count: 1,
                covered: true,
            }],
            branches: vec![BranchCoverage {
                line: 15,
                branch_index: 0,
                true_count: 3,
                false_count: 2,
                fully_covered: true,
            }],
            summary: CoverageSummary {
                total_lines: 1,
                covered_lines: 1,
                total_functions: 1,
                covered_functions: 1,
                total_branches: 1,
                covered_branches: 1,
            },
        }
    }

    #[test]
    fn test_json_output() {
        let reporter = JsonReporter::new();
        let report = create_test_report();
        let output = reporter.report(&[report]).unwrap();

        // Verify it's valid JSON
        let parsed: serde_json::Value = serde_json::from_str(&output).unwrap();

        assert!(parsed.get("summary").is_some());
        assert!(parsed.get("files").is_some());
        assert!(parsed["files"].as_array().unwrap().len() == 1);
    }

    #[test]
    fn test_json_pretty() {
        let compact = JsonReporter::new();
        let pretty = JsonReporter::pretty();
        let report = create_test_report();

        let compact_out = compact.report(&[report.clone()]).unwrap();
        let pretty_out = pretty.report(&[report]).unwrap();

        // Pretty output should be longer (has newlines/indentation)
        assert!(pretty_out.len() > compact_out.len());
        assert!(pretty_out.contains('\n'));
    }

    #[test]
    fn test_json_format_metadata() {
        let reporter = JsonReporter::new();
        assert_eq!(reporter.extension(), "json");
        assert_eq!(reporter.format_name(), "json");
    }
}
