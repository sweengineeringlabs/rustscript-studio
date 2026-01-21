//! # rsc-dnd
//!
//! Drag and drop library for RustScript applications.
//! Provides accessible, performant drag-and-drop similar to dnd-kit.
//!
//! ## Features
//!
//! - Draggable and droppable primitives
//! - Sortable lists with animations
//! - Collision detection strategies
//! - Keyboard navigation support
//! - Touch and pointer events
//!
//! ## Example
//!
//! ```rust,ignore
//! use rsc_dnd::{DndContext, Draggable, Droppable};
//!
//! // In RSX component
//! <DndContext on_drag_end={handle_drop}>
//!     <Droppable id="list">
//!         <Draggable id="item-1">"Item 1"</Draggable>
//!         <Draggable id="item-2">"Item 2"</Draggable>
//!     </Droppable>
//! </DndContext>
//! ```

mod collision;
mod context;
mod draggable;
mod droppable;
mod error;
mod sensors;
mod sortable;

pub use collision::*;
pub use context::*;
pub use draggable::*;
pub use droppable::*;
pub use error::*;
pub use sensors::*;
pub use sortable::*;

/// Re-export common types.
pub mod prelude {
    pub use crate::{
        CollisionDetection, CollisionStrategy,
        DndContext, DndState, DragEvent, DragEndEvent,
        Draggable, DraggableState,
        Droppable, DroppableState,
        Sensor, PointerSensor, KeyboardSensor,
        Sortable, SortableContext, SortDirection,
        DndError, DndResult,
    };
}
