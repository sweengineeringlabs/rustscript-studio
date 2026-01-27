# RFC-003: HashMap Iteration in RSX Templates

**Status**: Draft
**Author**: RustScript Team
**Created**: 2026-01-27
**Target**: RustScript 0.2.0

---

## Summary

Enable native iteration over HashMap and BTreeMap in `@for` loops within RSX templates, supporting both key-value pair destructuring and value-only iteration.

---

## Motivation

### Current Problem

```rust
component TokenEditor {
    let tokens_by_category: HashMap<String, Vec<Token>> = get_tokens();

    // WORKAROUND: Must convert to Vec, losing key information
    let categories: Vec<(String, Vec<Token>)> = tokens_by_category
        .iter()
        .map(|(k, v)| (k.clone(), v.clone()))
        .collect();

    render {
        // Can't directly iterate HashMap
        // @for (category, tokens) in tokens_by_category { } // ERROR!

        // Must use converted Vec
        @for item in categories {
            let category = item.0.clone();  // Awkward tuple access
            let tokens = item.1.clone();
            <div class="category">
                <h3>{category}</h3>
                @for token in tokens {
                    <TokenItem token={token} />
                }
            </div>
        }
    }
}
```

**Issues:**
1. Requires manual conversion to Vec
2. Loses natural (key, value) destructuring
3. Extra memory allocation
4. Verbose tuple access syntax
5. Type inference issues

### Proposed Solution

```rust
component TokenEditor {
    let tokens_by_category: HashMap<String, Vec<Token>> = get_tokens();

    render {
        // Direct iteration with destructuring
        @for (category, tokens) in tokens_by_category {
            <div class="category">
                <h3>{category}</h3>
                @for token in tokens {
                    <TokenItem token={token} />
                }
            </div>
        }
    }
}
```

---

## Detailed Design

### 1. Supported Syntax

#### Key-Value Iteration

```rust
// HashMap<K, V> or BTreeMap<K, V>
@for (key, value) in map {
    <div key={key}>{value}</div>
}

// With explicit reference
@for (key, value) in &map {
    <div>{key}: {value}</div>
}
```

#### Value-Only Iteration

```rust
// Iterate values only
@for value in map.values() {
    <Item data={value} />
}

// Iterate keys only
@for key in map.keys() {
    <Label text={key} />
}
```

#### With Index

```rust
// Index + key-value
@for ((key, value), index) in map {
    <div class={if index == 0 { "first" } else { "" }}>
        {key}: {value}
    </div>
}
```

### 2. Type Requirements

```rust
/// Trait bound for types iterable in @for loops
pub trait TemplateIterable {
    type Item;
    type Key: Hash + Eq + Clone;  // For keyed reconciliation

    fn iter(&self) -> impl Iterator<Item = Self::Item>;
    fn key_of(item: &Self::Item) -> Self::Key;
}

// Implementations
impl<K, V> TemplateIterable for HashMap<K, V>
where
    K: Hash + Eq + Clone,
    V: Clone,
{
    type Item = (K, V);
    type Key = K;

    fn iter(&self) -> impl Iterator<Item = (K, V)> {
        self.iter().map(|(k, v)| (k.clone(), v.clone()))
    }

    fn key_of(item: &(K, V)) -> K {
        item.0.clone()
    }
}

impl<K, V> TemplateIterable for BTreeMap<K, V>
where
    K: Ord + Clone,
    V: Clone,
{
    type Item = (K, V);
    type Key = K;

    fn iter(&self) -> impl Iterator<Item = (K, V)> {
        self.iter().map(|(k, v)| (k.clone(), v.clone()))
    }

    fn key_of(item: &(K, V)) -> K {
        item.0.clone()
    }
}
```

### 3. Automatic Key Extraction

When iterating a HashMap with `@for (key, value) in map`, the key is automatically used for DOM reconciliation:

```rust
// This:
@for (id, user) in users_map {
    <UserCard user={user} />
}

// Is equivalent to:
@for (id, user) in users_map {
    <UserCard key={id} user={user} />
}
```

This enables efficient list updates when items are added, removed, or reordered.

---

## Parser Changes

### Grammar Update

Current grammar for `@for`:
```
for_directive := '@for' pattern 'in' expr template_body
pattern := ident | '(' ident ',' ident ')'
```

Extended grammar:
```
for_directive := '@for' for_pattern 'in' expr template_body

for_pattern :=
    | ident                           // Single variable
    | '(' ident ',' ident ')'         // Tuple (key, value)
    | '(' for_pattern ',' ident ')'   // Nested with index

// Examples:
// @for item in list
// @for (key, value) in map
// @for ((key, value), index) in map
```

