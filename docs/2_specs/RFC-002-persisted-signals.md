# RFC-002: Persisted Signals

**Status**: Draft
**Author**: RustScript Team
**Created**: 2026-01-27
**Target**: RustScript 0.2.0

---

## Summary

Add automatic persistence for signals to localStorage, sessionStorage, and IndexedDB, enabling state that survives page refreshes with minimal boilerplate.

---

## Motivation

### Current Problem

```rust
component Settings {
    let theme = signal("light");
    let auto_save = signal(true);
    let recent_files = signal(vec![]);

    // Manual: Load from storage on mount
    effect {
        if let Some(t) = localStorage.get_json::<String>("theme") {
            theme.set(t);
        }
        if let Some(a) = localStorage.get_json::<bool>("auto_save") {
            auto_save.set(a);
        }
        if let Some(r) = localStorage.get_json::<Vec<String>>("recent_files") {
            recent_files.set(r);
        }
    }

    // Manual: Save theme changes
    effect {
        localStorage.set_json("theme", &theme.get());
    }

    // Manual: Save auto_save changes
    effect {
        localStorage.set_json("auto_save", &auto_save.get());
    }

    // Manual: Save recent_files changes
    effect {
        localStorage.set_json("recent_files", &recent_files.get());
    }

    render { ... }
}
```

**Issues:**
1. 6 effects for 3 persisted values (2 per value: load + save)
2. Key strings duplicated, prone to typos
3. No type safety between storage key and value type
4. Race conditions between load and initial render
5. No handling of storage errors
6. No migration strategy for schema changes

### Proposed Solution

```rust
component Settings {
    // One-liner: auto-loads on mount, auto-saves on change
    let theme = persisted("theme", "light");
    let auto_save = persisted("auto_save", true);
    let recent_files = persisted("recent_files", vec![]);

    render {
        <select value={theme.get()} on:change={|e| theme.set(e.value)}>
            <option value="light">"Light"</option>
            <option value="dark">"Dark"</option>
        </select>
    }
}
```

---

## Detailed Design

### 1. Core API

#### `persisted<T>` - localStorage Signal

```rust
/// Create a signal that automatically persists to localStorage.
///
/// # Arguments
/// * `key` - Storage key (must be unique within the app)
/// * `default` - Default value if key doesn't exist in storage
///
/// # Returns
/// A `PersistedSignal<T>` that behaves like a regular signal but syncs to storage.
pub fn persisted<T>(key: &str, default: T) -> PersistedSignal<T>
where
    T: Serialize + DeserializeOwned + Clone + PartialEq + 'static;
```

**Usage:**
```rust
let count = persisted("counter", 0);
count.set(count.get() + 1);  // Automatically saved to localStorage
```

#### `session_persisted<T>` - sessionStorage Signal

```rust
/// Create a signal that persists to sessionStorage (cleared when tab closes).
pub fn session_persisted<T>(key: &str, default: T) -> PersistedSignal<T>
where
    T: Serialize + DeserializeOwned + Clone + PartialEq + 'static;
```

#### `db_persisted<T>` - IndexedDB Signal

```rust
/// Create a signal that persists to IndexedDB.
/// Supports larger data and structured queries.
pub fn db_persisted<T>(
    db: &IdbDatabase,
    store: &str,
    key: impl Into<IdbKey>,
    default: T,
) -> DbPersistedSignal<T>
where
    T: Serialize + DeserializeOwned + Clone + PartialEq + 'static;
```

**Usage:**
```rust
component WorkflowEditor {
    prop db: IdbDatabase;
    prop workflow_id: String;

    // Auto-loads from IndexedDB, auto-saves changes
    let workflow = db_persisted(&db, "workflows", &workflow_id, Workflow::default());

    render {
        <input
            value={workflow.get().name}
            on:input={|e| workflow.update(|w| w.name = e.value)}
        />
    }
}
```

### 2. Type Definitions

#### `PersistedSignal<T>`

