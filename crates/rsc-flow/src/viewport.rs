//! Viewport and transform types.

use serde::{Deserialize, Serialize};

use crate::position::Position;

/// Viewport state for the canvas.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Viewport {
    /// Current transform.
    pub transform: ViewportTransform,
    /// Minimum zoom level.
    #[serde(default = "default_min_zoom")]
    pub min_zoom: f64,
    /// Maximum zoom level.
    #[serde(default = "default_max_zoom")]
    pub max_zoom: f64,
    /// Whether panning is enabled.
    #[serde(default = "default_true")]
    pub pan_enabled: bool,
    /// Whether zooming is enabled.
    #[serde(default = "default_true")]
    pub zoom_enabled: bool,
}

fn default_min_zoom() -> f64 {
    0.1
}

fn default_max_zoom() -> f64 {
    4.0
}

fn default_true() -> bool {
    true
}

impl Default for Viewport {
    fn default() -> Self {
        Self {
            transform: ViewportTransform::default(),
            min_zoom: default_min_zoom(),
            max_zoom: default_max_zoom(),
            pan_enabled: true,
            zoom_enabled: true,
        }
    }
}

impl Viewport {
    /// Zoom in by a factor.
    pub fn zoom_in(&mut self, factor: f64) {
        let new_zoom = (self.transform.zoom * factor).min(self.max_zoom);
        self.transform.zoom = new_zoom;
    }

    /// Zoom out by a factor.
    pub fn zoom_out(&mut self, factor: f64) {
        let new_zoom = (self.transform.zoom / factor).max(self.min_zoom);
        self.transform.zoom = new_zoom;
    }

    /// Pan by delta.
    pub fn pan(&mut self, dx: f64, dy: f64) {
        if self.pan_enabled {
            self.transform.x += dx;
            self.transform.y += dy;
        }
    }

    /// Reset to default transform.
    pub fn reset(&mut self) {
        self.transform = ViewportTransform::default();
    }

    /// Fit to bounds.
    pub fn fit_to_bounds(&mut self, bounds: &crate::position::Rect, padding: f64, canvas_size: &crate::position::Dimensions) {
        let scale_x = (canvas_size.width - padding * 2.0) / bounds.dimensions.width;
        let scale_y = (canvas_size.height - padding * 2.0) / bounds.dimensions.height;
        let zoom = scale_x.min(scale_y).min(self.max_zoom).max(self.min_zoom);

        let center = bounds.center();
        self.transform = ViewportTransform {
            x: canvas_size.width / 2.0 - center.x * zoom,
            y: canvas_size.height / 2.0 - center.y * zoom,
            zoom,
        };
    }

    /// Convert screen coordinates to canvas coordinates.
    pub fn screen_to_canvas(&self, screen_pos: Position) -> Position {
        Position {
            x: (screen_pos.x - self.transform.x) / self.transform.zoom,
            y: (screen_pos.y - self.transform.y) / self.transform.zoom,
        }
    }

    /// Convert canvas coordinates to screen coordinates.
    pub fn canvas_to_screen(&self, canvas_pos: Position) -> Position {
        Position {
            x: canvas_pos.x * self.transform.zoom + self.transform.x,
            y: canvas_pos.y * self.transform.zoom + self.transform.y,
        }
    }
}

/// Viewport transform (pan and zoom).
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct ViewportTransform {
    /// X translation.
    pub x: f64,
    /// Y translation.
    pub y: f64,
    /// Zoom level.
    pub zoom: f64,
}

impl Default for ViewportTransform {
    fn default() -> Self {
        Self {
            x: 0.0,
            y: 0.0,
            zoom: 1.0,
        }
    }
}

impl ViewportTransform {
    pub fn new(x: f64, y: f64, zoom: f64) -> Self {
        Self { x, y, zoom }
    }

    /// Get CSS transform string.
    pub fn to_css(&self) -> String {
        format!("translate({:.2}px, {:.2}px) scale({:.4})", self.x, self.y, self.zoom)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_viewport_zoom() {
        let mut viewport = Viewport::default();
        viewport.zoom_in(1.5);
        assert!((viewport.transform.zoom - 1.5).abs() < 0.001);
    }

    #[test]
    fn test_coordinate_conversion() {
        let mut viewport = Viewport::default();
        viewport.transform = ViewportTransform::new(100.0, 50.0, 2.0);

        let screen = Position::new(200.0, 150.0);
        let canvas = viewport.screen_to_canvas(screen);
        let back = viewport.canvas_to_screen(canvas);

        assert!((back.x - screen.x).abs() < 0.001);
        assert!((back.y - screen.y).abs() < 0.001);
    }
}
