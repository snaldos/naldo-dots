import {
  getMarkdownTheme,
  type ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import { Markdown, matchesKey } from "@earendil-works/pi-tui";
import { frameBottom, frameRow, frameTop, type UiColor } from "./ui-kit.ts";

export type ReportTone = "info" | "warning" | "error";

const BODY_LINES = 16;
const REPORT_WIDTH = 82;

export async function showReport(
  ctx: ExtensionCommandContext,
  title: string,
  body: string,
  tone: ReportTone = "info",
): Promise<void> {
  if (ctx.mode !== "tui") {
    if (ctx.hasUI) ctx.ui.notify(`${title}\n\n${body}`, tone);
    return;
  }

  await ctx.ui.custom(
    (tui, theme, _keybindings, done) => {
      const markdown = new Markdown(body.trim(), 0, 0, getMarkdownTheme());
      let scroll = 0;
      let totalLines = 0;

      const move = (delta: number) => {
        scroll = Math.max(
          0,
          Math.min(Math.max(0, totalLines - BODY_LINES), scroll + delta),
        );
        tui.requestRender();
      };

      return {
        render(width: number): string[] {
          const safeWidth = Math.max(4, width);
          const bodyWidth = Math.max(1, safeWidth - 4);
          const bodyLines = markdown.render(bodyWidth);
          totalLines = bodyLines.length;
          scroll = Math.min(scroll, Math.max(0, totalLines - BODY_LINES));

          const visible = bodyLines.slice(scroll, scroll + BODY_LINES);
          const remaining = Math.max(0, totalLines - scroll - visible.length);
          const scrollInfo =
            totalLines > BODY_LINES
              ? ` · ${scroll} above · ${remaining} below`
              : "";
          const color: UiColor =
            tone === "error"
              ? "error"
              : tone === "warning"
                ? "warning"
                : "accent";
          return [
            frameTop(theme, safeWidth, `π  ${title.toUpperCase()}`, color),
            ...visible.map((line) => frameRow(theme, safeWidth, line)),
            ...Array.from(
              { length: Math.max(0, Math.min(2, BODY_LINES - visible.length)) },
              () => frameRow(theme, safeWidth),
            ),
            frameBottom(
              theme,
              safeWidth,
              `j k / <C-d> <C-u> scroll · Esc close${scrollInfo}`,
            ),
          ];
        },
        invalidate(): void {
          markdown.invalidate();
        },
        handleInput(data: string): void {
          if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
            done(undefined);
          } else if (matchesKey(data, "j")) {
            move(1);
          } else if (matchesKey(data, "k")) {
            move(-1);
          } else if (matchesKey(data, "ctrl+d")) {
            move(BODY_LINES);
          } else if (matchesKey(data, "ctrl+u")) {
            move(-BODY_LINES);
          }
        },
      };
    },
    {
      overlay: true,
      overlayOptions: {
        anchor: "center",
        width: REPORT_WIDTH,
        minWidth: 36,
        maxHeight: "94%",
        margin: 1,
      },
    },
  );
}