### AST Changes

```rust
// In compiler/parser/src/ast.rs

pub struct ForDirective {
    pub pattern: ForPattern,
    pub iterable: Expr,
    pub body: Vec<TemplateNode>,
    pub span: Span,
}

pub enum ForPattern {
    /// Single binding: `@for item in ...`
    Single(Spanned<String>),

    /// Tuple binding: `@for (a, b) in ...`
    Tuple {
        first: Spanned<String>,
        second: Spanned<String>,
    },

    /// With index: `@for (pattern, index) in ...`
    WithIndex {
        inner: Box<ForPattern>,
        index: Spanned<String>,
    },
}
```

### Parser Implementation

```rust
// In compiler/parser/src/templates.rs

fn parse_for_pattern(&mut self) -> ParseResult<ForPattern> {
    if self.check(Token::LParen) {
        self.advance(); // consume '('

        // Check if nested pattern or simple tuple
        if self.check(Token::LParen) {
            // Nested: ((key, value), index)
            let inner = self.parse_for_pattern()?;
            self.expect(Token::Comma)?;
            let index = self.parse_ident()?;
            self.expect(Token::RParen)?;
            Ok(ForPattern::WithIndex {
                inner: Box::new(inner),
                index,
            })
        } else {
            // Simple tuple: (key, value)
            let first = self.parse_ident()?;
            self.expect(Token::Comma)?;
            let second = self.parse_ident()?;
            self.expect(Token::RParen)?;

            // Check for trailing index
            if self.check(Token::Comma) {
                self.advance();
                let index = self.parse_ident()?;
                self.expect(Token::RParen)?;
                Ok(ForPattern::WithIndex {
                    inner: Box::new(ForPattern::Tuple { first, second }),
                    index,
                })
            } else {
                Ok(ForPattern::Tuple { first, second })
            }
        }
    } else {
        // Single ident
        let ident = self.parse_ident()?;
        Ok(ForPattern::Single(ident))
    }
}
```

---

## Type Checking (Semantic Analysis)

### Iterable Detection

```rust
// In compiler/sema/src/check.rs

fn check_for_directive(&mut self, for_dir: &ForDirective) -> SemaResult<TypedForDirective> {
    let iterable_ty = self.check_expr(&for_dir.iterable)?;

    // Determine item type based on iterable type
    let (item_ty, key_ty) = match &iterable_ty {
        // Vec<T> -> T
        Type::Vec(inner) => (inner.clone(), Type::Usize),

        // HashMap<K, V> -> (K, V)
        Type::HashMap(key, value) => {
            (Type::Tuple(vec![key.clone(), value.clone()]), key.clone())
        }

        // BTreeMap<K, V> -> (K, V)
        Type::BTreeMap(key, value) => {
            (Type::Tuple(vec![key.clone(), value.clone()]), key.clone())
        }

        // &HashMap<K, V> -> (&K, &V)
        Type::Ref(inner) if matches!(&**inner, Type::HashMap(..)) => {
            if let Type::HashMap(k, v) = &**inner {
                (
                    Type::Tuple(vec![Type::Ref(k.clone()), Type::Ref(v.clone())]),
                    Type::Ref(k.clone()),
                )
            } else {
                unreachable!()
            }
        }

        _ => {
            // Check for IntoIterator trait
            self.check_into_iterator(&iterable_ty)?
        }
    };

    // Bind pattern variables
    self.bind_for_pattern(&for_dir.pattern, &item_ty)?;

    // Check body with bindings in scope
    let typed_body = self.check_template_body(&for_dir.body)?;

    Ok(TypedForDirective {
        pattern: for_dir.pattern.clone(),
        item_ty,
        key_ty,
        iterable: iterable_ty,
        body: typed_body,
    })
}
```

### Pattern Binding

```rust
fn bind_for_pattern(&mut self, pattern: &ForPattern, ty: &Type) -> SemaResult<()> {
    match pattern {
        ForPattern::Single(name) => {
            self.scope.bind(name.value.clone(), ty.clone());
        }

        ForPattern::Tuple { first, second } => {
            // Ensure ty is a tuple
            if let Type::Tuple(fields) = ty {
                if fields.len() != 2 {
                    return Err(SemaError::TupleSizeMismatch {
                        expected: 2,
                        found: fields.len(),
                    });
                }
                self.scope.bind(first.value.clone(), fields[0].clone());
                self.scope.bind(second.value.clone(), fields[1].clone());
            } else {
                return Err(SemaError::ExpectedTuple { found: ty.clone() });
            }
        }

        ForPattern::WithIndex { inner, index } => {
            self.bind_for_pattern(inner, ty)?;
            self.scope.bind(index.value.clone(), Type::Usize);
        }
    }
    Ok(())
}
```

