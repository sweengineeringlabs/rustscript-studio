//! ColorPicker component for selecting colors in the CSS Designer.

use rsc::prelude::*;

/// Color format for display and input.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ColorFormat {
    Hex,
    Rgb,
    Hsl,
}

impl Default for ColorFormat {
    fn default() -> Self {
        ColorFormat::Hex
    }
}

impl ColorFormat {
    pub fn as_str(&self) -> &'static str {
        match self {
            ColorFormat::Hex => "HEX",
            ColorFormat::Rgb => "RGB",
            ColorFormat::Hsl => "HSL",
        }
    }
}

/// Parsed color value.
#[derive(Debug, Clone, Copy, Default)]
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub a: f32,
}

impl Color {
    pub fn from_hex(hex: &str) -> Option<Self> {
        let hex = hex.trim_start_matches('#');
        if hex.len() == 6 {
            let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
            let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
            let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
            Some(Color { r, g, b, a: 1.0 })
        } else if hex.len() == 8 {
            let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
            let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
            let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
            let a = u8::from_str_radix(&hex[6..8], 16).ok()? as f32 / 255.0;
            Some(Color { r, g, b, a })
        } else if hex.len() == 3 {
            let r = u8::from_str_radix(&hex[0..1].repeat(2), 16).ok()?;
            let g = u8::from_str_radix(&hex[1..2].repeat(2), 16).ok()?;
            let b = u8::from_str_radix(&hex[2..3].repeat(2), 16).ok()?;
            Some(Color { r, g, b, a: 1.0 })
        } else {
            None
        }
    }

    pub fn to_hex(&self) -> String {
        if self.a >= 1.0 {
            format!("#{:02x}{:02x}{:02x}", self.r, self.g, self.b)
        } else {
            format!("#{:02x}{:02x}{:02x}{:02x}", self.r, self.g, self.b, (self.a * 255.0) as u8)
        }
    }

    pub fn to_rgb(&self) -> String {
        if self.a >= 1.0 {
            format!("rgb({}, {}, {})", self.r, self.g, self.b)
        } else {
            format!("rgba({}, {}, {}, {:.2})", self.r, self.g, self.b, self.a)
        }
    }

    pub fn to_hsl(&self) -> String {
        let (h, s, l) = self.to_hsl_values();
        if self.a >= 1.0 {
            format!("hsl({:.0}, {:.0}%, {:.0}%)", h, s * 100.0, l * 100.0)
        } else {
            format!("hsla({:.0}, {:.0}%, {:.0}%, {:.2})", h, s * 100.0, l * 100.0, self.a)
        }
    }

    pub fn to_hsl_values(&self) -> (f64, f64, f64) {
        let r = self.r as f64 / 255.0;
        let g = self.g as f64 / 255.0;
        let b = self.b as f64 / 255.0;

        let max = r.max(g).max(b);
        let min = r.min(g).min(b);
        let l = (max + min) / 2.0;

        if max == min {
            return (0.0, 0.0, l);
        }

        let d = max - min;
        let s = if l > 0.5 { d / (2.0 - max - min) } else { d / (max + min) };

        let h = if max == r {
            ((g - b) / d + if g < b { 6.0 } else { 0.0 }) * 60.0
        } else if max == g {
            ((b - r) / d + 2.0) * 60.0
        } else {
            ((r - g) / d + 4.0) * 60.0
        };

        (h, s, l)
    }

    pub fn from_hsl(h: f64, s: f64, l: f64, a: f32) -> Self {
        if s == 0.0 {
            let v = (l * 255.0) as u8;
            return Color { r: v, g: v, b: v, a };
        }

        let q = if l < 0.5 { l * (1.0 + s) } else { l + s - l * s };
        let p = 2.0 * l - q;
        let h = h / 360.0;

        let hue_to_rgb = |p: f64, q: f64, mut t: f64| -> f64 {
            if t < 0.0 { t += 1.0; }
            if t > 1.0 { t -= 1.0; }
            if t < 1.0 / 6.0 { return p + (q - p) * 6.0 * t; }
            if t < 1.0 / 2.0 { return q; }
            if t < 2.0 / 3.0 { return p + (q - p) * (2.0 / 3.0 - t) * 6.0; }
            p
        };

        let r = (hue_to_rgb(p, q, h + 1.0 / 3.0) * 255.0) as u8;
        let g = (hue_to_rgb(p, q, h) * 255.0) as u8;
        let b = (hue_to_rgb(p, q, h - 1.0 / 3.0) * 255.0) as u8;

        Color { r, g, b, a }
    }
}

