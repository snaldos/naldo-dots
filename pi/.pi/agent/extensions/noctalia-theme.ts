import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PREFERRED_THEME = "noctalia";
const FALLBACK_THEME = "dark";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    const hasPreferredTheme = ctx.ui
      .getAllThemes()
      .some((theme) => theme.name === PREFERRED_THEME);

    const selectedTheme = hasPreferredTheme ? PREFERRED_THEME : FALLBACK_THEME;
    const result = ctx.ui.setTheme(selectedTheme);

    if (!result.success && selectedTheme !== FALLBACK_THEME) {
      ctx.ui.setTheme(FALLBACK_THEME);
    }
  });
}
