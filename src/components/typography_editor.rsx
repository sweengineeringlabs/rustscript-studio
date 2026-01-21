//! TypographyEditor component for editing typography design tokens.

use rsc::prelude::*;

use super::{Select, SelectOption};

/// Typography value.
#[derive(Debug, Clone, Default)]
pub struct TypographyValue {
    pub font_family: String,
    pub font_size: String,
    pub font_weight: String,
    pub line_height: String,
    pub letter_spacing: String,
}

impl TypographyValue {
    pub fn new() -> Self {
        Self {
            font_family: "Inter, sans-serif".to_string(),
            font_size: "1rem".to_string(),
            font_weight: "400".to_string(),
            line_height: "1.5".to_string(),
            letter_spacing: "0".to_string(),
        }
    }

    pub fn to_css(&self) -> String {
        format!(
            "font-family: {}; font-size: {}; font-weight: {}; line-height: {}; letter-spacing: {};",
            self.font_family, self.font_size, self.font_weight, self.line_height, self.letter_spacing
        )
    }
}

/// Common font weights.
const FONT_WEIGHTS: &[(&str, &str)] = &[
    ("100", "Thin"),
    ("200", "Extra Light"),
    ("300", "Light"),
    ("400", "Regular"),
    ("500", "Medium"),
    ("600", "Semi Bold"),
    ("700", "Bold"),
    ("800", "Extra Bold"),
    ("900", "Black"),
];

/// Common font sizes.
const FONT_SIZES: &[&str] = &[
    "0.75rem", "0.875rem", "1rem", "1.125rem", "1.25rem",
    "1.5rem", "1.875rem", "2.25rem", "3rem", "3.75rem",
];

/// TypographyEditor component for editing font styles.
///
/// ## Example
/// ```rust,ignore
/// <TypographyEditor
///     value={typography.get()}
///     label={"Heading 1".to_string()}
///     font_families={vec!["Inter".to_string(), "Roboto".to_string()]}
///     on_change={Callback::new(move |v| typography.set(v))}
/// />
/// ```
component TypographyEditor(
    /// Current typography values
    value: TypographyValue,
    /// Label for the typography style
    label?: String,
    /// Sample text for preview
    sample_text?: String,
    /// Available font families
    font_families: Vec<String>,
    /// Whether the editor is disabled
    disabled: bool,
    /// Callback when value changes
    on_change?: Callback<TypographyValue>,
) {
    let sample_text = sample_text.unwrap_or("The quick brown fox jumps over the lazy dog".to_string());

    let typo = signal(value.clone());

    let emit_change = |new_typo: TypographyValue| {
        typo.set(new_typo.clone());
        if let Some(ref callback) = on_change {
            callback.call(new_typo);
        }
    };

    let on_family_change = Callback::new(|value: String| {
        let mut t = typo.get();
        t.font_family = value;
        emit_change(t);
    });

    let on_size_change = Callback::new(|value: String| {
        let mut t = typo.get();
        t.font_size = value;
        emit_change(t);
    });

    let on_weight_change = Callback::new(|value: String| {
        let mut t = typo.get();
        t.font_weight = value;
        emit_change(t);
    });

    let current = typo.get();

    // Build font family options
    let font_family_options: Vec<SelectOption> = if font_families.is_empty() {
        vec![
            SelectOption::new("Inter, sans-serif", "Inter"),
            SelectOption::new("Roboto, sans-serif", "Roboto"),
            SelectOption::new("system-ui, sans-serif", "System UI"),
            SelectOption::new("Georgia, serif", "Georgia"),
            SelectOption::new("monospace", "Monospace"),
        ]
    } else {
        font_families.iter()
            .map(|f| SelectOption::new(format!("{}, sans-serif", f), f.clone()))
            .collect()
    };

    let font_size_options: Vec<SelectOption> = FONT_SIZES.iter()
        .map(|s| SelectOption::new(*s, *s))
        .collect();

    let font_weight_options: Vec<SelectOption> = FONT_WEIGHTS.iter()
        .map(|(value, label)| SelectOption::new(*value, format!("{} ({})", label, value)))
        .collect();

    render {
        <div class="typography-editor" style={styles::container(disabled)}>
            // Label
            @if let Some(ref label) = label {
                <label class="typography-editor-label" style={styles::label()}>
                    {label.clone()}
                </label>
            }

            // Preview
            <div class="typography-editor-preview" style={styles::preview_container()}>
                <p style={styles::preview_text(&current)}>
                    {sample_text.clone()}
                </p>
            </div>

            // Font family
            <div class="typography-editor-field" style={styles::field()}>
                <label style={styles::field_label()}>Font Family</label>
                <Select
                    value={current.font_family.clone()}
                    options={font_family_options}
                    disabled={disabled}
                    on_change={on_family_change}
                />
            </div>

            // Font size and weight row
            <div class="typography-editor-row" style={styles::row()}>
                <div class="typography-editor-field" style={styles::field_half()}>
                    <label style={styles::field_label()}>Size</label>
                    <Select
                        value={current.font_size.clone()}
                        options={font_size_options}
                        disabled={disabled}
                        on_change={on_size_change}
                    />
                </div>

                <div class="typography-editor-field" style={styles::field_half()}>
                    <label style={styles::field_label()}>Weight</label>
                    <Select
                        value={current.font_weight.clone()}
                        options={font_weight_options}
                        disabled={disabled}
                        on_change={on_weight_change}
                    />
                </div>
            </div>

            // Line height and letter spacing row
            <div class="typography-editor-row" style={styles::row()}>
                <div class="typography-editor-field" style={styles::field_half()}>
                    <label style={styles::field_label()}>Line Height</label>
                    <input
                        type="text"
                        value={current.line_height.clone()}
                        disabled={disabled}
                        style={styles::text_input()}
                        on:input={|e: InputEvent| {
                            let mut t = typo.get();
                            t.line_height = e.value();
                            emit_change(t);
                        }}
                    />
                </div>

                <div class="typography-editor-field" style={styles::field_half()}>
                    <label style={styles::field_label()}>Letter Spacing</label>
                    <input
                        type="text"
                        value={current.letter_spacing.clone()}
                        disabled={disabled}
                        style={styles::text_input()}
                        on:input={|e: InputEvent| {
                            let mut t = typo.get();
                            t.letter_spacing = e.value();
                            emit_change(t);
                        }}
                    />
                </div>
            </div>

            // CSS output
            <div class="typography-editor-output" style={styles::output()}>
                <code style={styles::code()}>{current.to_css()}</code>
            </div>
        </div>
    }
}

