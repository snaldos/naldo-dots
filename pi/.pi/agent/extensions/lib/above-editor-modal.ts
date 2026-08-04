import type {
  ExtensionCommandContext,
  Theme,
} from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";

const MODAL_EDITOR_GAP = 2;

const FOCUS_PROXY_OPTIONS = {
  anchor: "bottom-right" as const,
  width: 1,
  minWidth: 1,
  maxHeight: 1,
  margin: 0,
};

/**
 * Render a modal card as a widget immediately above the normal editor while a
 * one-cell transparent overlay owns keyboard focus. This keeps the composer
 * and status bar visible and avoids a detached screen-center dialog.
 */
export async function showAboveEditorModal(
  ctx: ExtensionCommandContext,
  widgetId: string,
  create: (tui: TUI, theme: Theme, done: (value: void) => void) => Component,
): Promise<void> {
  if (ctx.mode !== "tui") return;
  try {
    await ctx.ui.custom<void>((tui, theme, _keybindings, done) => {
      const component = create(tui, theme, done);
      const spacedComponent: Component = {
        render: (width: number) => [
          ...component.render(width),
          ...Array.from({ length: MODAL_EDITOR_GAP }, () => ""),
        ],
        invalidate: () => component.invalidate(),
        handleInput: (data: string) => component.handleInput?.(data),
      };
      ctx.ui.setWidget(widgetId, () => spacedComponent, { placement: "aboveEditor" });
      return {
        render: () => [],
        invalidate: () => component.invalidate(),
        handleInput: (data: string) => component.handleInput?.(data),
      };
    }, {
      overlay: true,
      overlayOptions: FOCUS_PROXY_OPTIONS,
    });
  } finally {
    ctx.ui.setWidget(widgetId, undefined);
  }
}
