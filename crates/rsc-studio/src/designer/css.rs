//! Visual CSS designer.
//! Allows visual editing of design tokens and styles.

use indexmap::IndexMap;
use serde::{Deserialize, Serialize};

/// CSS Designer state.
#[derive(Debug, Clone, Default)]
pub struct CssDesigner {
    /// Design tokens being edited.
    pub tokens: DesignTokens,
    /// Selected token category.
    pub selected_category: TokenCategory,
    /// Selected token path (e.g., "colors.primary").
    pub selected_token: Option<String>,
    /// Preview mode.
    pub preview_mode: PreviewMode,
}

impl CssDesigner {
    pub fn new() -> Self {
        Self::default()
    }

    /// Load tokens from a design file.
    pub fn load_tokens(&mut self, tokens: DesignTokens) {
        self.tokens = tokens;
    }

    /// Get a token value.
    pub fn get_token(&self, path: &str) -> Option<&TokenValue> {
        let parts: Vec<&str> = path.split('.').collect();
        if parts.len() < 2 {
            return None;
        }

        match parts[0] {
            "colors" => self.tokens.colors.get(parts[1]).map(|v| v),
            "spacing" => self.tokens.spacing.get(parts[1]),
            "radius" => self.tokens.radius.get(parts[1]),
            "shadows" => self.tokens.shadows.get(parts[1]),
            "typography" => {
                if parts.len() < 3 {
                    return None;
                }
                match parts[1] {
                    "fonts" => self.tokens.typography.fonts.get(parts[2]),
                    "sizes" => self.tokens.typography.sizes.get(parts[2]),
                    "weights" => self.tokens.typography.weights.get(parts[2]),
                    _ => None,
                }
            }
            _ => None,
        }
    }

    /// Set a token value.
    pub fn set_token(&mut self, path: &str, value: TokenValue) {
        let parts: Vec<&str> = path.split('.').collect();
        if parts.len() < 2 {
            return;
        }

        match parts[0] {
            "colors" => {
                self.tokens.colors.insert(parts[1].to_string(), value);
            }
            "spacing" => {
                self.tokens.spacing.insert(parts[1].to_string(), value);
            }
            "radius" => {
                self.tokens.radius.insert(parts[1].to_string(), value);
            }
            "shadows" => {
                self.tokens.shadows.insert(parts[1].to_string(), value);
            }
            _ => {}
        }
    }

    /// Generate CSS variables from tokens.
    pub fn generate_css(&self) -> String {
        let mut css = String::from(":root {\n");

        // Colors
        for (name, value) in &self.tokens.colors {
            if let TokenValue::Simple(v) = value {
                css.push_str(&format!("  --color-{}: {};\n", name, v));
            }
        }

        // Spacing
        for (name, value) in &self.tokens.spacing {
            if let TokenValue::Simple(v) = value {
                css.push_str(&format!("  --spacing-{}: {};\n", name, v));
            }
        }

        // Radius
        for (name, value) in &self.tokens.radius {
            if let TokenValue::Simple(v) = value {
                css.push_str(&format!("  --radius-{}: {};\n", name, v));
            }
        }

        // Shadows
        for (name, value) in &self.tokens.shadows {
            if let TokenValue::Simple(v) = value {
                css.push_str(&format!("  --shadow-{}: {};\n", name, v));
            }
        }

        css.push_str("}\n");
        css
    }
}

/// Design tokens structure.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DesignTokens {
    #[serde(default)]
    pub colors: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub spacing: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub radius: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub shadows: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub typography: TypographyTokens,
    #[serde(default)]
    pub transitions: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub z_index: IndexMap<String, TokenValue>,
}

/// Typography tokens.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct TypographyTokens {
    #[serde(default)]
    pub fonts: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub sizes: IndexMap<String, TokenValue>,
    #[serde(default)]
    pub weights: IndexMap<String, TokenValue>,
}

/// Token value (simple or structured).
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum TokenValue {
    Simple(String),
    Adaptive { light: String, dark: String },
    Scale(IndexMap<String, String>),
}

impl Default for TokenValue {
    fn default() -> Self {
        Self::Simple(String::new())
    }
}

/// Token category for UI navigation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum TokenCategory {
    #[default]
    Colors,
    Spacing,
    Radius,
    Shadows,
    Typography,
    Transitions,
    ZIndex,
}

/// Preview mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PreviewMode {
    #[default]
    Light,
    Dark,
    Both,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_css_generation() {
        let mut designer = CssDesigner::new();
        designer.tokens.colors.insert(
            "primary".to_string(),
            TokenValue::Simple("#3b82f6".to_string()),
        );
        designer.tokens.spacing.insert(
            "md".to_string(),
            TokenValue::Simple("1rem".to_string()),
        );

        let css = designer.generate_css();
        assert!(css.contains("--color-primary: #3b82f6"));
        assert!(css.contains("--spacing-md: 1rem"));
    }
}
