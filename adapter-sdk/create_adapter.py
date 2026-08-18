#!/usr/bin/env python3
"""Create a validated starting point for a new Amber Strata agent adapter."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("id", help="lowercase adapter id, for example claude-code")
    parser.add_argument("--name", help="display name")
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", args.id):
        parser.error("id must contain lowercase letters, digits, or hyphens")
    repo = Path(__file__).resolve().parents[1]
    output_dir = args.output_dir or repo / "adapters"
    output = output_dir / f"{args.id}.json"
    if output.exists():
        parser.error(f"refusing to overwrite {output}")
    adapter = {
        "schema_version": 1,
        "id": args.id,
        "name": args.name or args.id.replace("-", " ").title(),
        "description": "Describe the agent surface this adapter maps.",
        "enabled": True,
        "detection": {
            "chroma_start": 0.035,
            "chroma_end": 0.14,
            "luminance_start": 0.008,
            "luminance_full": 0.018,
            "luminance_fade": 0.12,
            "luminance_end": 0.22,
        },
        "panel_color": [0.105, 0.034, 0.0],
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(adapter, indent=2) + "\n")
    print(output)


if __name__ == "__main__":
    main()