```rust
/// A signal that automatically syncs with browser storage.
pub struct PersistedSignal<T> {
    /// The underlying reactive signal
    inner: Signal<T>,
    /// Storage backend
    storage: StorageBackend,
    /// Storage key
    key: String,
    /// Serialization format
    format: SerializationFormat,
    /// Error handler
    on_error: Option<Box<dyn Fn(StorageError)>>,
}

pub enum StorageBackend {
    LocalStorage,
    SessionStorage,
    IndexedDB { db: IdbDatabase, store: String },
}

pub enum SerializationFormat {
    Json,
    MessagePack,  // Future: more compact binary format
}

impl<T> PersistedSignal<T> {
    /// Get the current value (same as Signal)
    pub fn get(&self) -> T;

    /// Set and persist the value
    pub fn set(&self, value: T);

    /// Update and persist
    pub fn update(&self, f: impl FnOnce(&T) -> T);

    /// Modify in place and persist
    pub fn modify(&self, f: impl FnOnce(&mut T));

    /// Force reload from storage
    pub fn reload(&self);

    /// Clear from storage and reset to default
    pub fn clear(&self);

    /// Check if value exists in storage
    pub fn is_stored(&self) -> bool;

    /// Get storage key
    pub fn key(&self) -> &str;
}
```

#### `PersistedSignalOptions<T>`

```rust
/// Builder for configuring persisted signals
pub struct PersistedSignalOptions<T> {
    key: String,
    default: T,
    storage: StorageBackend,
    debounce_ms: Option<u32>,
    on_error: Option<Box<dyn Fn(StorageError)>>,
    migrate: Option<Box<dyn Fn(JsValue) -> T>>,
    validate: Option<Box<dyn Fn(&T) -> bool>>,
}

impl<T> PersistedSignalOptions<T> {
    pub fn new(key: &str, default: T) -> Self;

    /// Use sessionStorage instead of localStorage
    pub fn session(self) -> Self;

    /// Use IndexedDB
    pub fn indexed_db(self, db: &IdbDatabase, store: &str) -> Self;

    /// Debounce writes (default: 0ms, immediate)
    pub fn debounce(self, ms: u32) -> Self;

    /// Handle storage errors
    pub fn on_error(self, handler: impl Fn(StorageError) + 'static) -> Self;

    /// Migrate from old schema
    pub fn migrate(self, migrator: impl Fn(JsValue) -> T + 'static) -> Self;

    /// Validate before saving
    pub fn validate(self, validator: impl Fn(&T) -> bool + 'static) -> Self;

    /// Build the persisted signal
    pub fn build(self) -> PersistedSignal<T>;
}
```

**Usage with options:**
```rust
let settings = PersistedSignalOptions::new("settings", Settings::default())
    .debounce(500)  // Wait 500ms after last change before saving
    .on_error(|e| console::error!("Storage error: {:?}", e))
    .migrate(|old| {
        // Handle schema changes
        if let Ok(v1) = serde_json::from_value::<SettingsV1>(old) {
            Settings::from_v1(v1)
        } else {
            Settings::default()
        }
    })
    .build();
```

### 3. Storage Error Handling

```rust
#[derive(Debug, Clone)]
pub enum StorageError {
    /// Storage is not available (private browsing, etc.)
    NotAvailable,
    /// Quota exceeded
    QuotaExceeded { used: u64, limit: u64 },
    /// Serialization failed
    SerializationError(String),
    /// Deserialization failed
    DeserializationError(String),
    /// IndexedDB specific error
    IndexedDbError(String),
    /// Key not found
    NotFound(String),
    /// Validation failed
    ValidationFailed,
}

impl PersistedSignal<T> {
    /// Set with explicit error handling
    pub fn try_set(&self, value: T) -> Result<(), StorageError>;

    /// Get last error if any
    pub fn last_error(&self) -> Option<StorageError>;
}
```

### 4. Namespace Support

