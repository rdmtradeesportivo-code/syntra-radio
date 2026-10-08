use serde::Serialize;
use std::time::Duration;

#[derive(Serialize)]
struct EngineState<'a> {
    product: &'a str,
    component: &'a str,
    status: &'a str,
    version: &'a str,
}

#[tokio::main]
async fn main() {
    let state = EngineState {
        product: "SYNTRA Radio",
        component: "Studio Engine",
        status: "bootstrap",
        version: env!("CARGO_PKG_VERSION"),
    };

    println!("{}", serde_json::to_string(&state).expect("valid engine state"));
    println!("Studio Engine iniciado. Nenhum dispositivo de áudio foi assumido automaticamente.");

    tokio::select! {
        _ = tokio::signal::ctrl_c() => {
            println!("Studio Engine encerrado de forma segura.");
        }
        _ = tokio::time::sleep(Duration::from_secs(86_400)) => {}
    }
}
