//! Coverage report generation.

use crate::data::{CoverageData, probe_kind};
use crate::map::{CoverageMap, CoverageMapSet};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};

/// Coverage information for a single line.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LineCoverage {
    /// Line number (1-indexed).
    pub line: u32,
    /// Number of times this line was executed.
    pub hit_count: u64,
    /// Whether this line was covered (hit_count > 0).
    pub covered: bool,
}

/// Coverage information for a function.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionCoverage {
    /// Function name.
    pub name: String,
    /// Starting line number.
    pub start_line: u32,
    /// Ending line number.
    pub end_line: u32,
    /// Number of times this function was called.
    pub hit_count: u64,
    /// Whether this function was covered.
    pub covered: bool,
}

/// Coverage information for a branch.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BranchCoverage {
    /// Line number where the branch occurs.
    pub line: u32,
    /// Branch index at this line (for multiple branches on same line).
    pub branch_index: u32,
    /// Number of times the true branch was taken.
    pub true_count: u64,
    /// Number of times the false branch was taken.
    pub false_count: u64,
    /// Whether both branches were covered.
    pub fully_covered: bool,
}

/// Summary statistics for coverage.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CoverageSummary {
    /// Total number of lines.
    pub total_lines: u32,
    /// Number of covered lines.
    pub covered_lines: u32,
    /// Total number of functions.
    pub total_functions: u32,
    /// Number of covered functions.
    pub covered_functions: u32,
    /// Total number of branches.
    pub total_branches: u32,
    /// Number of covered branches (both paths taken).
    pub covered_branches: u32,
}

impl CoverageSummary {
    /// Returns line coverage percentage (0.0 to 100.0).
    pub fn line_percent(&self) -> f64 {
        if self.total_lines == 0 {
            100.0
        } else {
            (self.covered_lines as f64 / self.total_lines as f64) * 100.0
        }
    }

    /// Returns function coverage percentage (0.0 to 100.0).
    pub fn function_percent(&self) -> f64 {
        if self.total_functions == 0 {
            100.0
        } else {
            (self.covered_functions as f64 / self.total_functions as f64) * 100.0
        }
    }

    /// Returns branch coverage percentage (0.0 to 100.0).
    pub fn branch_percent(&self) -> f64 {
        if self.total_branches == 0 {
            100.0
        } else {
            (self.covered_branches as f64 / self.total_branches as f64) * 100.0
        }
    }

    /// Merges another summary into this one.
    pub fn merge(&mut self, other: &CoverageSummary) {
        self.total_lines += other.total_lines;
        self.covered_lines += other.covered_lines;
        self.total_functions += other.total_functions;
        self.covered_functions += other.covered_functions;
        self.total_branches += other.total_branches;
        self.covered_branches += other.covered_branches;
    }
}

/// Coverage report for a single source file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CoverageReport {
    /// Source file path.
    pub file: String,
    /// Line coverage information (keyed by line number).
    pub lines: BTreeMap<u32, LineCoverage>,
    /// Function coverage information.
    pub functions: Vec<FunctionCoverage>,
    /// Branch coverage information.
    pub branches: Vec<BranchCoverage>,
    /// Summary statistics.
    pub summary: CoverageSummary,
}

impl CoverageReport {
    /// Creates a new empty coverage report for a file.
    pub fn new(file: String) -> Self {
        Self {
            file,
            lines: BTreeMap::new(),
            functions: Vec::new(),
            branches: Vec::new(),
            summary: CoverageSummary::default(),
        }
    }