```rust
/// Create a namespace for related persisted values
pub fn persisted_namespace(prefix: &str) -> PersistedNamespace;

pub struct PersistedNamespace {
    prefix: String,
}

impl PersistedNamespace {
    /// Create a persisted signal within this namespace
    pub fn signal<T>(&self, key: &str, default: T) -> PersistedSignal<T>;

    /// Clear all values in this namespace
    pub fn clear_all(&self);

    /// List all keys in this namespace
    pub fn keys(&self) -> Vec<String>;
}
```

**Usage:**
```rust
component App {
    let ns = persisted_namespace("myapp");

    let theme = ns.signal("theme", "light");           // key: "myapp:theme"
    let sidebar = ns.signal("sidebar_open", true);     // key: "myapp:sidebar_open"
    let recent = ns.signal("recent_files", vec![]);    // key: "myapp:recent_files"

    // Clear all app settings
    fn reset_settings() {
        ns.clear_all();
    }
}
```

### 5. Sync Across Tabs

```rust
/// Create a persisted signal that syncs across browser tabs
pub fn synced_persisted<T>(key: &str, default: T) -> SyncedPersistedSignal<T>
where
    T: Serialize + DeserializeOwned + Clone + PartialEq + 'static;
```

**Implementation:**
- Listens to `storage` event on window
- When another tab changes the value, this tab's signal updates
- Useful for settings that should apply everywhere

```rust
component App {
    // Changes in one tab reflect in all tabs
    let theme = synced_persisted("theme", "light");

    render {
        <div class={if theme.get() == "dark" { "dark-mode" } else { "" }}>
            // Theme changes in other tabs are reflected immediately
        </div>
    }
}
```

---

## Implementation Details

### Runtime Changes

#### Signal Storage Extension

```rust
// In runtime/core/src/signal.rs

pub struct SignalStorage {
    value: Box<dyn Any>,
    subscribers: HashSet<SubscriberId>,
    // NEW: Optional persistence config
    persistence: Option<PersistenceConfig>,
}

struct PersistenceConfig {
    backend: StorageBackend,
    key: String,
    serializer: Box<dyn Fn(&dyn Any) -> Result<String, StorageError>>,
    deserializer: Box<dyn Fn(&str) -> Result<Box<dyn Any>, StorageError>>,
    debounce_ms: u32,
    last_write: Option<Instant>,
}
```

#### Modified `set()` Method

```rust
impl<T> Signal<T> {
    pub fn set(&self, value: T) {
        RUNTIME.with(|rt| {
            let mut rt = rt.borrow_mut();
            let storage = rt.signals.get_mut(&self.id).unwrap();

            // Check equality
            if storage.value_eq(&value) {
                return;
            }

            // Update value
            storage.set_value(value);

            // NEW: Persist if configured
            if let Some(persistence) = &storage.persistence {
                rt.schedule_persist(self.id, persistence);
            }

            // Notify subscribers
            rt.notify_subscribers(self.id);
        });
    }
}
```

#### Persistence Scheduler

```rust
impl Runtime {
    /// Schedule a persist operation (with optional debouncing)
    fn schedule_persist(&mut self, signal_id: SignalId, config: &PersistenceConfig) {
        if config.debounce_ms == 0 {
            // Immediate persist
            self.persist_now(signal_id, config);
        } else {
            // Debounced persist
            self.pending_persists.insert(signal_id, Instant::now());
            self.schedule_flush_persists(config.debounce_ms);
        }
    }

    fn persist_now(&self, signal_id: SignalId, config: &PersistenceConfig) {
        let storage = self.signals.get(&signal_id).unwrap();
        let serialized = (config.serializer)(&storage.value)?;

        match &config.backend {
            StorageBackend::LocalStorage => {
                localStorage.set(&config.key, &serialized);
            }
            StorageBackend::SessionStorage => {
                sessionStorage.set(&config.key, &serialized);
            }
            StorageBackend::IndexedDB { db, store } => {
                // Async persist via effect
                spawn_persist_to_idb(db, store, &config.key, &serialized);
            }
        }
    }
}
```

