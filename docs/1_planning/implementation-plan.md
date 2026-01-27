# RustScript Studio - Production-Ready Implementation Plan

## Overview

Complete the RustScript Studio application with full functionality:
- Navigation Designer (flow-based workflow editor)
- CSS Designer (design token editor with live preview)
- Settings page
- IndexedDB persistence
- All 140 e2e tests passing

## Current State

- **main.rsx**: Minimal skeleton with basic navigation, sidebar toggle, and modal structure
- **Tests passing**: 101/140 (37 failing due to missing UI elements)
- **Reactive system**: Working (conditionals, class toggles, signals)

## Architecture

### Data Model (IndexedDB)

```
stores:
  - workflows: { id, name, nodes: [], edges: [], metadata: {} }
  - tokens: { id, category, name, value, type }
  - settings: { key, value }
```

### Signal Architecture

```
// Core navigation
active_designer: Signal<String>      // "navigation" | "css" | "settings"
sidebar_visible: Signal<bool>

// Navigation Designer
workflows: Signal<Vec<Workflow>>     // From IndexedDB
selected_workflow: Signal<Option<String>>
selected_node: Signal<Option<String>>
canvas_zoom: Signal<i32>
show_add_workflow_modal: Signal<bool>

// CSS Designer
tokens: Signal<Vec<Token>>           // From IndexedDB
selected_category: Signal<String>    // "colors" | "spacing" | "radius" | "shadows"
preview_mode: Signal<String>         // "light" | "dark" | "both" | "system"
show_export_modal: Signal<bool>
export_format: Signal<String>        // "css" | "json" | "sass"

// Settings
settings: Signal<Settings>           // From IndexedDB
```

## Implementation Phases

### Phase 1: Data Layer & IndexedDB Integration

**Files to create/modify:**
- `src/db.rsx` - IndexedDB wrapper module
- `src/models.rsx` - Data structures (Workflow, Token, Settings)

**Tasks:**
1. Create IndexedDB wrapper with async operations
2. Define data models for workflows, tokens, settings
3. Implement CRUD operations for each store
4. Add initialization and migration logic

### Phase 2: Complete Navigation Designer

**Add to main.rsx:**

1. **Workflow List (dynamic)**
   - `@for workflow in workflows.get()` loop
   - Add/delete workflow functionality
   - Workflow selection with class:selected
   - Workflow metadata display

2. **Add Workflow Modal (functional)**
   - Input binding with on:input
   - Form validation
   - Submit handler that saves to IndexedDB
   - Close on success

3. **Flow Canvas**
   - Render nodes from selected workflow
   - Node selection with on:click|stop
   - Add node functionality
   - Delete node (keyboard: Delete key)
   - Visual zoom (CSS transform based on canvas_zoom)

4. **Bottom Properties Panel**
   - `@if let Some(node) = selected_node.get()` conditional
   - Display node properties
   - Edit node properties

5. **Keyboard Shortcuts**
   - Delete: Remove selected node
   - Escape: Deselect
   - Ctrl+Z/Y: Undo/Redo (stretch goal)

**Data-testid elements to add:**
- `workflow-item` (dynamic)
- `flow-node` (dynamic)
- `bottom-panel`

### Phase 3: Complete CSS Designer

**Add to main.rsx:**

1. **Category Tabs (complete)**
   - Add `category-radius` button
   - Add `category-shadows` button
   - All with class:active binding

2. **Token Panel**
   - `@for token in tokens_for_category()` loop
   - Token items with name, value input
   - Color picker for color tokens (type="color")
   - On:input handlers for live updates

3. **Preview Pane**
   - Preview mode buttons (light/dark/both/system)
   - Live style injection via `<style>` element
   - Sample components (buttons, cards, inputs)
   - Dark mode class toggle

4. **Export Modal**
   - Format selector (CSS, JSON, Sass)
   - Export preview panel
   - Derived signal for CSS output
   - Close on overlay click (on:click|self)

5. **Action Buttons**
   - Export button (data-testid="export-btn")
   - Import button
   - CSS Output toggle

**Data-testid elements to add:**
- `category-radius`
- `category-shadows`
- `token-list`
- `export-btn`
- `export-modal`
- `preview-pane`
- `css-output-panel`

### Phase 4: Complete Settings Page

**Add to main.rsx:**

1. **Settings Form**
   - Auto-save checkbox
   - Theme selector (select dropdown)
   - Other configuration options

2. **Persistence**
   - Load settings from IndexedDB on mount
   - Save settings on change

### Phase 5: Polish & Testing

1. **Event Modifiers**
   - Verify on:click|stop works on flow nodes
   - Verify on:click|self works on modal overlays

2. **Accessibility**
   - Keyboard navigation (Tab through activity items)
   - Focus management in modals

3. **Error Handling**
   - Validation feedback
   - Error states

4. **Run All Tests**
   - Target: 140/140 passing

## File Structure

```
src/
├── main.rsx          # Main app component (enhanced)
├── db.rsx            # IndexedDB wrapper
├── models.rsx        # Data structures
└── styles.css        # Styling (existing)
```

## Detailed main.rsx Changes

