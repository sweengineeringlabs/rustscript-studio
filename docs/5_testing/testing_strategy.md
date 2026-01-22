# Testing Strategy

This document outlines the testing strategy and conventions for the RustScript Studio project.

## Test Organization

Tests are organized into distinct categories based on their purpose and scope. Each crate follows a consistent naming convention:

```
crates/<domain>/<crate>/
├── src/
│   └── *.rs                           # Unit tests inline (feature tests contained in class)
└── tests/
    ├── <crate>_int_test.rs            # Integration tests
    ├── <crate>_stress_test.rs         # Stress tests
    ├── <crate>_perf_test.rs           # Performance tests
    └── <crate>_load_test.rs           # Load tests
```

### Test Categories

| Category | File Pattern | Purpose | Characteristics |
|----------|-------------|---------|-----------------|
| **Unit** | `src/*.rs` (inline) | Test individual functions/methods in isolation | Fast, no I/O, mocked dependencies |
| **Integration** | `tests/<crate>_int_test.rs` | Test public API and module interactions | Uses real dependencies, tests contracts |
| **Stress** | `tests/<crate>_stress_test.rs` | Test edge cases and boundary conditions | Deep nesting, complex patterns, corner cases |
| **Performance** | `tests/<crate>_perf_test.rs` | Measure and guard against regressions | Compilation time, output size, scaling |
| **Load** | `tests/<crate>_load_test.rs` | Test behavior under heavy load | Concurrency, sustained throughput, memory stability |

### Category Details

#### Unit Tests
- Located inline within source files using `#[cfg(test)]` modules
- Test individual functions and methods in isolation
- Should be fast and have no external dependencies
- Mock external services and I/O

```rust
// src/parser.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_simple_expression() {
        // ...
    }
}
```

#### Integration Tests (`*_int_test.rs`)
- Test the public API of the crate
- Verify module interactions work correctly
- Use real implementations (no mocking)
- Test the contract between components

```rust
// tests/codegen_int_test.rs
#[test]
fn compile_simple_function() {
    let module = create_test_module();
    let wasm = compile(&module, CodegenOptions::new()).unwrap();
    assert!(wasmparser::validate(&wasm).is_ok());
}
```

#### Stress Tests (`*_stress_test.rs`)
- Test edge cases and boundary conditions
- Deep nesting levels (e.g., 5+ levels of nested conditionals)
- Complex patterns (diamond control flow, asymmetric branches)
- Large inputs that push limits

```rust
// tests/codegen_stress_test.rs
#[test]
fn stress_test_5_level_nested_conditionals() {
    // Verify compiler handles deeply nested structures
}
```

#### Performance Tests (`*_perf_test.rs`)
- Measure compilation time for various input sizes
- Track output size to detect bloat
- Verify linear scaling (catch exponential blowups)
- Compare sequential vs parallel performance

```rust
// tests/codegen_perf_test.rs
#[test]
fn perf_sequential_statements_1000() {
    let start = Instant::now();
    let wasm = compile(&module, options).unwrap();
    assert!(start.elapsed() < Duration::from_secs(2));
}
```

#### Load Tests (`*_load_test.rs`)
- Concurrent compilation from multiple threads
- Sustained throughput over time
- Memory stability under repeated operations
- Burst compilation (rapid successive calls)

```rust
// tests/codegen_load_test.rs
#[test]
fn load_concurrent_compilation() {
    // 8 threads × 50 compilations each
}

#[test]
fn load_sustained_throughput() {
    // Compile continuously for 3 seconds
}
```

### Running Tests

```bash
# Run all tests for a crate
cargo test -p <crate>

# Run specific test category
cargo test -p <crate> --test <crate>_int_test
cargo test -p <crate> --test <crate>_stress_test
cargo test -p <crate> --test <crate>_perf_test
cargo test -p <crate> --test <crate>_load_test

# Run with release optimizations (recommended for perf/load tests)
cargo test --release -p <crate> --test <crate>_perf_test
cargo test --release -p <crate> --test <crate>_load_test

# Run all tests in workspace
cargo test --workspace
```

### Example: `rsc-codegen` Test Structure

```
crates/compiler/codegen/
├── src/
│   └── wasm.rs                        # 158 unit tests
└── tests/
    ├── codegen_int_test.rs            # 150 integration tests
    ├── codegen_stress_test.rs         # 5 stress tests
    ├── codegen_perf_test.rs           # 10 performance tests
    └── codegen_load_test.rs           # 8 load tests
```

**Total: 331 tests**

### Guidelines

1. **Unit tests** should be fast (<100ms each) and run frequently during development
2. **Integration tests** verify the public contract; update when API changes
3. **Stress tests** catch edge cases; add new ones when bugs are found in complex scenarios
4. **Performance tests** set reasonable bounds; adjust thresholds if optimization changes expectations
5. **Load tests** run with `--release` for accurate measurements; may take longer than other tests

### Naming Conventions

- Test functions: `test_<what_is_being_tested>` or `<category>_<description>`
- Integration: `compile_*`, `parse_*`, `validate_*`
- Stress: `stress_test_*`
- Performance: `perf_*`
- Load: `load_*`
