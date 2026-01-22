# RustScript Studio - Project Backlog

**Created:** 2026-01-21
**Last Updated:** 2026-01-21

Visual IDE for RustScript - Design navigation flows and CSS visually.

## Legend

| Status | Meaning |
|--------|---------|
| [x] | Completed |
| [ ] | Pending |
| [~] | In Progress |

---

## Phase 1: Project Foundation

### 1.1 Project Setup

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Create project structure and workspace | 2026-01-21 | 2026-01-21 |
| [x] | Configure Cargo.toml with workspace dependencies | 2026-01-21 | 2026-01-21 |
| [x] | Create rsc.toml configuration | 2026-01-21 | 2026-01-21 |
| [x] | Set up .gitignore | 2026-01-21 | 2026-01-21 |
| [x] | Initialize git repository | 2026-01-21 | 2026-01-21 |
| [x] | Create GitHub remote repository | 2026-01-21 | 2026-01-21 |
| [x] | Push initial scaffold | 2026-01-21 | 2026-01-21 |

### 1.2 Core Rust Crates

#### rsc-flow (React Flow equivalent)

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Position and geometry types (Position, Dimensions, Rect) | 2026-01-21 | 2026-01-21 |
| [x] | Node types and state management | 2026-01-21 | 2026-01-21 |
| [x] | Edge types and connection logic | 2026-01-21 | 2026-01-21 |
| [x] | Viewport state (pan, zoom) | 2026-01-21 | 2026-01-21 |
| [x] | FlowCanvas state container | 2026-01-21 | 2026-01-21 |
| [x] | Hierarchical layout algorithm | 2026-01-21 | 2026-01-21 |
| [x] | Error types | 2026-01-21 | 2026-01-21 |
| [x] | Unit tests (8 tests passing) | 2026-01-21 | 2026-01-21 |

#### rsc-dnd (dnd-kit equivalent)

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | DndContext for drag state management | 2026-01-21 | 2026-01-21 |
| [x] | Draggable element types | 2026-01-21 | 2026-01-21 |
| [x] | Droppable zone types | 2026-01-21 | 2026-01-21 |
| [x] | Sortable list support | 2026-01-21 | 2026-01-21 |
| [x] | Collision detection algorithms | 2026-01-21 | 2026-01-21 |
| [x] | Sensor types (pointer, keyboard) | 2026-01-21 | 2026-01-21 |
| [x] | Error types | 2026-01-21 | 2026-01-21 |
| [x] | Unit tests (4 tests passing) | 2026-01-21 | 2026-01-21 |

#### rsc-studio (Core logic)

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Entity model (Workflow, Context, Preset) | 2026-01-21 | 2026-01-21 |
| [x] | StudioStore state management | 2026-01-21 | 2026-01-21 |
| [x] | Configuration loading | 2026-01-21 | 2026-01-21 |
| [x] | NavigationDesigner state | 2026-01-21 | 2026-01-21 |
| [x] | CssDesigner state | 2026-01-21 | 2026-01-21 |
| [x] | YAML export/import | 2026-01-21 | 2026-01-21 |
| [x] | Built-in templates (IDE, Minimal, Focus, Review) | 2026-01-21 | 2026-01-21 |
| [x] | Unit tests (6 tests passing) | 2026-01-21 | 2026-01-21 |

### 1.3 Design System

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Create design/theme.yaml with tokens | 2026-01-21 | 2026-01-21 |
| [x] | Create design/styles.yaml with component styles | 2026-01-21 | 2026-01-21 |
| [x] | Define color palette (light/dark adaptive) | 2026-01-21 | 2026-01-21 |
| [x] | Define spacing scale | 2026-01-21 | 2026-01-21 |
| [x] | Define typography tokens | 2026-01-21 | 2026-01-21 |
| [x] | Define shadow tokens | 2026-01-21 | 2026-01-21 |
| [x] | Define component styles | 2026-01-21 | 2026-01-21 |

