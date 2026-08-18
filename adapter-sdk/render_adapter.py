#!/usr/bin/env python3
"""Validate an Amber Strata agent adapter and render an active shader."""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path


FLOAT_CONSTANTS = {
    "AGENT_SURFACE_ADAPTER": lambda data: 1.0 if data["enabled"] else 0.0,
    "ADAPTER_CHROMA_START": lambda data: data["detection"]["chroma_start"],
    "ADAPTER_CHROMA_END": lambda data: data["detection"]["chroma_end"],
    "ADAPTER_LUMA_START": lambda data: data["detection"]["luminance_start"],
    "ADAPTER_LUMA_FULL": lambda data: data["detection"]["luminance_full"],
    "ADAPTER_LUMA_FADE": lambda data: data["detection"]["luminance_fade"],
    "ADAPTER_LUMA_END": lambda data: data["detection"]["luminance_end"],
}


def number(value: object, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{label} must be a number")
    result = float(value)
    if not math.isfinite(result) or not 0.0 <= result <= 1.0:
        raise ValueError(f"{label} must be between 0 and 1")
    return result


def load_adapter(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text())
    required = {"schema_version", "id", "name", "description", "enabled", "detection", "panel_color"}
    missing = required - data.keys()
    if missing:
        raise ValueError(f"missing adapter fields: {', '.join(sorted(missing))}")
    if data["schema_version"] != 1:
        raise ValueError("unsupported schema_version")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", str(data["id"])):
        raise ValueError("id must contain lowercase letters, digits, or hyphens")
    if not isinstance(data["enabled"], bool):
        raise ValueError("enabled must be true or false")
    detection = data["detection"]
    if not isinstance(detection, dict):
        raise ValueError("detection must be an object")
    for key in ("chroma_start", "chroma_end", "luminance_start", "luminance_full", "luminance_fade", "luminance_end"):
        detection[key] = number(detection.get(key), f"detection.{key}")
    if not detection["chroma_start"] < detection["chroma_end"]:
        raise ValueError("chroma_start must be below chroma_end")
    if not detection["luminance_start"] < detection["luminance_full"] <= detection["luminance_fade"] < detection["luminance_end"]:
        raise ValueError("luminance thresholds must increase from start through end")
    panel = data["panel_color"]
    if not isinstance(panel, list) or len(panel) != 3:
        raise ValueError("panel_color must contain three linear RGB values")
    data["panel_color"] = [number(value, f"panel_color[{index}]") for index, value in enumerate(panel)]
    return data


def replace_constant(shader: str, name: str, value: float) -> str:
    pattern = rf"(const float {re.escape(name)} = )[-+0-9.eE]+(;)"
    rendered, count = re.subn(pattern, rf"\g<1>{value:.6f}\2", shader, count=1)
    if count != 1:
        raise ValueError(f"shader constant not found: {name}")
    return rendered


def render(source: Path, adapter: dict[str, object], glow_mode: str) -> str:
    shader = source.read_text()
    for name, getter in FLOAT_CONSTANTS.items():
        shader = replace_constant(shader, name, float(getter(adapter)))
    color = adapter["panel_color"]
    color_text = f"vec3({color[0]:.6f}, {color[1]:.6f}, {color[2]:.6f})"
    shader, count = re.subn(
        r"(const vec3 ADAPTER_PANEL_COLOR = )vec3\([^;]+\)(;)",
        rf"\g<1>{color_text}\2",
        shader,
        count=1,
    )
    if count != 1:
        raise ValueError("shader constant not found: ADAPTER_PANEL_COLOR")
    if glow_mode == "glow-soft":
        shader = replace_constant(shader, "GLOW_STRENGTH", 0.72)
        shader = replace_constant(shader, "GLOW_RADIUS", 1.15)
        shader = replace_constant(shader, "TYPE_PULSE_STRENGTH", 0.30)
    return shader


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--adapter", required=True, type=Path)
    parser.add_argument("--glow-mode", choices=("glow-on", "glow-soft", "glow-off"), required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    adapter = load_adapter(args.adapter)
    output = render(args.source, adapter, args.glow_mode)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output)


if __name__ == "__main__":
    main()
