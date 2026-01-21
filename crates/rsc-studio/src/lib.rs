//! # rsc-studio
//!
//! Core studio logic for RustScript Studio - a visual IDE for RustScript.
//!
//! ## Features
//!
//! - Navigation flow designer (ported from Flowize)
//! - Visual CSS designer (using rsc-design tokens)
//! - Component scaffolding
//! - Live preview
//!
//! ## Architecture
//!
//! ```text
//! ┌─────────────────────────────────────────────────────┐
//! │                   RustScript Studio                  │
//! ├─────────────────────────────────────────────────────┤
//! │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐ │
//! │  │ Nav     │  │ CSS     │  │ Comp    │  │ Preview│ │
//! │  │ Designer│  │ Designer│  │ Scaffold│  │ Panel  │ │
//! │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬───┘ │
//! │       │            │            │            │      │
//! │  ┌────┴────────────┴────────────┴────────────┴───┐ │
//! │  │              Studio Store (Zustand-like)       │ │
//! │  └────────────────────────────────────────────────┘ │
//! │       │            │            │                   │
//! │  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐             │
//! │  │rsc-flow │  │rsc-dnd  │  │rsc-design│             │
//! │  └─────────┘  └─────────┘  └──────────┘             │
//! └─────────────────────────────────────────────────────┘
//! ```

pub mod config;
pub mod designer;
pub mod entity;
pub mod export;
pub mod store;
pub mod template;

pub use config::*;
pub use entity::*;
pub use store::*;

/// Studio version.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
