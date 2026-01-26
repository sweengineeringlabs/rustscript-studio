//! LCOV format coverage reporter.
//!
//! LCOV is a standard format supported by many coverage tools including
//! codecov, coveralls, and various IDE integrations.

use crate::error::Result;
use crate::report::CoverageReport;
use crate::reporter::CoverageReporter;

/// Reporter that generates LCOV format output.
///
/// LCOV format specification:
/// - TN: Test name
/// - SF: Source file path
/// - FN: Function (line,name)
/// - FNDA: Function data (hits,name)
/// - FNF: Functions found
/// - FNH: Functions hit
/// - BRDA: Branch data (line,block,branch,taken)
/// - BRF: Branches found
/// - BRH: Branches hit
/// - DA: Line data (line,hits)
/// - LF: Lines found
/// - LH: Lines hit
/// - end_of_record
#[derive(Debug, Clone, Default)]
pub struct LcovReporter {
    /// Optional test name to include in the report.
    pub test_name: Option<String>,
}

impl LcovReporter {
    /// Creates a new LCOV reporter.
    pub fn new() -> Self {
        Self::default()
    }

    /// Creates a new LCOV reporter with a test name.
    pub fn with_test_name(test_name: impl Into<String>) -> Self {
        Self {
            test_name: Some(test_name.into()),
        }
    }

    fn format_report(&self, report: &CoverageReport) -> String {
        let mut output = String::new();

        // Test name (optional)
        if let Some(ref name) = self.test_name {
            output.push_str(&format!("TN:{}\n", name));
        }

        // Source file
        output.push_str(&format!("SF:{}\n", report.file));

        // Functions
        for func in &report.functions {
            output.push_str(&format!("FN:{},{}\n", func.start_line, func.name));
        }
        for func in &report.functions {
            output.push_str(&format!("FNDA:{},{}\n", func.hit_count, func.name));
        }
        output.push_str(&format!("FNF:{}\n", report.summary.total_functions));
        output.push_str(&format!("FNH:{}\n", report.summary.covered_functions));

        // Branches
        for branch in &report.branches {
            // BRDA format: line,block,branch,taken
            // We use branch_index as block, 0/1 for true/false branch
            output.push_str(&format!(
                "BRDA:{},{},0,{}\n",
                branch.line,
                branch.branch_index,
                if branch.true_count > 0 {
                    branch.true_count.to_string()
                } else {
                    "-".to_string()
                }
            ));
            output.push_str(&format!(
                "BRDA:{},{},1,{}\n",
                branch.line,
                branch.branch_index,
                if branch.false_count > 0 {
                    branch.false_count.to_string()
                } else {
                    "-".to_string()
                }
            ));
        }
        output.push_str(&format!("BRF:{}\n", report.summary.total_branches * 2)); // *2 for true/false
        let branches_hit = report
            .branches
            .iter()
            .map(|b| {
                (if b.true_count > 0 { 1 } else { 0 }) + (if b.false_count > 0 { 1 } else { 0 })
            })
            .sum::<u32>();
        output.push_str(&format!("BRH:{}\n", branches_hit));

        // Lines
        for line_cov in report.lines.values() {
            output.push_str(&format!("DA:{},{}\n", line_cov.line, line_cov.hit_count));
        }
        output.push_str(&format!("LF:{}\n", report.summary.total_lines));
        output.push_str(&format!("LH:{}\n", report.summary.covered_lines));

        output.push_str("end_of_record\n");

        output
    }
}

impl CoverageReporter for LcovReporter {
    fn report(&self, reports: &[CoverageReport]) -> Result<String> {
        let mut output = String::new();
        for report in reports {
            output.push_str(&self.format_report(report));
        }
        Ok(output)
    }

    fn extension(&self) -> &'static str {
        "info"
    }

    fn format_name(&self) -> &'static str {
        "lcov"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::report::{BranchCoverage, CoverageSummary, FunctionCoverage, LineCoverage};
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
        lines.insert(
            11,
            LineCoverage {
                line: 11,
                hit_count: 0,
                covered: false,
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
                false_count: 0,
                fully_covered: false,
            }],
            summary: CoverageSummary {
                total_lines: 2,
                covered_lines: 1,
                total_functions: 1,
                covered_functions: 1,
                total_branches: 1,
                covered_branches: 0,
            },
        }
    }

    #[test]
    fn test_lcov_output() {
        let reporter = LcovReporter::with_test_name("test");
        let report = create_test_report();
        let output = reporter.report(&[report]).unwrap();

        assert!(output.contains("TN:test"));
        assert!(output.contains("SF:src/main.rsx"));
        assert!(output.contains("FN:10,main"));
        assert!(output.contains("FNDA:1,main"));
        assert!(output.contains("DA:10,5"));
        assert!(output.contains("DA:11,0"));
        assert!(output.contains("LF:2"));
        assert!(output.contains("LH:1"));
        assert!(output.contains("end_of_record"));
    }

    #[test]
    fn test_lcov_format_metadata() {
        let reporter = LcovReporter::new();
        assert_eq!(reporter.extension(), "info");
        assert_eq!(reporter.format_name(), "lcov");
    }
}
