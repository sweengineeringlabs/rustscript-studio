# RFC-001: Async Lifecycle Hooks

**Status**: Draft
**Author**: RustScript Team
**Created**: 2026-01-27
**Target**: RustScript 0.2.0

---

## Summary

Add async/await support for component lifecycle hooks, enabling natural data fetching and async operations without callback chains.

---

## Motivation

### Current Problem

```rust
component UserProfile {
    let user = signal(None);
    let loading = signal(true);
    let error = signal(None);

    // Awkward: Manual Promise chaining with multiple signals
    effect {
        loading.set(true);
        let promise = fetch_user(user_id);
        promise
            .then(|data| {
                user.set(Some(data));
                loading.set(false);
            })
            .catch(|err| {
                error.set(Some(err));
                loading.set(false);
            });
    }

    render {
        if loading.get() {
            <Spinner />
        } else if let Some(err) = error.get() {
            <Error message={err} />
        } else if let Some(u) = user.get() {
            <Profile user={u} />
        }
    }
}
```

**Issues:**
1. 3 signals for one async operation
2. Callback nesting
3. Error handling scattered
4. No automatic cleanup on unmount
5. Race conditions if user_id changes

### Proposed Solution

```rust
component UserProfile {
    // One-liner: handles loading, error, data, and cleanup
    let user = async_resource(|| fetch_user(user_id));

    render {
        @match user.state() {
            Pending => <Spinner />
            Error(e) => <Error message={e} />
            Ready(u) => <Profile user={u} />
        }
    }
}
```

---

## Detailed Design

### 1. New Types

#### `AsyncResource<T>`

```rust
/// Represents an async computation that produces a value of type T.
/// Automatically tracks dependencies and re-fetches when they change.
pub struct AsyncResource<T> {
    /// Current state of the resource
    state: Signal<ResourceState<T>>,
    /// The async function to call
    fetcher: Box<dyn Fn() -> JsPromise<T>>,
    /// Cancel token for in-flight requests
    cancel_token: Rc<Cell<bool>>,
    /// Subscriber ID for cleanup
    subscriber_id: SubscriberId,
}

/// The three states of an async resource
pub enum ResourceState<T> {
    /// Initial fetch in progress
    Pending,
    /// Fetch completed successfully
    Ready(T),
    /// Fetch failed with error
    Error(JsValue),
}

impl<T> AsyncResource<T> {
    /// Get current state
    pub fn state(&self) -> ResourceState<T>;

    /// Get value if ready, panics otherwise
    pub fn get(&self) -> &T;

    /// Get value if ready, returns None otherwise
    pub fn try_get(&self) -> Option<&T>;

    /// Is the resource currently loading?
    pub fn is_loading(&self) -> bool;

    /// Force refetch
    pub fn refetch(&self);

    /// Mutate the cached value without refetching
    pub fn mutate(&self, f: impl FnOnce(&mut T));
}
```

#### `AsyncEffect`

```rust
/// An effect that can contain async operations.
/// Automatically cancels in-flight operations when re-triggered or disposed.
pub struct AsyncEffect {
    /// Handle to dispose the effect
    handle: EffectHandle,
    /// Cancel token for current execution
    cancel_token: Rc<Cell<bool>>,
}

impl AsyncEffect {
    /// Create a new async effect
    pub fn new<F>(f: F) -> Self
    where
        F: Fn() -> Pin<Box<dyn Future<Output = ()>>> + 'static;

    /// Cancel and dispose
    pub fn dispose(&self);
}
```

### 2. Component Lifecycle Hooks

#### `on_mount` - Async Initialization

```rust
component App {
    let db = signal(None);

    // Runs once when component mounts
    async on_mount {
        let database = IndexedDB::open("app", 1).await?;
        db.set(Some(database));
    }

    render { ... }
}
```

**Implementation:**
- Parsed as special block in component body
- Lowered to `AsyncEffect::new()` that runs once
- Tracks no dependencies (runs only on mount)
- Automatically cancelled if component unmounts

