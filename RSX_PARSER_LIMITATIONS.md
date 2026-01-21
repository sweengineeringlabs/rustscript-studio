# RSX Parser Limitations Backlog

This document tracks all known limitations of the RSX parser discovered during development.

## Critical Limitations

### 1. No Generic Type Parameters on Components
**Status:** Workaround applied
**Severity:** High
**Files Affected:** `minimap.rsx`, `flow_node.rsx`, `flow_edge.rsx`

**Problematic Syntax:**
```rust
#[component]
pub fn FlowNode<T: Clone + 'static>(
    node: Node<T>,
) -> Element
```

**Workaround:**
```rust
// Define concrete type aliases
pub type StudioNode = Node<()>;

#[component]
pub fn FlowNode(
    node: StudioNode,
) -> Element
```

---

### 2. No Tuple Destructuring in Closure Parameters
**Status:** Workaround applied
**Severity:** High
**Files Affected:** `flow_canvas.rsx`, `component_style_editor.rsx`, `token_editor.rsx`, `navigation_designer.rsx`

**Problematic Syntax:**
```rust
Callback::new(move |(node_id, from_top, pos): (String, bool, Position)| {
    // ...
})
```

**Workaround:**
```rust
Callback::new(move |args: (String, bool, Position)| {
    let node_id = args.0;
    let from_top = args.1;
    let pos = args.2;
    // ...
})
```

---

### 3. No Underscore Patterns in Tuple/Struct Destructuring
**Status:** Workaround applied
**Severity:** High
**Files Affected:** `store.rsx`, `token_editor.rsx`, `navigation_designer.rsx`

**Problematic Syntax:**
```rust
for (_, preset) in &context.presets {
    // ...
}

.filter(|(_, node)| node.selected)
```

**Workaround:**
```rust
for preset in context.presets.values() {
    // ...
}

.filter(|entry| entry.1.selected)
```

---

### 4. No Enum Path Patterns in Match Arms
**Status:** Workaround applied
**Severity:** High
**Files Affected:** `flow_node.rsx`, `flow_edge.rsx`, `minimap.rsx`, `navigation_canvas.rsx`

**Problematic Syntax:**
```rust
match entity_type {
    EntityType::Workflow => "workflow",
    EntityType::Context => "context",
    EntityType::Preset => "preset",
}
```

**Workaround:**
```rust
let wf = EntityType::Workflow;
let ctx = EntityType::Context;
if entity_type == wf {
    "workflow"
} else if entity_type == ctx {
    "context"
} else {
    "preset"
}
```

---

### 5. Reserved Variable Names Conflict with HTML Attributes
**Status:** Workaround applied
**Severity:** High
**Files Affected:** `icon.rsx`, `button.rsx`, `select.rsx`, `activity_bar.rsx`, `tabs.rsx`, `store.rsx`

**Reserved Names:** `style`, `class`

**Problematic Syntax:**
```rust
let style = get_button_style(variant);
let class = css_class.unwrap_or_default();
```

**Workaround:**
```rust
let btn_style = get_button_style(variant);
let extra_class = css_class.unwrap_or_default();
```

---

### 6. No Raw Identifier Syntax
**Status:** Workaround applied
**Severity:** Medium
**Files Affected:** `navigation_designer.rsx`, `preset_layout_editor.rsx`

**Problematic Syntax:**
```rust
input(
    r#type: "text",
    // ...
)
```

**Workaround:**
```rust
// Option 1: Use direct attribute name (if parser supports it)
input(
    type: "text",
)

// Option 2: Rename the prop in component definition
input(
    input_type: "text",
)
```

---

### 7. No Loop Labels
**Status:** Workaround applied
**Severity:** Medium
**Files Affected:** `navigation_designer.rsx`

**Problematic Syntax:**
```rust
'outer: for workflow in store.workflows() {
    for context in &workflow.contexts {
        if found {
            break 'outer;
        }
    }
}
```

**Workaround:**
```rust
let mut found = false;
for workflow in store.workflows() {
    if found { break; }
    for context in &workflow.contexts {
        if condition {
            found = true;
            break;
        }
    }
}
```

---

### 8. No Struct Field Shorthand
**Status:** Workaround applied
**Severity:** Medium
**Files Affected:** `flow_canvas.rsx`

**Problematic Syntax:**
```rust
ConnectionState {
    is_connecting: true,
    from_top,  // shorthand
    current_pos: pos,
}
```

**Workaround:**
```rust
ConnectionState {
    is_connecting: true,
    from_top: from_top,  // explicit
    current_pos: pos,
}
```

---

### 9. No Or-Patterns in Match Arms
**Status:** Workaround applied
**Severity:** Medium
**Files Affected:** `flow_canvas.rsx`

