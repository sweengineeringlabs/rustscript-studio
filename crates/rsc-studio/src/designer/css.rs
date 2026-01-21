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

/// Component state variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
pub enum StateVariant {
    #[default]
    Default,
    Hover,
    Active,
    Focus,
    Disabled,
}

impl StateVariant {
    pub fn all() -> &'static [StateVariant] {
        &[
            StateVariant::Default,
            StateVariant::Hover,
            StateVariant::Active,
            StateVariant::Focus,
            StateVariant::Disabled,
        ]
    }

    pub fn label(&self) -> &'static str {
        match self {
            StateVariant::Default => "Default",
            StateVariant::Hover => "Hover",
            StateVariant::Active => "Active",
            StateVariant::Focus => "Focus",
            StateVariant::Disabled => "Disabled",
        }
    }

    pub fn css_selector(&self) -> &'static str {
        match self {
            StateVariant::Default => "",
            StateVariant::Hover => ":hover",
            StateVariant::Active => ":active",
            StateVariant::Focus => ":focus",
            StateVariant::Disabled => ":disabled",
        }
    }
}

/// Responsive breakpoint.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
pub enum Breakpoint {
    #[default]
    Base,
    Sm,  // 640px
    Md,  // 768px
    Lg,  // 1024px
    Xl,  // 1280px
    Xxl, // 1536px
}

impl Breakpoint {
    pub fn all() -> &'static [Breakpoint] {
        &[
            Breakpoint::Base,
            Breakpoint::Sm,
            Breakpoint::Md,
            Breakpoint::Lg,
            Breakpoint::Xl,
            Breakpoint::Xxl,
        ]
    }

    pub fn label(&self) -> &'static str {
        match self {
            Breakpoint::Base => "Base",
            Breakpoint::Sm => "SM",
            Breakpoint::Md => "MD",
            Breakpoint::Lg => "LG",
            Breakpoint::Xl => "XL",
            Breakpoint::Xxl => "2XL",
        }
    }

    pub fn min_width(&self) -> Option<u32> {
        match self {
            Breakpoint::Base => None,
            Breakpoint::Sm => Some(640),
            Breakpoint::Md => Some(768),
            Breakpoint::Lg => Some(1024),
            Breakpoint::Xl => Some(1280),
            Breakpoint::Xxl => Some(1536),
        }
    }
}

/// Component style definition.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ComponentStyle {
    /// Base styles (applied to all states and breakpoints).
    #[serde(default)]
    pub base: StyleProperties,
    /// State-specific overrides.
    #[serde(default)]
    pub states: IndexMap<StateVariant, StyleProperties>,
    /// Breakpoint-specific overrides.
    #[serde(default)]
    pub breakpoints: IndexMap<Breakpoint, StyleProperties>,
}

/// CSS style properties.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct StyleProperties {
    // Layout
    #[serde(skip_serializing_if = "Option::is_none")]
    pub display: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub flex_direction: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub align_items: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub justify_content: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gap: Option<String>,

    // Sizing
    #[serde(skip_serializing_if = "Option::is_none")]
    pub width: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub height: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub min_width: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub min_height: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_width: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_height: Option<String>,

    // Spacing
    #[serde(skip_serializing_if = "Option::is_none")]
    pub padding: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub padding_top: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub padding_right: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub padding_bottom: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub padding_left: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub margin: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub margin_top: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub margin_right: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub margin_bottom: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub margin_left: Option<String>,

    // Colors
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub background: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub background_color: Option<String>,

    // Border
    #[serde(skip_serializing_if = "Option::is_none")]
    pub border: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub border_width: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub border_style: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub border_color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub border_radius: Option<String>,

    // Shadow
    #[serde(skip_serializing_if = "Option::is_none")]
    pub box_shadow: Option<String>,

    // Typography
    #[serde(skip_serializing_if = "Option::is_none")]
    pub font_family: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub font_size: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub font_weight: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub line_height: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text_align: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text_decoration: Option<String>,

    // Effects
    #[serde(skip_serializing_if = "Option::is_none")]
    pub opacity: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cursor: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub transition: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub transform: Option<String>,

    // Position
    #[serde(skip_serializing_if = "Option::is_none")]
    pub position: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub right: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bottom: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub left: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub z_index: Option<String>,

    // Overflow
    #[serde(skip_serializing_if = "Option::is_none")]
    pub overflow: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub overflow_x: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub overflow_y: Option<String>,
}

