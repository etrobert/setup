use std::collections::BTreeMap;
use std::fs;
use std::fmt::Write;

use niri_ipc::socket::Socket;
use niri_ipc::{Output, Request, Response, Transform};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct Screen {
    mode: String,
    scale: f64,
    transform: String,
    x: i32,
    y: i32,
}

/// Mirrors niri's own `format_make_model_serial_or_connector`.
fn identity(output: &Output) -> String {
    if output.make == "Unknown" && output.model == "Unknown" && output.serial.is_none() {
        return output.name.clone();
    }
    let serial = output.serial.as_deref().unwrap_or("Unknown");
    format!("{} {} {}", output.make, output.model, serial)
}

fn transform_name(transform: Transform) -> &'static str {
    match transform {
        Transform::Normal => "normal",
        Transform::_90 => "90",
        Transform::_180 => "180",
        Transform::_270 => "270",
        Transform::Flipped => "flipped",
        Transform::Flipped90 => "flipped-90",
        Transform::Flipped180 => "flipped-180",
        Transform::Flipped270 => "flipped-270",
    }
}

fn screen(output: &Output) -> Option<Screen> {
    // An interlaced mode leaves a screen that is on with no mode to name.
    let logical = output.logical.as_ref()?;
    let mode = output.modes.get(output.current_mode?)?;

    Some(Screen {
        mode: format!(
            "{}x{}@{}",
            mode.width,
            mode.height,
            f64::from(mode.refresh_rate) / 1000.
        ),
        scale: logical.scale,
        transform: transform_name(logical.transform).to_owned(),
        x: logical.x,
        y: logical.y,
    })
}

fn replace(path: &std::path::Path, contents: &str) -> std::io::Result<()> {
    // niri polls the layout every 500ms, so swap it in one step rather than
    // letting it read a half-written config.
    let staged = path.with_extension("new");
    fs::write(&staged, contents)?;
    fs::rename(staged, path)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let state = dirs_home()?.join(".local/state/niri");
    let store = state.join("outputs.json");
    let layout = state.join("outputs.kdl");
    fs::create_dir_all(&state)?;

    // Screens that are unplugged keep their entry: that is the whole point, and
    // a wlr-output-management apply drops them from niri's own copy (niri#676).
    let mut saved: BTreeMap<String, Screen> = match fs::read_to_string(&store) {
        Ok(json) => serde_json::from_str(&json)?,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => BTreeMap::new(),
        Err(e) => return Err(e.into()),
    };

    let Response::Outputs(outputs) = Socket::connect()?.send(Request::Outputs)?? else {
        return Err("niri answered a different request".into());
    };

    for output in outputs.values() {
        if let Some(screen) = screen(output) {
            saved.insert(identity(output), screen);
        }
    }

    replace(&store, &serde_json::to_string_pretty(&saved)?)?;

    let mut kdl = String::new();
    for (id, screen) in &saved {
        // serde_json quotes the name: an unescaped quote in an EDID string
        // would take the whole niri config down with it, not just this file.
        writeln!(kdl, "output {} {{", serde_json::to_string(id)?)?;
        writeln!(kdl, "    mode {}", serde_json::to_string(&screen.mode)?)?;
        writeln!(kdl, "    scale {}", screen.scale)?;
        writeln!(
            kdl,
            "    transform {}",
            serde_json::to_string(&screen.transform)?
        )?;
        writeln!(kdl, "    position x={} y={}", screen.x, screen.y)?;
        writeln!(kdl, "}}")?;
    }
    replace(&layout, &kdl)?;

    Ok(())
}

fn dirs_home() -> Result<std::path::PathBuf, Box<dyn std::error::Error>> {
    Ok(std::env::var("HOME")?.into())
}