**Problematic Syntax:**
```rust
match key.as_str() {
    "+" | "=" => zoom_in(),
    // ...
}
```

**Workaround:**
```rust
match key.as_str() {
    "+" => zoom_in(),
    "=" => zoom_in(),
    // ...
}
```

---

### 10. No Wildcard Match Arms with Underscore
**Status:** Partially addressed
**Severity:** Medium
**Files Affected:** Multiple

**Problematic Syntax:**
```rust
match value {
    Some(x) => x,
    _ => default,
}
```

**Workaround:**
```rust
// Use if-let instead
if let Some(x) = value {
    x
} else {
    default
}

// Or use a named binding
match value {
    Some(x) => x,
    other => default,  // named instead of _
}
```

---

### 11. Tuple Type Annotations in Generics
**Status:** Workaround applied
**Severity:** Low
**Files Affected:** `token_editor.rsx`

**Problematic Syntax:**
```rust
let items: Vec<(String, TokenValue)> = match category {
    // ...
};
```

**Workaround:**
```rust
let items: Vec<_> = match category {
    // ...
};
```

---

### 12. Parameter Name `style` in Function Signatures
**Status:** Workaround applied
**Severity:** Medium
**Files Affected:** `flow_edge.rsx`, `store.rsx`

**Problematic Syntax:**
```rust
pub fn FlowEdge(
    style: Option<EdgeStyle>,
) -> Element
```

**Workaround:**
```rust
pub fn FlowEdge(
    edge_variant: Option<EdgeStyle>,
) -> Element
```

---

## Pending Issues (Not Yet Fixed)

### Files Still Requiring Fixes
Based on the last build attempt, the following files may still have parser issues:
- `navigation_designer.rsx` - Additional patterns
- `component_style_editor.rsx` - Additional patterns
- Other files with similar patterns

---

## Parser Analysis Results

Based on review of `~/rustscript/crates/compiler/parser/src/`:

### Root Cause: Syntax Mismatch

The RSX files use **Dioxus-style syntax**:
```rust
#[component]
pub fn Counter() -> Element {
    rsx! { ... }
}
```

But the RustScript parser expects **native component syntax**:
```rust
component Counter {
    render { ... }
}
```

### Features Already Supported in Native RustScript Parser

| Feature | Parser Location | Notes |
|---------|----------------|-------|
| Wildcard `_` | patterns.rs:172-178 | Works in native syntax |
| Or-patterns `\|` | patterns.rs:52-70 | Works in native syntax |
| Tuple patterns | patterns.rs:439-454 | Works in native syntax |
| Path patterns `::` | patterns.rs:367-369 | Works in native syntax |
| Generic components | components.rs:52 | `component Button<T>` supported |

### True Parser Limitations

| Limitation | Root Cause | Fix Required |
|------------|------------|--------------|
| **Closure destructuring** | `parse_closure_param()` only accepts `ident`, not patterns | Modify to use `parse_pattern()` |
| **`style`/`class` names** | Lexer tokens `PrefixClass`/`PrefixStyle` take precedence | Workaround: rename variables |

### Limitations Due to `rsx!` Macro (Not Parser)

The `rsx!` macro has its own internal parser which may not support all Rust patterns.
Limitations #3, #4, #9, #10 work in native RustScript but fail in `rsx!` macro context.

---

## Recommendations

### Short-term (Continue Workarounds)
1. Apply workarounds consistently across all RSX files
2. Create a linting rule to catch these patterns before build
3. Document patterns to avoid in RSX files

### Medium-term (Parser Enhancement)
1. **Closure pattern support** - Modify `parse_closure_param()` in expressions.rs:921 to use `parse_pattern()` instead of `parse_ident()`
2. **Reduce `class:`/`style:` token priority** - Allow as variable names outside attribute context

### Long-term (Architecture Decision)
1. **Decide on component syntax**: Either fully support Dioxus `#[component]` + `rsx!` OR migrate to native `component { render { } }`
2. Native syntax already supports most "missing" features
3. Consider unifying the `rsx!` macro parser with the main RustScript parser

---

## Testing Checklist

When adding new RSX code, verify:
- [ ] No generic parameters on `#[component]` functions
- [ ] No tuple destructuring `|(a, b)|` in closures
- [ ] No underscore `_` in patterns
- [ ] No `Enum::Variant` in match arms (use if-else)
- [ ] No variables named `style` or `class`
- [ ] No `r#identifier` syntax
- [ ] No loop labels like `'label:`
- [ ] No field shorthand in struct initialization
- [ ] No or-patterns like `"a" | "b" =>`
