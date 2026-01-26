//! HTML format coverage reporter with CSS styling.

use crate::error::{CoverageError, Result};
use crate::report::{CoverageReport, CoverageSummary, aggregate_summaries};
use crate::reporter::{CoverageReporter, coverage_color_class, escape_html, format_percent};
use std::path::Path;

/// Reporter that generates interactive HTML reports.
#[derive(Debug, Clone)]
pub struct HtmlReporter {
    /// Title for the report.
    pub title: String,
    /// Whether to embed CSS inline (true) or reference external file (false).
    pub inline_css: bool,
}

impl Default for HtmlReporter {
    fn default() -> Self {
        Self {
            title: "Coverage Report".to_string(),
            inline_css: true,
        }
    }
}

impl HtmlReporter {
    /// Creates a new HTML reporter with default settings.
    pub fn new() -> Self {
        Self::default()
    }

    /// Creates a new HTML reporter with a custom title.
    pub fn with_title(title: impl Into<String>) -> Self {
        Self {
            title: title.into(),
            ..Self::default()
        }
    }

    /// Returns the CSS stylesheet for the report.
    pub fn css() -> &'static str {
        r#"
:root {
    --color-high: #28a745;
    --color-medium: #ffc107;
    --color-low: #dc3545;
    --color-bg: #f8f9fa;
    --color-border: #dee2e6;
    --color-text: #212529;
    --color-covered: #d4edda;
    --color-uncovered: #f8d7da;
}

* {
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    margin: 0;
    padding: 20px;
    background: var(--color-bg);
    color: var(--color-text);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
}

h1, h2, h3 {
    margin-top: 0;
}

.summary-card {
    background: white;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 20px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
}

.metric {
    text-align: center;
}

.metric-value {
    font-size: 2em;
    font-weight: bold;
}

.metric-label {
    color: #6c757d;
    font-size: 0.9em;
}

.metric-value.high { color: var(--color-high); }
.metric-value.medium { color: var(--color-medium); }
.metric-value.low { color: var(--color-low); }

.progress-bar {
    height: 8px;
    background: #e9ecef;
    border-radius: 4px;
    overflow: hidden;
    margin-top: 8px;
}

.progress-fill {
    height: 100%;
    transition: width 0.3s ease;
}

.progress-fill.high { background: var(--color-high); }
.progress-fill.medium { background: var(--color-medium); }
.progress-fill.low { background: var(--color-low); }

.file-list {
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.file-header {
    display: grid;
    grid-template-columns: 1fr 100px 100px 100px;
    padding: 12px 20px;
    background: #e9ecef;
    font-weight: bold;
    border-bottom: 1px solid var(--color-border);
}

.file-row {
    display: grid;
    grid-template-columns: 1fr 100px 100px 100px;
    padding: 12px 20px;
    border-bottom: 1px solid var(--color-border);
    text-decoration: none;
    color: inherit;
}

.file-row:hover {
    background: #f8f9fa;
}

.file-row:last-child {
    border-bottom: none;
}

.source-view {
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    margin-top: 20px;
}

.source-header {
    padding: 15px 20px;
    background: #e9ecef;
    border-bottom: 1px solid var(--color-border);
}

.source-code {
    font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
    font-size: 13px;
    line-height: 1.5;
    overflow-x: auto;
}

.source-line {
    display: flex;
    min-height: 21px;
}

.line-number {
    width: 60px;
    padding: 0 10px;
    text-align: right;
    color: #6c757d;
    background: #f8f9fa;
    border-right: 1px solid var(--color-border);
    user-select: none;
    flex-shrink: 0;
}

.line-hits {
    width: 50px;
    padding: 0 8px;
    text-align: right;
    color: #6c757d;
    font-size: 11px;
    flex-shrink: 0;
}

.line-content {
    padding: 0 10px;
    white-space: pre;
    flex-grow: 1;
}

.source-line.covered {
    background: var(--color-covered);
}

.source-line.uncovered {
    background: var(--color-uncovered);
}

.breadcrumb {
    margin-bottom: 20px;
}

.breadcrumb a {
    color: #007bff;
    text-decoration: none;
}

.breadcrumb a:hover {
    text-decoration: underline;
}

@media (max-width: 768px) {
    .file-header, .file-row {
        grid-template-columns: 1fr 80px;
    }
    .file-header > *:nth-child(3),
    .file-header > *:nth-child(4),
    .file-row > *:nth-child(3),
    .file-row > *:nth-child(4) {
        display: none;
    }
}
"#
    }

