//! Drag and drop context and state management.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Unique identifier for draggable/droppable elements.
pub type DndId = String;

/// Drag and drop context state.
#[derive(Debug, Clone, Default)]
pub struct DndContext {
    /// Currently active (dragging) item.
    pub active: Option<DndId>,
    /// Item being dragged over.
    pub over: Option<DndId>,
    /// All registered draggables.
    pub draggables: HashMap<DndId, DraggableInfo>,
    /// All registered droppables.
    pub droppables: HashMap<DndId, DroppableInfo>,
    /// Current drag state.
    pub state: DndState,
}

impl DndContext {
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a draggable element.
    pub fn register_draggable(&mut self, id: impl Into<String>, info: DraggableInfo) {
        self.draggables.insert(id.into(), info);
    }

    /// Register a droppable element.
    pub fn register_droppable(&mut self, id: impl Into<String>, info: DroppableInfo) {
        self.droppables.insert(id.into(), info);
    }

    /// Unregister a draggable.
    pub fn unregister_draggable(&mut self, id: &str) {
        self.draggables.remove(id);
    }

    /// Unregister a droppable.
    pub fn unregister_droppable(&mut self, id: &str) {
        self.droppables.remove(id);
    }

    /// Start dragging.
    pub fn start_drag(&mut self, id: impl Into<String>) -> DragEvent {
        let id = id.into();
        self.active = Some(id.clone());
        self.state = DndState::Dragging;
        DragEvent::Start { id }
    }

    /// Update drag position.
    pub fn update_drag(&mut self, x: f64, y: f64) -> DragEvent {
        DragEvent::Move {
            id: self.active.clone().unwrap_or_default(),
            x,
            y,
        }
    }

    /// Set the current drop target.
    pub fn set_over(&mut self, id: Option<String>) {
        self.over = id;
    }

    /// End dragging.
    pub fn end_drag(&mut self) -> DragEndEvent {
        let event = DragEndEvent {
            active: self.active.take(),
            over: self.over.take(),
        };
        self.state = DndState::Idle;
        event
    }

    /// Cancel dragging.
    pub fn cancel_drag(&mut self) {
        self.active = None;
        self.over = None;
        self.state = DndState::Idle;
    }

    /// Check if currently dragging.
    pub fn is_dragging(&self) -> bool {
        matches!(self.state, DndState::Dragging)
    }

    /// Check if a specific item is being dragged.
    pub fn is_dragging_id(&self, id: &str) -> bool {
        self.active.as_deref() == Some(id)
    }

    /// Check if dragging over a specific droppable.
    pub fn is_over(&self, id: &str) -> bool {
        self.over.as_deref() == Some(id)
    }
}

/// Drag and drop state.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum DndState {
    #[default]
    Idle,
    Dragging,
}

/// Information about a draggable element.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DraggableInfo {
    /// Element bounds.
    pub rect: Rect,
    /// Whether dragging is disabled.
    #[serde(default)]
    pub disabled: bool,
    /// Data associated with this draggable.
    #[serde(default)]
    pub data: serde_json::Value,
}

/// Information about a droppable element.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DroppableInfo {
    /// Element bounds.
    pub rect: Rect,
    /// Whether dropping is disabled.
    #[serde(default)]
    pub disabled: bool,
    /// Accepted draggable types.
    #[serde(default)]
    pub accepts: Vec<String>,
    /// Data associated with this droppable.
    #[serde(default)]
    pub data: serde_json::Value,
}

/// Rectangle bounds.
#[derive(Debug, Clone, Copy, Default, Serialize, Deserialize)]
pub struct Rect {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl Rect {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self { x, y, width, height }
    }

    pub fn contains_point(&self, px: f64, py: f64) -> bool {
        px >= self.x && px <= self.x + self.width && py >= self.y && py <= self.y + self.height
    }

    pub fn center(&self) -> (f64, f64) {
        (self.x + self.width / 2.0, self.y + self.height / 2.0)
    }

    pub fn intersects(&self, other: &Rect) -> bool {
        self.x < other.x + other.width
            && self.x + self.width > other.x
            && self.y < other.y + other.height
            && self.y + self.height > other.y
    }
}

/// Drag event.
#[derive(Debug, Clone)]
pub enum DragEvent {
    Start { id: DndId },
    Move { id: DndId, x: f64, y: f64 },
    Over { id: DndId, over: DndId },
    Leave { id: DndId, left: DndId },
}

/// Drag end event.
#[derive(Debug, Clone)]
pub struct DragEndEvent {
    /// The item that was dragged.
    pub active: Option<DndId>,
    /// The droppable it was dropped on.
    pub over: Option<DndId>,
}

impl DragEndEvent {
    /// Check if the drop was successful.
    pub fn is_dropped(&self) -> bool {
        self.active.is_some() && self.over.is_some()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_drag_lifecycle() {
        let mut ctx = DndContext::new();

        ctx.start_drag("item-1");
        assert!(ctx.is_dragging());
        assert!(ctx.is_dragging_id("item-1"));

        ctx.set_over(Some("drop-zone".to_string()));
        assert!(ctx.is_over("drop-zone"));

        let event = ctx.end_drag();
        assert_eq!(event.active, Some("item-1".to_string()));
        assert_eq!(event.over, Some("drop-zone".to_string()));
        assert!(!ctx.is_dragging());
    }
}