impl StyleProperties {
    /// Convert to CSS string.
    pub fn to_css(&self) -> String {
        let mut css = String::new();

        macro_rules! add_prop {
            ($prop:ident, $css_name:expr) => {
                if let Some(v) = &self.$prop {
                    css.push_str(&format!("  {}: {};\n", $css_name, v));
                }
            };
        }

        // Layout
        add_prop!(display, "display");
        add_prop!(flex_direction, "flex-direction");
        add_prop!(align_items, "align-items");
        add_prop!(justify_content, "justify-content");
        add_prop!(gap, "gap");

        // Sizing
        add_prop!(width, "width");
        add_prop!(height, "height");
        add_prop!(min_width, "min-width");
        add_prop!(min_height, "min-height");
        add_prop!(max_width, "max-width");
        add_prop!(max_height, "max-height");

        // Spacing
        add_prop!(padding, "padding");
        add_prop!(padding_top, "padding-top");
        add_prop!(padding_right, "padding-right");
        add_prop!(padding_bottom, "padding-bottom");
        add_prop!(padding_left, "padding-left");
        add_prop!(margin, "margin");
        add_prop!(margin_top, "margin-top");
        add_prop!(margin_right, "margin-right");
        add_prop!(margin_bottom, "margin-bottom");
        add_prop!(margin_left, "margin-left");

        // Colors
        add_prop!(color, "color");
        add_prop!(background, "background");
        add_prop!(background_color, "background-color");

        // Border
        add_prop!(border, "border");
        add_prop!(border_width, "border-width");
        add_prop!(border_style, "border-style");
        add_prop!(border_color, "border-color");
        add_prop!(border_radius, "border-radius");

        // Shadow
        add_prop!(box_shadow, "box-shadow");

        // Typography
        add_prop!(font_family, "font-family");
        add_prop!(font_size, "font-size");
        add_prop!(font_weight, "font-weight");
        add_prop!(line_height, "line-height");
        add_prop!(text_align, "text-align");
        add_prop!(text_decoration, "text-decoration");

        // Effects
        add_prop!(opacity, "opacity");
        add_prop!(cursor, "cursor");
        add_prop!(transition, "transition");
        add_prop!(transform, "transform");

        // Position
        add_prop!(position, "position");
        add_prop!(top, "top");
        add_prop!(right, "right");
        add_prop!(bottom, "bottom");
        add_prop!(left, "left");
        add_prop!(z_index, "z-index");

        // Overflow
        add_prop!(overflow, "overflow");
        add_prop!(overflow_x, "overflow-x");
        add_prop!(overflow_y, "overflow-y");

        css
    }

    /// Get a property value by name.
    pub fn get(&self, name: &str) -> Option<&String> {
        match name {
            "display" => self.display.as_ref(),
            "flex-direction" => self.flex_direction.as_ref(),
            "align-items" => self.align_items.as_ref(),
            "justify-content" => self.justify_content.as_ref(),
            "gap" => self.gap.as_ref(),
            "width" => self.width.as_ref(),
            "height" => self.height.as_ref(),
            "min-width" => self.min_width.as_ref(),
            "min-height" => self.min_height.as_ref(),
            "max-width" => self.max_width.as_ref(),
            "max-height" => self.max_height.as_ref(),
            "padding" => self.padding.as_ref(),
            "padding-top" => self.padding_top.as_ref(),
            "padding-right" => self.padding_right.as_ref(),
            "padding-bottom" => self.padding_bottom.as_ref(),
            "padding-left" => self.padding_left.as_ref(),
            "margin" => self.margin.as_ref(),
            "margin-top" => self.margin_top.as_ref(),
            "margin-right" => self.margin_right.as_ref(),
            "margin-bottom" => self.margin_bottom.as_ref(),
            "margin-left" => self.margin_left.as_ref(),
            "color" => self.color.as_ref(),
            "background" => self.background.as_ref(),
            "background-color" => self.background_color.as_ref(),
            "border" => self.border.as_ref(),
            "border-width" => self.border_width.as_ref(),
            "border-style" => self.border_style.as_ref(),
            "border-color" => self.border_color.as_ref(),
            "border-radius" => self.border_radius.as_ref(),
            "box-shadow" => self.box_shadow.as_ref(),
            "font-family" => self.font_family.as_ref(),
            "font-size" => self.font_size.as_ref(),
            "font-weight" => self.font_weight.as_ref(),
            "line-height" => self.line_height.as_ref(),
            "text-align" => self.text_align.as_ref(),
            "text-decoration" => self.text_decoration.as_ref(),
            "opacity" => self.opacity.as_ref(),
            "cursor" => self.cursor.as_ref(),
            "transition" => self.transition.as_ref(),
            "transform" => self.transform.as_ref(),
            "position" => self.position.as_ref(),
            "top" => self.top.as_ref(),
            "right" => self.right.as_ref(),
            "bottom" => self.bottom.as_ref(),
            "left" => self.left.as_ref(),
            "z-index" => self.z_index.as_ref(),
            "overflow" => self.overflow.as_ref(),
            "overflow-x" => self.overflow_x.as_ref(),
            "overflow-y" => self.overflow_y.as_ref(),
            _ => None,
        }
    }

