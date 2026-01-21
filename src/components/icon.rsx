//! Icon component - renders SVG icons.

use rsc::prelude::*;

/// Icon component.
/// Uses Lucide icons via SVG sprite or inline SVG.
#[component]
pub fn Icon(
    name: String,
    size: Option<u32>,
    css_class: Option<String>,
) -> Element {
    let size = size.unwrap_or(20);
    let class = class.unwrap_or_default();
    let style = format!(
        "width: {}px; height: {}px; display: inline-block;",
        size, size
    );

    rsx! {
        svg(
            class: format!("icon icon-{} {}", name, class),
            style: style,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: "2",
            stroke_linecap: "round",
            stroke_linejoin: "round"
        ) {
            use_(href: format!("#icon-{}", name))
        }
    }
}

/// Icon sprite component - defines all icon SVG paths.
/// Should be included once in the app root.
#[component]
pub fn IconSprite() -> Element {
    rsx! {
        svg(style: "display: none;") {
            defs {
                // Git branch icon
                symbol(id: "icon-git-branch", viewBox: "0 0 24 24") {
                    line(x1: "6", y1: "3", x2: "6", y2: "15")
                    circle(cx: "18", cy: "6", r: "3")
                    circle(cx: "6", cy: "18", r: "3")
                    path(d: "M18 9a9 9 0 0 1-9 9")
                }

                // Palette icon
                symbol(id: "icon-palette", viewBox: "0 0 24 24") {
                    circle(cx: "13.5", cy: "6.5", r: "0.5")
                    circle(cx: "17.5", cy: "10.5", r: "0.5")
                    circle(cx: "8.5", cy: "7.5", r: "0.5")
                    circle(cx: "6.5", cy: "12.5", r: "0.5")
                    path(d: "M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.555C21.965 6.012 17.461 2 12 2z")
                }

                // Settings icon
                symbol(id: "icon-settings", viewBox: "0 0 24 24") {
                    circle(cx: "12", cy: "12", r: "3")
                    path(d: "M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z")
                }

                // Folder icon
                symbol(id: "icon-folder", viewBox: "0 0 24 24") {
                    path(d: "M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z")
                }

                // Plus icon
                symbol(id: "icon-plus", viewBox: "0 0 24 24") {
                    line(x1: "12", y1: "5", x2: "12", y2: "19")
                    line(x1: "5", y1: "12", x2: "19", y2: "12")
                }

                // Sidebar icon
                symbol(id: "icon-sidebar", viewBox: "0 0 24 24") {
                    rect(x: "3", y: "3", width: "18", height: "18", rx: "2", ry: "2")
                    line(x1: "9", y1: "3", x2: "9", y2: "21")
                }

                // Panel bottom icon
                symbol(id: "icon-panel-bottom", viewBox: "0 0 24 24") {
                    rect(x: "3", y: "3", width: "18", height: "18", rx: "2", ry: "2")
                    line(x1: "3", y1: "15", x2: "21", y2: "15")
                }

                // Sun icon
                symbol(id: "icon-sun", viewBox: "0 0 24 24") {
                    circle(cx: "12", cy: "12", r: "5")
                    line(x1: "12", y1: "1", x2: "12", y2: "3")
                    line(x1: "12", y1: "21", x2: "12", y2: "23")
                    line(x1: "4.22", y1: "4.22", x2: "5.64", y2: "5.64")
                    line(x1: "18.36", y1: "18.36", x2: "19.78", y2: "19.78")
                    line(x1: "1", y1: "12", x2: "3", y2: "12")
                    line(x1: "21", y1: "12", x2: "23", y2: "12")
                    line(x1: "4.22", y1: "19.78", x2: "5.64", y2: "18.36")
                    line(x1: "18.36", y1: "5.64", x2: "19.78", y2: "4.22")
                }

                // Sliders icon
                symbol(id: "icon-sliders", viewBox: "0 0 24 24") {
                    line(x1: "4", y1: "21", x2: "4", y2: "14")
                    line(x1: "4", y1: "10", x2: "4", y2: "3")
                    line(x1: "12", y1: "21", x2: "12", y2: "12")
                    line(x1: "12", y1: "8", x2: "12", y2: "3")
                    line(x1: "20", y1: "21", x2: "20", y2: "16")
                    line(x1: "20", y1: "12", x2: "20", y2: "3")
                    line(x1: "1", y1: "14", x2: "7", y2: "14")
                    line(x1: "9", y1: "8", x2: "15", y2: "8")
                    line(x1: "17", y1: "16", x2: "23", y2: "16")
                }

                // Type icon
                symbol(id: "icon-type", viewBox: "0 0 24 24") {
                    polyline(points: "4 7 4 4 20 4 20 7")
                    line(x1: "9", y1: "20", x2: "15", y2: "20")
                    line(x1: "12", y1: "4", x2: "12", y2: "20")
                }

                // Circle icon
                symbol(id: "icon-circle", viewBox: "0 0 24 24") {
                    circle(cx: "12", cy: "12", r: "10")
                }

                // Maximize icon
                symbol(id: "icon-maximize", viewBox: "0 0 24 24") {
                    path(d: "M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3")
                }

                // Layers icon
                symbol(id: "icon-layers", viewBox: "0 0 24 24") {
                    polygon(points: "12 2 2 7 12 12 22 7 12 2")
                    polyline(points: "2 17 12 22 22 17")
                    polyline(points: "2 12 12 17 22 12")
                }

                // Download icon
                symbol(id: "icon-download", viewBox: "0 0 24 24") {
                    path(d: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4")
                    polyline(points: "7 10 12 15 17 10")
                    line(x1: "12", y1: "15", x2: "12", y2: "3")
                }

                // Keyboard icon
                symbol(id: "icon-keyboard", viewBox: "0 0 24 24") {
                    rect(x: "2", y: "4", width: "20", height: "16", rx: "2", ry: "2")
                    line(x1: "6", y1: "8", x2: "6", y2: "8")
                    line(x1: "10", y1: "8", x2: "10", y2: "8")
                    line(x1: "14", y1: "8", x2: "14", y2: "8")
                    line(x1: "18", y1: "8", x2: "18", y2: "8")
                    line(x1: "6", y1: "12", x2: "6", y2: "12")
                    line(x1: "18", y1: "12", x2: "18", y2: "12")
                    line(x1: "8", y1: "16", x2: "16", y2: "16")
                }
            }
        }
    }
}
