# RustScript Framework Enhancement Specifications

This directory contains detailed specifications (RFCs) for enhancing the RustScript framework to support production-ready application development.

## Overview

These RFCs address gaps identified in the [Framework Assessment](../1_planning/framework-assessment.md) and aim to transform RustScript from "technically capable but verbose" to "best of all worlds" (Rust safety + React DX + Svelte simplicity).

## RFCs Index

| RFC | Title | Status | Priority | Complexity |
|-----|-------|--------|----------|------------|
| [RFC-001](RFC-001-async-lifecycle-hooks.md) | Async Lifecycle Hooks | Draft | P0 | High |
| [RFC-002](RFC-002-persisted-signals.md) | Persisted Signals | Draft | P0 | Medium |
| [RFC-003](RFC-003-hashmap-iteration.md) | HashMap Iteration in RSX | Draft | P1 | Medium |
| [RFC-004](RFC-004-parser-improvements.md) | Parser Improvements | Draft | P1 | Low-Medium |

## Implementation Roadmap

### Phase 1: Core Async & Persistence (Weeks 1-6)
**Goal**: Enable natural async operations and automatic state persistence

- RFC-001: Async Lifecycle Hooks
  - Week 1-2: Runtime AsyncEffect + cancellation
  - Week 3-4: Parser async on_mount/on_update syntax
  - Week 5-6: Codegen + testing

- RFC-002: Persisted Signals
  - Week 1-2: PersistedSignal type + localStorage
  - Week 3-4: IndexedDB backend
  - Week 5-6: Cross-tab sync + testing

### Phase 2: Template Enhancements (Weeks 7-10)
**Goal**: Natural iteration patterns and Rust compatibility

- RFC-003: HashMap Iteration
  - Week 7-8: Parser + type checking
  - Week 9-10: Codegen + testing

- RFC-004: Parser Improvements
  - Week 7: Underscore patterns
  - Week 8: Closure destructuring
  - Week 9: Reserved words
  - Week 10: Struct shorthand

## Impact Summary

| Metric | Current | After All RFCs |
|--------|---------|----------------|
| Lines of code for typical component | 150 | 30 (**80% reduction**) |
| Async operation boilerplate | 15 lines | 1 line |
| Persistence boilerplate | 10 lines | 1 line |
| HashMap iteration | Workaround required | Native support |
| Rust pattern compatibility | ~70% | ~95% |

## Dependencies

```
RFC-001 (Async) ──────────────────────────────────┐
                                                   ├──► Full Implementation
RFC-002 (Persistence) ────────────────────────────┤
                                                   │
RFC-003 (HashMap) ─────────► RFC-004 (Parser) ────┘
                   (benefits from)
```

## How to Contribute

1. **Review**: Read the RFC and provide feedback
2. **Implement**: Pick up implementation tasks from the timeline
3. **Test**: Write tests for new features
4. **Document**: Update docs with new patterns

## Status Definitions

- **Draft**: Initial specification, open for feedback
- **Accepted**: Approved for implementation
- **In Progress**: Implementation underway
- **Complete**: Merged and released

## Questions?

Open an issue with the `rfc` label for discussion.