    fn render_summary(&self, summary: &CoverageSummary) -> String {
        let line_pct = summary.line_percent();
        let func_pct = summary.function_percent();
        let branch_pct = summary.branch_percent();

        format!(
            r#"<div class="summary-card">
    <h2>Coverage Summary</h2>
    <div class="summary-grid">
        <div class="metric">
            <div class="metric-value {}">{}</div>
            <div class="metric-label">Lines ({}/{})</div>
            <div class="progress-bar">
                <div class="progress-fill {}" style="width: {}%"></div>
            </div>
        </div>
        <div class="metric">
            <div class="metric-value {}">{}</div>
            <div class="metric-label">Functions ({}/{})</div>
            <div class="progress-bar">
                <div class="progress-fill {}" style="width: {}%"></div>
            </div>
        </div>
        <div class="metric">
            <div class="metric-value {}">{}</div>
            <div class="metric-label">Branches ({}/{})</div>
            <div class="progress-bar">
                <div class="progress-fill {}" style="width: {}%"></div>
            </div>
        </div>
    </div>
</div>"#,
            coverage_color_class(line_pct),
            format_percent(line_pct),
            summary.covered_lines,
            summary.total_lines,
            coverage_color_class(line_pct),
            line_pct,
            coverage_color_class(func_pct),
            format_percent(func_pct),
            summary.covered_functions,
            summary.total_functions,
            coverage_color_class(func_pct),
            func_pct,
            coverage_color_class(branch_pct),
            format_percent(branch_pct),
            summary.covered_branches,
            summary.total_branches,
            coverage_color_class(branch_pct),
            branch_pct,
        )
    }

    fn render_file_list(&self, reports: &[CoverageReport]) -> String {
        let mut rows = String::new();

        for report in reports {
            let line_pct = report.summary.line_percent();
            let func_pct = report.summary.function_percent();
            let branch_pct = report.summary.branch_percent();

            // Create a safe filename for the HTML file
            let safe_name = report.file.replace(['/', '\\'], "_");

            rows.push_str(&format!(
                r#"<a href="{}.html" class="file-row">
    <span>{}</span>
    <span class="{}">{}</span>
    <span class="{}">{}</span>
    <span class="{}">{}</span>
</a>"#,
                escape_html(&safe_name),
                escape_html(&report.file),
                coverage_color_class(line_pct),
                format_percent(line_pct),
                coverage_color_class(func_pct),
                format_percent(func_pct),
                coverage_color_class(branch_pct),
                format_percent(branch_pct),
            ));
        }

        format!(
            r#"<div class="file-list">
    <div class="file-header">
        <span>File</span>
        <span>Lines</span>
        <span>Functions</span>
        <span>Branches</span>
    </div>
    {}
</div>"#,
            rows
        )
    }

    fn render_index(&self, reports: &[CoverageReport]) -> String {
        let summary = aggregate_summaries(reports);

        format!(
            r#"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{}</title>
    <style>{}</style>
</head>
<body>
    <div class="container">
        <h1>{}</h1>
        {}
        <h2>Files</h2>
        {}
    </div>
</body>
</html>"#,
            escape_html(&self.title),
            Self::css(),
            escape_html(&self.title),
            self.render_summary(&summary),
            self.render_file_list(reports),
        )
    }

    /// Renders a single file's source coverage view.
    pub fn render_file_page(
        &self,
        report: &CoverageReport,
        source_content: &str,
    ) -> String {
        let mut source_lines = String::new();

        for (idx, line_content) in source_content.lines().enumerate() {
            let line_num = (idx + 1) as u32;
            let line_cov = report.lines.get(&line_num);

            let (class, hits_display) = match line_cov {
                Some(cov) if cov.covered => ("covered", cov.hit_count.to_string()),
                Some(_) => ("uncovered", "0".to_string()),
                None => ("", "".to_string()),
            };

            source_lines.push_str(&format!(
                r#"<div class="source-line {}">
    <span class="line-number">{}</span>
    <span class="line-hits">{}</span>
    <span class="line-content">{}</span>
</div>"#,
                class,
                line_num,
                hits_display,
                escape_html(line_content),
            ));
        }

        format!(
            r#"<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{} - {}</title>
    <style>{}</style>
</head>
<body>
    <div class="container">
        <div class="breadcrumb">
            <a href="index.html">Coverage Report</a> &gt; {}
        </div>
        <h1>{}</h1>
        {}
        <div class="source-view">
            <div class="source-header">
                <strong>{}</strong>
            </div>
            <div class="source-code">
                {}
            </div>
        </div>
    </div>
</body>
</html>"#,
            escape_html(&report.file),
            escape_html(&self.title),
            Self::css(),
            escape_html(&report.file),
            escape_html(&report.file),
            self.render_summary(&report.summary),
            escape_html(&report.file),
            source_lines,
        )
    }

