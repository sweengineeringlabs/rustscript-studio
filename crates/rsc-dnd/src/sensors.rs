//! Input sensors for drag detection.

/// Sensor trait for detecting drag start.
pub trait Sensor {
    /// Check if drag should start.
    fn should_start(&self, event: &SensorEvent) -> bool;
    /// Get the current pointer position.
    fn get_position(&self, event: &SensorEvent) -> Option<(f64, f64)>;
}

/// Sensor event data.
#[derive(Debug, Clone)]
pub struct SensorEvent {
    pub event_type: SensorEventType,
    pub x: f64,
    pub y: f64,
    pub button: Option<u8>,
    pub key: Option<String>,
    pub modifiers: Modifiers,
}

/// Sensor event type.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SensorEventType {
    PointerDown,
    PointerMove,
    PointerUp,
    KeyDown,
    KeyUp,
}

/// Keyboard modifiers.
#[derive(Debug, Clone, Copy, Default)]
pub struct Modifiers {
    pub ctrl: bool,
    pub shift: bool,
    pub alt: bool,
    pub meta: bool,
}

/// Pointer sensor configuration.
#[derive(Debug, Clone)]
pub struct PointerSensor {
    /// Activation constraint (minimum distance to start drag).
    pub activation_constraint: ActivationConstraint,
}

impl Default for PointerSensor {
    fn default() -> Self {
        Self {
            activation_constraint: ActivationConstraint::Distance(10.0),
        }
    }
}

impl Sensor for PointerSensor {
    fn should_start(&self, event: &SensorEvent) -> bool {
        matches!(event.event_type, SensorEventType::PointerDown)
            && event.button == Some(0) // Left mouse button
    }

    fn get_position(&self, event: &SensorEvent) -> Option<(f64, f64)> {
        Some((event.x, event.y))
    }
}

/// Keyboard sensor for accessibility.
#[derive(Debug, Clone, Default)]
pub struct KeyboardSensor {
    /// Keys that trigger drag start.
    pub start_keys: Vec<String>,
    /// Keys that move the dragged item.
    pub move_keys: MoveKeys,
}

impl KeyboardSensor {
    pub fn new() -> Self {
        Self {
            start_keys: vec!["Enter".to_string(), " ".to_string()],
            move_keys: MoveKeys::default(),
        }
    }
}

impl Sensor for KeyboardSensor {
    fn should_start(&self, event: &SensorEvent) -> bool {
        if let (SensorEventType::KeyDown, Some(key)) = (&event.event_type, &event.key) {
            self.start_keys.contains(key)
        } else {
            false
        }
    }

    fn get_position(&self, _event: &SensorEvent) -> Option<(f64, f64)> {
        None // Keyboard doesn't provide position
    }
}

/// Keys for moving items.
#[derive(Debug, Clone)]
pub struct MoveKeys {
    pub up: Vec<String>,
    pub down: Vec<String>,
    pub left: Vec<String>,
    pub right: Vec<String>,
}

impl Default for MoveKeys {
    fn default() -> Self {
        Self {
            up: vec!["ArrowUp".to_string()],
            down: vec!["ArrowDown".to_string()],
            left: vec!["ArrowLeft".to_string()],
            right: vec!["ArrowRight".to_string()],
        }
    }
}

/// Activation constraint for starting drag.
#[derive(Debug, Clone)]
pub enum ActivationConstraint {
    /// Minimum distance before drag starts.
    Distance(f64),
    /// Minimum delay before drag starts.
    Delay(u64),
    /// Both distance and delay.
    DistanceAndDelay { distance: f64, delay: u64 },
}
