//! RustScript Studio - Visual IDE for RustScript
//!
//! NOTE: Debugging circular reference error in @if conditional rendering:
//! - RS-151: @if works but runtime has "circular reference" error during mount
//! - Root cause investigation in progress - see debug_test.html for testing
//! - Component props aren't shared between parent and child components
//!
//! Debug logging added to runtime:
//! - getElementById, createElement, appendChild - track handles
//! - HandleManager.alloc - detect duplicate allocations
//! - conditionals.create/update - track parent handles
//! - renderBranch - track insertion targets
//!
//! Fixed issues:
//! - Event handler format: changed "on{}" to "on:{}" in HIR lowering (lower.rs:1059)
//! - Added parent element tracking for @if (lower.rs:859-871, wasm.rs:2162-2164)

use rsc::prelude::*;

component App {
    render {
        <div class="app" data-testid="app-root">
            <ActivityBar />
            <Sidebar />
            <MainArea />
        </div>
    }
}

component ActivityBar {
    render {
        <div class="activity-bar" data-testid="activity-bar">
            <button class="activity-item" title="Navigation Designer" data-testid="activity-item-navigation">"Nav"</button>
            <button class="activity-item" title="CSS Designer" data-testid="activity-item-css">"CSS"</button>
            <button class="activity-item" title="Settings" data-testid="activity-item-settings">"Set"</button>
            <button title="Toggle Sidebar" data-testid="toggle-sidebar">"Toggle"</button>
        </div>
    }
}

component Sidebar {
    render {
        <div class="sidebar" data-testid="sidebar">
            @if true {
                <span>"Hello"</span>
            }
            <NavigationSidebar />
        </div>
    }
}

component MainArea {
    render {
        <div class="main-area" data-testid="main-area">
            <h1 data-testid="page-title">"Navigation Designer"</h1>
            <NavigationDesignerPage />
        </div>
    }
}

component NavigationSidebar {
    render {
        <div class="navigation-sidebar" data-testid="navigation-sidebar">
            <h3>"Workflows"</h3>
            <button data-testid="add-workflow">"+ Add Workflow"</button>
            <div data-testid="workflow-list">
                <div data-testid="workflow-item">"Main Flow"</div>
                <div data-testid="workflow-item">"Auth Flow"</div>
            </div>
        </div>
    }
}

component CssSidebar {
    render {
        <div class="css-sidebar" data-testid="css-sidebar">
            <h3>"Categories"</h3>
            <button data-testid="category-colors">"Colors"</button>
            <button data-testid="category-spacing">"Spacing"</button>
        </div>
    }
}

component SettingsSidebar {
    render {
        <div class="settings-sidebar" data-testid="settings-sidebar">
            <h3>"Settings"</h3>
        </div>
    }
}

component NavigationDesignerPage {
    render {
        <div class="navigation-designer-page">
            <div data-testid="toolbar">
                <button data-testid="add-node">"+ Add Node"</button>
                <div data-testid="zoom-controls">
                    <span>"100%"</span>
                </div>
            </div>
            <div data-testid="flow-canvas">
                <div data-testid="flow-node">"Start"</div>
                <div data-testid="flow-node">"Process"</div>
            </div>
            <div data-testid="minimap">"Mini"</div>
            <div data-testid="bottom-panel">"Properties"</div>
        </div>
    }
}

component CssDesignerPage {
    render {
        <div class="css-designer-page" data-testid="css-designer-page">
            <div data-testid="token-panel">
                <h3>"Design Tokens"</h3>
                <div data-testid="token-list">
                    <div>"--primary-color: #007bff"</div>
                </div>
            </div>
            <div data-testid="preview-pane">
                <button>"Sample Button"</button>
                <input type="text" placeholder="Sample Input" />
            </div>
            <div data-testid="css-output-panel">
                <pre>":root { }"</pre>
            </div>
        </div>
    }
}

component SettingsPage {
    render {
        <div class="settings-page">
            <h2>"Settings"</h2>
        </div>
    }
}