### Signals to Add
```rust
// In App component, add these signals:
let workflows = signal(vec![]);           // Load from IndexedDB
let tokens = signal(vec![]);              // Load from IndexedDB
let selected_node = signal("");
let preview_mode = signal("light");
let show_export_modal = signal(false);
let export_format = signal("css");
let workflow_name_input = signal("");
```

### UI Sections to Complete

#### 1. CSS Sidebar - Add Missing Categories
```rsx
// Add after category-spacing button:
<button
    class:active={selected_category.get() == "radius"}
    data-testid="category-radius"
    on:click={selected_category.set("radius")}
>
    "Radius"
</button>
<button
    class:active={selected_category.get() == "shadows"}
    data-testid="category-shadows"
    on:click={selected_category.set("shadows")}
>
    "Shadows"
</button>
```

#### 2. Token List with Loop
```rsx
<div data-testid="token-list" class="token-list">
    @for token in get_tokens_for_category(selected_category.get()) {
        <div class="token-item">
            <span class="token-name">{token.name}</span>
            @if token.category == "colors" {
                <input type="color" value={token.value}
                       on:input={|e| update_token(token.id, e.value)} />
            } else {
                <input type="text" value={token.value}
                       class="token-value-input"
                       on:input={|e| update_token(token.id, e.value)} />
            }
        </div>
    }
</div>
```

#### 3. Export Button & Modal
```rsx
<button data-testid="export-btn" on:click={show_export_modal.set(true)}>
    "Export"
</button>

@if show_export_modal.get() {
    <div class="modal-overlay" data-testid="export-modal"
         on:click|self={show_export_modal.set(false)}>
        <div class="modal-content" on:click|stop={}>
            <h2>"Export Tokens"</h2>
            <div class="export-format-selector">
                <button class:active={export_format.get() == "css"}
                        on:click={export_format.set("css")}>"CSS"</button>
                <button class:active={export_format.get() == "json"}
                        on:click={export_format.set("json")}>"JSON"</button>
            </div>
            <div class="export-preview">
                <pre><code>{generate_export(export_format.get())}</code></pre>
            </div>
        </div>
    </div>
}
```

#### 4. Preview Pane
```rsx
<div data-testid="preview-pane" class="preview-pane">
    <div class="preview-header">
        <button class:active={preview_mode.get() == "light"}
                on:click={preview_mode.set("light")}>"Light"</button>
        <button class:active={preview_mode.get() == "dark"}
                on:click={preview_mode.set("dark")}>"Dark"</button>
        <button class:active={preview_mode.get() == "both"}
                on:click={preview_mode.set("both")}>"Both"</button>
    </div>
    <div class="preview-content" class:dark-mode={preview_mode.get() == "dark"}>
        <style>{generate_css_variables()}</style>
        <button class="preview-button">"Sample Button"</button>
        <div class="preview-card">"Sample Card"</div>
        <input class="preview-input" placeholder="Sample Input" />
    </div>
</div>
```

#### 5. Bottom Panel with @if let
```rsx
<div data-testid="bottom-panel" class="bottom-panel">
    @if selected_node.get() != "" {
        <div class="node-properties">
            <h3>"Node Properties"</h3>
            <p>"ID: " {selected_node.get()}</p>
        </div>
    } else {
        <p>"Select a node to view properties"</p>
    }
</div>
```

#### 6. Flow Canvas with Dynamic Nodes
```rsx
<div data-testid="flow-canvas" class="flow-canvas"
     style={"transform: scale(" + (canvas_zoom.get() / 100) + ")"}>
    @for node in get_workflow_nodes(selected_workflow.get()) {
        <div class="flow-node"
             class:selected={selected_node.get() == node.id}
             class:flow-node-workflow={node.type == "workflow"}
             data-testid="flow-node"
             on:click|stop={selected_node.set(node.id)}>
            {node.name}
        </div>
    }
</div>
```

## Verification

### Build & Run
```bash
cd /home/adentic/rustscript && cargo build -p rsc --release
cd /home/adentic/rustscript-studio
/home/adentic/rustscript/target/release/rsc dev --port 8099
```

### Run Tests
```bash
RSC_TEST_BASE_URL="http://localhost:8099" cargo test --test e2e -- --ignored
```

### Target Metrics
- All 140 e2e tests passing
- No JavaScript console errors
- Responsive design works at tablet/mobile viewports
- Data persists across browser refresh (IndexedDB)

## Estimated Effort

| Phase | Complexity | Key Deliverables |
|-------|-----------|------------------|
| Phase 1 | Medium | IndexedDB wrapper, data models |
| Phase 2 | High | Dynamic workflows, canvas, nodes |
| Phase 3 | High | Tokens, preview, export |
| Phase 4 | Low | Settings form |
| Phase 5 | Medium | Testing, polish |

## Notes

- RustScript doesn't have native IndexedDB bindings yet - may need JS interop
- Consider using localStorage as fallback if IndexedDB is complex
- Focus on test coverage first, polish later

## RSX Parser Limitations to Avoid

Based on RSX_PARSER_LIMITATIONS.md:
- No generic type parameters on components
- No tuple destructuring in closure parameters
- No underscore patterns in tuple/struct destructuring
- No enum path patterns in match arms (use if-else)
- Avoid variable names `style` or `class`
- No raw identifier syntax (r#type)
- No loop labels
- No struct field shorthand
- No or-patterns in match arms
- No HashMap, complex iterators with closures
