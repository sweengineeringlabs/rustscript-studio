//! End-to-end browser tests for RustScript Studio.
//!
//! These tests require:
//! 1. Chrome browser installed
//! 2. The dev server running at http://localhost:3000
//!
//! # Running Tests
//!
//! ```bash
//! # Terminal 1: Start the dev server
//! rsc dev --port 3000
//!
//! # Terminal 2: Run e2e tests
//! cargo test --test e2e -- --ignored --test-threads=1
//! ```
//!
//! # Running Specific Tests
//!
//! ```bash
//! # Run only app tests
//! cargo test --test e2e app_test -- --ignored
//!
//! # Run only CSS designer tests
//! cargo test --test e2e css_designer -- --ignored
//!
//! # Run only navigation designer tests
//! cargo test --test e2e navigation_designer -- --ignored
//! ```
//!
//! # Viewing Screenshots
//!
//! Failed tests and certain tests capture screenshots to:
//! `target/e2e-screenshots/`

#[path = "e2e/mod.rs"]
mod e2e;

// Re-export test context for use in tests
pub use e2e::{TestConfig, TestContext, BASE_URL, DEFAULT_TIMEOUT};
