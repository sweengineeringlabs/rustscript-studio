//! Studio configuration.

use serde::{Deserialize, Serialize};

/// Studio configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StudioConfig {
    /// Project name.
    pub name: String,
    /// Version.
    #[serde(default = "default_version")]
    pub version: String,
    /// Theme configuration.
    #[serde(default)]
    pub theme: ThemeRef,
    /// Features enabled.
    #[serde(default)]
    pub features: Features,
}

fn default_version() -> String {
    "1.0.0".to_string()
}

impl Default for StudioConfig {
    fn default() -> Self {
        Self {
            name: "Untitled Project".to_string(),
            version: default_version(),
            theme: ThemeRef::default(),
            features: Features::default(),
        }
    }
}

/// Theme reference.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ThemeRef {
    /// Path to design tokens file.
    #[serde(default)]
    pub tokens: Option<String>,
    /// Path to styles file.
    #[serde(default)]
    pub styles: Option<String>,
    /// Inline theme overrides.
    #[serde(default)]
    pub overrides: ThemeOverrides,
}

/// Theme overrides.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ThemeOverrides {
    /// Primary color.
    #[serde(default)]
    pub primary: Option<String>,
    /// Background color.
    #[serde(default)]
    pub background: Option<String>,
    /// Text color.
    #[serde(default)]
    pub text: Option<String>,
    /// Accent color.
    #[serde(default)]
    pub accent: Option<String>,
}

/// Feature flags.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Features {
    /// Enable navigation designer.
    #[serde(default = "default_true")]
    pub navigation_designer: bool,
    /// Enable CSS designer.
    #[serde(default = "default_true")]
    pub css_designer: bool,
    /// Enable component scaffolding.
    #[serde(default = "default_true")]
    pub component_scaffold: bool,
    /// Enable live preview.
    #[serde(default = "default_true")]
    pub live_preview: bool,
    /// Enable YAML export.
    #[serde(default = "default_true")]
    pub yaml_export: bool,
    /// Enable code generation.
    #[serde(default = "default_true")]
    pub codegen: bool,
}

fn default_true() -> bool {
    true
}

impl Default for Features {
    fn default() -> Self {
        Self {
            navigation_designer: true,
            css_designer: true,
            component_scaffold: true,
            live_preview: true,
            yaml_export: true,
            codegen: true,
        }
    }
}