### Initialization Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    persisted("key", default)                 │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              1. Check localStorage for "key"                 │
│                                                              │
│  localStorage.getItem("key")                                │
│    ├─ null → use default                                    │
│    └─ value → deserialize JSON                              │
│                 ├─ success → use deserialized               │
│                 └─ error → log warning, use default         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              2. Create Signal with initial value             │
│                                                              │
│  signal_id = runtime.create_signal(initial_value)           │
│  runtime.configure_persistence(signal_id, config)           │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              3. Register storage event listener              │
│                                                              │
│  window.addEventListener("storage", |e| {                   │
│    if e.key == "key" {                                      │
│      signal.set(deserialize(e.newValue))                    │
│    }                                                        │
│  })                                                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              4. Return PersistedSignal<T>                    │
│                                                              │
│  PersistedSignal { inner: signal, key, storage, ... }       │
└─────────────────────────────────────────────────────────────┘
```

### Write Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    signal.set(new_value)                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              1. Update in-memory value                       │
│                                                              │
│  runtime.signals[id].value = new_value                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              2. Notify subscribers (immediate)               │
│                                                              │
│  effects re-run, derived marked dirty                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              3. Schedule persistence                         │
│                                                              │
│  if debounce_ms == 0:                                       │
│    persist_now()                                            │
│  else:                                                      │
│    schedule_persist_after(debounce_ms)                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              4. Persist to storage                           │
│                                                              │
│  serialized = JSON.stringify(value)                         │
│  localStorage.setItem(key, serialized)                      │
│    ├─ success → done                                        │
│    └─ error → call on_error handler                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Parser Changes

No parser changes needed. `persisted()` is a regular function call, not special syntax.

---

## Code Examples

### Basic Usage

```rust
component Counter {
    // Persists to localStorage, survives page refresh
    let count = persisted("counter", 0);

    render {
        <div>
            <p>"Count: " {count.get()}</p>
            <button on:click={|| count.update(|c| c + 1)}>"+"</button>
            <button on:click={|| count.update(|c| c - 1)}>"-"</button>
            <button on:click={|| count.clear()}>"Reset"</button>
        </div>
    }
}
```

### Settings Panel

```rust
#[derive(Serialize, Deserialize, Clone, PartialEq)]
struct UserSettings {
    theme: String,
    font_size: i32,
    notifications_enabled: bool,
}

impl Default for UserSettings {
    fn default() -> Self {
        Self {
            theme: "light".to_string(),
            font_size: 14,
            notifications_enabled: true,
        }
    }
}

component SettingsPanel {
    let settings = persisted("user_settings", UserSettings::default());

    render {
        <div class="settings">
            <label>
                "Theme"
                <select
                    value={settings.get().theme}
                    on:change={|e| settings.update(|s| s.theme = e.value)}
                >
                    <option value="light">"Light"</option>
                    <option value="dark">"Dark"</option>
                    <option value="system">"System"</option>
                </select>
            </label>

            <label>
                "Font Size"
                <input
                    type="range"
                    min="10"
                    max="24"
                    value={settings.get().font_size}
                    on:input={|e| settings.update(|s| s.font_size = e.value.parse().unwrap())}
                />
            </label>

            <label>
                <input
                    type="checkbox"
                    checked={settings.get().notifications_enabled}
                    on:change={|e| settings.update(|s| s.notifications_enabled = e.checked)}
                />
                "Enable Notifications"
            </label>
        </div>
    }
}
```

### IndexedDB for Large Data

```rust
component WorkflowEditor {
    prop db: IdbDatabase;

    // List of all workflows (IndexedDB query)
    let workflows = use_query::<Workflow>(&db, "workflows");

    // Currently selected workflow (persisted to IndexedDB)
    let current_id = persisted("current_workflow_id", None::<String>);

    // Current workflow data (IndexedDB persisted signal)
    let workflow = current_id.get().map(|id| {
        db_persisted(&db, "workflows", &id, Workflow::default())
    });

    render {
        <div class="editor">
            <Sidebar>
                @for wf in workflows.get() {
                    <WorkflowItem
                        workflow={wf}
                        selected={current_id.get() == Some(wf.id)}
                        on:click={|| current_id.set(Some(wf.id.clone()))}
                    />
                }
            </Sidebar>
            <Main>
                @if let Some(wf) = workflow {
                    <WorkflowCanvas workflow={wf} />
                } else {
                    <EmptyState message="Select a workflow" />
                }
            </Main>
        </div>
    }
}
```

### Migration Between Versions

```rust
// Old schema
#[derive(Deserialize)]
struct SettingsV1 {
    dark_mode: bool,  // Old: boolean
}

