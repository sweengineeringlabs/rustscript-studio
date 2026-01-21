//! # rsc-flow
//!
//! Graph visualization library for RustScript applications.
//! Provides interactive node-based UI similar to React Flow.
//!
//! ## Features
//!
//! - Interactive canvas with pan and zoom
//! - Customizable nodes and edges
//! - Automatic layout algorithms (dagre-style)
//! - Connection handling with validation
//! - Minimap and controls
//!
//! ## Example
//!
//! ```rust,ignore
//! use rsc_flow::{FlowCanvas, Node, Edge};
//!
//! let nodes = vec![
//!     Node::new("1", "Start", Position::new(0.0, 0.0)),
//!     Node::new("2", "Process", Position::new(200.0, 100.0)),
//! ];
//!
//! let edges = vec![
//!     Edge::new("e1", "1", "2"),
//! ];
//! ```

mod canvas;
mod edge;
mod error;
mod layout;
mod node;
mod position;
mod viewport;

pub use canvas::*;
pub use edge::*;
pub use error::*;
pub use layout::*;
pub use node::*;
pub use position::*;
pub use viewport::*;

/// Re-export common types
pub mod prelude {
    pub use crate::{
        FlowCanvas, FlowCanvasConfig,
        Node, NodeType, NodeData,
        Edge, EdgeType, EdgeData,
        Position, Dimensions, Rect,
        Viewport, ViewportTransform,
        LayoutDirection, LayoutConfig,
        FlowError, FlowResult,
    };
}
