# RustScript Framework Capabilities Assessment

**Purpose**: Identify what features are needed in the RustScript framework to fully implement the Studio plan.

---

## 1. FEATURES REQUIRED BY THE STUDIO PLAN

From the `implementation-plan.md`, the Studio needs:

### Phase 1: Data Layer & IndexedDB Integration
- IndexedDB wrapper with async operations
- Data models for Workflows, Tokens, Settings
- CRUD operations for each store
- Initialization and migration logic

### Phase 2: Navigation Designer
- Dynamic workflow list iteration
- Flow canvas with node rendering
- Node selection and properties panel
- Keyboard shortcuts (Delete, Escape)
- Add/delete node functionality

### Phase 3: CSS Designer
- Token list iteration with dynamic updates
- Color picker input
- Live CSS variable injection
- Export functionality (CSS, JSON, Sass)
- Live preview with dark mode toggle

### Phase 4: Settings Page
- Auto-save checkbox
- Theme selector
- Persistence to IndexedDB

### Data Models Needed:
```rust
Workflow { id, name, nodes: [], edges: [], metadata: {} }
Token { id, category, name, value, type }
Settings { key, value }
```

---

## 2. FEATURES CURRENTLY AVAILABLE IN RUSTSCRIPT

### A. Data Structures & Collections

✅ **Supported:**
- `Vec<T>` - fully supported with standard methods
- `String` and string literals
- Struct definitions with fields
- Basic primitives (i32, bool, String)
- HashMap and BTreeMap available in stdlib (used internally)

✅ **Iterator Support:**
- `@for` loops over Vec collections
- Iterator trait support (demonstrated in codebase)
- `.iter()` method
- `.map()`, `.filter()`, `.collect()` via iterators
- Storage iteration (LocalStorage::iter())

✅ **Conditional Rendering:**
- `if` / `else if` / `else` expressions
- `@if` in RSX for conditional rendering
- Pattern matching (with workarounds noted in limitations)

### B. Data Persistence - localStorage/sessionStorage

✅ **Full Support:**
- `LocalStorage` API (string and JSON get/set)
- `SessionStorage` API (string and JSON get/set)
- `TypedStorage<T>` wrapper for type-safe access
- Iterator over key-value pairs
- `.keys()`, `.length()`, `.has()` methods
- Error handling with `StorageResult<T>`
- Automatic JSON serialization/deserialization via Serde

**Limitations:**
- Max 64KB buffer per read operation
- 5-10MB total quota per origin
- Not available in private browsing mode

### C. IndexedDB Support

✅ **Full Implementation Available:**
- `IdbDatabase` - database initialization
- `ObjectStore` - CRUD operations
- Schema builder for store creation
- Index support for queries
- Transaction support (read/write)
- Type-safe API with generic operations
- Reactive hooks: `use_query()`, `use_record()`, `use_count()`
- Query builder with filtering
- Cursor support for iteration

**Key Methods:**
- `db.store(name)?` - get store reference
- `store.add(record)?` - insert
- `store.put(record)?` - upsert
- `store.get(key)?` - fetch single record
- `store.get_all()?` - fetch all records
- `store.delete(key)?` - remove
- `store.clear()?` - clear all

### D. JavaScript Interoperability

✅ **Comprehensive JS Interop:**
- `JsValue` - opaque handle for JS values
- `js::call(name, args)` - call global functions
- `js::call_method(obj, method, args)` - call methods
- `js::global(name)` - get global values
- `js::eval(code)` - evaluate JavaScript
- Callbacks for event handlers
- Promise interop via `JsPromise`
- `construct()` - call constructors with `new`
- `import_module()` - dynamic ES module imports
- Console logging (`js::log()`, `js::error()`, `js::warn()`)
- Timers (`set_timeout()`, `set_interval()`, etc.)
- Animation frames (`request_animation_frame()`)

✅ **Async/Promise Support:**
- `JsPromise` implements `Future`
- `.await` support on Promises
- `.then()`, `.catch()`, `.finally()` chainable methods
- `Promise::all()`, `.race()`, `.all_settled()`, `.any()`
- Callback registration for promise resolution

### E. Reactive System

✅ **Signals (State Management):**
- `signal(T)` function to create signals
- `.get()` - read with dependency tracking
- `.set(value)` - update and notify
- `.update(f)` - transform current value
- `.modify(f)` - in-place mutation
- `.clone()` - clone signal reference
- Derived signals
- Effects system