mod styles {
    use super::TypographyValue;

    pub fn container(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                display: flex;
                flex-direction: column;
                gap: var(--spacing-md);
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
            padding: var(--spacing-lg);
            background: var(--color-bg-secondary);
            border-radius: var(--radius-md);
            overflow: hidden;
        "#
    }

    pub fn preview_text(typo: &TypographyValue) -> String {
        format!(
            r#"
                margin: 0;
                font-family: {font_family};
                font-size: {font_size};
                font-weight: {font_weight};
                line-height: {line_height};
                letter-spacing: {letter_spacing};
                color: var(--color-text-primary);
            "#,
            font_family = typo.font_family,
            font_size = typo.font_size,
            font_weight = typo.font_weight,
            line_height = typo.line_height,
            letter_spacing = typo.letter_spacing,
        )
    }

    pub fn field() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
        "#
    }

    pub fn field_half() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-xs);
            flex: 1;
        "#
    }

    pub fn field_label() -> &'static str {
        r#"
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
        "#
    }

    pub fn row() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-sm);
        "#
    }

    pub fn text_input() -> &'static str {
        r#"
            height: 40px;
            padding: 0 var(--spacing-md);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-surface);
            color: var(--color-text-primary);
            font-size: var(--font-size-base);
        "#
    }

    pub fn output() -> &'static str {
        r#"
            padding: var(--spacing-sm);
            background: var(--color-bg-secondary);
            border-radius: var(--radius-md);
            overflow-x: auto;
        "#
    }

    pub fn code() -> &'static str {
        r#"
            font-family: var(--font-mono);
            font-size: var(--font-size-xs);
            color: var(--color-text-secondary);
            white-space: pre-wrap;
            word-break: break-all;
        "#
    }
}