/// ColorPicker component with saturation/brightness picker, hue slider, and optional alpha slider.
///
/// ## Example
/// ```rust,ignore
/// ColorPicker {
///     value: color.get(),
///     on_change: Callback::new(move |c| color.set(c)),
///     presets: vec!["#3b82f6", "#10b981", "#f59e0b", "#ef4444"],
/// }
/// ```
#[component]
pub fn ColorPicker(
    value: String,
    on_change: Option<Callback<String>>,
    show_alpha: Option<bool>,
    format: ColorFormat,
    disabled: bool,
    presets: Vec<String>,
) -> Element {
    let show_alpha = show_alpha.unwrap_or(true);
    let color = use_signal(|| Color::from_hex(&value).unwrap_or_default());
    let format = use_signal(|| format);
    let is_dragging_sv = use_signal(|| false);
    let is_dragging_hue = use_signal(|| false);
    let is_dragging_alpha = use_signal(|| false);
    let sv_ref = use_node_ref();

    // Extract HSL values for the pickers
    let (hue, sat, light) = color.get().to_hsl_values();

    // Emit color change
    let emit_change = {
        let on_change = on_change.clone();
        move |new_color: Color| {
            color.set(new_color);
            if let Some(ref callback) = on_change {
                callback.call(new_color.to_hex());
            }
        }
    };

    // Saturation/Brightness picker mouse handlers
    let on_sv_mouse_down = move |e: MouseEvent| {
        if disabled { return; }
        e.prevent_default();
        is_dragging_sv.set(true);
        update_sv_from_event(&e, &sv_ref, color, &emit_change);
    };

    let on_sv_mouse_move = {
        let emit_change = emit_change.clone();
        move |e: MouseEvent| {
            if is_dragging_sv.get() {
                update_sv_from_event(&e, &sv_ref, color, &emit_change);
            }
        }
    };

    let on_sv_mouse_up = move |_: MouseEvent| {
        is_dragging_sv.set(false);
    };

    // Hue slider handlers
    let on_hue_input = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Ok(h) = e.value().parse::<f64>() {
                let c = color.get();
                let (_, s, l) = c.to_hsl_values();
                let new_color = Color::from_hsl(h, s, l, c.a);
                emit_change(new_color);
            }
        }
    };

    // Alpha slider handlers
    let on_alpha_input = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            if let Ok(a) = e.value().parse::<f32>() {
                let mut c = color.get();
                c.a = a / 100.0;
                emit_change(c);
            }
        }
    };

    // Hex input handler
    let on_hex_input = {
        let emit_change = emit_change.clone();
        move |e: InputEvent| {
            let val = e.value();
            if let Some(new_color) = Color::from_hex(&val) {
                emit_change(new_color);
            }
        }
    };

    // Format toggle
    let on_format_click = move |_: MouseEvent| {
        format.update(|f| {
            *f = match f {
                ColorFormat::Hex => ColorFormat::Rgb,
                ColorFormat::Rgb => ColorFormat::Hsl,
                ColorFormat::Hsl => ColorFormat::Hex,
            };
        });
    };

    // Preset color click
    let on_preset_click = {
        let emit_change = emit_change.clone();
        move |preset: String| {
            if let Some(new_color) = Color::from_hex(&preset) {
                emit_change(new_color);
            }
        }
    };

    let current_color = color.get();
    let hex_value = current_color.to_hex();
    let display_value = match format.get() {
        ColorFormat::Hex => hex_value.clone(),
        ColorFormat::Rgb => current_color.to_rgb(),
        ColorFormat::Hsl => current_color.to_hsl(),
    };

    rsx! {
        div(class: "color-picker", style: styles::container(disabled)) {
            // Saturation/Brightness picker
            div(
                class: "color-picker-sv",
                style: styles::sv_picker(hue),
                ref: sv_ref,
                onmousedown: on_sv_mouse_down,
                onmousemove: on_sv_mouse_move,
                onmouseup: on_sv_mouse_up,
                onmouseleave: on_sv_mouse_up,
            ) {
                div(class: "color-picker-sv-white", style: styles::sv_white())
                div(class: "color-picker-sv-black", style: styles::sv_black())
                div(class: "color-picker-sv-cursor", style: styles::sv_cursor(sat, light))
            }

            // Sliders section
            div(class: "color-picker-sliders", style: styles::sliders()) {
                // Hue slider
                div(class: "color-picker-hue", style: styles::slider_row()) {
                    div(class: "color-picker-hue-track", style: styles::hue_track())
                    input(
                        type: "range",
                        min: "0",
                        max: "360",
                        value: hue.to_string(),
                        style: styles::slider_input(),
                        disabled: disabled,
                        oninput: on_hue_input,
                    )
                }

                // Alpha slider (optional)
                if show_alpha {
                    div(class: "color-picker-alpha", style: styles::slider_row()) {
                        div(class: "color-picker-alpha-track", style: styles::alpha_track(&hex_value))
                        input(
                            type: "range",
                            min: "0",
                            max: "100",
                            value: (current_color.a * 100.0).to_string(),
                            style: styles::slider_input(),
                            disabled: disabled,
                            oninput: on_alpha_input,
                        )
                    }
                }
            }

            // Color preview and input
            div(class: "color-picker-input-row", style: styles::input_row()) {
                div(class: "color-picker-preview", style: styles::preview(&hex_value, current_color.a))
                input(
                    type: "text",
                    value: display_value.clone(),
                    style: styles::text_input(),
                    disabled: disabled,
                    oninput: on_hex_input,
                )
                button(
                    style: styles::format_button(),
                    disabled: disabled,
                    onclick: on_format_click,
                ) {
                    { format.get().as_str() }
                }
            }

            // Preset colors
            if !presets.is_empty() {
                div(class: "color-picker-presets", style: styles::presets()) {
                    for preset in presets.iter() {
                        button(
                            class: "color-picker-preset",
                            style: styles::preset_button(preset),
                            disabled: disabled,
                            onclick: {
                                let preset = preset.clone();
                                let on_preset_click = on_preset_click.clone();
                                move |_| on_preset_click(preset.clone())
                            },
                        )
                    }
                }
            }
        }
    }
}

