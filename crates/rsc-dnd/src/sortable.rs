//! Sortable list functionality.

use serde::{Deserialize, Serialize};

use crate::context::DndId;
use crate::draggable::Transform;

/// Sortable context for list reordering.
#[derive(Debug, Clone, Default)]
pub struct SortableContext {
    /// Ordered list of item IDs.
    pub items: Vec<DndId>,
    /// Sort direction.
    pub direction: SortDirection,
    /// Currently active (dragging) item.
    pub active_id: Option<DndId>,
    /// Index of the active item.
    pub active_index: Option<usize>,
    /// Current over index.
    pub over_index: Option<usize>,
}

impl SortableContext {
    pub fn new(items: Vec<DndId>) -> Self {
        Self {
            items,
            direction: SortDirection::Vertical,
            active_id: None,
            active_index: None,
            over_index: None,
        }
    }

    pub fn with_direction(mut self, direction: SortDirection) -> Self {
        self.direction = direction;
        self
    }

    /// Start sorting an item.
    pub fn start(&mut self, id: &str) {
        self.active_id = Some(id.to_string());
        self.active_index = self.items.iter().position(|i| i == id);
        self.over_index = self.active_index;
    }

    /// Update the over index.
    pub fn move_to(&mut self, over_id: &str) {
        self.over_index = self.items.iter().position(|i| i == over_id);
    }

    /// End sorting and return the new order.
    pub fn end(&mut self) -> Option<SortResult> {
        let result = match (self.active_index, self.over_index) {
            (Some(from), Some(to)) if from != to => Some(SortResult {
                items: self.reorder(from, to),
                from,
                to,
            }),
            _ => None,
        };

        self.active_id = None;
        self.active_index = None;
        self.over_index = None;

        result
    }

    /// Reorder items.
    fn reorder(&self, from: usize, to: usize) -> Vec<DndId> {
        let mut items = self.items.clone();
        let item = items.remove(from);
        items.insert(to, item);
        items
    }

    /// Get the visual index for an item (accounting for drag).
    pub fn get_sorted_index(&self, id: &str) -> Option<usize> {
        let current_index = self.items.iter().position(|i| i == id)?;

        match (self.active_index, self.over_index) {
            (Some(from), Some(to)) if from != to => {
                if id == self.active_id.as_deref()? {
                    Some(to)
                } else if from < to {
                    if current_index > from && current_index <= to {
                        Some(current_index - 1)
                    } else {
                        Some(current_index)
                    }
                } else {
                    if current_index >= to && current_index < from {
                        Some(current_index + 1)
                    } else {
                        Some(current_index)
                    }
                }
            }
            _ => Some(current_index),
        }
    }
}

/// Sort direction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum SortDirection {
    #[default]
    Vertical,
    Horizontal,
    Grid,
}

/// Result of a sort operation.
#[derive(Debug, Clone)]
pub struct SortResult {
    /// New order of items.
    pub items: Vec<DndId>,
    /// Original index.
    pub from: usize,
    /// New index.
    pub to: usize,
}

/// Sortable item state.
#[derive(Debug, Clone, Default)]
pub struct Sortable {
    /// Unique identifier.
    pub id: DndId,
    /// Current index in the list.
    pub index: usize,
    /// Whether this item is being sorted.
    pub is_sorting: bool,
    /// Transform for animation.
    pub transform: Option<Transform>,
    /// Transition style.
    pub transition: Option<String>,
}

impl Sortable {
    pub fn new(id: impl Into<String>, index: usize) -> Self {
        Self {
            id: id.into(),
            index,
            is_sorting: false,
            transform: None,
            transition: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sortable_reorder() {
        let mut ctx = SortableContext::new(vec![
            "a".to_string(),
            "b".to_string(),
            "c".to_string(),
            "d".to_string(),
        ]);

        ctx.start("b");
        ctx.move_to("d");
        let result = ctx.end().unwrap();

        assert_eq!(result.items, vec!["a", "c", "d", "b"]);
        assert_eq!(result.from, 1);
        assert_eq!(result.to, 3);
    }
}
