import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { useTerminalCursor, useTerminalCursorLines } from "./terminal-cursor.ts";

const marker = "\x1b_pi:c\x07";

describe("terminal cursor rendering", () => {
  it("keeps Pi's marker and removes the Editor's fake cursor styling", () => {
    const line = `before${marker}\x1b[7mX\x1b[0mafter`;

    assert.equal(useTerminalCursor(line, marker), `before${marker}Xafter`);
  });

  it("supports the Input component's inverse-only reset", () => {
    const line = `before${marker}\x1b[7m \x1b[27mafter`;

    assert.equal(useTerminalCursor(line, marker), `before${marker} after`);
  });

  it("does not strip unrelated inverse styling or malformed cursor output", () => {
    assert.equal(
      useTerminalCursor("before\x1b[7mX\x1b[0mafter", marker),
      "before\x1b[7mX\x1b[0mafter",
    );
    assert.equal(
      useTerminalCursor(`before${marker}\x1b[7mX`, marker),
      `before${marker}\x1b[7mX`,
    );
  });

  it("transforms only the line containing the cursor marker", () => {
    assert.deepEqual(
      useTerminalCursorLines(
        ["plain", `${marker}\x1b[7m界\x1b[0m`, "tail"],
        marker,
      ),
      ["plain", `${marker}界`, "tail"],
    );
  });

  it("removes only the editor cursor when a modal owns focus", () => {
    assert.deepEqual(
      useTerminalCursorLines(
        [
          "rule",
          "before\x1b[7m \x1b[0mafter",
          "rule",
          "autocomplete \x1b[7mselection\x1b[0m",
        ],
        marker,
        false,
      ),
      [
        "rule",
        "before after",
        "rule",
        "autocomplete \x1b[7mselection\x1b[0m",
      ],
    );
  });

  it("leaves unfocused output untouched when the first inverse span is malformed", () => {
    const lines = ["before\x1b[7mX", "later\x1b[7mY\x1b[0m"];

    assert.deepEqual(useTerminalCursorLines(lines, marker, false), lines);
  });
});