fn update_sv_from_event<F>(
    e: &MouseEvent,
    sv_ref: &NodeRef,
    color: Signal<Color>,
    emit_change: &F,
) where
    F: Fn(Color),
{
    // Get the bounding rect of the SV picker
    let rect_x = e.offset_x() as f64;
    let rect_y = e.offset_y() as f64;
    let width = 200.0; // Default width
    let height = 150.0; // Default height

    let sat = (rect_x / width).clamp(0.0, 1.0);
    let val = 1.0 - (rect_y / height).clamp(0.0, 1.0);

    // Convert saturation/value to HSL
    let c = color.get();
    let (h, _, _) = c.to_hsl_values();

    // Convert HSV to HSL
    let l = val * (1.0 - sat / 2.0);
    let s = if l == 0.0 || l == 1.0 { 0.0 } else { (val - l) / l.min(1.0 - l) };

    let new_color = Color::from_hsl(h, s, l, c.a);
    emit_change(new_color);
}

mod styles {
    pub fn container(disabled: bool) -> String {
        let opacity = if disabled { "0.5" } else { "1" };
        format!(
            r#"
                display: flex;
                flex-direction: column;
                gap: var(--spacing-md);
                padding: var(--spacing-md);
                background: var(--color-surface);
                border: 1px solid var(--color-border);
                border-radius: var(--radius-lg);
                width: 232px;
                opacity: {opacity};
            "#,
            opacity = opacity,
        )
    }

    pub fn sv_picker(hue: f64) -> String {
        format!(
            r#"
                position: relative;
                width: 200px;
                height: 150px;
                border-radius: var(--radius-md);
                background: hsl({hue}, 100%, 50%);
                cursor: crosshair;
            "#,
            hue = hue,
        )
    }