// New schema
#[derive(Serialize, Deserialize, Clone, PartialEq)]
struct SettingsV2 {
    theme: String,  // New: "light" | "dark" | "system"
}

component App {
    let settings = PersistedSignalOptions::new("settings", SettingsV2::default())
        .migrate(|old_value| {
            // Try parsing as V1
            if let Ok(v1) = serde_json::from_value::<SettingsV1>(old_value.clone()) {
                return SettingsV2 {
                    theme: if v1.dark_mode { "dark" } else { "light" }.to_string(),
                };
            }
            // Try parsing as V2
            if let Ok(v2) = serde_json::from_value::<SettingsV2>(old_value) {
                return v2;
            }
            // Fallback to default
            SettingsV2::default()
        })
        .build();

    render { ... }
}
```

---

## Testing Strategy

### Unit Tests

```rust
#[test]
fn test_persisted_signal_basic() {
    // Setup mock localStorage
    let storage = MockStorage::new();

    let count = persisted_with_storage("count", 0, &storage);
    assert_eq!(count.get(), 0);
    assert_eq!(storage.get("count"), None);

    count.set(5);
    assert_eq!(count.get(), 5);
    assert_eq!(storage.get("count"), Some("5".to_string()));
}

#[test]
fn test_persisted_signal_loads_existing() {
    let storage = MockStorage::new();
    storage.set("count", "42");

    let count = persisted_with_storage("count", 0, &storage);
    assert_eq!(count.get(), 42);  // Loaded from storage, not default
}

#[test]
fn test_persisted_signal_handles_invalid_json() {
    let storage = MockStorage::new();
    storage.set("count", "not valid json");

    let count = persisted_with_storage("count", 0, &storage);
    assert_eq!(count.get(), 0);  // Falls back to default
}
```

### Integration Tests

```rust
#[wasm_bindgen_test]
async fn test_persisted_signal_in_browser() {
    // Clear any existing data
    window().local_storage().unwrap().clear();

    let count = persisted("test_count", 0);
    count.set(10);

    // Verify in actual localStorage
    let stored = window().local_storage().unwrap().get_item("test_count").unwrap();
    assert_eq!(stored, "10");
}
```

---

## Timeline

| Week | Milestone |
|------|-----------|
| 1 | Core PersistedSignal type + localStorage backend |
| 2 | sessionStorage + debouncing |
| 3 | IndexedDB backend (db_persisted) |
| 4 | Cross-tab sync (synced_persisted) |
| 5 | Migration support + error handling |
| 6 | Testing + documentation |

---

## Open Questions

1. **Encryption**: Should we support encrypted storage for sensitive data?
2. **Compression**: Auto-compress large values before storing?
3. **Quotas**: How to handle quota exceeded gracefully?
4. **SSR**: How do persisted signals behave during server rendering?

---

## References

- [Svelte stores with localStorage](https://svelte.dev/repl/7b4d6b448f8c4ed2b3f5f0b8f4f4f4f4)
- [Solid.js createStorage](https://github.com/solidjs-community/solid-primitives/tree/main/packages/storage)
- [Zustand persist middleware](https://github.com/pmndrs/zustand#persist-middleware)
- [Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API)
