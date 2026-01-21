# RustScript Studio - Project Backlog

**Created:** 2026-01-21
**Last Updated:** 2026-01-21

Visual IDE for RustScript - Design navigation flows and CSS visually.

## Legend

- [x] Completed
- [ ] Pending
- 🔵 In Progress

---

## Phase 1: Project Foundation

### 1.1 Project Setup
- [x] Create project structure and workspace
- [x] Configure Cargo.toml with workspace dependencies
- [x] Create rsc.toml configuration
- [x] Set up .gitignore
- [x] Initialize git repository
- [x] Create GitHub remote repository
- [x] Push initial scaffold

### 1.2 Core Rust Crates

#### rsc-flow (React Flow equivalent)
- [x] Position and geometry types (Position, Dimensions, Rect)
- [x] Node types and state management
- [x] Edge types and connection logic
- [x] Viewport state (pan, zoom)
- [x] FlowCanvas state container
- [x] Hierarchical layout algorithm
- [x] Error types
- [x] Unit tests (8 tests passing)

#### rsc-dnd (dnd-kit equivalent)
- [x] DndContext for drag state management
- [x] Draggable element types
- [x] Droppable zone types
- [x] Sortable list support
- [x] Collision detection algorithms
- [x] Sensor types (pointer, keyboard)
- [x] Error types
- [x] Unit tests (4 tests passing)

#### rsc-studio (Core logic)
- [x] Entity model (Workflow, Context, Preset)
- [x] StudioStore state management
- [x] Configuration loading
- [x] NavigationDesigner state
- [x] CssDesigner state
- [x] YAML export/import
- [x] Built-in templates (IDE, Minimal, Focus, Review)
- [x] Unit tests (6 tests passing)

### 1.3 Design System
- [x] Create design/theme.yaml with tokens
- [x] Create design/styles.yaml with component styles
- [x] Define color palette (light/dark adaptive)
- [x] Define spacing scale
- [x] Define typography tokens
- [x] Define shadow tokens
- [x] Define component styles

### 1.4 RSX Application Scaffold
- [x] Main entry point (main.rsx)
- [x] App component with routing
- [x] Component module structure
- [x] Hooks module structure
- [x] Pages module structure

### 1.5 Fix Compilation Issues
- [x] Add missing serde_json dependency
- [x] Fix generic type bounds for serde
- [x] Fix layout.apply type signature
- [x] Remove duplicate Default implementations
- [x] Clean up unused imports

---

## Phase 2: Core UI Components

### 2.1 Layout Components
- [x] ActivityBar component (scaffold)
- [x] Sidebar component (scaffold)
- [x] Header component (scaffold)
- [x] BottomPanel component (scaffold)
- [ ] Implement ActivityBar interactivity
- [ ] Implement Sidebar resize
- [ ] Implement BottomPanel resize
- [ ] Implement panel collapse/expand animations

### 2.2 Basic Components
- [x] Button component with variants (scaffold)
- [x] Icon component with SVG sprite (scaffold)
- [x] Panel component (scaffold)
- [x] Tabs component (scaffold)
- [x] Toolbar component (scaffold)
- [ ] Input component
- [ ] Select component
- [ ] Checkbox component
- [ ] Modal/Dialog component
- [ ] Tooltip component
- [ ] Context menu component

### 2.3 Flow Components
- [x] FlowCanvas component (scaffold)
- [x] FlowNode component (scaffold)
- [x] FlowEdge component (scaffold)
- [ ] Implement canvas pan/zoom gestures
- [ ] Implement node drag with snap-to-grid
- [ ] Implement edge creation by dragging
- [ ] Implement node selection (single/multi)
- [ ] Implement edge selection
- [ ] Implement minimap
- [ ] Implement zoom controls
- [ ] Implement fit-to-view

### 2.4 Token Editor Components
- [x] TokenEditor component (scaffold)
- [ ] ColorPicker component
- [ ] SpacingEditor component
- [ ] ShadowEditor component
- [ ] TypographyEditor component
- [ ] Token preview with live updates

---

## Phase 3: Navigation Designer

### 3.1 Workflow Management
- [ ] Create new workflow
- [ ] Edit workflow properties (name, icon, description)
- [ ] Delete workflow with confirmation
- [ ] Duplicate workflow
- [ ] Reorder workflows

### 3.2 Context Management
- [ ] Create new context within workflow
- [ ] Edit context properties
- [ ] Delete context
- [ ] Drag context between workflows
- [ ] Visual context node rendering

### 3.3 Preset Management
- [ ] Create new preset within context
- [ ] Edit preset properties
- [ ] Configure preset layout (activity bar, sidebar, panels)
- [ ] Delete preset
- [ ] Duplicate preset
- [ ] Visual preset node rendering

### 3.4 Visual Flow Editor
- [ ] Render workflow hierarchy as flow graph
- [ ] Auto-layout on structure change
- [ ] Manual node positioning with persistence
- [ ] Edge routing (bezier curves)
- [ ] Zoom to selection
- [ ] Search/filter nodes
- [ ] Keyboard navigation

### 3.5 Navigation Preview
- [ ] Preview navigation flow
- [ ] Simulate context switching
- [ ] Preview preset layouts
- [ ] Hot reload preview on changes

---

## Phase 4: CSS Designer