    pub fn sv_white() -> &'static str {
        r#"
            position: absolute;
            inset: 0;
            background: linear-gradient(to right, #fff, transparent);
            border-radius: var(--radius-md);
        "#
    }

    pub fn sv_black() -> &'static str {
        r#"
            position: absolute;
            inset: 0;
            background: linear-gradient(to top, #000, transparent);
            border-radius: var(--radius-md);
        "#
    }

    pub fn sv_cursor(sat: f64, light: f64) -> String {
        // Convert HSL saturation/lightness to position
        // This is an approximation; proper conversion would need the original HSV values
        let x = sat * 100.0;
        let y = (1.0 - light * 2.0).max(0.0) * 100.0;
        format!(
            r#"
                position: absolute;
                width: 12px;
                height: 12px;
                border: 2px solid white;
                border-radius: 50%;
                box-shadow: 0 0 0 1px rgba(0,0,0,0.3), inset 0 0 0 1px rgba(0,0,0,0.3);
                transform: translate(-50%, -50%);
                left: {x}%;
                top: {y}%;
                pointer-events: none;
            "#,
            x = x,
            y = y,
        )
    }

    pub fn sliders() -> &'static str {
        r#"
            display: flex;
            flex-direction: column;
            gap: var(--spacing-sm);
        "#
    }

    pub fn slider_row() -> &'static str {
        r#"
            position: relative;
            height: 16px;
        "#
    }

    pub fn hue_track() -> &'static str {
        r#"
            position: absolute;
            inset: 0;
            border-radius: var(--radius-sm);
            background: linear-gradient(
                to right,
                hsl(0, 100%, 50%),
                hsl(60, 100%, 50%),
                hsl(120, 100%, 50%),
                hsl(180, 100%, 50%),
                hsl(240, 100%, 50%),
                hsl(300, 100%, 50%),
                hsl(360, 100%, 50%)
            );
        "#
    }

    pub fn alpha_track(color: &str) -> String {
        format!(
            r#"
                position: absolute;
                inset: 0;
                border-radius: var(--radius-sm);
                background:
                    linear-gradient(to right, transparent, {color}),
                    repeating-conic-gradient(#ccc 0% 25%, white 0% 50%) 50% / 8px 8px;
            "#,
            color = color,
        )
    }

    pub fn slider_input() -> &'static str {
        r#"
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            opacity: 0;
            cursor: pointer;
        "#
    }

    pub fn input_row() -> &'static str {
        r#"
            display: flex;
            gap: var(--spacing-sm);
            align-items: center;
        "#
    }

    pub fn preview(color: &str, alpha: f32) -> String {
        format!(
            r#"
                width: 32px;
                height: 32px;
                border-radius: var(--radius-md);
                border: 1px solid var(--color-border);
                background:
                    linear-gradient({color}e{alpha_hex}, {color}e{alpha_hex}),
                    repeating-conic-gradient(#ccc 0% 25%, white 0% 50%) 50% / 8px 8px;
            "#,
            color = color,
            alpha_hex = format!("{:02x}", (alpha * 255.0) as u8),
        )
    }

    pub fn text_input() -> &'static str {
        r#"
            flex: 1;
            height: 32px;
            padding: 0 var(--spacing-sm);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-bg-secondary);
            color: var(--color-text-primary);
            font-family: var(--font-mono);
            font-size: var(--font-size-sm);
        "#
    }

    pub fn format_button() -> &'static str {
        r#"
            height: 32px;
            padding: 0 var(--spacing-sm);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-md);
            background: var(--color-bg-secondary);
            color: var(--color-text-secondary);
            font-size: var(--font-size-xs);
            font-weight: var(--font-weight-medium);
            cursor: pointer;
        "#
    }

    pub fn presets() -> &'static str {
        r#"
            display: flex;
            flex-wrap: wrap;
            gap: var(--spacing-xs);
        "#
    }

    pub fn preset_button(color: &str) -> String {
        format!(
            r#"
                width: 24px;
                height: 24px;
                border: 1px solid var(--color-border);
                border-radius: var(--radius-sm);
                background: {color};
                cursor: pointer;
                transition: transform var(--transition-fast);
            "#,
            color = color,
        )
    }
}