### 1.4 RSX Application Scaffold

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Main entry point (main.rsx) | 2026-01-21 | 2026-01-21 |
| [x] | App component with routing | 2026-01-21 | 2026-01-21 |
| [x] | Component module structure | 2026-01-21 | 2026-01-21 |
| [x] | Hooks module structure | 2026-01-21 | 2026-01-21 |
| [x] | Pages module structure | 2026-01-21 | 2026-01-21 |

### 1.5 Fix Compilation Issues

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Add missing serde_json dependency | 2026-01-21 | 2026-01-21 |
| [x] | Fix generic type bounds for serde | 2026-01-21 | 2026-01-21 |
| [x] | Fix layout.apply type signature | 2026-01-21 | 2026-01-21 |
| [x] | Remove duplicate Default implementations | 2026-01-21 | 2026-01-21 |
| [x] | Clean up unused imports | 2026-01-21 | 2026-01-21 |

---

## Phase 2: Core UI Components

### 2.1 Layout Components

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | ActivityBar component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Sidebar component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Header component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | BottomPanel component (scaffold) | 2026-01-21 | 2026-01-21 |
| [ ] | Implement ActivityBar interactivity | 2026-01-21 | |
| [ ] | Implement Sidebar resize | 2026-01-21 | |
| [ ] | Implement BottomPanel resize | 2026-01-21 | |
| [ ] | Implement panel collapse/expand animations | 2026-01-21 | |