#### `on_update` - Reactive Async

```rust
component SearchResults {
    prop query: String;
    let results = signal(vec![]);

    // Re-runs when `query` changes
    async on_update {
        let data = search_api(query).await;
        results.set(data);
    }

    render { ... }
}
```

**Implementation:**
- Similar to `effect` but supports await
- Tracks dependencies during synchronous portion
- Cancels previous execution if dependencies change before completion

#### `on_cleanup` - Cleanup Handler

```rust
component WebSocketChat {
    let socket = signal(None);

    async on_mount {
        let ws = WebSocket::connect("wss://...").await;
        socket.set(Some(ws));
    }

    on_cleanup {
        if let Some(ws) = socket.get() {
            ws.close();
        }
    }

    render { ... }
}
```

### 3. Syntax Sugar: `async_resource`

```rust
/// Create an async resource that tracks dependencies
pub fn async_resource<T, F>(fetcher: F) -> AsyncResource<T>
where
    F: Fn() -> Pin<Box<dyn Future<Output = T>>> + 'static,
    T: Clone + 'static;
```

**Usage:**
```rust
component UserList {
    prop filter: String;

    // Automatically refetches when `filter` changes
    let users = async_resource(async || {
        fetch_users(filter).await
    });

    render {
        @match users.state() {
            Pending => <Loading />
            Ready(list) => {
                @for user in list {
                    <UserCard user={user} />
                }
            }
            Error(e) => <ErrorBanner error={e} />
        }
    }
}
```

### 4. Runtime Changes

#### Modified `Runtime` struct

```rust
pub struct Runtime {
    // ... existing fields ...

    /// Pending async effects awaiting completion
    async_effects: HashMap<SubscriberId, AsyncEffectState>,

    /// Resources with their fetcher functions
    resources: HashMap<ResourceId, ResourceState>,
}

struct AsyncEffectState {
    /// The future being polled
    future: Option<Pin<Box<dyn Future<Output = ()>>>>,
    /// Waker for async notification
    waker: Option<Waker>,
    /// Cancel flag
    cancelled: Rc<Cell<bool>>,
}
```

#### New Runtime Methods

```rust
impl Runtime {
    /// Register an async effect
    pub fn register_async_effect(&mut self, id: SubscriberId, future: Pin<Box<dyn Future<Output = ()>>>);

    /// Poll all pending async effects
    pub fn poll_async_effects(&mut self);

    /// Cancel an async effect
    pub fn cancel_async_effect(&mut self, id: SubscriberId);

    /// Create a resource
    pub fn create_resource<T>(&mut self, fetcher: impl Fn() -> JsPromise<T>) -> ResourceId;
}
```

### 5. Integration with JS Promise

```rust
impl<T> Future for JsPromise<T> {
    type Output = Result<T, JsValue>;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let state = self.state.lock().unwrap();
        match &*state {
            PromiseState::Pending => {
                // Store waker for later notification
                self.waker.replace(Some(cx.waker().clone()));
                Poll::Pending
            }
            PromiseState::Resolved(value) => Poll::Ready(Ok(value.clone())),
            PromiseState::Rejected(error) => Poll::Ready(Err(error.clone())),
        }
    }
}
```

### 6. Cancellation Pattern

```rust
/// Token passed to async operations for cancellation check
pub struct CancelToken {
    cancelled: Rc<Cell<bool>>,
}

impl CancelToken {
    pub fn is_cancelled(&self) -> bool {
        self.cancelled.get()
    }
}

// Usage in async effect
async on_update {
    let token = cancel_token();

    let page1 = fetch_page(1).await;
    if token.is_cancelled() { return; }

    let page2 = fetch_page(2).await;
    if token.is_cancelled() { return; }

    results.set(vec![page1, page2]);
}
```

---

## Parser Changes

### Grammar Additions

```
component_item :=
    | signal_decl
    | derived_decl
    | effect_decl
    | async_on_mount      // NEW
    | async_on_update     // NEW
    | on_cleanup          // NEW
    | let_binding
    | style_block

async_on_mount := 'async' 'on_mount' block
async_on_update := 'async' 'on_update' block
on_cleanup := 'on_cleanup' block
```

