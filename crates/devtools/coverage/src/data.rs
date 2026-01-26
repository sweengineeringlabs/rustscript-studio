//! Coverage data collection types.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

/// Probe kind constants matching MIR definitions.
pub mod probe_kind {
    /// Line coverage probe - tracks if a line was executed.
    pub const LINE: u8 = 0;
    /// Function entry probe - tracks function calls.
    pub const FUNCTION_ENTRY: u8 = 1;
    /// Branch true probe - tracks true branch of conditionals.
    pub const BRANCH_TRUE: u8 = 2;
    /// Branch false probe - tracks false branch of conditionals.
    pub const BRANCH_FALSE: u8 = 3;
}

/// A single probe hit record.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ProbeHit {
    /// Unique identifier for the probe.
    pub probe_id: u64,
    /// Kind of probe (line, function, branch).
    pub kind: u8,
    /// Number of times this probe was hit.
    pub count: u64,
}

impl ProbeHit {
    /// Creates a new probe hit with count of 1.
    pub fn new(probe_id: u64, kind: u8) -> Self {
        Self {
            probe_id,
            kind,
            count: 1,
        }
    }

    /// Creates a probe hit with a specific count.
    pub fn with_count(probe_id: u64, kind: u8, count: u64) -> Self {
        Self {
            probe_id,
            kind,
            count,
        }
    }
}

/// Collected coverage data from a test run.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CoverageData {
    /// Map of probe IDs to their hit records.
    pub probe_hits: HashMap<u64, ProbeHit>,
    /// Timestamp when collection started (Unix milliseconds).
    pub start_time: u64,
    /// Timestamp when collection ended (Unix milliseconds).
    pub end_time: u64,
}

impl Default for CoverageData {
    fn default() -> Self {
        Self::new()
    }
}

impl CoverageData {
    /// Creates a new empty coverage data instance.
    pub fn new() -> Self {
        Self {
            probe_hits: HashMap::new(),
            start_time: current_time_millis(),
            end_time: 0,
        }
    }

    /// Records a probe hit.
    pub fn record_hit(&mut self, probe_id: u64, kind: u8) {
        self.probe_hits
            .entry(probe_id)
            .and_modify(|hit| hit.count += 1)
            .or_insert_with(|| ProbeHit::new(probe_id, kind));
    }

    /// Gets the hit count for a probe, returning 0 if not hit.
    pub fn get_hit_count(&self, probe_id: u64) -> u64 {
        self.probe_hits.get(&probe_id).map_or(0, |h| h.count)
    }

    /// Marks the collection as finished with current timestamp.
    pub fn finish(&mut self) {
        self.end_time = current_time_millis();
    }

    /// Resets all collected data.
    pub fn reset(&mut self) {
        self.probe_hits.clear();
        self.start_time = current_time_millis();
        self.end_time = 0;
    }

    /// Merges another coverage data into this one.
    pub fn merge(&mut self, other: &CoverageData) {
        for (probe_id, hit) in &other.probe_hits {
            self.probe_hits
                .entry(*probe_id)
                .and_modify(|h| h.count += hit.count)
                .or_insert_with(|| hit.clone());
        }
        // Extend time range
        if other.start_time < self.start_time {
            self.start_time = other.start_time;
        }
        if other.end_time > self.end_time {
            self.end_time = other.end_time;
        }
    }

    /// Returns the total number of unique probes hit.
    pub fn probes_hit(&self) -> usize {
        self.probe_hits.len()
    }

    /// Returns an iterator over all probe hits.
    pub fn iter(&self) -> impl Iterator<Item = &ProbeHit> {
        self.probe_hits.values()
    }

    /// Converts probe hits to a vector for serialization.
    pub fn to_probe_hits_vec(&self) -> Vec<ProbeHit> {
        self.probe_hits.values().cloned().collect()
    }

    /// Creates coverage data from a vector of probe hits.
    pub fn from_probe_hits(hits: Vec<ProbeHit>) -> Self {
        let mut data = Self::new();
        for hit in hits {
            data.probe_hits.insert(hit.probe_id, hit);
        }
        data
    }
}

/// Returns current time in milliseconds since Unix epoch.
fn current_time_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_probe_hit_creation() {
        let hit = ProbeHit::new(42, probe_kind::LINE);
        assert_eq!(hit.probe_id, 42);
        assert_eq!(hit.kind, probe_kind::LINE);
        assert_eq!(hit.count, 1);
    }

    #[test]
    fn test_coverage_data_record_hit() {
        let mut data = CoverageData::new();
        data.record_hit(1, probe_kind::LINE);
        data.record_hit(1, probe_kind::LINE);
        data.record_hit(2, probe_kind::FUNCTION_ENTRY);

        assert_eq!(data.get_hit_count(1), 2);
        assert_eq!(data.get_hit_count(2), 1);
        assert_eq!(data.get_hit_count(3), 0);
    }

    #[test]
    fn test_coverage_data_merge() {
        let mut data1 = CoverageData::new();
        data1.record_hit(1, probe_kind::LINE);

        let mut data2 = CoverageData::new();
        data2.record_hit(1, probe_kind::LINE);
        data2.record_hit(2, probe_kind::LINE);

        data1.merge(&data2);
        assert_eq!(data1.get_hit_count(1), 2);
        assert_eq!(data1.get_hit_count(2), 1);
    }

    #[test]
    fn test_coverage_data_reset() {
        let mut data = CoverageData::new();
        data.record_hit(1, probe_kind::LINE);
        assert_eq!(data.probes_hit(), 1);

        data.reset();
        assert_eq!(data.probes_hit(), 0);
    }
}