    /// Set a property value by name.
    pub fn set(&mut self, name: &str, value: Option<String>) {
        match name {
            "display" => self.display = value,
            "flex-direction" => self.flex_direction = value,
            "align-items" => self.align_items = value,
            "justify-content" => self.justify_content = value,
            "gap" => self.gap = value,
            "width" => self.width = value,
            "height" => self.height = value,
            "min-width" => self.min_width = value,
            "min-height" => self.min_height = value,
            "max-width" => self.max_width = value,
            "max-height" => self.max_height = value,
            "padding" => self.padding = value,
            "padding-top" => self.padding_top = value,
            "padding-right" => self.padding_right = value,
            "padding-bottom" => self.padding_bottom = value,
            "padding-left" => self.padding_left = value,
            "margin" => self.margin = value,
            "margin-top" => self.margin_top = value,
            "margin-right" => self.margin_right = value,
            "margin-bottom" => self.margin_bottom = value,
            "margin-left" => self.margin_left = value,
            "color" => self.color = value,
            "background" => self.background = value,
            "background-color" => self.background_color = value,
            "border" => self.border = value,
            "border-width" => self.border_width = value,
            "border-style" => self.border_style = value,
            "border-color" => self.border_color = value,
            "border-radius" => self.border_radius = value,
            "box-shadow" => self.box_shadow = value,
            "font-family" => self.font_family = value,
            "font-size" => self.font_size = value,
            "font-weight" => self.font_weight = value,
            "line-height" => self.line_height = value,
            "text-align" => self.text_align = value,
            "text-decoration" => self.text_decoration = value,
            "opacity" => self.opacity = value,
            "cursor" => self.cursor = value,
            "transition" => self.transition = value,
            "transform" => self.transform = value,
            "position" => self.position = value,
            "top" => self.top = value,
            "right" => self.right = value,
            "bottom" => self.bottom = value,
            "left" => self.left = value,
            "z-index" => self.z_index = value,
            "overflow" => self.overflow = value,
            "overflow-x" => self.overflow_x = value,
            "overflow-y" => self.overflow_y = value,
            _ => {}
        }
    }
}

/// Built-in component types.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum ComponentType {
    Button,
    Input,
    Card,
    Modal,
    Badge,
    Alert,
    Tooltip,
    Dropdown,
    Tabs,
    Panel,
}

impl ComponentType {
    pub fn all() -> &'static [ComponentType] {
        &[
            ComponentType::Button,
            ComponentType::Input,
            ComponentType::Card,
            ComponentType::Modal,
            ComponentType::Badge,
            ComponentType::Alert,
            ComponentType::Tooltip,
            ComponentType::Dropdown,
            ComponentType::Tabs,
            ComponentType::Panel,
        ]
    }

    pub fn label(&self) -> &'static str {
        match self {
            ComponentType::Button => "Button",
            ComponentType::Input => "Input",
            ComponentType::Card => "Card",
            ComponentType::Modal => "Modal",
            ComponentType::Badge => "Badge",
            ComponentType::Alert => "Alert",
            ComponentType::Tooltip => "Tooltip",
            ComponentType::Dropdown => "Dropdown",
            ComponentType::Tabs => "Tabs",
            ComponentType::Panel => "Panel",
        }
    }

    pub fn icon(&self) -> &'static str {
        match self {
            ComponentType::Button => "square",
            ComponentType::Input => "edit-3",
            ComponentType::Card => "credit-card",
            ComponentType::Modal => "maximize-2",
            ComponentType::Badge => "tag",
            ComponentType::Alert => "alert-circle",
            ComponentType::Tooltip => "message-circle",
            ComponentType::Dropdown => "chevron-down",
            ComponentType::Tabs => "folder",
            ComponentType::Panel => "sidebar",
        }
    }
}

/// Component styles collection.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ComponentStyles {
    #[serde(default)]
    pub styles: IndexMap<String, ComponentStyle>,
}

impl ComponentStyles {
    pub fn new() -> Self {
        Self::default()
    }

    /// Get style for a component.
    pub fn get(&self, component: &str) -> Option<&ComponentStyle> {
        self.styles.get(component)
    }

    /// Get mutable style for a component.
    pub fn get_mut(&mut self, component: &str) -> Option<&mut ComponentStyle> {
        self.styles.get_mut(component)
    }

    /// Set style for a component.
    pub fn set(&mut self, component: String, style: ComponentStyle) {
        self.styles.insert(component, style);
    }

    /// Generate CSS for all component styles.
    pub fn generate_css(&self) -> String {
        let mut css = String::new();

        for (name, style) in &self.styles {
            // Base styles
            let base_css = style.base.to_css();
            if !base_css.is_empty() {
                css.push_str(&format!(".{} {{\n{}}}\n\n", name, base_css));
            }

            // State variants
            for (state, props) in &style.states {
                let state_css = props.to_css();
                if !state_css.is_empty() {
                    css.push_str(&format!(
                        ".{}{} {{\n{}}}\n\n",
                        name,
                        state.css_selector(),
                        state_css
                    ));
                }
            }

            // Breakpoint overrides
            for (breakpoint, props) in &style.breakpoints {
                let bp_css = props.to_css();
                if !bp_css.is_empty() {
                    if let Some(min_width) = breakpoint.min_width() {
                        css.push_str(&format!(
                            "@media (min-width: {}px) {{\n  .{} {{\n{}}}\n}}\n\n",
                            min_width,
                            name,
                            bp_css.lines().map(|l| format!("  {}", l)).collect::<Vec<_>>().join("\n")
                        ));
                    }
                }
            }
        }

        css
    }
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
