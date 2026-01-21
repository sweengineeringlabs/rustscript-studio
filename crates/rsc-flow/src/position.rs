//! Position and geometry types.

use serde::{Deserialize, Serialize};

/// 2D position.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize, Default)]
pub struct Position {
    pub x: f64,
    pub y: f64,
}

impl Position {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    pub fn zero() -> Self {
        Self::default()
    }

    pub fn distance_to(&self, other: &Position) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        (dx * dx + dy * dy).sqrt()
    }

    pub fn lerp(&self, other: &Position, t: f64) -> Position {
        Position {
            x: self.x + (other.x - self.x) * t,
            y: self.y + (other.y - self.y) * t,
        }
    }
}

/// Dimensions (width/height).
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize, Default)]
pub struct Dimensions {
    pub width: f64,
    pub height: f64,
}

impl Dimensions {
    pub fn new(width: f64, height: f64) -> Self {
        Self { width, height }
    }

    pub fn square(size: f64) -> Self {
        Self { width: size, height: size }
    }
}

/// Rectangle with position and dimensions.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize, Default)]
pub struct Rect {
    pub position: Position,
    pub dimensions: Dimensions,
}

impl Rect {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self {
            position: Position::new(x, y),
            dimensions: Dimensions::new(width, height),
        }
    }

    pub fn from_center(center: Position, dimensions: Dimensions) -> Self {
        Self {
            position: Position::new(
                center.x - dimensions.width / 2.0,
                center.y - dimensions.height / 2.0,
            ),
            dimensions,
        }
    }

    pub fn center(&self) -> Position {
        Position::new(
            self.position.x + self.dimensions.width / 2.0,
            self.position.y + self.dimensions.height / 2.0,
        )
    }

    pub fn contains(&self, point: &Position) -> bool {
        point.x >= self.position.x
            && point.x <= self.position.x + self.dimensions.width
            && point.y >= self.position.y
            && point.y <= self.position.y + self.dimensions.height
    }

    pub fn intersects(&self, other: &Rect) -> bool {
        self.position.x < other.position.x + other.dimensions.width
            && self.position.x + self.dimensions.width > other.position.x
            && self.position.y < other.position.y + other.dimensions.height
            && self.position.y + self.dimensions.height > other.position.y
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_position_distance() {
        let a = Position::new(0.0, 0.0);
        let b = Position::new(3.0, 4.0);
        assert!((a.distance_to(&b) - 5.0).abs() < 0.001);
    }

    #[test]
    fn test_rect_contains() {
        let rect = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(rect.contains(&Position::new(50.0, 50.0)));
        assert!(!rect.contains(&Position::new(150.0, 50.0)));
    }
}