    /// Creates a coverage report from a coverage map and collected data.
    pub fn from_map_and_data(map: &CoverageMap, data: &CoverageData) -> Self {
        let mut report = Self::new(map.file.clone());

        // Process line coverage
        let mut line_hits: HashMap<u32, u64> = HashMap::new();
        for (probe_id, location) in map.line_probes() {
            let count = data.get_hit_count(probe_id);
            line_hits
                .entry(location.line)
                .and_modify(|c| *c = (*c).max(count))
                .or_insert(count);
        }

        for (line, hit_count) in line_hits {
            report.lines.insert(
                line,
                LineCoverage {
                    line,
                    hit_count,
                    covered: hit_count > 0,
                },
            );
        }

        // Process function coverage
        for func in &map.functions {
            let hit_count = data.get_hit_count(func.entry_probe);
            report.functions.push(FunctionCoverage {
                name: func.name.clone(),
                start_line: func.start_line,
                end_line: func.end_line,
                hit_count,
                covered: hit_count > 0,
            });
        }

        // Process branch coverage
        let mut branch_map: HashMap<u32, Vec<(u64, u8)>> = HashMap::new();
        for (probe_id, location) in map.branch_probes() {
            branch_map
                .entry(location.line)
                .or_default()
                .push((probe_id, location.kind));
        }

        for (line, probes) in branch_map {
            // Group branch probes into pairs (true/false)
            let true_probes: Vec<_> = probes
                .iter()
                .filter(|(_, k)| *k == probe_kind::BRANCH_TRUE)
                .collect();
            let false_probes: Vec<_> = probes
                .iter()
                .filter(|(_, k)| *k == probe_kind::BRANCH_FALSE)
                .collect();

            for (idx, (true_probe, _)) in true_probes.iter().enumerate() {
                let true_count = data.get_hit_count(*true_probe);
                let false_count = false_probes
                    .get(idx)
                    .map(|(id, _)| data.get_hit_count(*id))
                    .unwrap_or(0);

                report.branches.push(BranchCoverage {
                    line,
                    branch_index: idx as u32,
                    true_count,
                    false_count,
                    fully_covered: true_count > 0 && false_count > 0,
                });
            }
        }

        // Calculate summary
        report.summary = report.calculate_summary();
        report
    }

    /// Calculates summary statistics from the report data.
    fn calculate_summary(&self) -> CoverageSummary {
        CoverageSummary {
            total_lines: self.lines.len() as u32,
            covered_lines: self.lines.values().filter(|l| l.covered).count() as u32,
            total_functions: self.functions.len() as u32,
            covered_functions: self.functions.iter().filter(|f| f.covered).count() as u32,
            total_branches: self.branches.len() as u32,
            covered_branches: self.branches.iter().filter(|b| b.fully_covered).count() as u32,
        }
    }

    /// Returns whether a specific line is covered.
    pub fn is_line_covered(&self, line: u32) -> Option<bool> {
        self.lines.get(&line).map(|l| l.covered)
    }

    /// Returns the hit count for a specific line.
    pub fn line_hit_count(&self, line: u32) -> Option<u64> {
        self.lines.get(&line).map(|l| l.hit_count)
    }

    /// Returns all uncovered lines.
    pub fn uncovered_lines(&self) -> Vec<u32> {
        self.lines
            .values()
            .filter(|l| !l.covered)
            .map(|l| l.line)
            .collect()
    }

    /// Returns all uncovered functions.
    pub fn uncovered_functions(&self) -> Vec<&str> {
        self.functions
            .iter()
            .filter(|f| !f.covered)
            .map(|f| f.name.as_str())
            .collect()
    }
}

/// Aggregates summaries from multiple coverage reports.
pub fn aggregate_summaries(reports: &[CoverageReport]) -> CoverageSummary {
    let mut summary = CoverageSummary::default();
    for report in reports {
        summary.merge(&report.summary);
    }
    summary
}

