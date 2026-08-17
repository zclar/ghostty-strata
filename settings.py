#!/usr/bin/env python3
"""Visual settings panel for Amber Strata."""

from __future__ import annotations

import os
import subprocess
import tkinter as tk
import tkinter.font as tkfont
from pathlib import Path
from tkinter import ttk

REPO = Path(__file__).resolve().parent
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "ghostty"
FONT_CONFIG = CONFIG / "font.ghostty"
ACTIVE_SHADER = CONFIG / "shaders" / "active.glsl"

FONTS = {
    "Terminus": ("Terminus (TTF)", "Medium", True, 165, "-6%", 11),
    "DM Mono — Modern": ("DM Mono", "Regular", False, 0, "-3%", 11),
    "IBM Plex Mono — Technical": ("IBM Plex Mono", "Regular", False, 0, "-3%", 11),
    "IBM 3270 — Retro": ("IBM 3270", "Regular", False, 0, "-4%", 12),
    "Strata Dot — Display": ("Strata Dot", "Regular", False, 0, "0%", 20),
    "Strata Square — Display": ("Strata Square", "Regular", False, 0, "0%", 20),
    "Strata Matrix — Display": ("Strata Matrix", "Regular", False, 0, "3%", 22),
}

BG = "#100902"
SURFACE = "#1b0f04"
BORDER = "#6a3c0d"
TEXT = "#ea851d"
BRIGHT = "#ffb840"
MUTED = "#a96318"
PANEL = "#160c03"
DIM = "#3a2108"


def parse_config() -> dict[str, str]:
    values: dict[str, str] = {}
    if FONT_CONFIG.exists():
        for line in FONT_CONFIG.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                key, value = line.split("=", 1)
                values[key.strip()] = value.strip()
    return values