### AST Nodes

```rust
pub enum ComponentItem {
    // ... existing variants ...
    AsyncOnMount(AsyncOnMount),
    AsyncOnUpdate(AsyncOnUpdate),
    OnCleanup(OnCleanup),
}

pub struct AsyncOnMount {
    pub body: Block,
    pub span: Span,
}

pub struct AsyncOnUpdate {
    pub body: Block,
    pub span: Span,
}

pub struct OnCleanup {
    pub body: Block,
    pub span: Span,
}
```

---

## Lowering (MIR Generation)

### `async on_mount` Lowering

```rust
fn lower_async_on_mount(&mut self, mount: &AsyncOnMount) -> MirResult<()> {
    // Generate:
    // 1. Effect that runs once (empty dependency tracking)
    // 2. Async executor that polls the future
    // 3. Cleanup registration for unmount

    let effect_id = self.fresh_subscriber_id();

    // Lower the async block to a future
    let future_expr = self.lower_async_block(&mount.body)?;

    // Emit: register_async_effect(effect_id, future_expr)
    self.emit(Stmt::CallRuntime {
        func: "register_async_effect",
        args: vec![effect_id.into(), future_expr],
    });

    // Register cleanup
    self.emit(Stmt::RegisterCleanup {
        effect_id,
        cleanup: CleanupAction::CancelAsync,
    });

    Ok(())
}
```

### `async_resource` Lowering

```rust
fn lower_async_resource(&mut self, resource: &AsyncResourceExpr) -> MirResult<Operand> {
    // Generate:
    // 1. Signal for state (Pending | Ready(T) | Error(E))
    // 2. Effect that tracks dependencies and triggers fetch
    // 3. Cancellation handling

    let state_signal = self.fresh_signal_id();
    let effect_id = self.fresh_subscriber_id();

    // Initialize state to Pending
    self.emit(Stmt::SignalInit {
        id: state_signal,
        value: Operand::Enum("ResourceState", "Pending", vec![]),
    });

    // Create effect that runs fetcher
    self.emit(Stmt::AsyncEffectInit {
        id: effect_id,
        fetcher: self.lower_closure(&resource.fetcher)?,
        on_success: |value| state_signal.set(Ready(value)),
        on_error: |err| state_signal.set(Error(err)),
    });

    Ok(Operand::Resource { state_signal, effect_id })
}
```

---

## Code Generation (WASM)

### New Runtime Imports

```wat
(import "rsc" "register_async_effect" (func $register_async_effect (param i32 i32)))
(import "rsc" "poll_async_effects" (func $poll_async_effects))
(import "rsc" "cancel_async_effect" (func $cancel_async_effect (param i32)))
(import "rsc" "create_resource" (func $create_resource (param i32) (result i32)))
```

### JS Runtime Support

```javascript
// In rustscript-runtime.js
class AsyncEffectRunner {
    constructor() {
        this.effects = new Map();
    }

    register(id, promiseFactory) {
        // Cancel existing if any
        this.cancel(id);

        const controller = new AbortController();
        this.effects.set(id, { controller, running: true });

        promiseFactory(controller.signal)
            .then(result => {
                if (!controller.signal.aborted) {
                    this.notifyComplete(id, result);
                }
            })
            .catch(error => {
                if (!controller.signal.aborted) {
                    this.notifyError(id, error);
                }
            });
    }

    cancel(id) {
        const effect = this.effects.get(id);
        if (effect) {
            effect.controller.abort();
            this.effects.delete(id);
        }
    }
}
```

---

## Examples

### Basic Data Fetching

```rust
component UserProfile {
    prop user_id: i32;

    let user = async_resource(async || {
        let response = fetch(&format!("/api/users/{}", user_id)).await?;
        response.json::<User>().await
    });

    render {
        @match user.state() {
            Pending => <div class="skeleton" />
            Error(e) => <Alert variant="error">{e.message()}</Alert>
            Ready(u) => {
                <div class="profile">
                    <Avatar src={u.avatar} />
                    <h1>{u.name}</h1>
                    <p>{u.bio}</p>
                </div>
            }
        }
    }
}
```

