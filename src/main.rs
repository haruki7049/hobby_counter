use dioxus::prelude::*;
use tracing::{info, Level};

#[derive(Debug, Clone, Routable, PartialEq)]
#[rustfmt::skip]
enum Route {
    #[route("/")]
    Counter {},
}

const FAVICON: Asset = asset!("/assets/favicon.ico");
const MAIN_CSS: Asset = asset!("/assets/main.css");

static COUNT: GlobalSignal<isize> = Signal::global(|| 0);

fn main() {
    dioxus_logger::init(Level::INFO).expect("failed to init logger");
    dioxus::launch(App);
}

#[component]
fn App() -> Element {
    rsx! {
        document::Link { rel: "icon", href: FAVICON }
        document::Link { rel: "stylesheet", href: MAIN_CSS }
        Router::<Route> {}
    }
}

/// Counter page
#[component]
fn Counter() -> Element {
    rsx! {
        div {
            id: "counter",
            button {
                onclick: move |_| {
                    info!("Count up...");
                    *COUNT.write() += 1;
                },
                "Count up!!"
            }

            button {
                onclick: move |_| {
                    info!("Count down...");
                    *COUNT.write() -= 1;
                },
                "Count down!!"
            }

            p { "{COUNT}" }
        }
    }
}
