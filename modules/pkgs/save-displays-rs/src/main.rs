use std::fs;
use std::path::Path;

use kdl::{KdlDocument, KdlEntry, KdlNode};
use niri_ipc::socket::Socket;
use niri_ipc::{Output, Request, Response, Transform};

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

fn argument(name: &str, value: impl Into<KdlEntry>) -> KdlNode {
    let mut node = KdlNode::new(name);
    node.push(value);
    node
}

/// The `output` block niri matches against this screen's make, model and serial.
fn block(output: &Output) -> Option<KdlNode> {
    // An interlaced mode leaves a screen that is on with no mode to name.
    let logical = output.logical.as_ref()?;
    let mode = output.modes.get(output.current_mode?)?;

    let mut position = KdlNode::new("position");
    position.push(KdlEntry::new_prop("x", i128::from(logical.x)));
    position.push(KdlEntry::new_prop("y", i128::from(logical.y)));

    let mut children = KdlDocument::new();
    children.nodes_mut().extend([
        argument(
            "mode",
            format!(
                "{}x{}@{}",
                mode.width,
                mode.height,
                f64::from(mode.refresh_rate) / 1000.
            ),
        ),
        argument("scale", logical.scale),
        argument("transform", transform_name(logical.transform)),
        position,
    ]);

    let mut node = KdlNode::new("output");
    node.push(identity(output));
    node.set_children(children);
    Some(node)
}

fn names(node: &KdlNode, id: &str) -> bool {
    node.name().value() == "output"
        && node.entries().first().and_then(|e| e.value().as_string()) == Some(id)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let layout = Path::new(&std::env::var("HOME")?).join(".local/state/niri/outputs.kdl");
    fs::create_dir_all(layout.parent().unwrap())?;

    // Screens that are unplugged keep their block: that is the whole point, and
    // a wlr-output-management apply drops them from niri's own copy (niri#676).
    let mut document = match fs::read_to_string(&layout) {
        Ok(text) => KdlDocument::parse_v1(&text)?,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => KdlDocument::new(),
        Err(e) => return Err(e.into()),
    };

    let Response::Outputs(outputs) = Socket::connect()?.send(Request::Outputs)?? else {
        return Err("niri answered a different request".into());
    };

    for output in outputs.values() {
        let Some(block) = block(output) else { continue };
        let id = identity(output);
        match document.nodes_mut().iter_mut().find(|n| names(n, &id)) {
            // Carry over anything written above the block, so a note a human
            // left on a screen outlives the next save.
            Some(existing) => {
                let note = existing.format().map(|f| f.leading.clone());
                *existing = block;
                if let (Some(note), Some(format)) = (note, existing.format_mut()) {
                    format.leading = note;
                }
            }
            None => document.nodes_mut().push(block),
        }
    }

    document.autoformat();
    // niri parses its config as KDL v1 (knuffel), where this crate's v2 default
    // of bare identifier strings is rejected: `transform normal` must be quoted.
    document.ensure_v1();

    // niri polls this file every 500ms, so swap it in one step rather than
    // letting it read a half-written config.
    let staged = layout.with_extension("new");
    fs::write(&staged, document.to_string())?;
    fs::rename(staged, layout)?;

    Ok(())
}
