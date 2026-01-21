//! Collision detection strategies.

use crate::context::Rect;

/// Collision detection strategy.
#[derive(Debug, Clone, Copy, Default)]
pub enum CollisionStrategy {
    /// Rectangle intersection.
    #[default]
    RectIntersection,
    /// Closest center point.
    ClosestCenter,
    /// Closest corners.
    ClosestCorners,
    /// Pointer within bounds.
    PointerWithin,
}

/// Collision detection result.
#[derive(Debug, Clone)]
pub struct Collision {
    /// ID of the colliding element.
    pub id: String,
    /// Collision ratio (0.0 to 1.0).
    pub ratio: f64,
}

/// Collision detection utilities.
pub struct CollisionDetection;

impl CollisionDetection {
    /// Detect collisions using the specified strategy.
    pub fn detect(
        active_rect: &Rect,
        droppable_rects: &[(String, Rect)],
        strategy: CollisionStrategy,
        pointer: Option<(f64, f64)>,
    ) -> Vec<Collision> {
        match strategy {
            CollisionStrategy::RectIntersection => {
                Self::rect_intersection(active_rect, droppable_rects)
            }
            CollisionStrategy::ClosestCenter => {
                Self::closest_center(active_rect, droppable_rects)
            }
            CollisionStrategy::ClosestCorners => {
                Self::closest_corners(active_rect, droppable_rects)
            }
            CollisionStrategy::PointerWithin => {
                if let Some((px, py)) = pointer {
                    Self::pointer_within(px, py, droppable_rects)
                } else {
                    Vec::new()
                }
            }
        }
    }

    /// Find droppables that intersect with the active rect.
    fn rect_intersection(active: &Rect, droppables: &[(String, Rect)]) -> Vec<Collision> {
        droppables
            .iter()
            .filter_map(|(id, rect)| {
                if active.intersects(rect) {
                    let intersection = Self::intersection_area(active, rect);
                    let ratio = intersection / (active.width * active.height);
                    Some(Collision {
                        id: id.clone(),
                        ratio,
                    })
                } else {
                    None
                }
            })
            .collect()
    }

    /// Find the droppable with the closest center.
    fn closest_center(active: &Rect, droppables: &[(String, Rect)]) -> Vec<Collision> {
        let (ax, ay) = active.center();
        let mut collisions: Vec<(String, f64)> = droppables
            .iter()
            .map(|(id, rect)| {
                let (cx, cy) = rect.center();
                let distance = ((ax - cx).powi(2) + (ay - cy).powi(2)).sqrt();
                (id.clone(), distance)
            })
            .collect();

        collisions.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap());

        collisions
            .into_iter()
            .take(1)
            .map(|(id, distance)| Collision {
                id,
                ratio: 1.0 / (1.0 + distance / 100.0), // Normalize to 0-1
            })
            .collect()
    }

    /// Find droppables by closest corners.
    fn closest_corners(active: &Rect, droppables: &[(String, Rect)]) -> Vec<Collision> {
        let active_corners = Self::corners(active);

        let mut collisions: Vec<(String, f64)> = droppables
            .iter()
            .map(|(id, rect)| {
                let drop_corners = Self::corners(rect);
                let min_distance = active_corners
                    .iter()
                    .flat_map(|ac| {
                        drop_corners
                            .iter()
                            .map(|dc| ((ac.0 - dc.0).powi(2) + (ac.1 - dc.1).powi(2)).sqrt())
                    })
                    .fold(f64::MAX, f64::min);
                (id.clone(), min_distance)
            })
            .collect();

        collisions.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap());

        collisions
            .into_iter()
            .take(1)
            .map(|(id, distance)| Collision {
                id,
                ratio: 1.0 / (1.0 + distance / 100.0),
            })
            .collect()
    }

    /// Find droppables that contain the pointer.
    fn pointer_within(px: f64, py: f64, droppables: &[(String, Rect)]) -> Vec<Collision> {
        droppables
            .iter()
            .filter_map(|(id, rect)| {
                if rect.contains_point(px, py) {
                    Some(Collision {
                        id: id.clone(),
                        ratio: 1.0,
                    })
                } else {
                    None
                }
            })
            .collect()
    }

    fn intersection_area(a: &Rect, b: &Rect) -> f64 {
        let x_overlap = (a.x + a.width).min(b.x + b.width) - a.x.max(b.x);
        let y_overlap = (a.y + a.height).min(b.y + b.height) - a.y.max(b.y);

        if x_overlap > 0.0 && y_overlap > 0.0 {
            x_overlap * y_overlap
        } else {
            0.0
        }
    }

    fn corners(rect: &Rect) -> [(f64, f64); 4] {
        [
            (rect.x, rect.y),
            (rect.x + rect.width, rect.y),
            (rect.x, rect.y + rect.height),
            (rect.x + rect.width, rect.y + rect.height),
        ]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rect_intersection_collision() {
        let active = Rect::new(50.0, 50.0, 100.0, 100.0);
        let droppables = vec![
            ("a".to_string(), Rect::new(0.0, 0.0, 100.0, 100.0)),   // Overlaps
            ("b".to_string(), Rect::new(200.0, 200.0, 100.0, 100.0)), // No overlap
        ];

        let collisions = CollisionDetection::detect(
            &active,
            &droppables,
            CollisionStrategy::RectIntersection,
            None,
        );

        assert_eq!(collisions.len(), 1);
        assert_eq!(collisions[0].id, "a");
    }
}
