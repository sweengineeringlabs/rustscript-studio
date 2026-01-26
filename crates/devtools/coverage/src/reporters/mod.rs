//! Coverage report format implementations.

mod html;
mod json;
mod lcov;

pub use html::HtmlReporter;
pub use json::JsonReporter;
pub use lcov::LcovReporter;
