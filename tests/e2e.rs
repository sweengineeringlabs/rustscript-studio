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
//! # Parallel Execution with CI Sharding
//!
//! ```bash
//! # Start multiple dev servers
//! rsc dev --port 3000 &
//! rsc dev --port 3001 &
//! rsc dev --port 3002 &
//! rsc dev --port 3003 &
//!
//! # Run sharded tests in parallel
//! RSC_TEST_SHARD_INDEX=0 RSC_TEST_SHARD_TOTAL=4 RSC_TEST_PORT=3000 cargo test --test e2e -- --ignored &
//! RSC_TEST_SHARD_INDEX=1 RSC_TEST_SHARD_TOTAL=4 RSC_TEST_PORT=3001 cargo test --test e2e -- --ignored &
//! RSC_TEST_SHARD_INDEX=2 RSC_TEST_SHARD_TOTAL=4 RSC_TEST_PORT=3002 cargo test --test e2e -- --ignored &
//! RSC_TEST_SHARD_INDEX=3 RSC_TEST_SHARD_TOTAL=4 RSC_TEST_PORT=3003 cargo test --test e2e -- --ignored &
//! wait
//! ```
//!
//! # Environment Variables
//!
//! - `RSC_TEST_PORT`: Port number (default: 3000)
//! - `RSC_TEST_BASE_URL`: Full base URL
//! - `RSC_TEST_HEADLESS`: Run headless (default: true)
//! - `RSC_TEST_SHARD_INDEX`: Current shard (0-based)
//! - `RSC_TEST_SHARD_TOTAL`: Total shards
//! - `RSC_TEST_TIMEOUT`: Timeout in seconds (default: 30)
//!
//! # Viewing Screenshots
//!
//! Failed tests and certain tests capture screenshots to:
//! `target/e2e-screenshots/`

#[path = "e2e/mod.rs"]
mod e2e;

// Re-export test context for use in tests
pub use e2e::{TestConfig, TestContext, BASE_URL, DEFAULT_TIMEOUT};
pub use e2e::harness;