/// Generates coverage reports for all files in a map set.
pub fn generate_reports(maps: &CoverageMapSet, data: &CoverageData) -> Vec<CoverageReport> {
    maps.maps
        .values()
        .map(|map| CoverageReport::from_map_and_data(map, data))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::map::{FunctionInfo, ProbeLocation};

    fn create_test_map() -> CoverageMap {
        let mut map = CoverageMap::new("test.rsx".to_string());

        // Add line probes
        map.add_probe(
            1,
            ProbeLocation {
                line: 10,
                column: 1,
                kind: probe_kind::LINE,
                function: Some("main".to_string()),
                file: "test.rsx".to_string(),
            },
        );
        map.add_probe(
            2,
            ProbeLocation {
                line: 11,
                column: 1,
                kind: probe_kind::LINE,
                function: Some("main".to_string()),
                file: "test.rsx".to_string(),
            },
        );
        map.add_probe(
            3,
            ProbeLocation {
                line: 12,
                column: 1,
                kind: probe_kind::LINE,
                function: Some("main".to_string()),
                file: "test.rsx".to_string(),
            },
        );

        // Add function probe
        map.add_probe(
            10,
            ProbeLocation {
                line: 10,
                column: 1,
                kind: probe_kind::FUNCTION_ENTRY,
                function: Some("main".to_string()),
                file: "test.rsx".to_string(),
            },
        );

        map.add_function(FunctionInfo {
            name: "main".to_string(),
            start_line: 10,
            end_line: 15,
            entry_probe: 10,
        });

        // Add branch probes
        map.add_probe(
            20,
            ProbeLocation {
                line: 11,
                column: 5,
                kind: probe_kind::BRANCH_TRUE,
                function: Some("main".to_string()),
                file: "test.rsx".to_string(),
            },
        );
        map.add_probe(
            21,
            ProbeLocation {
                line: 11,
                column: 5,
                kind: probe_kind::BRANCH_FALSE,
                function: Some("main".to_string()),
                file: "test.rsx".to_string(),
            },
        );

        map
    }

    #[test]
    fn test_coverage_report_generation() {
        let map = create_test_map();
        let mut data = CoverageData::new();

        // Simulate hits
        data.record_hit(1, probe_kind::LINE); // Line 10 hit
        data.record_hit(2, probe_kind::LINE); // Line 11 hit
        // Line 12 not hit
        data.record_hit(10, probe_kind::FUNCTION_ENTRY); // Function hit
        data.record_hit(20, probe_kind::BRANCH_TRUE); // True branch hit
        // False branch not hit

        let report = CoverageReport::from_map_and_data(&map, &data);

        assert_eq!(report.summary.total_lines, 3);
        assert_eq!(report.summary.covered_lines, 2);
        assert_eq!(report.summary.total_functions, 1);
        assert_eq!(report.summary.covered_functions, 1);
        assert_eq!(report.summary.total_branches, 1);
        assert_eq!(report.summary.covered_branches, 0); // Not fully covered

        assert!(report.is_line_covered(10).unwrap());
        assert!(report.is_line_covered(11).unwrap());
        assert!(!report.is_line_covered(12).unwrap());
    }

    #[test]
    fn test_coverage_summary_percentages() {
        let summary = CoverageSummary {
            total_lines: 100,
            covered_lines: 75,
            total_functions: 10,
            covered_functions: 8,
            total_branches: 20,
            covered_branches: 15,
        };

        assert!((summary.line_percent() - 75.0).abs() < 0.001);
        assert!((summary.function_percent() - 80.0).abs() < 0.001);
        assert!((summary.branch_percent() - 75.0).abs() < 0.001);
    }

    #[test]
    fn test_aggregate_summaries() {
        let reports = vec![
            CoverageReport {
                file: "a.rsx".to_string(),
                lines: BTreeMap::new(),
                functions: vec![],
                branches: vec![],
                summary: CoverageSummary {
                    total_lines: 50,
                    covered_lines: 40,
                    total_functions: 5,
                    covered_functions: 4,
                    total_branches: 10,
                    covered_branches: 8,
                },
            },
            CoverageReport {
                file: "b.rsx".to_string(),
                lines: BTreeMap::new(),
                functions: vec![],
                branches: vec![],
                summary: CoverageSummary {
                    total_lines: 50,
                    covered_lines: 35,
                    total_functions: 5,
                    covered_functions: 3,
                    total_branches: 10,
                    covered_branches: 5,
                },
            },
        ];

        let summary = aggregate_summaries(&reports);

        assert_eq!(summary.total_lines, 100);
        assert_eq!(summary.covered_lines, 75);
        assert_eq!(summary.total_functions, 10);
        assert_eq!(summary.covered_functions, 7);
        assert_eq!(summary.total_branches, 20);
        assert_eq!(summary.covered_branches, 13);
    }
}
