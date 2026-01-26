//! Thread-local coverage data collector.

use crate::data::{CoverageData, probe_kind};
use std::cell::RefCell;
use std::sync::atomic::{AtomicBool, Ordering};

/// Global flag indicating whether coverage collection is enabled.
static COVERAGE_ENABLED: AtomicBool = AtomicBool::new(false);

thread_local! {
    /// Thread-local coverage data storage.
    static COVERAGE_DATA: RefCell<CoverageData> = RefCell::new(CoverageData::new());
}

/// Enables coverage collection.
pub fn enable() {
    COVERAGE_ENABLED.store(true, Ordering::SeqCst);
}

/// Disables coverage collection.
pub fn disable() {
    COVERAGE_ENABLED.store(false, Ordering::SeqCst);
}

/// Returns whether coverage collection is currently enabled.
pub fn is_enabled() -> bool {
    COVERAGE_ENABLED.load(Ordering::SeqCst)
}

/// Resets collected coverage data.
pub fn reset() {
    COVERAGE_DATA.with(|data| {
        data.borrow_mut().reset();
    });
}

/// Exports the collected coverage data.
pub fn export_coverage() -> CoverageData {
    COVERAGE_DATA.with(|data| {
        let mut borrowed = data.borrow_mut();
        borrowed.finish();
        borrowed.clone()
    })
}

/// Records a coverage hit for a probe.
///
/// This is called by the instrumented code via WASM imports.
#[inline]
pub fn record_hit(probe_id: u64, kind: u8) {
    if COVERAGE_ENABLED.load(Ordering::Relaxed) {
        COVERAGE_DATA.with(|data| {
            data.borrow_mut().record_hit(probe_id, kind);
        });
    }
}

/// WASM export function for recording coverage hits.
///
/// The probe ID encodes both the ID and kind:
/// - Lower 56 bits: probe ID
/// - Upper 8 bits: probe kind
///
/// This matches the encoding used by the MIR codegen.
#[unsafe(no_mangle)]
pub extern "C" fn __coverage_hit(encoded: i64) {
    let encoded = encoded as u64;
    let probe_id = encoded & 0x00FFFFFFFFFFFFFF;
    let kind = ((encoded >> 56) & 0xFF) as u8;
    record_hit(probe_id, kind);
}

/// Alternative signature using separate parameters.
#[unsafe(no_mangle)]
pub extern "C" fn __coverage_hit_ex(probe_id: i64, kind: i32) {
    record_hit(probe_id as u64, kind as u8);
}

/// Records a line coverage hit.
#[inline]
pub fn hit_line(probe_id: u64) {
    record_hit(probe_id, probe_kind::LINE);
}

/// Records a function entry coverage hit.
#[inline]
pub fn hit_function(probe_id: u64) {
    record_hit(probe_id, probe_kind::FUNCTION_ENTRY);
}

/// Records a branch coverage hit.
#[inline]
pub fn hit_branch(probe_id: u64, taken: bool) {
    let kind = if taken {
        probe_kind::BRANCH_TRUE
    } else {
        probe_kind::BRANCH_FALSE
    };
    record_hit(probe_id, kind);
}

/// RAII guard for scoped coverage collection.
pub struct CoverageGuard {
    was_enabled: bool,
}

impl CoverageGuard {
    /// Creates a new guard that enables coverage collection.
    pub fn new() -> Self {
        let was_enabled = is_enabled();
        enable();
        Self { was_enabled }
    }

    /// Creates a guard with a fresh/reset state.
    pub fn new_fresh() -> Self {
        reset();
        Self::new()
    }
}

impl Default for CoverageGuard {
    fn default() -> Self {
        Self::new()
    }
}

impl Drop for CoverageGuard {
    fn drop(&mut self) {
        if !self.was_enabled {
            disable();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_enable_disable() {
        disable();
        assert!(!is_enabled());

        enable();
        assert!(is_enabled());

        disable();
        assert!(!is_enabled());
    }

    #[test]
    fn test_record_hit() {
        enable();
        reset();

        record_hit(1, probe_kind::LINE);
        record_hit(1, probe_kind::LINE);
        record_hit(2, probe_kind::FUNCTION_ENTRY);

        let data = export_coverage();
        assert_eq!(data.get_hit_count(1), 2);
        assert_eq!(data.get_hit_count(2), 1);

        disable();
    }

    #[test]
    fn test_coverage_guard() {
        disable();

        {
            let _guard = CoverageGuard::new_fresh();
            assert!(is_enabled());
            record_hit(1, probe_kind::LINE);
        }

        assert!(!is_enabled());
    }

    #[test]
    fn test_encoded_hit() {
        enable();
        reset();

        // Encode probe_id=42, kind=LINE (0)
        let encoded: i64 = 42;
        __coverage_hit(encoded);

        let data = export_coverage();
        assert_eq!(data.get_hit_count(42), 1);

        disable();
    }
}
