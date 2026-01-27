# RFC-004: Parser Improvements for Rust Compatibility

**Status**: Draft
**Author**: RustScript Team
**Created**: 2026-01-27
**Target**: RustScript 0.2.0

---

## Summary

Enhance the RustScript parser to support common Rust patterns currently requiring workarounds: tuple destructuring in closures, underscore patterns, and reserved word handling.

---

## Motivation

The current parser has several limitations documented in `RSX_PARSER_LIMITATIONS.md` that force developers to use verbose workarounds. These limitations create friction for Rust developers and make code harder to read.

### Current Limitations

| Limitation | Severity | Frequency |
|-----------|----------|-----------|
| No tuple destructuring in closures | High | Very Common |
| No underscore `_` in patterns | High | Common |
| Reserved words `style`/`class` as variables | Medium | Common |
| No struct field shorthand | Low | Occasional |

---

## Detailed Design

### 1. Tuple Destructuring in Closures

#### Current Problem

```rust
// FAILS: Tuple destructuring in closure parameter
items.iter().map(|(id, name)| format!("{}: {}", id, name))

// WORKAROUND: Must use tuple access
items.iter().map(|item| {
    let id = item.0;
    let name = item.1;
    format!("{}: {}", id, name)
})
```

#### Proposed Solution

Support full pattern matching in closure parameters:

```rust
// Direct destructuring
items.iter().map(|(id, name)| format!("{}: {}", id, name))

// Nested destructuring
data.iter().map(|((a, b), c)| a + b + c)

// With type annotation
items.iter().map(|(id, name): (i32, String)| { ... })
```

#### Parser Changes

```rust
// In compiler/parser/src/expressions.rs

fn parse_closure_param(&mut self) -> ParseResult<ClosureParam> {
    // BEFORE: Only accepted single ident
    // let name = self.parse_ident()?;

    // AFTER: Accept full pattern
    let pattern = self.parse_pattern()?;

    let ty = if self.check(Token::Colon) {
        self.advance();
        Some(self.parse_type()?)
    } else {
        None
    };

    Ok(ClosureParam { pattern, ty })
}

fn parse_closure_params(&mut self) -> ParseResult<Vec<ClosureParam>> {
    // Handle |param| and |(a, b)| cases
    self.expect(Token::Pipe)?;

    let mut params = vec![];

    if !self.check(Token::Pipe) {
        params.push(self.parse_closure_param()?);

        while self.check(Token::Comma) {
            self.advance();
            if self.check(Token::Pipe) {
                break; // Trailing comma
            }
            params.push(self.parse_closure_param()?);
        }
    }

    self.expect(Token::Pipe)?;
    Ok(params)
}
```

#### AST Changes

```rust
// Update ClosureParam to use Pattern instead of Ident
pub struct ClosureParam {
    pub pattern: Pattern,  // Changed from: name: Spanned<String>
    pub ty: Option<Type>,
    pub span: Span,
}

// Pattern enum already exists and supports:
pub enum Pattern {
    Ident(Spanned<String>),
    Tuple(Vec<Pattern>),
    Struct { name: Path, fields: Vec<FieldPattern> },
    Wildcard,
    // ...
}
```

---

### 2. Underscore Patterns

#### Current Problem

```rust
// FAILS: Underscore in patterns
for (_, value) in map { ... }
let (_, y, _) = point;
match result {
    Ok(data) => data,
    _ => default,  // FAILS
}

// WORKAROUND: Must name unused variables
for (unused_key, value) in map { ... }
let (unused_x, y, unused_z) = point;
match result {
    Ok(data) => data,
    err => default,  // Named but unused
}
```

#### Proposed Solution

```rust
// All standard Rust underscore patterns work
for (_, value) in map { ... }
let (_, y, _) = point;
if let Some(_) = optional { ... }
match result {
    Ok(data) => data,
    _ => default,
}
```

#### Parser Changes

```rust
// In compiler/parser/src/patterns.rs

fn parse_pattern(&mut self) -> ParseResult<Pattern> {
    match self.current_token() {
        // NEW: Handle underscore
        Token::Underscore => {
            let span = self.current_span();
            self.advance();
            Ok(Pattern::Wildcard(span))
        }

        Token::LParen => self.parse_tuple_pattern(),
        Token::Ident(_) => self.parse_ident_or_struct_pattern(),
        // ...
    }
}

fn parse_tuple_pattern(&mut self) -> ParseResult<Pattern> {
    self.expect(Token::LParen)?;

    let mut elements = vec![];
    while !self.check(Token::RParen) {
        // Allow underscore in tuple elements
        elements.push(self.parse_pattern()?);

        if !self.check(Token::RParen) {
            self.expect(Token::Comma)?;
        }
    }

    self.expect(Token::RParen)?;
    Ok(Pattern::Tuple(elements))
}
```

