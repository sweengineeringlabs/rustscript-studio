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
    ├── <crate>_load_test.rs           # Load tests
    ├── <crate>_e2e_test.rs            # End-to-end tests
    └── <crate>_security_test.rs       # Security tests
```

### Test Categories

| Category | File Pattern | Purpose | Characteristics |
|----------|-------------|---------|-----------------|
| **Unit** | `src/*.rs` (inline) | Test a single function/method in complete isolation | Fast, mocked dependencies, pure logic |
| **Feature** | `src/*.rs` (inline) | Test module capabilities by exercising multiple internal functions together | Fast, no I/O, co-located with code |
| **Integration** | `tests/<crate>_int_test.rs` | Test public API and module interactions | Uses real dependencies, tests contracts |
| **Stress** | `tests/<crate>_stress_test.rs` | Test edge cases and boundary conditions | Deep nesting, complex patterns, corner cases |
| **Performance** | `tests/<crate>_perf_test.rs` | Measure and guard against regressions | Compilation time, output size, scaling |
| **Load** | `tests/<crate>_load_test.rs` | Test behavior under heavy load | Concurrency, sustained throughput, memory stability |
| **E2E** | `tests/<crate>_e2e_test.rs` | Test full user workflows in real browser | Browser automation, UI interactions, full stack |
| **Security** | `tests/<crate>_security_test.rs` | Test security properties and vulnerabilities | Input validation, injection, auth, OWASP checks |

### Category Details

#### Unit Tests
- Located inline within source files using `#[cfg(test)]` modules
- Test a single function/method in complete isolation
- Mock all dependencies
- Focus on pure logic and edge cases of one function

```rust
// src/math.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_positive_numbers() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn add_handles_overflow() {
        assert_eq!(add(i32::MAX, 1), i32::MIN); // or error
    }
}
```

#### Feature Tests
- Located inline within source files using `#[cfg(test)]` modules
- Test module capabilities by exercising multiple internal functions together
- Verify a feature works end-to-end within the module
- Should be fast and have no external dependencies
- Co-located with the code they test

```rust
// src/parser.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_nested_expression() {
        // Exercises tokenize() -> parse_expr() -> build_ast()
        let input = "(1 + (2 * 3))";
        let ast = parse(input).unwrap();
        assert_eq!(ast.evaluate(), 7);
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

#### E2E Tests (`*_e2e_test.rs`)
- Test complete user workflows in a real browser
- Use `rsc-test/browser` module for browser automation
- Verify UI interactions, navigation, and visual rendering
- Test full stack from UI to backend

```rust
// tests/studio_e2e_test.rs
#[tokio::test]
async fn e2e_user_login_flow() {
    let ctx = BrowserTestContext::new_default().await?;
    ctx.goto("/login").await?;
    ctx.fill("#username", "testuser").await?;
    ctx.fill("#password", "password").await?;
    ctx.click("button[type=submit]").await?;
    ctx.wait_for("#dashboard").await?;
    ctx.assert_url_contains("/dashboard").await?;
}

#[tokio::test]
async fn e2e_create_workflow() {
    let ctx = BrowserTestContext::new_default().await?;
    ctx.goto("/workflows").await?;
    ctx.click("#new-workflow").await?;
    ctx.assert_element_exists(".workflow-canvas").await?;
}
```

#### Security Tests (`*_security_test.rs`)
- Test input validation and sanitization
- Check for injection vulnerabilities (XSS, SQL, command)
- Verify authentication and authorization
- Test OWASP Top 10 vulnerabilities
- Validate cryptographic implementations

```rust
// tests/parser_security_test.rs
#[test]
fn security_reject_script_injection() {
    let malicious = "<script>alert('xss')</script>";
    let result = parse_input(malicious);
    assert!(result.is_err() || !result.unwrap().contains("<script>"));
}

#[test]
fn security_path_traversal_blocked() {
    let malicious = "../../../etc/passwd";
    let result = resolve_path(malicious);
    assert!(result.is_err());
}

#[test]
fn security_input_length_limits() {
    let oversized = "A".repeat(1_000_000);
    let result = parse_input(&oversized);
    assert!(result.is_err());
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
cargo test -p <crate> --test <crate>_e2e_test
cargo test -p <crate> --test <crate>_security_test

# Run with release optimizations (recommended for perf/load tests)
cargo test --release -p <crate> --test <crate>_perf_test
cargo test --release -p <crate> --test <crate>_load_test

# Run E2E tests (requires browser)
cargo test -p <crate> --test <crate>_e2e_test --features browser

# Run all tests in workspace
cargo test --workspace
```

### Example: `rsc-codegen` Test Structure

```
crates/compiler/codegen/
├── src/
│   └── wasm.rs                        # 158 feature tests
└── tests/
    ├── codegen_int_test.rs            # 150 integration tests
    ├── codegen_stress_test.rs         # 5 stress tests
    ├── codegen_perf_test.rs           # 10 performance tests
    └── codegen_load_test.rs           # 8 load tests
```

**Total: 331 tests**

### Guidelines

1. **Unit tests** test one function in isolation; mock dependencies; focus on edge cases
2. **Feature tests** should be fast (<100ms each) and run frequently during development
3. **Integration tests** verify the public contract; update when API changes
4. **Stress tests** catch edge cases; add new ones when bugs are found in complex scenarios
5. **Performance tests** set reasonable bounds; adjust thresholds if optimization changes expectations
6. **Load tests** run with `--release` for accurate measurements; may take longer than other tests
7. **E2E tests** require browser setup; run in CI with headless Chrome; use retries for flaky tests
8. **Security tests** should cover OWASP Top 10; run on every PR; block merge on failures

### Naming Conventions

- Test functions: `test_<what_is_being_tested>` or `<category>_<description>`
- Unit: `<function>_<scenario>` (e.g., `add_handles_overflow`)
- Feature: `<feature>_<behavior>` (e.g., `parse_nested_expression`)
- Integration: `compile_*`, `parse_*`, `validate_*`
- Stress: `stress_test_*`
- Performance: `perf_*`
- Load: `load_*`
- E2E: `e2e_*`
- Security: `security_*`