    /// Writes a complete HTML report to a directory.
    pub fn write_to_directory(
        &self,
        reports: &[CoverageReport],
        output_dir: &Path,
        source_reader: impl Fn(&str) -> std::io::Result<String>,
    ) -> Result<()> {
        // Create output directory
        std::fs::create_dir_all(output_dir)?;

        // Write index page
        let index_path = output_dir.join("index.html");
        std::fs::write(&index_path, self.render_index(reports))?;

        // Write individual file pages
        for report in reports {
            let safe_name = report.file.replace(['/', '\\'], "_");
            let file_path = output_dir.join(format!("{}.html", safe_name));

            let source_content = source_reader(&report.file).map_err(|e| {
                CoverageError::SourceFileError {
                    path: report.file.clone(),
                    source: e,
                }
            })?;

            let page_content = self.render_file_page(report, &source_content);
            std::fs::write(&file_path, page_content)?;
        }

        Ok(())
    }
}

impl CoverageReporter for HtmlReporter {
    fn report(&self, reports: &[CoverageReport]) -> Result<String> {
        // When using the trait method, just return the index page
        Ok(self.render_index(reports))
    }

    fn extension(&self) -> &'static str {
        "html"
    }

    fn format_name(&self) -> &'static str {
        "html"
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::report::{LineCoverage, FunctionCoverage, BranchCoverage};
    use std::collections::BTreeMap;

    fn create_test_report() -> CoverageReport {
        let mut lines = BTreeMap::new();
        lines.insert(1, LineCoverage { line: 1, hit_count: 5, covered: true });
        lines.insert(2, LineCoverage { line: 2, hit_count: 0, covered: false });
        lines.insert(3, LineCoverage { line: 3, hit_count: 3, covered: true });

        CoverageReport {
            file: "src/main.rsx".to_string(),
            lines,
            functions: vec![FunctionCoverage {
                name: "main".to_string(),
                start_line: 1,
                end_line: 10,
                hit_count: 1,
                covered: true,
            }],
            branches: vec![BranchCoverage {
                line: 5,
                branch_index: 0,
                true_count: 3,
                false_count: 2,
                fully_covered: true,
            }],
            summary: CoverageSummary {
                total_lines: 3,
                covered_lines: 2,
                total_functions: 1,
                covered_functions: 1,
                total_branches: 1,
                covered_branches: 1,
            },
        }
    }

    #[test]
    fn test_html_index_generation() {
        let reporter = HtmlReporter::with_title("Test Coverage");
        let report = create_test_report();
        let output = reporter.report(&[report]).unwrap();

        assert!(output.contains("<!DOCTYPE html>"));
        assert!(output.contains("Test Coverage"));
        assert!(output.contains("src/main.rsx"));
        assert!(output.contains("Coverage Summary"));
    }

    #[test]
    fn test_html_file_page() {
        let reporter = HtmlReporter::new();
        let report = create_test_report();
        let source = "fn main() {\n    println!(\"hello\");\n    return 0;\n}";

        let page = reporter.render_file_page(&report, source);

        assert!(page.contains("<!DOCTYPE html>"));
        assert!(page.contains("src/main.rsx"));
        assert!(page.contains("fn main()"));
        assert!(page.contains("covered"));
        assert!(page.contains("uncovered"));
    }

    #[test]
    fn test_html_escaping() {
        let mut report = create_test_report();
        report.file = "<script>alert('xss')</script>".to_string();

        let reporter = HtmlReporter::new();
        let output = reporter.report(&[report]).unwrap();

        assert!(!output.contains("<script>alert"));
        assert!(output.contains("&lt;script&gt;"));
    }

    #[test]
    fn test_html_format_metadata() {
        let reporter = HtmlReporter::new();
        assert_eq!(reporter.extension(), "html");
        assert_eq!(reporter.format_name(), "html");
    }
}
