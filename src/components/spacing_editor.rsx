//! SpacingEditor component for editing spacing design tokens.

use rsc::prelude::*;

/// Spacing unit type.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpacingUnit {
    Rem,
    Px,
    Em,
}

impl Default for SpacingUnit {
    fn default() -> Self {
        SpacingUnit::Rem
    }
}

impl SpacingUnit {
    pub fn as_str(&self) -> &'static str {
        match self {
            SpacingUnit::Rem => "rem",
            SpacingUnit::Px => "px",
            SpacingUnit::Em => "em",
        }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "rem" => Some(SpacingUnit::Rem),
            "px" => Some(SpacingUnit::Px),
            "em" => Some(SpacingUnit::Em),
            _ => None,
        }
    }
}

/// Parsed spacing value.
#[derive(Debug, Clone, Copy, Default)]
pub struct SpacingValue {
    pub value: f64,
    pub unit: SpacingUnit,
}

impl SpacingValue {
    pub fn new(value: f64, unit: SpacingUnit) -> Self {
        Self { value, unit }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        let s = s.trim();
        if s.is_empty() {
            return None;
        }

        // Find where the number ends and unit begins
        let num_end = s.chars()
            .take_while(|c| c.is_ascii_digit() || *c == '.' || *c == '-')
            .count();

        if num_end == 0 {
            return None;
        }

        let value: f64 = s[..num_end].parse().ok()?;
        let unit_str = s[num_end..].trim();

        let unit = if unit_str.is_empty() {
            SpacingUnit::Rem // Default to rem
        } else {
            SpacingUnit::from_str(unit_str)?
        };

        Some(Self { value, unit })
    }

    pub fn to_string(&self) -> String {
        format!("{}{}", self.value, self.unit.as_str())
    }

    pub fn to_px(&self, base_font_size: f64) -> f64 {
        match self.unit {
            SpacingUnit::Px => self.value,
            SpacingUnit::Rem => self.value * base_font_size,
            SpacingUnit::Em => self.value * base_font_size,
        }
    }
}

/// SpacingEditor component for editing spacing values with visual preview.
///
/// ## Example
/// ```rust,ignore
/// SpacingEditor {
///     value: spacing.get(),
///     label: Some("Padding".to_string()),
///     min: Some(0.0),
///     max: Some(4.0),
///     step: Some(0.25),
///     on_change: Callback::new(move |v| spacing.set(v)),
/// }
/// ```
component SpacingEditor(
    /// Current spacing value (e.g., "1rem", "16px")
    value: String,
    /// Label for the spacing value
    label?: String,
    /// Minimum value
    min?: f64,
    /// Maximum value
    max?: f64,
    /// Step increment
    step?: f64,
    /// Whether to show the visual preview
    show_preview?: bool,
    /// Whether the editor is disabled
    disabled: bool,
    /// Callback when value changes
    on_change?: Callback<String>,
) {
    let min = min.unwrap_or(0.0);
    let max = max.unwrap_or(10.0);
    let step = step.unwrap_or(0.25);
    let show_preview = show_preview.unwrap_or(true);

    let parsed = signal(SpacingValue::from_str(&value).unwrap_or_default());
    let base_font_size = 16.0; // Standard base font size

    // Update internal state when prop changes
    effect(move || {
        if let Some(new_parsed) = SpacingValue::from_str(&value) {
            parsed.set(new_parsed);
        }
    });

    let emit_change = {
        let on_change = on_change.clone();
        move |new_value: SpacingValue| {
            parsed.set(new_value);
            if let Some(ref callback) = on_change {
                callback.call(new_value.to_string());
            }
        }
    };

    let on_slider_input = {
        let emit_change = emit_change.clone();
        let unit = parsed.get().unit;
        move |e: InputEvent| {
            if let Ok(value) = e.value().parse::<f64>() {
                emit_change(SpacingValue::new(value, unit));
            }
        }
    };

    let on_value_input = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Some(new_parsed) = SpacingValue::from_str(&e.value()) {
                emit_change(new_parsed);
            }
        }
    };

    let on_unit_change = {
        let emit_change = emit_change.clone();
        let value = parsed.get().value;
        move |e: InputEvent| {
            if let Some(unit) = SpacingUnit::from_str(&e.value()) {
                emit_change(SpacingValue::new(value, unit));
            }
        }
    };

    let current = parsed.get();
    let preview_px = current.to_px(base_font_size);

    render {
        <div class="spacing-editor" style={styles::container(disabled)}>
            // Label
            @if let Some(ref label) = label {
                <label class="spacing-editor-label" style={styles::label()}>
                    {label.clone()}
                </label>
            }

            // Visual preview
            @if show_preview {
                <div class="spacing-editor-preview" style={styles::preview_container()}>
                    <div class="spacing-editor-preview-bar" style={styles::preview_bar(preview_px)} />
                    <span class="spacing-editor-preview-value" style={styles::preview_value()}>
                        {format!("{}px", preview_px as i32)}
                    </span>
                </div>
            }

            // Slider
            <div class="spacing-editor-slider" style={styles::slider_container()}>
                <input
                    type="range"
                    min={min.to_string()}
                    max={max.to_string()}
                    step={step.to_string()}
                    value={current.value.to_string()}
                    disabled={disabled}
                    style={styles::slider()}
                    on:input={on_slider_input}
                />
            </div>

            // Value input and unit selector
            <div class="spacing-editor-inputs" style={styles::inputs_row()}>
                <input
                    type="number"
                    min={min.to_string()}
                    max={max.to_string()}
                    step={step.to_string()}
                    value={current.value.to_string()}
                    disabled={disabled}
                    style={styles::value_input()}
                    on:input={on_value_input}
                />

                <select
                    disabled={disabled}
                    style={styles::unit_select()}
                    on:change={on_unit_change}
                >
                    <option value="rem" selected={current.unit == SpacingUnit::Rem}>rem</option>
                    <option value="px" selected={current.unit == SpacingUnit::Px}>px</option>
                    <option value="em" selected={current.unit == SpacingUnit::Em}>em</option>
                </select>
            </div>
        </div>
    }
}

