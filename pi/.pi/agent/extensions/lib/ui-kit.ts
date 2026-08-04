import type { Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

export type UiColor =
  | "accent"
  | "success"
  | "warning"
  | "error"
  | "muted"
  | "text"
  | "border"
  | "borderAccent";

export function safeText(value: string, maxLength = 500): string {
  return value
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxLength);
}

export function clampPercent(value: number): number {
  return Math.max(0, Math.min(100, value));
}

export function formatPercent(value: number): string {
  const clamped = clampPercent(value);
  return clamped < 10 && !Number.isInteger(clamped)
    ? clamped.toFixed(1)
    : String(Math.round(clamped));
}

export function severityColor(
  value: number,
  warningAt = 80,
  criticalAt = 95,
): "accent" | "warning" | "error" {
  if (value >= criticalAt) return "error";
  if (value >= warningAt) return "warning";
  return "accent";
}

export function padAnsi(value: string, width: number): string {
  const safeWidth = Math.max(0, width);
  const clipped = truncateToWidth(value, safeWidth, "");
  return `${clipped}${" ".repeat(Math.max(0, safeWidth - visibleWidth(clipped)))}`;
}

export function centerLines(lines: string[], width: number): string[] {
  const safeWidth = Math.max(1, width);
  return lines.map((line) => {
    const clipped = truncateToWidth(line, safeWidth, "");
    return `${" ".repeat(Math.max(0, Math.floor((safeWidth - visibleWidth(clipped)) / 2)))}${clipped}`;
  });
}

export function wrapPlain(text: string, width: number): string[] {
  const safeWidth = Math.max(1, width);
  const words = safeText(text).split(/\s+/).filter(Boolean);
  if (!words.length) return [""];
  const lines: string[] = [];
  let line = "";
  for (const word of words) {
    if (!line) {
      line = truncateToWidth(word, safeWidth, "");
    } else if (visibleWidth(line) + 1 + visibleWidth(word) <= safeWidth) {
      line += ` ${word}`;
    } else {
      lines.push(line);
      line = truncateToWidth(word, safeWidth, "");
    }
  }
  if (line) lines.push(line);
  return lines;
}

export function frameTop(
  theme: Theme,
  width: number,
  title: string,
  color: UiColor = "accent",
): string {
  const safeWidth = Math.max(4, width);
  const label = truncateToWidth(` ${title} `, Math.max(1, safeWidth - 4), "");
  const trailing = Math.max(0, safeWidth - 3 - visibleWidth(label));
  return `${theme.fg("borderAccent", "╭─")}${theme.fg(color, theme.bold(label))}${theme.fg("borderAccent", `${"─".repeat(trailing)}╮`)}`;
}

export function frameRow(theme: Theme, width: number, value = ""): string {
  const safeWidth = Math.max(4, width);
  const contentWidth = Math.max(0, safeWidth - 4);
  return `${theme.fg("borderAccent", "│")} ${padAnsi(value, contentWidth)} ${theme.fg("borderAccent", "│")}`;
}

export function frameColumns(
  theme: Theme,
  width: number,
  left: string,
  right: string,
): string {
  const contentWidth = Math.max(1, width - 4);
  const rightWidth = Math.min(contentWidth, visibleWidth(right));
  const leftWidth = Math.max(0, contentWidth - rightWidth - (rightWidth ? 1 : 0));
  const content = rightWidth
    ? `${padAnsi(left, leftWidth)} ${truncateToWidth(right, rightWidth, "")}`
    : padAnsi(left, contentWidth);
  return frameRow(theme, width, content);
}

export function frameDivider(theme: Theme, width: number): string {
  return frameRow(theme, width, theme.fg("border", "─".repeat(Math.max(1, width - 4))));
}

export function frameBottom(theme: Theme, width: number, hint: string): string {
  const safeWidth = Math.max(4, width);
  const label = truncateToWidth(` ${hint} `, Math.max(1, safeWidth - 3), "");
  const trailing = Math.max(0, safeWidth - 2 - visibleWidth(label));
  return `${theme.fg("borderAccent", "╰")}${theme.fg("muted", label)}${theme.fg("borderAccent", `${"─".repeat(trailing)}╯`)}`;
}
