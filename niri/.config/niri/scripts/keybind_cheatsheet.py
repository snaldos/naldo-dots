#!/usr/bin/env python3
"""Show active Niri keybindings in Noctalia's searchable dmenu."""

from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

ONE_LINE_BIND_RE = re.compile(
    r"^ {4}(?P<combo>[^/\s{]+)(?P<attributes>.*?)"
    r"\{\s*(?P<action>.*?)\s*\}\s*$"
)
BIND_START_RE = re.compile(r"^ {4}(?P<combo>[^/\s{]+)(?P<attributes>.*?)\{\s*$")
TITLE_RE = re.compile(r'\bhotkey-overlay-title="(?P<title>(?:\\.|[^"\\])*)"')

KEY_LABELS = {
    "BracketLeft": "[",
    "BracketRight": "]",
    "Comma": ",",
    "Equal": "=",
    "Minus": "-",
    "Period": ".",
    "Slash": "/",
    "XF86AudioLowerVolume": "VOLUME DOWN",
    "XF86AudioMicMute": "MIC MUTE",
    "XF86AudioMute": "VOLUME MUTE",
    "XF86AudioNext": "MEDIA NEXT",
    "XF86AudioPause": "MEDIA PAUSE",
    "XF86AudioPlay": "MEDIA PLAY",
    "XF86AudioPrev": "MEDIA PREVIOUS",
    "XF86AudioRaiseVolume": "VOLUME UP",
    "XF86AudioStop": "MEDIA STOP",
    "XF86MonBrightnessDown": "BRIGHTNESS DOWN",
    "XF86MonBrightnessUp": "BRIGHTNESS UP",
}
MODIFIER_LABELS = {
    "Alt": "ALT",
    "Ctrl": "CTRL",
    "Mod": "SUPER",
    "Shift": "SHIFT",
    "Super": "SUPER",
}


def config_path() -> Path:
    configured = os.environ.get("NIRI_CONFIG")
    if configured:
        return Path(configured).expanduser()

    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "niri" / "config.kdl"


def decode_title(encoded: str) -> str:
    try:
        return json.loads(f'"{encoded}"')
    except json.JSONDecodeError:
        return encoded.replace(r"\"", '"').replace(r"\\", "\\")


def humanize_key(key: str) -> str:
    if key in KEY_LABELS:
        return KEY_LABELS[key]

    label = key.replace("_", " ")
    label = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", label)
    return label.upper()


def humanize_combo(combo: str) -> str:
    components = combo.split("+")
    labels = [MODIFIER_LABELS.get(part, humanize_key(part)) for part in components]
    return " + ".join(labels)


def humanize_action(action: str) -> str:
    action = action.strip().removesuffix(";").strip()
    try:
        tokens = shlex.split(action)
    except ValueError:
        tokens = action.replace('"', "").split()

    if not tokens:
        return "Unknown action"

    name, *arguments = tokens
    argument_text = " ".join(arguments)

    if name == "spawn":
        return f"Run: {argument_text}"
    if name == "spawn-sh":
        return f"Run shell: {argument_text}"

    description = name.replace("-", " ").capitalize()
    if argument_text:
        description = f"{description} {argument_text}"
    return description


def parse_bindings(path: Path) -> list[tuple[str, str]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise RuntimeError(f"could not read Niri config {path}: {error}") from error

    inside_binds = False
    bindings: list[tuple[str, str]] = []
    line_index = 0

    while line_index < len(lines):
        line = lines[line_index]
        line_index += 1

        if line == "binds {":
            inside_binds = True
            continue
        if inside_binds and line == "}":
            break
        if not inside_binds:
            continue

        match = ONE_LINE_BIND_RE.match(line)
        if match is None:
            match = BIND_START_RE.match(line)
            if match is None:
                continue

            action_lines: list[str] = []
            while line_index < len(lines) and lines[line_index] != "    }":
                action_line = lines[line_index].strip()
                line_index += 1
                if action_line and not action_line.startswith("//"):
                    action_lines.append(action_line)

            if line_index == len(lines):
                raise RuntimeError(
                    f"unterminated binding for {match.group('combo')} in {path}"
                )

            line_index += 1
            action = " ".join(action_lines)
        else:
            action = match.group("action")

        combo = humanize_combo(match.group("combo"))
        title_match = TITLE_RE.search(match.group("attributes"))
        if title_match is not None:
            description = decode_title(title_match.group("title"))
        else:
            description = humanize_action(action)

        bindings.append((combo, description))

    if not bindings:
        raise RuntimeError(f"no active bindings found in {path}")

    return bindings


def format_bindings(bindings: list[tuple[str, str]]) -> str:
    width = max(len(combo) for combo, _ in bindings) + 3
    entries = [f"{combo:<{width}}{description}" for combo, description in bindings]
    return "\n".join(entries) + "\n"


def main(arguments: list[str]) -> int:
    if arguments not in ([], ["--print"]):
        print(f"Usage: {Path(sys.argv[0]).name} [--print]", file=sys.stderr)
        return 2

    try:
        output = format_bindings(parse_bindings(config_path()))
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    if arguments == ["--print"]:
        print(output, end="")
        return 0

    noctalia = os.environ.get("NOCTALIA", "noctalia")
    if shutil.which(noctalia) is None:
        print(f"Error: Noctalia is required: {noctalia}", file=sys.stderr)
        return 1

    subprocess.run(
        [noctalia, "dmenu", "-p", "Niri keybinds > "],
        input=output,
        text=True,
        stdout=subprocess.DEVNULL,
        check=False,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