✅ **Component Features:**
- `component` keyword for declarations
- Event handlers: `on:click`, `on:input`, `on:change`, etc.
- Event modifiers: `|stop`, `|self`, `|prevent`
- Class binding: `class:name={condition}`
- Style binding: `style:property={value}`
- Dynamic rendering with `@for` and `@if`

### F. Type System

✅ **Supported:**
- Generic types with constraints
- Trait implementations
- Serde for serialization/deserialization
- Type inference
- Error types with proper Error trait

---

## 3. GAP ANALYSIS - MISSING FEATURES NEEDED

### Critical Gaps

#### 1. No Native IndexedDB Initialization in Components
- ❌ IndexedDB is available at library level but lacks:
  - Component-level initialization hooks
  - Signal-based reactive queries directly in components
  - Automatic persistence triggers
- **Workaround**: Use `use_query()` and `use_record()` hooks, manually initialize DB in parent component

#### 2. No HashMap/Dict Iteration in RSX
- ❌ Current workaround requires `.values()` extraction
- ❌ No destructuring of key-value pairs in `@for` loops
- ❌ Plan mentions HashMap but parser limitations exist
- **Impact**: Makes token and workflow filtering difficult
- **Current Workaround**: Convert HashMap to Vec before iteration

#### 3. Parser Limitations (from RSX_PARSER_LIMITATIONS.md)
- ❌ No underscore patterns (`_`) in destructuring
- ❌ No tuple destructuring in closure parameters
- ❌ No enum path patterns in match arms
- ❌ No generic parameters on `#[component]` functions
- ❌ Reserved word conflicts (`style`, `class` as variable names)
- ❌ No struct field shorthand
- ❌ No or-patterns
- ❌ No loop labels
- **Impact**: Workarounds already documented and applied in codebase

#### 4. No Advanced Async Primitives
- ❌ No `async fn` support in components
- ⚠️ Promise support exists but limited reactive integration
- ❌ No `async` effect hooks
- ❌ No async iterators
- **Current State**: Manual Promise chaining required

#### 5. No Built-in State Persistence Layer
- ❌ No automatic signal serialization to IndexedDB
- ❌ No cache invalidation strategy
- ❌ No optimistic updates with rollback
- ⚠️ Manual integration required between signals and DB

---

## 4. DETAILED FEATURE MATRIX

| Feature | Available | Notes |
|---------|-----------|-------|
| **Data Types** | | |
| Vec<T> | ✅ Full | All standard methods |
| HashMap<K,V> | ✅ Std lib | Can use, but limited in RSX |
| String | ✅ Full | Full string support |
| Struct types | ✅ Full | Can serialize with Serde |
| **Collections** | | |
| Iteration (@for) | ✅ Full | Works with Vec, limited with HashMap |
| Iterator trait | ✅ Full | All standard adapter methods |
| Filter/Map/Collect | ✅ Full | Works in regular Rust code |
| **Persistence** | | |
| localStorage | ✅ Full | String + JSON serialization |
| sessionStorage | ✅ Full | String + JSON serialization |
| IndexedDB | ✅ Full | Complete API, reactive hooks |
| **JS Interop** | | |
| Call JS functions | ✅ Full | `js::call()` |
| Call methods | ✅ Full | `js::call_method()` |
| Promises | ✅ Full | `.await` support |
| Callbacks | ✅ Full | Event handlers + custom callbacks |
| Dynamic imports | ✅ Full | `import_module()` |
| Fetch API | ✅ Full | Via JS interop + HttpClient |
| **Async/Await** | | |
| Promise.then() | ✅ Full | Chainable methods |
| async/await keywords | ⚠️ Limited | Works with JsPromise, not components |
| Async iterators | ❌ No | Not available |
| **Reactive** | | |
| Signals | ✅ Full | Signal<T> with get/set/update |
| Derived signals | ✅ Full | Dependency tracking |
| Effects | ✅ Full | Automatic re-runs |
| Event handlers | ✅ Full | All standard DOM events |
| Event modifiers | ✅ Full | stop, prevent, self, etc. |

---

## 5. RECOMMENDED IMPLEMENTATION PATH

### Phase 1: Data Layer (✅ FEASIBLE)

```rust
// Create a database module with initialization
let db = IdbDatabase::open("studio", 1, |schema| {
    schema
        .create_store("workflows")
        .key_path("id")
        .build();
    schema
        .create_store("tokens")
        .key_path("id")
        .build();
    schema
        .create_store("settings")
        .key_path("key")
        .build();
})?;

// Use reactive queries
let workflows = use_query::<Workflow>(&db, "workflows");
let tokens = use_query::<Token>(&db, "tokens");
```

**Status**: All features available. Use `use_query()` and `use_record()` hooks for reactive binding.

