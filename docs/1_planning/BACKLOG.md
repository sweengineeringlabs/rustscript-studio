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
| [x] | Input component | 2026-01-21 | 2026-01-21 |
| [ ] | Select component | 2026-01-21 | |
| [ ] | Checkbox component | 2026-01-21 | |
| [ ] | Modal/Dialog component | 2026-01-21 | |
| [ ] | Tooltip component | 2026-01-21 | |
| [ ] | Context menu component | 2026-01-21 | |

### 2.3 Flow Components

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | FlowCanvas component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | FlowNode component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | FlowEdge component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | Implement canvas pan/zoom gestures | 2026-01-21 | 2026-01-21 |
| [x] | Implement node drag with snap-to-grid | 2026-01-21 | 2026-01-21 |
| [ ] | Implement edge creation by dragging | 2026-01-21 | |
| [ ] | Implement node selection (single/multi) | 2026-01-21 | |
| [ ] | Implement edge selection | 2026-01-21 | |
| [ ] | Implement minimap | 2026-01-21 | |
| [ ] | Implement zoom controls | 2026-01-21 | |
| [ ] | Implement fit-to-view | 2026-01-21 | |

### 2.4 Token Editor Components

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [x] | TokenEditor component (scaffold) | 2026-01-21 | 2026-01-21 |
| [x] | ColorPicker component | 2026-01-21 | 2026-01-21 |
| [ ] | SpacingEditor component | 2026-01-21 | |
| [ ] | ShadowEditor component | 2026-01-21 | |
| [ ] | TypographyEditor component | 2026-01-21 | |
| [ ] | Token preview with live updates | 2026-01-21 | |

---

## Phase 3: Navigation Designer

### 3.1 Workflow Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Create new workflow | 2026-01-21 | |
| [ ] | Edit workflow properties (name, icon, description) | 2026-01-21 | |
| [ ] | Delete workflow with confirmation | 2026-01-21 | |
| [ ] | Duplicate workflow | 2026-01-21 | |
| [ ] | Reorder workflows | 2026-01-21 | |

### 3.2 Context Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Create new context within workflow | 2026-01-21 | |
| [ ] | Edit context properties | 2026-01-21 | |
| [ ] | Delete context | 2026-01-21 | |
| [ ] | Drag context between workflows | 2026-01-21 | |
| [ ] | Visual context node rendering | 2026-01-21 | |

### 3.3 Preset Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Create new preset within context | 2026-01-21 | |
| [ ] | Edit preset properties | 2026-01-21 | |
| [ ] | Configure preset layout (activity bar, sidebar, panels) | 2026-01-21 | |
| [ ] | Delete preset | 2026-01-21 | |
| [ ] | Duplicate preset | 2026-01-21 | |
| [ ] | Visual preset node rendering | 2026-01-21 | |

### 3.4 Visual Flow Editor

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Render workflow hierarchy as flow graph | 2026-01-21 | |
| [ ] | Auto-layout on structure change | 2026-01-21 | |
| [ ] | Manual node positioning with persistence | 2026-01-21 | |
| [ ] | Edge routing (bezier curves) | 2026-01-21 | |
| [ ] | Zoom to selection | 2026-01-21 | |
| [ ] | Search/filter nodes | 2026-01-21 | |
| [ ] | Keyboard navigation | 2026-01-21 | |

### 3.5 Navigation Preview

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Preview navigation flow | 2026-01-21 | |
| [ ] | Simulate context switching | 2026-01-21 | |
| [ ] | Preview preset layouts | 2026-01-21 | |
| [ ] | Hot reload preview on changes | 2026-01-21 | |

---

## Phase 4: CSS Designer

### 4.1 Token Categories

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Colors editor with color picker | 2026-01-21 | |
| [ ] | Spacing editor with visual scale | 2026-01-21 | |
| [ ] | Border radius editor | 2026-01-21 | |
| [ ] | Shadow editor with visual preview | 2026-01-21 | |
| [ ] | Typography editor (fonts, sizes, weights) | 2026-01-21 | |
| [ ] | Transitions/animations editor | 2026-01-21 | |
| [ ] | Z-index scale editor | 2026-01-21 | |

### 4.2 Adaptive Theming

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Light/dark mode toggle | 2026-01-21 | |
| [ ] | Side-by-side theme preview | 2026-01-21 | |
| [ ] | Adaptive token editing (light + dark values) | 2026-01-21 | |
| [ ] | System theme detection | 2026-01-21 | |
| [ ] | Theme export (CSS variables, SCSS, JSON) | 2026-01-21 | |

### 4.3 Component Styles

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Visual style editor for components | 2026-01-21 | |
| [ ] | State variants (hover, active, focus, disabled) | 2026-01-21 | |
| [ ] | Responsive breakpoint support | 2026-01-21 | |
| [ ] | Style inheritance visualization | 2026-01-21 | |
| [ ] | CSS output preview | 2026-01-21 | |

### 4.4 Design Token Management

| Status | Task | Created | Completed |
|--------|------|---------|-----------|
| [ ] | Import tokens from YAML/JSON | 2026-01-21 | |
| [ ] | Export tokens to multiple formats | 2026-01-21 | |
| [ ] | Token validation | 2026-01-21 | |
| [ ] | Unused token detection | 2026-01-21 | |
| [ ] | Token dependency graph | 2026-01-21 | |

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
| Phase 2: UI Components | 28 | 16 | 57% |
| Phase 3: Navigation | 19 | 0 | 0% |
| Phase 4: CSS Designer | 17 | 0 | 0% |
| Phase 5: Integration | 14 | 0 | 0% |
| Phase 6: Advanced | 18 | 0 | 0% |
| Phase 7: Testing | 13 | 3 | 23% |
| Phase 8: Polish | 14 | 0 | 0% |
| **Total** | **158** | **54** | **34%** |

---

## Current Sprint

**Focus:** Phase 2 - Core UI Components

**Completed:**
- [x] Implement canvas pan/zoom gestures (2026-01-21)
- [x] Implement node drag with snap-to-grid (2026-01-21)
- [x] Input component (2026-01-21)
- [x] ColorPicker component (2026-01-21)

**Next Tasks:**
| Task | Assignee | Started |
|------|----------|---------|
| Select component | - | - |
| Checkbox component | - | - |
| SpacingEditor component | - | - |
| Implement edge creation by dragging | - | - |

---

## Notes

- Project migrates functionality from ~/flowize (React) to RustScript
- Uses signal-based reactivity (similar to SolidJS)
- RSX files are compiled by RustScript compiler, not cargo
- Three Rust crates provide core logic, UI is in RSX