#### Type Checking

```rust
// In compiler/sema/src/patterns.rs

fn check_pattern(&mut self, pattern: &Pattern, expected_ty: &Type) -> SemaResult<()> {
    match pattern {
        Pattern::Wildcard(_) => {
            // Wildcard matches any type, binds nothing
            Ok(())
        }

        Pattern::Tuple(elements) => {
            if let Type::Tuple(field_types) = expected_ty {
                if elements.len() != field_types.len() {
                    return Err(SemaError::TupleSizeMismatch { ... });
                }
                for (elem, ty) in elements.iter().zip(field_types) {
                    self.check_pattern(elem, ty)?;
                }
                Ok(())
            } else {
                Err(SemaError::ExpectedTuple { found: expected_ty.clone() })
            }
        }

        // ...
    }
}
```

---

### 3. Reserved Word Handling

#### Current Problem

```rust
// FAILS: 'style' and 'class' are reserved
let style = compute_style();  // ERROR: unexpected token
let class = get_class_name(); // ERROR: unexpected token

// WORKAROUND: Rename variables
let btn_style = compute_style();
let css_class = get_class_name();
```

**Root Cause**: The lexer produces `PrefixStyle` and `PrefixClass` tokens for `style:` and `class:` attribute prefixes, but this interferes with using these as variable names.

#### Proposed Solution

Context-sensitive lexing: Only treat `style` and `class` as special tokens when followed by `:` in attribute position.

```rust
// All of these should work:
let style = "color: red";
let class = "btn-primary";
fn get_style() -> String { ... }

// These still work as attribute prefixes:
<div style:color="red" class:active={is_active}>
```

#### Lexer Changes

```rust
// In compiler/lexer/src/lib.rs

fn scan_ident(&mut self) -> Token {
    let ident = self.scan_ident_string();

    // Check for contextual keywords
    match ident.as_str() {
        "style" | "class" => {
            // Only special if followed by ':'
            if self.peek() == Some(':') {
                // Look ahead to see if this is an attribute context
                // (inside element, after < or after another attribute)
                if self.in_attribute_context() {
                    return if ident == "style" {
                        Token::PrefixStyle
                    } else {
                        Token::PrefixClass
                    };
                }
            }
            // Otherwise, treat as regular identifier
            Token::Ident(ident)
        }

        // Other keywords...
        "let" => Token::KwLet,
        "if" => Token::KwIf,
        // ...

        _ => Token::Ident(ident),
    }
}

fn in_attribute_context(&self) -> bool {
    // Check parser state or use lookahead
    // True if we're inside <element ...> parsing attributes
    self.context_stack.last() == Some(&LexerContext::ElementAttributes)
}
```

#### Alternative: Parser-Level Resolution

```rust
// In compiler/parser/src/expressions.rs

fn parse_ident(&mut self) -> ParseResult<Spanned<String>> {
    match self.current_token() {
        Token::Ident(name) => {
            let span = self.current_span();
            self.advance();
            Ok(Spanned::new(name, span))
        }

        // NEW: Allow style/class as identifiers outside attribute context
        Token::PrefixStyle if !self.in_attribute_context() => {
            let span = self.current_span();
            self.advance();
            Ok(Spanned::new("style".to_string(), span))
        }

        Token::PrefixClass if !self.in_attribute_context() => {
            let span = self.current_span();
            self.advance();
            Ok(Spanned::new("class".to_string(), span))
        }

        _ => Err(ParseError::ExpectedIdent { found: self.current_token() }),
    }
}
```

---

### 4. Struct Field Shorthand

#### Current Problem

```rust
// FAILS: Field shorthand
let name = "Alice";
let age = 30;
let user = User { name, age };  // ERROR

// WORKAROUND: Explicit field assignment
let user = User { name: name, age: age };
```

#### Proposed Solution

```rust
// Standard Rust shorthand works
let name = "Alice";
let age = 30;
let user = User { name, age };

// Mixed shorthand and explicit
let user = User {
    name,           // Shorthand
    age: age + 1,   // Explicit
};
```

#### Parser Changes

```rust
// In compiler/parser/src/expressions.rs

fn parse_struct_field(&mut self) -> ParseResult<StructField> {
    let name = self.parse_ident()?;

    if self.check(Token::Colon) {
        // Explicit: field: value
        self.advance();
        let value = self.parse_expr()?;
        Ok(StructField::Explicit { name, value })
    } else {
        // Shorthand: field (means field: field)
        Ok(StructField::Shorthand { name: name.clone() })
    }
}
```

#### AST Changes

```rust
pub enum StructField {
    Explicit {
        name: Spanned<String>,
        value: Expr,
    },
    Shorthand {
        name: Spanned<String>,
    },
}
```

#### Lowering