### Sequential Async Operations

```rust
component Dashboard {
    let data = signal(None);

    async on_mount {
        // Sequential: user first, then their posts
        let user = fetch_current_user().await?;
        let posts = fetch_posts(user.id).await?;
        let comments = fetch_comments(posts.iter().map(|p| p.id)).await?;

        data.set(Some(DashboardData { user, posts, comments }));
    }

    render { ... }
}
```

### Parallel Async Operations

```rust
component Dashboard {
    let data = signal(None);

    async on_mount {
        // Parallel: fetch all at once
        let (user, notifications, stats) = join!(
            fetch_user(),
            fetch_notifications(),
            fetch_stats(),
        ).await;

        data.set(Some(DashboardData { user?, notifications?, stats? }));
    }

    render { ... }
}
```

### Debounced Search

```rust
component SearchBox {
    let query = signal("");
    let results = signal(vec![]);

    async on_update {
        let q = query.get();
        if q.len() < 3 { return; }

        // Debounce: wait 300ms before fetching
        sleep(Duration::from_millis(300)).await;

        // Check if query changed during debounce
        if query.get() != q { return; }

        let data = search_api(q).await?;
        results.set(data);
    }

    render {
        <input
            value={query.get()}
            on:input={|e| query.set(e.target.value)}
            placeholder="Search..."
        />
        <SearchResults results={results.get()} />
    }
}
```

---

## Migration Path

### Phase 1: AsyncResource (Non-Breaking)
- Add `async_resource()` function
- Add `ResourceState<T>` enum
- Works alongside existing patterns

### Phase 2: Lifecycle Hooks (Non-Breaking)
- Add `async on_mount` syntax
- Add `on_cleanup` syntax
- Existing `effect` continues to work

### Phase 3: Enhanced Effect (Non-Breaking)
- Add `async effect` syntax
- Original `effect` unchanged for sync use cases

---

## Alternatives Considered

### 1. Suspense Pattern (React-style)
```rust
// Rejected: Too implicit, harder to reason about
<Suspense fallback={<Loading />}>
    <UserProfile />  // Magically suspends
</Suspense>
```
**Reason**: Explicit state handling is more Rust-like.

### 2. Use Hooks (React-style)
```rust
// Rejected: Requires call-site ordering rules
let (data, loading, error) = use_async(|| fetch_data());
```
**Reason**: RustScript components are struct-based, not function-based.

### 3. Builder Pattern
```rust
// Considered but deferred
let user = Resource::new()
    .fetcher(|| fetch_user(id))
    .on_error(|e| log_error(e))
    .build();
```
**Reason**: More verbose, can add later if needed.

---

## Testing Strategy

1. **Unit Tests**: Runtime async effect management
2. **Integration Tests**: Parser → Lowering → Codegen pipeline
3. **E2E Tests**: Actual browser async behavior
4. **Stress Tests**: Many concurrent async effects

---

## Timeline

| Week | Milestone |
|------|-----------|
| 1 | Runtime: AsyncEffect type + cancellation |
| 2 | Runtime: AsyncResource implementation |
| 3 | Parser: async on_mount/on_update syntax |
| 4 | Lowering: MIR generation for async |
| 5 | Codegen: WASM + JS runtime support |
| 6 | Testing + documentation |

---

## Open Questions

1. **Error boundaries**: Should async errors propagate to parent components?
2. **SSR**: How do async resources behave during server rendering?
3. **Streaming**: Support for async iterators / streaming responses?

---

## References

- [Solid.js createResource](https://www.solidjs.com/docs/latest/api#createresource)
- [Svelte await blocks](https://svelte.dev/docs#template-syntax-await)
- [React Suspense](https://react.dev/reference/react/Suspense)
- [Rust async book](https://rust-lang.github.io/async-book/)