### Phase 2: Navigation Designer (✅ FEASIBLE)

**✅ Working:**
- `@for workflow in workflows.get()` loop
- `on:click` handlers with signal updates
- `.selected` class binding
- Flow node rendering and selection
- Bottom panel conditional rendering with `@if`

**Workaround Note**: If workflows contain complex nested objects, flatten before iteration.

### Phase 3: CSS Designer (✅ FEASIBLE)

**✅ Working:**
- Token iteration over vectors
- Input binding with `on:input` handlers
- Category filtering via helper function
- Export format switching with signals
- Live CSS injection via `<style>` element

**Note**: Color input type not explicitly tested, use standard HTML `type="color"`.

### Phase 4: Settings (✅ FEASIBLE)

**✅ Working:**
- Form inputs with signal binding
- Checkbox for auto-save
- Select dropdown for theme
- Persistence via IndexedDB `use_record()` hook

---

## 6. KNOWN LIMITATIONS & WORKAROUNDS

| Limitation | Workaround | Impact |
|-----------|-----------|--------|
| No `_` in destructuring | Use named binding or index access | Low - mostly style |
| HashMap in @for | Convert to Vec before loop | Medium - affects token grouping |
| No tuple destructuring in closures | Extract tuple in function body | Low - verbose but works |
| No async fn in components | Use Promise chains with callbacks | Medium - async operations awkward |
| No reserved word variable names | Rename (e.g., `btn_style` instead of `style`) | Low - simple refactor |

---

## 7. SUMMARY: FEASIBILITY ASSESSMENT

| Phase | Status | Risk | Notes |
|-------|--------|------|-------|
| Phase 1 (IndexedDB) | ✅ READY | Low | All APIs available, just need wiring |
| Phase 2 (Navigation) | ✅ READY | Low | No missing features, purely implementation |
| Phase 3 (CSS Designer) | ✅ READY | Low | Token management straightforward |
| Phase 4 (Settings) | ✅ READY | Low | Simple form handling |
| Phase 5 (Polish) | ✅ READY | Low | Accessibility features available |

---

## 8. FEATURES REQUIRING FRAMEWORK ENHANCEMENT

The **only truly missing features** that would require RustScript enhancements:

### High Priority (Would Significantly Improve DX)

1. **Better HashMap iteration in RSX**
   - Current: Must convert to Vec before `@for` loop
   - Needed: Direct `@for (key, value) in hashmap` support
   - Impact: Medium - affects token grouping by category

2. **Async component lifecycle hooks**
   - Current: Manual Promise chaining
   - Needed: `async fn on_mount()`, `async fn on_update()`
   - Impact: Medium - makes IndexedDB initialization awkward

3. **Automatic signal-to-storage persistence**
   - Current: Manual sync between signals and IndexedDB
   - Needed: `persisted_signal("key", default)` that auto-syncs
   - Impact: Medium - boilerplate reduction

### Medium Priority (Nice to Have)

4. **Parser improvements for closures**
   - Tuple destructuring in closure parameters
   - Underscore patterns in destructuring
   - Impact: Low - workarounds exist

5. **Form builder utilities**
   - Validation helpers
   - Form state management
   - Impact: Low - can be implemented as utility module

### Low Priority (Future Enhancements)

6. **Async iterators**
   - For streaming data from IndexedDB
   - Impact: Low - not critical for Studio

7. **Optimistic updates with rollback**
   - For better UX during save operations
   - Impact: Low - can be implemented manually

---

## 9. CONCLUSION

**The RustScript framework has all the core features needed to implement the Studio plan.**

The gaps are primarily:
1. **Parser ergonomics** - Workarounds documented and usable
2. **Async component integration** - Manual Promise handling works
3. **HashMap iteration in RSX** - Convert to Vec as workaround

No blocking issues exist. Implementation can proceed with documented workarounds.

---

## Files Analyzed

- `/home/adentic/rustscript-studio/RSX_PARSER_LIMITATIONS.md`
- `/home/adentic/rustscript-studio/docs/1_planning/implementation-plan.md`
- `/home/adentic/rustscript/crates/runtime/std/src/storage.rs`
- `/home/adentic/rustscript/crates/runtime/js/src/lib.rs`
- `/home/adentic/rustscript/crates/runtime/js/src/promise.rs`
- `/home/adentic/rustscript/crates/runtime/core/src/signal.rs`
- `/home/adentic/rustscript/crates/runtime/db/client/src/lib.rs`
- `/home/adentic/rustscript/crates/runtime/db/client/src/hooks.rs`
