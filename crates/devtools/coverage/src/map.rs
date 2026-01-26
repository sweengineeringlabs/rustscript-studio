//! Coverage map types for linking probes to source locations.

use crate::data::probe_kind;
use crate::error::{CoverageError, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Information about a function in the source code.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FunctionInfo {
    /// Function name.
    pub name: String,
    /// Starting line number (1-indexed).
    pub start_line: u32,
    /// Ending line number (1-indexed).
    pub end_line: u32,
    /// Probe ID for function entry.
    pub entry_probe: u64,
}

/// Location of a coverage probe in source code.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ProbeLocation {
    /// Line number (1-indexed).
    pub line: u32,
    /// Column number (1-indexed).
    pub column: u32,
    /// Kind of probe (line, function, branch).
    pub kind: u8,
    /// Name of the containing function, if any.
    pub function: Option<String>,
    /// Source file path.
    pub file: String,
}

/// Coverage map linking probe IDs to source locations.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CoverageMap {
    /// Map of probe IDs to their source locations.
    pub probes: HashMap<u64, ProbeLocation>,
    /// Information about functions in the source.
    pub functions: Vec<FunctionInfo>,
    /// Source file path.
    pub file: String,
    /// Total number of probes in this map.
    pub total_probes: usize,
}

impl CoverageMap {
    /// Creates a new empty coverage map for a file.
    pub fn new(file: String) -> Self {
        Self {
            probes: HashMap::new(),
            functions: Vec::new(),
            file,
            total_probes: 0,
        }
    }

    /// Parses a coverage map from JSON string.
    pub fn from_json(json: &str) -> Result<Self> {
        serde_json::from_str(json).map_err(|e| CoverageError::ParseError(e.to_string()))
    }

    /// Parses multiple coverage maps from a combined JSON string.
    pub fn from_json_array(json: &str) -> Result<Vec<Self>> {
        serde_json::from_str(json).map_err(|e| CoverageError::ParseError(e.to_string()))
    }

    /// Serializes the coverage map to JSON.
    pub fn to_json(&self) -> Result<String> {
        serde_json::to_string_pretty(self).map_err(CoverageError::from)
    }

    /// Adds a probe to the map.
    pub fn add_probe(&mut self, probe_id: u64, location: ProbeLocation) {
        self.probes.insert(probe_id, location);
        self.total_probes = self.probes.len();
    }

    /// Adds a function to the map.
    pub fn add_function(&mut self, info: FunctionInfo) {
        self.functions.push(info);
    }

    /// Gets the location for a probe ID.
    pub fn get_location(&self, probe_id: u64) -> Option<&ProbeLocation> {
        self.probes.get(&probe_id)
    }

    /// Gets all probes for a specific line.
    pub fn probes_for_line(&self, line: u32) -> Vec<(u64, &ProbeLocation)> {
        self.probes
            .iter()
            .filter(|(_, loc)| loc.line == line)
            .map(|(id, loc)| (*id, loc))
            .collect()
    }

    /// Gets all line probes in the map.
    pub fn line_probes(&self) -> impl Iterator<Item = (u64, &ProbeLocation)> {
        self.probes
            .iter()
            .filter(|(_, loc)| loc.kind == probe_kind::LINE)
            .map(|(id, loc)| (*id, loc))
    }

    /// Gets all function entry probes in the map.
    pub fn function_probes(&self) -> impl Iterator<Item = (u64, &ProbeLocation)> {
        self.probes
            .iter()
            .filter(|(_, loc)| loc.kind == probe_kind::FUNCTION_ENTRY)
            .map(|(id, loc)| (*id, loc))
    }

    /// Gets all branch probes in the map.
    pub fn branch_probes(&self) -> impl Iterator<Item = (u64, &ProbeLocation)> {
        self.probes
            .iter()
            .filter(|(_, loc)| {
                loc.kind == probe_kind::BRANCH_TRUE || loc.kind == probe_kind::BRANCH_FALSE
            })
            .map(|(id, loc)| (*id, loc))
    }

    /// Returns all unique line numbers that have probes.
    pub fn covered_lines(&self) -> Vec<u32> {
        let mut lines: Vec<u32> = self.probes.values().map(|loc| loc.line).collect();
        lines.sort_unstable();
        lines.dedup();
        lines
    }

    /// Returns the function containing a given line, if any.
    pub fn function_at_line(&self, line: u32) -> Option<&FunctionInfo> {
        self.functions
            .iter()
            .find(|f| line >= f.start_line && line <= f.end_line)
    }
}

/// Collection of coverage maps for multiple files.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CoverageMapSet {
    /// Maps keyed by file path.
    pub maps: HashMap<String, CoverageMap>,
}

impl CoverageMapSet {
    /// Creates a new empty map set.
    pub fn new() -> Self {
        Self {
            maps: HashMap::new(),
        }
    }

    /// Parses a map set from JSON.
    pub fn from_json(json: &str) -> Result<Self> {
        let maps: Vec<CoverageMap> = serde_json::from_str(json)
            .map_err(|e| CoverageError::ParseError(e.to_string()))?;

        let mut set = Self::new();
        for map in maps {
            set.maps.insert(map.file.clone(), map);
        }
        Ok(set)
    }

    /// Adds a coverage map for a file.
    pub fn add(&mut self, map: CoverageMap) {
        self.maps.insert(map.file.clone(), map);
    }

    /// Gets the coverage map for a file.
    pub fn get(&self, file: &str) -> Option<&CoverageMap> {
        self.maps.get(file)
    }

    /// Gets the location for a probe ID across all maps.
    pub fn get_location(&self, probe_id: u64) -> Option<&ProbeLocation> {
        for map in self.maps.values() {
            if let Some(loc) = map.get_location(probe_id) {
                return Some(loc);
            }
        }
        None
    }

    /// Returns an iterator over all files.
    pub fn files(&self) -> impl Iterator<Item = &str> {
        self.maps.keys().map(String::as_str)
    }

    /// Returns the total number of probes across all maps.
    pub fn total_probes(&self) -> usize {
        self.maps.values().map(|m| m.total_probes).sum()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_coverage_map_creation() {
        let mut map = CoverageMap::new("test.rsx".to_string());
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

        assert_eq!(map.total_probes, 1);
        assert!(map.get_location(1).is_some());
    }

    #[test]
    fn test_coverage_map_json_roundtrip() {
        let mut map = CoverageMap::new("test.rsx".to_string());
        map.add_probe(
            1,
            ProbeLocation {
                line: 10,
                column: 1,
                kind: probe_kind::LINE,
                function: None,
                file: "test.rsx".to_string(),
            },
        );
        map.add_function(FunctionInfo {
            name: "main".to_string(),
            start_line: 5,
            end_line: 20,
            entry_probe: 0,
        });

        let json = map.to_json().unwrap();
        let parsed = CoverageMap::from_json(&json).unwrap();

        assert_eq!(parsed.file, map.file);
        assert_eq!(parsed.total_probes, map.total_probes);
    }

    #[test]
    fn test_probes_for_line() {
        let mut map = CoverageMap::new("test.rsx".to_string());
        map.add_probe(
            1,
            ProbeLocation {
                line: 10,
                column: 1,
                kind: probe_kind::LINE,
                function: None,
                file: "test.rsx".to_string(),
            },
        );
        map.add_probe(
            2,
            ProbeLocation {
                line: 10,
                column: 5,
                kind: probe_kind::BRANCH_TRUE,
                function: None,
                file: "test.rsx".to_string(),
            },
        );

        let probes = map.probes_for_line(10);
        assert_eq!(probes.len(), 2);
    }
}