```rust
// In compiler/mir/src/lower.rs

fn lower_struct_field(&mut self, field: &StructField) -> MirResult<(String, Operand)> {
    match field {
        StructField::Explicit { name, value } => {
            let value_op = self.lower_expr(value)?;
            Ok((name.value.clone(), value_op))
        }

        StructField::Shorthand { name } => {
            // Shorthand: look up variable with same name
            let var_op = self.resolve_variable(&name.value)?;
            Ok((name.value.clone(), var_op))
        }
    }
}
```

---

## Implementation Priority

| Feature | Priority | Complexity | Impact |
|---------|----------|------------|--------|
| Tuple destructuring in closures | P0 | Medium | High |
| Underscore patterns | P0 | Low | High |
| Reserved word handling | P1 | Medium | Medium |
| Struct field shorthand | P2 | Low | Low |

---

## Migration Path

All changes are **backward compatible**. Existing workarounds continue to work, but are no longer necessary.

### Before

```rust
// Verbose workarounds
items.iter().map(|item| {
    let id = item.0;
    let name = item.1;
    format!("{}: {}", id, name)
})

for entry in map.iter() {
    let key = entry.0;
    let value = entry.1;
}

let btn_style = get_style();
let user = User { name: name, age: age };
```

### After

```rust
// Idiomatic Rust
items.iter().map(|(id, name)| format!("{}: {}", id, name))

for (key, value) in map.iter() { ... }

let style = get_style();
let user = User { name, age };
```

---

## Testing Strategy

### Parser Tests

```rust
#[test]
fn test_closure_tuple_destructure() {
    let code = "|( a, b )| a + b";
    let ast = parse_closure(code).unwrap();
    assert!(matches!(ast.params[0].pattern, Pattern::Tuple(_)));
}

#[test]
fn test_underscore_in_tuple() {
    let code = "let (_, y) = point;";
    let ast = parse_let(code).unwrap();
    assert!(matches!(ast.pattern, Pattern::Tuple(_)));
}

#[test]
fn test_style_as_variable() {
    let code = "let style = \"color: red\";";
    let ast = parse_let(code).unwrap();
    assert_eq!(ast.name.value, "style");
}

#[test]
fn test_struct_shorthand() {
    let code = "User { name, age }";
    let ast = parse_struct_expr(code).unwrap();
    assert!(matches!(ast.fields[0], StructField::Shorthand { .. }));
}
```

### Type Checking Tests

```rust
#[test]
fn test_closure_destructure_types() {
    let code = r#"
        let pairs: Vec<(i32, String)> = vec![];
        let names = pairs.iter().map(|(_, name)| name);
    "#;
    let result = typecheck(code);
    assert!(result.is_ok());
    // names should be Iterator<Item = &String>
}

#[test]
fn test_wildcard_matches_any() {
    let code = r#"
        let opt: Option<ComplexType> = None;
        if let Some(_) = opt {
            // _ matches ComplexType without binding
        }
    "#;
    let result = typecheck(code);
    assert!(result.is_ok());
}
```

### E2E Tests

```rust
#[wasm_bindgen_test]
async fn test_closure_destructure_in_component() {
    let items = vec![("a", 1), ("b", 2), ("c", 3)];

    render(html! {
        @for (key, value) in items.iter().map(|(k, v)| (*k, *v)) {
            <div>{key}: {value}</div>
        }
    });

    let divs = query_all("div");
    assert_eq!(divs.len(), 3);
}
```

---

## Error Messages

### Improved Error Messages

```
// Before (confusing)
error: expected identifier, found `(`
  --> src/main.rs:5:20
   |
5  | items.map(|(a, b)| a + b)
   |            ^ expected identifier

// After (helpful)
error: tuple destructuring in closure parameters is supported
  --> src/main.rs:5:20
   |
5  | items.map(|(a, b)| a + b)
   |            ^^^^^^ this pattern is valid
   |
   = note: ensure you're using RustScript 0.2.0 or later
```

---

## Timeline

| Week | Milestone |
|------|-----------|
| 1 | Underscore patterns (low complexity) |
| 2 | Closure tuple destructuring |
| 3 | Reserved word handling |
| 4 | Struct field shorthand |
| 5 | Testing + error message improvements |
| 6 | Documentation |

---

## Open Questions

1. **Or-patterns**: Support `Some(1) | Some(2) => ...`?
2. **@ bindings**: Support `x @ Some(y) => ...`?
3. **Slice patterns**: Support `[first, .., last]`?

---

## References

- [Rust patterns documentation](https://doc.rust-lang.org/book/ch18-03-pattern-syntax.html)
- [RustScript RSX_PARSER_LIMITATIONS.md](../RSX_PARSER_LIMITATIONS.md)
- [Rust closure syntax](https://doc.rust-lang.org/rust-by-example/fn/closures.html)