---

## MIR Lowering

### HashMap-Specific Lowering

```rust
// In compiler/mir/src/lower.rs

fn lower_template_for(&mut self, for_dir: &TypedForDirective) -> MirResult<()> {
    let items_local = self.fresh_local();

    // Different iteration strategy based on type
    match &for_dir.iterable {
        Type::HashMap(..) | Type::BTreeMap(..) => {
            self.lower_map_iteration(for_dir, items_local)
        }
        Type::Vec(..) => {
            self.lower_vec_iteration(for_dir, items_local)
        }
        _ => {
            self.lower_generic_iteration(for_dir, items_local)
        }
    }
}

fn lower_map_iteration(
    &mut self,
    for_dir: &TypedForDirective,
    items_local: LocalId,
) -> MirResult<()> {
    // 1. Convert map to iterable entries
    // let entries: Vec<(K, V)> = map.iter().collect();
    self.emit(Stmt::Call {
        result: items_local,
        func: "map_to_entries",
        args: vec![self.lower_expr(&for_dir.iterable)?],
    });

    // 2. Extract key function (uses first element of tuple)
    let key_fn = self.emit_key_extractor(|item| {
        // item.0 (the key)
        Expr::TupleAccess(item, 0)
    });

    // 3. Start keyed list
    let placeholder = self.fresh_placeholder();
    self.emit(Stmt::DomListStart {
        items: items_local,
        key_fn: Some(key_fn),
        placeholder,
    });

    // 4. For each item, bind pattern and render body
    let item_local = self.fresh_local();
    let index_local = for_dir.pattern.index().map(|_| self.fresh_local());

    self.emit(Stmt::DomListItem {
        placeholder,
        item: item_local,
        index: index_local,
    });

    // 5. Destructure tuple into key and value
    match &for_dir.pattern {
        ForPattern::Tuple { first, second } => {
            let key_local = self.bind_local(&first.value);
            let value_local = self.bind_local(&second.value);

            self.emit(Stmt::TupleDestructure {
                tuple: item_local,
                bindings: vec![key_local, value_local],
            });
        }
        _ => { /* handle other patterns */ }
    }

    // 6. Lower body
    for node in &for_dir.body {
        self.lower_template_node(node)?;
    }

    // 7. End list
    self.emit(Stmt::DomListEnd { placeholder });

    Ok(())
}
```

---

## Code Generation

### WASM Output

```wat
;; map_to_entries function
(func $map_to_entries (param $map i32) (result i32)
    ;; Convert HashMap to Vec<(K, V)> for iteration
    ;; Returns pointer to entries array

    ;; Call into JS runtime for HashMap iteration
    (call $__rsc_map_entries (local.get $map))
)

;; Key extractor for tuple
(func $extract_tuple_key (param $item i32) (result i32)
    ;; Return first element of tuple (the key)
    (call $__rsc_tuple_get (local.get $item) (i32.const 0))
)
```

### JS Runtime Support

```javascript
// In rustscript-runtime.js

function __rsc_map_entries(mapId) {
    const map = getHeapObject(mapId);

    // Handle different map types
    if (map instanceof Map) {
        return Array.from(map.entries());
    } else if (typeof map === 'object') {
        return Object.entries(map);
    }

    throw new Error('Expected Map or object for iteration');
}

function __rsc_map_keys(mapId) {
    const map = getHeapObject(mapId);

    if (map instanceof Map) {
        return Array.from(map.keys());
    } else if (typeof map === 'object') {
        return Object.keys(map);
    }

    throw new Error('Expected Map or object');
}

function __rsc_map_values(mapId) {
    const map = getHeapObject(mapId);

    if (map instanceof Map) {
        return Array.from(map.values());
    } else if (typeof map === 'object') {
        return Object.values(map);
    }

    throw new Error('Expected Map or object');
}
```

---

## Examples

### Basic HashMap Iteration

```rust
component UserDirectory {
    let users_by_department: HashMap<String, Vec<User>> = fetch_users();

    render {
        <div class="directory">
            @for (department, users) in users_by_department {
                <section class="department">
                    <h2>{department}</h2>
                    <ul>
                        @for user in users {
                            <li>{user.name}</li>
                        }
                    </ul>
                </section>
            }
        </div>
    }
}
```

### Config/Settings Map

```rust
component SettingsEditor {
    let settings: HashMap<String, String> = load_settings();

    render {
        <form>
            @for (key, value) in settings {
                <div class="setting-row">
                    <label>{key}</label>
                    <input
                        value={value}
                        on:input={|e| update_setting(key.clone(), e.value)}
                    />
                </div>
            }
        </form>
    }
}
```