class Settings(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Amber Strata Settings")
        self.geometry("760x780")
        self.minsize(680, 740)
        self.configure(bg=BG)

        current = parse_config()
        current_family = current.get("font-family", "Terminus (TTF)")
        selected = next(
            (label for label, data in FONTS.items() if data[0] == current_family),
            "Terminus",
        )
        self.font_choice = tk.StringVar(value=selected)
        self.font_size = tk.DoubleVar(value=float(current.get("font-size", "15")))
        self.thickness = tk.IntVar(
            value=int(current.get("font-thicken-strength", "165"))
        )
        glow_off_source = REPO / "shaders" / "cursor-pulse.glsl"
        glow_enabled = (
            ACTIVE_SHADER.exists()
            and glow_off_source.exists()
            and ACTIVE_SHADER.read_bytes() != glow_off_source.read_bytes()
        )
        self.glow = tk.BooleanVar(value=glow_enabled)
        self.status = tk.StringVar(value="Changes preview here immediately.")
        self.identity_phase = 0

        self._styles()
        self._build()
        self._update_preview()

    def _styles(self) -> None:
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure("TFrame", background=BG)
        style.configure("Card.TFrame", background=SURFACE, borderwidth=1, relief="solid")
        style.configure("TLabel", background=BG, foreground=TEXT, font=("DM Mono", 10))
        # The finer 7x11 face retains detail at display size. Explicit tracking
        # keeps the identity open and technical instead of horizontally cramped.
        style.configure(
            "Title.TLabel",
            foreground=BRIGHT,
            font=("Strata Dot", 25, "normal"),
        )
        style.configure("Muted.TLabel", foreground=MUTED)
        style.configure(
            "Section.TLabel",
            background=SURFACE,
            foreground=BRIGHT,
            font=("DM Mono", 9, "bold"),
        )
        style.configure(
            "Status.TLabel",
            foreground=MUTED,
            font=("DM Mono", 9),
        )
        style.configure("Card.TLabel", background=SURFACE, foreground=TEXT)
        style.configure("TRadiobutton", background=SURFACE, foreground=TEXT)
        style.map("TRadiobutton", background=[("active", SURFACE)], foreground=[("active", BRIGHT)])
        style.configure("TCheckbutton", background=SURFACE, foreground=TEXT)
        style.map("TCheckbutton", background=[("active", SURFACE)], foreground=[("active", BRIGHT)])
        style.configure("TButton", background=SURFACE, foreground=BRIGHT, bordercolor=BORDER, padding=(12, 8))
        style.map("TButton", background=[("active", "#2b1806")])
        style.configure(
            "Accent.TButton",
            background=TEXT,
            foreground=BG,
            bordercolor=BRIGHT,
            padding=(15, 9),
        )
        style.map("Accent.TButton", background=[("active", BRIGHT)])

    def _build(self) -> None:
        root = ttk.Frame(self, padding=24)
        root.pack(fill="both", expand=True)
        identity = tk.Canvas(
            root,
            height=70,
            bg=BG,
            highlightthickness=0,
            borderwidth=0,
        )
        identity.pack(fill="x", anchor="w")
        self.identity_canvas = identity
        identity_font = tkfont.Font(family="Strata Dot", size=25)
        identity_x = 0
        for character in "AMBER STRATA":
            identity.create_text(
                identity_x,
                2,
                text=character,
                anchor="nw",
                fill=BRIGHT,
                font=identity_font,
            )
            identity_x += identity_font.measure(character) + 3
        identity.create_text(
            728,
            6,
            text="◫  01",
            anchor="ne",
            fill=MUTED,
            font=("DM Mono", 10, "bold"),
        )
        self.identity_dots = []
        for index in range(28):
            x = 4 + index * 12
            dot = identity.create_oval(x, 53, x + 4, 57, fill=DIM, outline="")
            self.identity_dots.append(dot)
        identity.create_line(348, 55, 724, 55, fill=DIM, width=1)
        self.after(80, self._animate_identity)
        ttk.Label(
            root,
            text="SYSTEM / PHOSPHOR INTERFACE / LIVE",
            style="Muted.TLabel",
        ).pack(anchor="w", pady=(0, 18))

        card = ttk.Frame(root, style="Card.TFrame", padding=18)
        card.pack(fill="x")
        ttk.Label(card, text="01  /  TYPE SYSTEM", style="Section.TLabel").grid(row=0, column=0, sticky="w", columnspan=2, pady=(0, 7))
        for index, label in enumerate(FONTS, start=1):
            ttk.Radiobutton(
                card,
                text=label,
                value=label,
                variable=self.font_choice,
                command=self._select_font,
            ).grid(row=index, column=0, sticky="w", pady=3)

        ttk.Label(card, text="Size", style="Card.TLabel").grid(row=1, column=1, sticky="w", padx=(40, 0))
        tk.Scale(
            card,
            from_=11,
            to=24,
            resolution=0.5,
            orient="horizontal",
            variable=self.font_size,
            command=lambda _value: self._update_preview(),
            bg=SURFACE,
            fg=TEXT,
            troughcolor=BG,
            highlightthickness=0,
            activebackground=BRIGHT,
            length=250,
        ).grid(row=2, column=1, rowspan=2, sticky="ew", padx=(40, 0))

        ttk.Label(card, text="Terminus thickness", style="Card.TLabel").grid(row=4, column=1, sticky="w", padx=(40, 0))
        tk.Scale(
            card,
            from_=0,
            to=255,
            resolution=5,
            orient="horizontal",
            variable=self.thickness,
            bg=SURFACE,
            fg=TEXT,
            troughcolor=BG,
            highlightthickness=0,
            activebackground=BRIGHT,
            length=250,
        ).grid(row=5, column=1, sticky="ew", padx=(40, 0))
        card.columnconfigure(1, weight=1)

        effects = ttk.Frame(root, style="Card.TFrame", padding=18)
        effects.pack(fill="x", pady=12)
        ttk.Label(effects, text="02  /  SIGNAL + MOTION", style="Section.TLabel").pack(anchor="w")
        ttk.Checkbutton(
            effects,
            text="Phosphor character glow and typing pulse",
            variable=self.glow,
            command=self._apply_glow_live,
        ).pack(anchor="w", pady=(8, 0))

        preview_card = ttk.Frame(root, style="Card.TFrame", padding=18)
        preview_card.pack(fill="both", expand=True)
        ttk.Label(preview_card, text="03  /  LIVE GLYPH PREVIEW", style="Section.TLabel").pack(anchor="w")
        self.preview = tk.Label(
            preview_card,
            text="AMBER STRATA 03   ◫ ◇ ⌁\nThe quick brown fox 0123456789\n> glow --modern   [ SIGNAL READY ]",
            justify="left",
            anchor="w",
            bg=BG,
            fg=BRIGHT,
            padx=14,
            pady=14,
        )
        self.preview.pack(fill="both", expand=True, pady=(9, 0))

        buttons = ttk.Frame(root)
        buttons.pack(fill="x", pady=(14, 0))
        ttk.Button(buttons, text="Apply", command=self._apply, style="Accent.TButton").pack(side="left")
        ttk.Button(buttons, text="Apply + Open Ghostty Preview", command=self._open_preview).pack(side="left", padx=8)
        ttk.Button(buttons, text="Close", command=self.destroy).pack(side="right")
        ttk.Label(root, textvariable=self.status, style="Status.TLabel").pack(anchor="w", pady=(10, 0))

    def _animate_identity(self) -> None:
        """Run a restrained Nothing-inspired signal sweep in the header."""
        if not self.winfo_exists():
            return
        count = len(self.identity_dots)
        for index, dot in enumerate(self.identity_dots):
            distance = (index - self.identity_phase) % count
            color = BRIGHT if distance == 0 else TEXT if distance in (1, count - 1) else DIM
            self.identity_canvas.itemconfigure(dot, fill=color)
        self.identity_phase = (self.identity_phase + 1) % count
        self.after(90, self._animate_identity)

    def _update_preview(self) -> None:
        family = FONTS[self.font_choice.get()][0]
        size = max(8, int(self.font_size.get()))
        try:
            font = tkfont.Font(family=family, size=size)
            self.preview.configure(font=font)
        except tk.TclError:
            self.preview.configure(font=("Monospace", size))

    def _select_font(self) -> None:
        """Preview immediately and keep matrix faces above their legible floor."""
        minimum = FONTS[self.font_choice.get()][5]
        if self.font_size.get() < minimum:
            self.font_size.set(minimum)
        self._update_preview()
        self.status.set(
            "Preview updated. Apply, then press Ctrl+Shift+, in an existing Ghostty window."
        )

    def _apply_glow_live(self) -> None:
        display_face = self.font_choice.get().endswith("— Display")
        profile = "glow-soft" if self.glow.get() and display_face else (
            "glow-on" if self.glow.get() else "glow-off"
        )
        subprocess.run([str(REPO / "profile.sh"), profile], check=True)
        state = "display-safe" if profile == "glow-soft" else (
            "enabled" if self.glow.get() else "disabled"
        )
        self.status.set(f"Glow {state} live.")

    def _write_font(self) -> None:
        family, style, thicken, default_strength, width, _minimum = FONTS[self.font_choice.get()]
        strength = self.thickness.get() if thicken else default_strength
        FONT_CONFIG.parent.mkdir(parents=True, exist_ok=True)
        FONT_CONFIG.write_text(
            f"font-family = {family}\n"
            f"font-style = {style}\n"
            f"font-size = {self.font_size.get():g}\n"
            f"font-thicken = {str(thicken).lower()}\n"
            f"font-thicken-strength = {strength}\n"
            f"adjust-cell-width = {width}\n"
        )

    def _apply(self) -> None:
        self._write_font()
        self._apply_glow_live()
        result = subprocess.run(["ghostty", "+validate-config"], capture_output=True, text=True)
        if result.returncode == 0:
            self.status.set("Applied. Existing Ghostty windows: press Ctrl+Shift+, once.")
        else:
            self.status.set("Validation failed; settings were not accepted.")

    def _open_preview(self) -> None:
        self._apply()
        command = (
            "printf 'AMBER STRATA SETTINGS PREVIEW\\n\\n'; "
            "printf 'ABCDEFGHIJKLMNOPQRSTUVWXYZ\\nabcdefghijklmnopqrstuvwxyz\\n0123456789 !@#$%%&*()\\n\\n'; "
            "printf 'The quick brown fox jumps over the lazy dog.\\n\\n'; exec bash"
        )
        subprocess.Popen(["ghostty", "-e", "bash", "-lc", command])
        self.status.set("Applied and opened a new Ghostty preview window.")


if __name__ == "__main__":
    Settings().mainloop()
