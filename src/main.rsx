//! RustScript Studio - Visual IDE for RustScript
//! Design navigation flows and CSS visually.

use rsc::prelude::*;

mod app;
mod components;
mod hooks;
mod pages;

use app::App;

fn main() {
    rsc::mount(App);
}