### 2.2 Basic Components

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Button component with variants (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Icon component with SVG sprite (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Panel component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Tabs component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Toolbar component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Input component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Select component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Checkbox component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Modal/Dialog component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Tooltip component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Context menu component (scaffold) | 2026-01-21 | 2026-01-21 |
| [ ] | Implement Button click handlers | 2026-01-21 | |
| [ ] | Implement Input two-way binding | 2026-01-21 | |
| [ ] | Implement Select dropdown | 2026-01-21 | |
| [ ] | Implement Modal open/close | 2026-01-21 | |

### 2.3 Flow Components

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | FlowCanvas component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | FlowNode component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | FlowEdge component (scaffold) | 2026-01-21 | 2026-01-21 |
| [ ] | Implement canvas pan/zoom gestures | 2026-01-21 | |
| [ ] | Implement node drag with snap-to-grid | 2026-01-21 | |
| [ ] | Implement edge creation by dragging | 2026-01-21 | |
| [ ] | Implement node selection (single/multi) | 2026-01-21 | |
| [ ] | Implement edge selection | 2026-01-21 | |
| [x] | Minimap component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Zoom controls component (scaffold) | 2026-01-21 | 2026-01-21 |
| [ ] | Implement minimap interactivity | 2026-01-21 | |
| [ ] | Implement zoom controls interactivity | 2026-01-21 | |
| [ ] | Implement fit-to-view | 2026-01-21 | |

### 2.4 Token Editor Components

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | TokenEditor component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | ColorPicker component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | SpacingEditor component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | ShadowEditor component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | TypographyEditor component (scaffold) | 2026-01-21 | 2026-01-21 |
| [ ] | Implement ColorPicker interactivity | 2026-01-21 | |
| [ ] | Implement SpacingEditor interactivity | 2026-01-21 | |
| [ ] | Implement ShadowEditor interactivity | 2026-01-21 | |
| [ ] | Implement TypographyEditor interactivity | 2026-01-21 | |
| [ ] | Token preview with live updates | 2026-01-21 | |

---

## Phase 3: Navigation Designer

> **Note:** Core logic implemented in `rsc-studio` Rust crate. RSX UI integration pending.

### 3.1 Workflow Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Workflow data model (Rust) | 2026-01-21 | 2026-01-21 |
| [ ] | Create new workflow (RSX UI) | 2026-01-21 | |
| [ ] | Edit workflow properties (RSX UI) | 2026-01-21 | |
| [ ] | Delete workflow with confirmation (RSX UI) | 2026-01-21 | |
| [ ] | Duplicate workflow (RSX UI) | 2026-01-21 | |
| [ ] | Reorder workflows (RSX UI) | 2026-01-21 | |

### 3.2 Context Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Context data model (Rust) | 2026-01-21 | 2026-01-21 |
| [ ] | Create new context within workflow (RSX UI) | 2026-01-21 | |
| [ ] | Edit context properties (RSX UI) | 2026-01-21 | |
| [ ] | Delete context (RSX UI) | 2026-01-21 | |
| [ ] | Drag context between workflows (RSX UI) | 2026-01-21 | |
| [ ] | Visual context node rendering (RSX UI) | 2026-01-21 | |

### 3.3 Preset Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Preset data model (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Built-in templates (IDE, Minimal, Focus, Review) | 2026-01-21 | 2026-01-21 |
| [ ] | Create new preset within context (RSX UI) | 2026-01-21 | |
| [ ] | Edit preset properties (RSX UI) | 2026-01-21 | |
| [ ] | Configure preset layout (RSX UI) | 2026-01-21 | |
| [ ] | Delete preset (RSX UI) | 2026-01-21 | |
| [ ] | Duplicate preset (RSX UI) | 2026-01-21 | |
| [ ] | Visual preset node rendering (RSX UI) | 2026-01-21 | |

### 3.4 Visual Flow Editor

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Hierarchical layout algorithm (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Edge routing logic (Rust) | 2026-01-21 | 2026-01-21 |
| [ ] | Render workflow hierarchy as flow graph (RSX UI) | 2026-01-21 | |
| [ ] | Auto-layout on structure change (RSX UI) | 2026-01-21 | |
| [ ] | Manual node positioning with persistence (RSX UI) | 2026-01-21 | |
| [ ] | Zoom to selection (RSX UI) | 2026-01-21 | |
| [ ] | Search/filter nodes (RSX UI) | 2026-01-21 | |
| [ ] | Keyboard navigation (RSX UI) | 2026-01-21 | |

### 3.5 Navigation Preview

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Preview navigation flow | 2026-01-21 | |
| [ ] | Simulate context switching | 2026-01-21 | |
| [ ] | Preview preset layouts | 2026-01-21 | |
| [ ] | Hot reload preview on changes | 2026-01-21 | |

---

## Phase 4: CSS Designer

> **Note:** Core logic implemented in `rsc-studio` Rust crate. RSX UI integration pending.

### 4.1 Token Categories

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Token data models (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Token panel scaffold (RSX) | 2026-01-21 | 2026-01-21 |
| [ ] | Colors editor with color picker (RSX UI) | 2026-01-21 | |
| [ ] | Spacing editor with visual scale (RSX UI) | 2026-01-21 | |
| [ ] | Border radius editor (RSX UI) | 2026-01-21 | |
| [ ] | Shadow editor with visual preview (RSX UI) | 2026-01-21 | |
| [ ] | Typography editor (RSX UI) | 2026-01-21 | |
| [ ] | Transitions/animations editor (RSX UI) | 2026-01-21 | |
| [ ] | Z-index scale editor (RSX UI) | 2026-01-21 | |

### 4.2 Adaptive Theming

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Theme data model (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Multi-format export logic (Rust) | 2026-01-21 | 2026-01-21 |
| [ ] | Light/dark mode toggle (RSX UI) | 2026-01-21 | |
| [ ] | Side-by-side theme preview (RSX UI) | 2026-01-21 | |
| [ ] | Adaptive token editing (RSX UI) | 2026-01-21 | |
| [ ] | System theme detection (RSX UI) | 2026-01-21 | |
| [ ] | Theme export UI (RSX UI) | 2026-01-21 | |

### 4.3 Component Styles

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | Component style data model (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | State variants model (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Responsive breakpoint model (Rust) | 2026-01-21 | 2026-01-21 |
| [ ] | Visual style editor (RSX UI) | 2026-01-21 | |
| [ ] | State variants UI (RSX UI) | 2026-01-21 | |
| [ ] | Responsive breakpoint UI (RSX UI) | 2026-01-21 | |
| [ ] | Style inheritance visualization (RSX UI) | 2026-01-21 | |
| [x] | CSS output preview scaffold (RSX) | 2026-01-21 | 2026-01-21 |

### 4.4 Design Token Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | YAML/JSON import logic (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Multi-format export logic (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Token validation logic (Rust) | 2026-01-21 | 2026-01-21 |
| [x] | Token dependency graph (Rust) | 2026-01-21 | 2026-01-21 |
| [ ] | Import tokens UI (RSX UI) | 2026-01-21 | |
| [ ] | Export tokens UI (RSX UI) | 2026-01-21 | |
| [ ] | Validation UI (RSX UI) | 2026-01-21 | |
| [ ] | Unused token detection UI (RSX UI) | 2026-01-21 | |
| [ ] | Dependency graph visualization (RSX UI) | 2026-01-21 | |

---

## Phase 5: Integration & Export

### 5.1 File System Integration

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Watch design files for changes | 2026-01-21 | |
| [ ] | Auto-reload on external changes | 2026-01-21 | |
| [ ] | Save to design/theme.yaml | 2026-01-21 | |
| [ ] | Save to design/styles.yaml | 2026-01-21 | |
| [ ] | Backup/versioning | 2026-01-21 | |

### 5.2 RustScript Integration

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Generate RSX component code | 2026-01-21 | |
| [ ] | Generate style! macro code | 2026-01-21 | |
| [ ] | Generate routes.yaml from workflows | 2026-01-21 | |
| [ ] | Integrate with rsc CLI | 2026-01-21 | |
| [ ] | Hot reload in rsc dev server | 2026-01-21 | |

### 5.3 Export Formats

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Export to CSS variables | 2026-01-21 | |
| [ ] | Export to SCSS variables | 2026-01-21 | |
| [ ] | Export to JSON tokens | 2026-01-21 | |
| [ ] | Export to Tailwind config | 2026-01-21 | |
| [ ] | Export navigation as routes.yaml | 2026-01-21 | |
| [ ] | Export as standalone HTML preview | 2026-01-21 | |

---

## Phase 6: Advanced Features

### 6.1 Undo/Redo

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Command pattern implementation | 2026-01-21 | |
| [ ] | Undo stack management | 2026-01-21 | |
| [ ] | Redo stack management | 2026-01-21 | |
| [ ] | Keyboard shortcuts (Ctrl+Z, Ctrl+Shift+Z) | 2026-01-21 | |
| [ ] | History panel | 2026-01-21 | |

### 6.2 Keyboard Shortcuts

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Define shortcut registry | 2026-01-21 | |
| [ ] | Navigation shortcuts | 2026-01-21 | |
| [ ] | Editing shortcuts | 2026-01-21 | |
| [ ] | View shortcuts | 2026-01-21 | |
| [ ] | Customizable shortcuts | 2026-01-21 | |
| [ ] | Shortcut help overlay | 2026-01-21 | |

### 6.3 Collaboration (Future)

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Real-time sync protocol | 2026-01-21 | |
| [ ] | Conflict resolution | 2026-01-21 | |
| [ ] | User presence indicators | 2026-01-21 | |
| [ ] | Comments/annotations | 2026-01-21 | |
| [ ] | Version history | 2026-01-21 | |

### 6.4 Plugins (Future)

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Plugin API design | 2026-01-21 | |
| [ ] | Custom node types | 2026-01-21 | |
| [ ] | Custom token types | 2026-01-21 | |
| [ ] | Custom export formats | 2026-01-21 | |
| [ ] | Plugin marketplace | 2026-01-21 | |

---

## Phase 7: Testing & Quality

### 7.1 Unit Tests

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | rsc-flow tests (8 passing) | 2026-01-21 | 2026-01-21 |
| [x] | rsc-dnd tests (4 passing) | 2026-01-21 | 2026-01-21 |
| [x] | rsc-studio tests (6 passing) | 2026-01-21 | 2026-01-21 |
| [ ] | Component unit tests | 2026-01-21 | |
| [ ] | Hook unit tests | 2026-01-21 | |
| [ ] | Utility function tests | 2026-01-21 | |

### 7.2 Integration Tests

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Workflow CRUD operations | 2026-01-21 | |
| [ ] | Token editing flow | 2026-01-21 | |
| [ ] | Export/import roundtrip | 2026-01-21 | |
| [ ] | Canvas interactions | 2026-01-21 | |

### 7.3 E2E Tests

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Full navigation designer flow | 2026-01-21 | |
| [ ] | Full CSS designer flow | 2026-01-21 | |
| [ ] | Cross-browser testing | 2026-01-21 | |
| [ ] | Performance benchmarks | 2026-01-21 | |

### 7.4 Documentation

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | API documentation | 2026-01-21 | |
| [ ] | User guide | 2026-01-21 | |
| [ ] | Component storybook | 2026-01-21 | |
| [ ] | Architecture decision records | 2026-01-21 | |
| [ ] | Contributing guide | 2026-01-21 | |

---

## Phase 8: Polish & Release

### 8.1 Performance

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Virtual scrolling for large lists | 2026-01-21 | |
| [ ] | Canvas rendering optimization | 2026-01-21 | |
| [ ] | Lazy loading for panels | 2026-01-21 | |
| [ ] | Memory usage optimization | 2026-01-21 | |
| [ ] | Bundle size optimization | 2026-01-21 | |

### 8.2 Accessibility

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Keyboard navigation | 2026-01-21 | |
| [ ] | Screen reader support | 2026-01-21 | |
| [ ] | High contrast mode | 2026-01-21 | |
| [ ] | Reduced motion support | 2026-01-21 | |
| [ ] | Focus management | 2026-01-21 | |

### 8.3 Release Preparation

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Version 0.1.0 feature freeze | 2026-01-21 | |
| [ ] | Release notes | 2026-01-21 | |
| [ ] | Demo/showcase | 2026-01-21 | |
| [ ] | Landing page | 2026-01-21 | |
| [ ] | Distribution packages | 2026-01-21 | |

---

## Metrics

| Phase | Total | Done | Progress |
|-------|-------|------|----------|
| Phase 1: Foundation | 35 | 35 | 100% |
| Phase 2: UI Components | 38 | 16 | 42% |
| Phase 3: Navigation | 28 | 4 | 14% |
| Phase 4: CSS Designer | 31 | 11 | 35% |
| Phase 5: Integration | 14 | 0 | 0% |
| Phase 6: Advanced | 18 | 0 | 0% |
| Phase 7: Testing | 13 | 3 | 23% |
| Phase 8: Polish | 14 | 0 | 0% |
| **Total** | **191** | **69** | **36%** |

---

## Current Sprint

**Focus:** Phase 2.1 - Implementing UI Interactivity

**What's Actually Done:**
- [x] Project structure and Rust crates (Phase 1)
- [x] RSX component scaffolds (static HTML with data-testid)
- [x] Rust data models and algorithms
- [x] Unit tests for Rust crates (18 passing)

**What's NOT Done (marked incorrectly before):**
- [ ] All RSX interactivity (click handlers, state management)
- [ ] Canvas interactions (pan, zoom, drag)
- [ ] Form inputs (two-way binding)
- [ ] Navigation between pages

**Next Tasks:**
| Task | Assignee | Started |
|------|----------|---------|
| Implement ActivityBar interactivity | - | - |
| Implement Sidebar content switching | - | - |
| Implement page visibility toggling | - | - |
| Run e2e tests to verify | - | - |

---

## Notes

- Project migrates functionality from ~/flowize (React) to RustScript
- Uses signal-based reactivity (similar to SolidJS)
- RSX files are compiled by RustScript compiler, not cargo
- Three Rust crates provide core logic, UI is in RSX
- **Important:** "Scaffold" means static HTML only - interactivity must be added separately

## Known Compiler Limitations (Blocking)

The following RSX features are **documented but not yet implemented in codegen**:

| Feature | Parser | Codegen | Status |
|---------|--------|---------|--------|
| `signal()` | ✅ | ❌ | Fails with "type mismatch" |
| `on:click={...}` | ✅ | ❌ | Fails with "MissingFunction" |
| `@if condition { }` | ✅ | ❌ | Fails with "binop on Infer" |
| `class:active={...}` | ✅ | ❌ | Not implemented |
| `@for item in items { }` | ✅ | ❌ | Not tested |

**Impact:** All RSX interactivity is blocked until these codegen features are implemented.
The RSX app can only render static HTML. 7/37 e2e tests pass (basic rendering), 30 fail (require interaction).

**Workaround:** None available. Waiting on RustScript compiler updates.
