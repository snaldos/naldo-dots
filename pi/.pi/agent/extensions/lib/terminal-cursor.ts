const INVERSE_VIDEO = "\x1b[7m";
const INVERSE_RESETS = ["\x1b[0m", "\x1b[27m"] as const;

function stripInverseSpanAt(
  line: string,
  inverseIndex: number,
): string | undefined {
  const contentIndex = inverseIndex + INVERSE_VIDEO.length;
  let resetIndex = -1;
  let reset = "";
  for (const candidate of INVERSE_RESETS) {
    const candidateIndex = line.indexOf(candidate, contentIndex);
    if (candidateIndex >= 0 && (resetIndex < 0 || candidateIndex < resetIndex)) {
      resetIndex = candidateIndex;
      reset = candidate;
    }
  }
  if (resetIndex < 0) return undefined;
  return (
    line.slice(0, inverseIndex)
    + line.slice(contentIndex, resetIndex)
    + line.slice(resetIndex + reset.length)
  );
}

/**
 * Remove Pi's reverse-video cursor cell while preserving its zero-width cursor
 * marker. The TUI can then position a visible terminal cursor at the marker.
 *
 * This deliberately changes only an inverse-video span immediately following
 * the marker. If Pi changes its cursor protocol, leave the line untouched
 * rather than stripping unrelated styling.
 */
export function useTerminalCursor(line: string, cursorMarker: string): string {
  let markerIndex = line.indexOf(cursorMarker);
  while (markerIndex >= 0) {
    const inverseIndex = markerIndex + cursorMarker.length;
    if (line.startsWith(INVERSE_VIDEO, inverseIndex)) {
      return stripInverseSpanAt(line, inverseIndex) ?? line;
    }
    markerIndex = line.indexOf(cursorMarker, markerIndex + cursorMarker.length);
  }
  return line;
}

export function useTerminalCursorLines(
  lines: string[],
  cursorMarker: string,
  focused = true,
): string[] {
  if (focused) {
    return lines.map((line) => useTerminalCursor(line, cursorMarker));
  }

  // Editor omits CURSOR_MARKER when focus moves to a modal but still renders
  // its software cursor. It is the first inverse span, before autocomplete.
  const result = [...lines];
  for (let index = 0; index < result.length; index += 1) {
    const line = result[index]!;
    const inverseIndex = line.indexOf(INVERSE_VIDEO);
    if (inverseIndex < 0) continue;
    result[index] = stripInverseSpanAt(line, inverseIndex) ?? line;
    break;
  }
  return result;
}
