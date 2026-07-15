import type { Theme } from "@earendil-works/pi-coding-agent";

const MASCOT_SOURCE = [
  " ███████████ ",
  "███◆█████◆███",
  "  █████████  ",
  "  ███   ███  ",
  "  ███   ███  ",
  " ████   ████ ",
] as const;

function blackPixel(): string {
  return "\x1b[30m█\x1b[39m";
}

/** A solid theme-colored π pet. Diamond markers become true-black block eyes. */
export function piMascot(theme: Theme): string[] {
  return MASCOT_SOURCE.map((line) => [...line].map((pixel) => {
    if (pixel === " ") return " ";
    if (pixel === "◆") return blackPixel();
    return theme.fg("accent", pixel);
  }).join(""));
}

export const PI_MASCOT_WIDTH = 13;
