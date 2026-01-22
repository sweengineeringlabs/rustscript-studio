//! RustScript Studio - Visual IDE for RustScript

use rsc::prelude::*;

component App {
    let sidebar_visible = signal(true);
    let page = signal(0);
    let counter = signal(0);

    render {
        <div class="app">
            @if sidebar_visible.get() {
                <aside class="sidebar">
                    <h3>"Navigation"</h3>
                    <button on:click={move |_| page.set(0)}>"Dashboard"</button>
                    <button on:click={move |_| page.set(1)}>"Flow Designer"</button>
                    <button on:click={move |_| page.set(2)}>"CSS Designer"</button>
                    <button on:click={move |_| sidebar_visible.set(false)}>"Hide"</button>
                </aside>
            }

            <main>
                @if !sidebar_visible.get() {
                    <button on:click={move |_| sidebar_visible.set(true)}>"Show Sidebar"</button>
                }
                <h1>"RustScript Studio"</h1>

                @if page.get() == 0 {
                    <section class="dashboard">
                        <h2>"Dashboard"</h2>
                        <div class="counter">
                            <button on:click={move |_| counter.set(counter.get() - 1)}>"-"</button>
                            <span>"Count"</span>
                            <button on:click={move |_| counter.set(counter.get() + 1)}>"+"</button>
                        </div>
                        @if counter.get() > 5 {
                            <div class="alert">
                                @if counter.get() > 10 {
                                    <strong>"Very High!"</strong>
                                }
                                <p>"Counter above 5"</p>
                            </div>
                        }
                    </section>
                }

                @if page.get() == 1 {
                    <section class="flow-designer">
                        <h2>"Flow Designer"</h2>
                        <p>"Design navigation flows visually."</p>
                    </section>
                }

                @if page.get() == 2 {
                    <section class="css-designer">
                        <h2>"CSS Designer"</h2>
                        <p>"Create and manage design tokens."</p>
                    </section>
                }
            </main>
        </div>
    }
}
