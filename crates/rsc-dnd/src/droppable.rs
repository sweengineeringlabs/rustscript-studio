//! Droppable element types.

use crate::context::DndId;

/// Droppable element configuration.
#[derive(Debug, Clone, Default)]
pub struct Droppable {
    /// Unique identifier.
    pub id: DndId,
    /// Whether dropping is disabled.
    pub disabled: bool,
    /// Accepted draggable IDs or types.
    pub accepts: Vec<String>,
    /// Associated data.
    pub data: serde_json::Value,
}

impl Droppable {
    pub fn new(id: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            disabled: false,
            accepts: Vec::new(),
            data: serde_json::Value::Null,
        }
    }

    pub fn accepts(mut self, types: impl IntoIterator<Item = impl Into<String>>) -> Self {
        self.accepts = types.into_iter().map(|t| t.into()).collect();
        self
    }

    pub fn disabled(mut self) -> Self {
        self.disabled = true;
        self
    }
}

/// Droppable state for components.
#[derive(Debug, Clone, Default)]
pub struct DroppableState {
    /// Whether a draggable is over this droppable.
    pub is_over: bool,
    /// Whether this droppable is disabled.
    pub is_disabled: bool,
    /// The ID of the draggable currently over this droppable.
    pub active_id: Option<DndId>,
    /// Whether the active draggable can be dropped here.
    pub can_drop: bool,
}

impl DroppableState {
    /// Check if ready to receive a drop.
    pub fn is_drop_target(&self) -> bool {
        self.is_over && self.can_drop && !self.is_disabled
    }
}
