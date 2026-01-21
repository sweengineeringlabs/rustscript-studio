//! Draggable element types.

use serde::{Deserialize, Serialize};

use crate::context::{DndId, Rect};

/// Draggable element state.
#[derive(Debug, Clone, Default)]
pub struct Draggable {
    /// Unique identifier.
    pub id: DndId,
    /// Whether currently being dragged.
    pub is_dragging: bool,
    /// Whether dragging is disabled.
    pub disabled: bool,
    /// Current transform during drag.
    pub transform: Option<Transform>,
    /// Associated data.
    pub data: serde_json::Value,
}

impl Draggable {
    pub fn new(id: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            is_dragging: false,
            disabled: false,
            transform: None,
            data: serde_json::Value::Null,
        }
    }

    pub fn with_data(mut self, data: impl Serialize) -> Self {
        self.data = serde_json::to_value(data).unwrap_or_default();
        self
    }

    pub fn disabled(mut self) -> Self {
        self.disabled = true;
        self
    }
}

/// Draggable state for components.
#[derive(Debug, Clone, Default)]
pub struct DraggableState {
    /// Whether this element is being dragged.
    pub is_dragging: bool,
    /// Whether this element is disabled.
    pub is_disabled: bool,
    /// Current transform.
    pub transform: Option<Transform>,
    /// Attributes to apply to the element.
    pub attributes: DraggableAttributes,
    /// Listeners for drag events.
    pub listeners: DraggableListeners,
}

/// Attributes for draggable elements.
#[derive(Debug, Clone, Default)]
pub struct DraggableAttributes {
    pub role: String,
    pub tabindex: i32,
    pub aria_pressed: Option<bool>,
    pub aria_roledescription: String,
    pub aria_describedby: Option<String>,
}

impl DraggableAttributes {
    pub fn new() -> Self {
        Self {
            role: "button".to_string(),
            tabindex: 0,
            aria_pressed: None,
            aria_roledescription: "draggable".to_string(),
            aria_describedby: None,
        }
    }
}

/// Event listeners for draggable elements.
#[derive(Debug, Clone, Default)]
pub struct DraggableListeners {
    // These would be actual event handlers in the RSX runtime
    pub on_pointer_down: bool,
    pub on_key_down: bool,
}

/// Transform applied during drag.
#[derive(Debug, Clone, Copy, Default, Serialize, Deserialize)]
pub struct Transform {
    pub x: f64,
    pub y: f64,
    pub scale_x: f64,
    pub scale_y: f64,
}

impl Transform {
    pub fn new(x: f64, y: f64) -> Self {
        Self {
            x,
            y,
            scale_x: 1.0,
            scale_y: 1.0,
        }
    }

    pub fn to_css(&self) -> String {
        if self.scale_x != 1.0 || self.scale_y != 1.0 {
            format!(
                "translate3d({:.1}px, {:.1}px, 0) scale({:.2}, {:.2})",
                self.x, self.y, self.scale_x, self.scale_y
            )
        } else {
            format!("translate3d({:.1}px, {:.1}px, 0)", self.x, self.y)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_transform_css() {
        let t = Transform::new(10.0, 20.0);
        assert_eq!(t.to_css(), "translate3d(10.0px, 20.0px, 0)");
    }
}
