//! Main application component.

use rsc::prelude::*;

use crate::components::{
    ActivityBar, BottomPanel, Header, Sidebar,
};
use crate::hooks::use_studio_store;
use crate::pages::{CssDesignerPage, NavigationDesignerPage, SettingsPage};

/// Application routes.
#[derive(Debug, Clone, PartialEq)]
pub enum Route {
    Navigation,
    CssDesigner,
    Settings,
}

impl Default for Route {
    fn default() -> Self {
        Self::Navigation
    }
}

/// Main application component.
#[component]
pub fn App() -> Element {
    let store = use_studio_store();
    let route = use_signal(Route::default);
    let sidebar_visible = use_signal(|| true);
    let bottom_panel_visible = use_signal(|| true);

    rsx! {
        div(class="app-container", style=styles::ide_layout()) {
            // Activity bar
            ActivityBar {
                active_view: route.clone(),
                on_change: move |new_route| route.set(new_route),
            }

            // Sidebar (conditionally rendered)
            if sidebar_visible.get() {
                Sidebar {
                    route: route.get(),
                    store: store.clone(),
                }
            }

            // Main content area
            div(class="main-area") {
                Header {
                    title: get_page_title(&route.get()),
                    sidebar_visible: sidebar_visible.clone(),
                    bottom_panel_visible: bottom_panel_visible.clone(),
                }

                main(class="content") {
                    match route.get() {
                        Route::Navigation => {
                            NavigationDesignerPage {
                                store: store.clone(),
                            }
                        }
                        Route::CssDesigner => {
                            CssDesignerPage {
                                store: store.clone(),
                            }
                        }
                        Route::Settings => {
                            SettingsPage {
                                store: store.clone(),
                            }
                        }
                    }
                }

                // Bottom panel (conditionally rendered)
                if bottom_panel_visible.get() {
                    BottomPanel {
                        store: store.clone(),
                    }
                }
            }
        }
    }
}

fn get_page_title(route: &Route) -> &'static str {
    match route {
        Route::Navigation => "Navigation Designer",
        Route::CssDesigner => "CSS Designer",
        Route::Settings => "Settings",
    }
}

mod styles {
    pub fn ide_layout() -> &'static str {
        r#"
            display: grid;
            grid-template-columns: auto auto 1fr;
            grid-template-rows: 1fr;
            height: 100vh;
            background: var(--color-bg-primary);
        "#
    }
}
