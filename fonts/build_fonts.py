#!/usr/bin/env python3
"""Build the original Strata Dot and Strata Square matrix fonts."""

from __future__ import annotations

import argparse
import math
import subprocess
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.pointInsidePen import PointInsidePen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

UPEM = 1000
ADVANCE = 800
ASCENT = 850
DESCENT = -200
COLS = 7
ROWS = 11
X_STEP = 100
Y_STEP = 82
X_START = 100
Y_START = -30


def terminus_path() -> Path:
    output = subprocess.check_output(
        ["fc-match", "-f", "%{file}", "Terminus (TTF)"], text=True
    )
    path = Path(output.strip())
    if not path.is_file():
        raise SystemExit("Terminus (TTF) is required to build the matrix fonts")
    return path


def add_circle(pen: TTGlyphPen, cx: float, cy: float, radius: float) -> None:
    points = [
        (cx + math.cos(index * math.tau / 16) * radius,
         cy + math.sin(index * math.tau / 16) * radius)
        for index in range(16)
    ]
    pen.moveTo(points[0])
    for point in points[1:]:
        pen.lineTo(point)
    pen.closePath()


def add_rounded_square(
    pen: TTGlyphPen, cx: float, cy: float, half: float, radius: float
) -> None:
    left, right = cx - half, cx + half
    bottom, top = cy - half, cy + half
    pen.moveTo((left + radius, bottom))
    pen.lineTo((right - radius, bottom))
    pen.qCurveTo((right, bottom), (right, bottom + radius))
    pen.lineTo((right, top - radius))
    pen.qCurveTo((right, top), (right - radius, top))
    pen.lineTo((left + radius, top))
    pen.qCurveTo((left, top), (left, top - radius))
    pen.lineTo((left, bottom + radius))
    pen.qCurveTo((left, bottom), (left + radius, bottom))
    pen.closePath()


def is_inside(glyph_set, glyph_name: str, x: float, y: float) -> bool:
    pen = PointInsidePen(glyph_set, (x, y), evenOdd=False)
    glyph_set[glyph_name].draw(pen)
    return pen.getResult()


def sample_matrix(
    source: TTFont, codepoint: int, cols: int = COLS, rows: int = ROWS
) -> set[tuple[int, int]]:
    cmap = source.getBestCmap()
    glyph_name = cmap.get(codepoint)
    if glyph_name is None or codepoint == 0x20:
        return set()

    glyph_set = source.getGlyphSet()
    source_upem = source["head"].unitsPerEm
    scale = source_upem / UPEM
    source_advance = source["hmtx"].metrics[glyph_name][0]
    lit: set[tuple[int, int]] = set()

    # Multiple probes per cell retain thin diagonals without filling counters.
    probes = ((0.0, 0.0), (-0.22, 0.0), (0.22, 0.0), (0.0, -0.22), (0.0, 0.22))
    for row in range(rows):
        for col in range(cols):
            hits = 0
            for dx, dy in probes:
                sx = source_advance * ((col + 0.5 + dx) / cols)
                sy = (-200 + (row + 0.5 + dy) * (1200 / rows)) * scale
                hits += is_inside(glyph_set, glyph_name, sx, sy)
            if hits >= 1:
                lit.add((col, row))
    return lit


def glyph_from_matrix(matrix: set[tuple[int, int]], shape: str):
    pen = TTGlyphPen(None)
    for col, row in sorted(matrix):
        cx = X_START + col * X_STEP
        cy = Y_START + row * Y_STEP
        if shape == "dot":
            # Slightly oversized nodes survive grayscale rasterization at the
            # 13–16 px sizes used by terminal grids without becoming a blob.
            add_circle(pen, cx, cy, 40)
        else:
            add_rounded_square(pen, cx, cy, 43, 10)
    return pen.glyph()


def coarse_glyph(matrix: set[tuple[int, int]]):
    """Nothing-inspired coarse 5x7 display rhythm with original glyph maps."""
    pen = TTGlyphPen(None)
    for col, row in sorted(matrix):
        add_circle(pen, 155 + col * 122, 85 + row * 118, 49)
    return pen.glyph()


def build(source_path: Path, output: Path, family: str, shape: str) -> None:
    source = TTFont(source_path)
    codepoints = list(range(0x20, 0x7F)) + list(range(0xA0, 0x100))
    glyph_order = [".notdef"] + [f"uni{cp:04X}" for cp in codepoints]
    coarse = shape == "matrix"
    glyphs = {".notdef": (
        coarse_glyph({(0, 0), (0, 6), (4, 0), (4, 6)})
        if coarse else
        glyph_from_matrix({(0, 0), (0, 10), (6, 0), (6, 10)}, shape)
    )}
    cmap = {}

    for codepoint in codepoints:
        name = f"uni{codepoint:04X}"
        matrix = sample_matrix(source, codepoint, 5, 7) if coarse else sample_matrix(source, codepoint)
        glyphs[name] = coarse_glyph(matrix) if coarse else glyph_from_matrix(matrix, shape)
        cmap[codepoint] = name

    builder = FontBuilder(UPEM, isTTF=True)
    builder.setupGlyphOrder(glyph_order)
    builder.setupCharacterMap(cmap)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics({name: (ADVANCE, 0) for name in glyph_order})
    builder.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT)
    builder.setupNameTable(
        {
            "copyright": "Terminus Copyright (C) 2016 Dimitar Toshkov Zhekov; Copyright (C) 2017 Tilman Blumenbach. Strata matrix adaptation Copyright (C) 2026 The Amber Strata Project Authors.",
            "familyName": family,
            "styleName": "Regular",
            "uniqueFontIdentifier": f"AmberStrata:{family}:1.000",
            "fullName": f"{family} Regular",
            "psName": family.replace(" ", "-") + "-Regular",
            "version": "Version 1.000",
            "manufacturer": "Amber Strata Project",
            "designer": "Amber Strata Project",
            "description": "Original 7x11 modern matrix terminal typeface.",
            "licenseDescription": "Licensed under the SIL Open Font License, Version 1.1.",
            "licenseInfoURL": "https://openfontlicense.org",
        }
    )
    builder.setupOS2(
        sTypoAscender=ASCENT,
        sTypoDescender=DESCENT,
        usWinAscent=ASCENT,
        usWinDescent=abs(DESCENT),
        sxHeight=520,
        sCapHeight=780,
        usWeightClass=500,
        usWidthClass=5,
    )
    builder.setupPost(isFixedPitch=1)
    builder.setupMaxp()
    output.parent.mkdir(parents=True, exist_ok=True)
    builder.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=None)
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).parent / "dist")
    args = parser.parse_args()
    source = args.source or terminus_path()
    build(source, args.output_dir / "StrataDot-Regular.ttf", "Strata Dot", "dot")
    build(source, args.output_dir / "StrataSquare-Regular.ttf", "Strata Square", "square")
    build(source, args.output_dir / "StrataMatrix-Regular.ttf", "Strata Matrix", "matrix")
    print(f"Built Strata Dot, Strata Square, and Strata Matrix in {args.output_dir}")


if __name__ == "__main__":
    main()