### BTreeMap for Sorted Output

```rust
component SortedList {
    // BTreeMap maintains key order
    let items: BTreeMap<i32, String> = get_items();

    render {
        <ol>
            @for (priority, item) in items {
                // Items rendered in priority order (1, 2, 3, ...)
                <li data-priority={priority}>{item}</li>
            }
        </ol>
    }
}
```

### With Index

```rust
component NumberedMap {
    let data: HashMap<String, i32> = get_data();

    render {
        <table>
            @for ((key, value), index) in data {
                <tr class={if index % 2 == 0 { "even" } else { "odd" }}>
                    <td>{index + 1}</td>
                    <td>{key}</td>
                    <td>{value}</td>
                </tr>
            }
        </table>
    }
}
```

### Nested Maps

```rust
component NestedData {
    let data: HashMap<String, HashMap<String, i32>> = get_nested();

    render {
        @for (outer_key, inner_map) in data {
            <div class="outer">
                <h3>{outer_key}</h3>
                @for (inner_key, value) in inner_map {
                    <span>{inner_key}: {value}</span>
                }
            </div>
        }
    }
}
```

---

## Migration Guide

### Before (Workaround)

```rust
// Convert HashMap to Vec
let entries: Vec<_> = map.iter()
    .map(|(k, v)| (k.clone(), v.clone()))
    .collect();

// Iterate Vec with tuple access
@for entry in entries {
    let key = entry.0;
    let value = entry.1;
    // ...
}
```

### After (Native)

```rust
// Direct iteration with destructuring
@for (key, value) in map {
    // ...
}
```

---

## Performance Considerations

1. **Memory**: HashMap iteration creates temporary entries Vec
   - Mitigation: Use lazy iterator in future optimization

2. **Key Hashing**: Keys are hashed for reconciliation
   - Benefit: O(1) lookup for updates
   - Cost: Initial hash computation

3. **Ordering**: HashMap iteration order is non-deterministic
   - Use BTreeMap for deterministic order
   - Document this behavior clearly

---

## Testing Strategy

### Parser Tests

```rust
#[test]
fn test_parse_map_iteration() {
    let input = "@for (key, value) in map { <div>{key}</div> }";
    let ast = parse(input).unwrap();

    assert!(matches!(
        ast.pattern,
        ForPattern::Tuple { .. }
    ));
}

#[test]
fn test_parse_map_with_index() {
    let input = "@for ((key, value), i) in map { <div>{i}</div> }";
    let ast = parse(input).unwrap();

    assert!(matches!(
        ast.pattern,
        ForPattern::WithIndex { .. }
    ));
}
```

### Type Checking Tests

```rust
#[test]
fn test_typecheck_hashmap_iteration() {
    let code = r#"
        component Test {
            let map: HashMap<String, i32> = HashMap::new();
            render {
                @for (key, value) in map {
                    <div>{key}: {value}</div>
                }
            }
        }
    "#;

    let result = typecheck(code);
    assert!(result.is_ok());

    // key should be String, value should be i32
    let scope = result.unwrap().body_scope;
    assert_eq!(scope.get("key"), Some(&Type::String));
    assert_eq!(scope.get("value"), Some(&Type::I32));
}
```

### E2E Tests

```rust
#[wasm_bindgen_test]
async fn test_hashmap_renders_all_entries() {
    let mut map = HashMap::new();
    map.insert("a", 1);
    map.insert("b", 2);
    map.insert("c", 3);

    render(html! {
        @for (key, value) in map {
            <div class="entry">{key}: {value}</div>
        }
    });

    let entries = query_all(".entry");
    assert_eq!(entries.len(), 3);
}
```

---

## Timeline

| Week | Milestone |
|------|-----------|
| 1 | Parser: ForPattern enum + tuple destructuring |
| 2 | Type checking: HashMap/BTreeMap detection |
| 3 | MIR lowering: map iteration strategy |
| 4 | Codegen: WASM + JS runtime support |
| 5 | Testing + edge cases |
| 6 | Documentation + examples |

---

## Open Questions

1. **Object iteration**: Should plain JS objects be iterable too?
2. **Entry modification**: Allow `@for (key, mut value) in map`?
3. **Parallel iteration**: `@for (a, b) in zip(map1, map2)`?

---

## References

- [Rust HashMap iteration](https://doc.rust-lang.org/std/collections/struct.HashMap.html#method.iter)
- [Svelte each blocks](https://svelte.dev/docs#template-syntax-each)
- [Vue v-for with objects](https://vuejs.org/guide/essentials/list.html#v-for-with-an-object)