### 4.1 Token Categories
- [ ] Colors editor with color picker
- [ ] Spacing editor with visual scale
- [ ] Border radius editor
- [ ] Shadow editor with visual preview
- [ ] Typography editor (fonts, sizes, weights)
- [ ] Transitions/animations editor
- [ ] Z-index scale editor

### 4.2 Adaptive Theming
- [ ] Light/dark mode toggle
- [ ] Side-by-side theme preview
- [ ] Adaptive token editing (light + dark values)
- [ ] System theme detection
- [ ] Theme export (CSS variables, SCSS, JSON)

### 4.3 Component Styles
- [ ] Visual style editor for components
- [ ] State variants (hover, active, focus, disabled)
- [ ] Responsive breakpoint support
- [ ] Style inheritance visualization
- [ ] CSS output preview

### 4.4 Design Token Management
- [ ] Import tokens from YAML/JSON
- [ ] Export tokens to multiple formats
- [ ] Token validation
- [ ] Unused token detection
- [ ] Token dependency graph

---

## Phase 5: Integration & Export

### 5.1 File System Integration
- [ ] Watch design files for changes
- [ ] Auto-reload on external changes
- [ ] Save to design/theme.yaml
- [ ] Save to design/styles.yaml
- [ ] Backup/versioning

### 5.2 RustScript Integration
- [ ] Generate RSX component code
- [ ] Generate style! macro code
- [ ] Generate routes.yaml from workflows
- [ ] Integrate with rsc CLI
- [ ] Hot reload in rsc dev server

### 5.3 Export Formats
- [ ] Export to CSS variables
- [ ] Export to SCSS variables
- [ ] Export to JSON tokens
- [ ] Export to Tailwind config
- [ ] Export navigation as routes.yaml
- [ ] Export as standalone HTML preview

---

## Phase 6: Advanced Features

### 6.1 Undo/Redo
- [ ] Command pattern implementation
- [ ] Undo stack management
- [ ] Redo stack management
- [ ] Keyboard shortcuts (Ctrl+Z, Ctrl+Shift+Z)
- [ ] History panel

### 6.2 Keyboard Shortcuts
- [ ] Define shortcut registry
- [ ] Navigation shortcuts
- [ ] Editing shortcuts
- [ ] View shortcuts
- [ ] Customizable shortcuts
- [ ] Shortcut help overlay

### 6.3 Collaboration (Future)
- [ ] Real-time sync protocol
- [ ] Conflict resolution
- [ ] User presence indicators
- [ ] Comments/annotations
- [ ] Version history

### 6.4 Plugins (Future)
- [ ] Plugin API design
- [ ] Custom node types
- [ ] Custom token types
- [ ] Custom export formats
- [ ] Plugin marketplace

---

## Phase 7: Testing & Quality

### 7.1 Unit Tests
- [x] rsc-flow tests (8 passing)
- [x] rsc-dnd tests (4 passing)
- [x] rsc-studio tests (6 passing)
- [ ] Component unit tests
- [ ] Hook unit tests
- [ ] Utility function tests

### 7.2 Integration Tests
- [ ] Workflow CRUD operations
- [ ] Token editing flow
- [ ] Export/import roundtrip
- [ ] Canvas interactions

### 7.3 E2E Tests
- [ ] Full navigation designer flow
- [ ] Full CSS designer flow
- [ ] Cross-browser testing
- [ ] Performance benchmarks

### 7.4 Documentation
- [ ] API documentation
- [ ] User guide
- [ ] Component storybook
- [ ] Architecture decision records
- [ ] Contributing guide

---

## Phase 8: Polish & Release

### 8.1 Performance
- [ ] Virtual scrolling for large lists
- [ ] Canvas rendering optimization
- [ ] Lazy loading for panels
- [ ] Memory usage optimization
- [ ] Bundle size optimization

### 8.2 Accessibility
- [ ] Keyboard navigation
- [ ] Screen reader support
- [ ] High contrast mode
- [ ] Reduced motion support
- [ ] Focus management

### 8.3 Release Preparation
- [ ] Version 0.1.0 feature freeze
- [ ] Release notes
- [ ] Demo/showcase
- [ ] Landing page
- [ ] Distribution packages

---

## Metrics

| Phase | Total Tasks | Completed | Progress |
|-------|-------------|-----------|----------|
| Phase 1: Foundation | 35 | 35 | 100% |
| Phase 2: UI Components | 28 | 12 | 43% |
| Phase 3: Navigation | 19 | 0 | 0% |
| Phase 4: CSS Designer | 17 | 0 | 0% |
| Phase 5: Integration | 14 | 0 | 0% |
| Phase 6: Advanced | 18 | 0 | 0% |
| Phase 7: Testing | 13 | 3 | 23% |
| Phase 8: Polish | 14 | 0 | 0% |
| **Total** | **158** | **50** | **32%** |

---

## Current Sprint

**Focus:** Phase 2 - Core UI Components

**Active Tasks:**
- Implement canvas pan/zoom gestures
- Implement node drag with snap-to-grid
- Input component
- ColorPicker component

---

## Notes

- Project migrates functionality from ~/flowize (React) to RustScript
- Uses signal-based reactivity (similar to SolidJS)
- RSX files are compiled by RustScript compiler, not cargo
- Three Rust crates provide core logic, UI is in RSX