mod styles {
    pub fn container(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                display: flex;
                flex-direction: column;
                gap: var(--spacing-sm);
                opacity: {opacity};
            "#,
            opacity = opacity,
        )
    }

    pub fn label() -> &'static str {
        r#"
            font-size: var(--font-size-sm);
            font-weight: var(--font-weight-medium);
            color: var(--color-text-primary);
        "#
    }

    pub fn preview_container() -> &'static str {
        r#"
            display: flex;
            align-items: center;
            gap: var(--spacing-sm);
            padding: var(--spacing-sm);
            background: var(--color-bg-secondary);
            border-radius: var(--radius-md);
        "#
    }

    pub fn preview_bar(width_px: f64) -> String {
        let clamped_width = width_px.clamp(0.0, 160.0);
        format!(
            r#"
                height: 8px;
                width: {width}px;
                min-width: 4px;
                background: var(--color-primary);
                border-radius: var(--radius-sm);
                transition: width var(--transition-fast);
            "#,
            width = clamped_width,
        )
    }

    pub fn preview_value() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            font-family: var(--font-mono);
            color: var(--color-text-secondary);
            min-width: 40px;
        "#
    }

    pub fn slider_container() -> &'static str {
        r#"
            position: relative;
        "#
    }

    pub fn slider() -> &'static str {
        r#"
            width: 100%;
            height: 6px;
            border-radius: var(--radius-sm);
            background: var(--color-bg-tertiary);
            appearance: none;
            -webkit-appearance: none;
            cursor: pointer;
        "#
    }

    pub fn inputs_row() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-xs);
        "#
    }

    pub fn value_input() -> &'static str {
        r#"
            flex: 1;
            height: 32px;
            padding: 0 var(--spacing-sm);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-surface);
            color: var(--color-text-primary);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
            text-align: right;
        "#
    }

    pub fn unit_select() -> &'static str {
        r#"
            width: 64px;
            height: 32px;
            padding: 0 var(--spacing-sm);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-surface);
            color: var(--color-text-primary);
            font-size: var(--font-size-sm);
            cursor: pointer;
        "#
    }
}

/// SpacingScale component for editing multiple spacing tokens at once.
component SpacingScale(
    /// Spacing scale values (e.g., {"xs": "0.25rem", "sm": "0.5rem", ...})
    values: Vec<(String, String)>,
    /// Whether the editor is disabled
    disabled: bool,
    /// Callback when a value changes (token_name, new_value)
    on_change?: Callback<(String, String)>,
) {
    render {
        <div class="spacing-scale" style={scale_styles::container()}>
            @for (name, value) in values.iter() {
                <div class="spacing-scale-item" style={scale_styles::item()}>
                    <SpacingEditor
                        value={value.clone()}
                        label={Some(name.clone())}
                        disabled={disabled}
                        on_change={{
                            let name = name.clone();
                            let on_change = on_change.clone();
                            Callback::new(move |new_value: String| {
                                if let Some(ref callback) = on_change {
                                    callback.call((name.clone(), new_value));
                                }
                            })
                        }}
                    />
                </div>
            }
        </div>
    }
}

mod scale_styles {
    pub fn container() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-lg);
        "#
    }

    pub fn item() -> &'static str {
        r#"
            padding-bottom: var(--spacing-md);
            border-bottom: 1px solid var(--color-border);
        "#
    }
}
