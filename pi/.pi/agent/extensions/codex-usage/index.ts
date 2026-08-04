import type { ExtensionAPI, ExtensionCommandContext, Theme } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth, type TUI } from "@earendil-works/pi-tui";
import { randomUUID } from "node:crypto";
import { showAboveEditorModal } from "../lib/above-editor-modal.ts";
import {
  centerLines,
  clampPercent,
  formatPercent,
  frameBottom,
  frameColumns,
  frameDivider,
  frameRow,
  frameTop,
  safeText,
  severityColor,
  wrapPlain,
  type UiColor,
} from "../lib/ui-kit.ts";
import {
  CodexUsageError,
  consumeCodexUsageResetCard,
  fetchCodexUsage,
  type CodexUsageSnapshot,
  type RateLimitWindow,
} from "./client.ts";
import {
  applyUsageResetCard,
  selectableUsageResetCards,
  usageResetCardEffect,
  UsageResetCardError,
  type ResetApplicationResult,
  type UsageResetCardSelection,
} from "./reset-flow.ts";

const CARD_WIDTH = 82;
const MAX_VISIBLE_RESET_CARDS = 5;

let cached: CodexUsageSnapshot | undefined;
let inFlight: Promise<CodexUsageSnapshot> | undefined;
let resetOperation: Promise<ResetApplicationResult> | undefined;

export type UsageView =
  | { kind: "loading"; message: string }
  | { kind: "snapshot"; snapshot: CodexUsageSnapshot; staleReason?: string; cachedOnly?: boolean }
  | { kind: "unavailable"; message: string };

export type UsageOverlayPage =
  | { kind: "main"; verbose: boolean }
  | { kind: "loading"; message: string }
  | { kind: "resets"; selected: number }
  | { kind: "preview"; selection: UsageResetCardSelection }
  | { kind: "applying"; selection: UsageResetCardSelection }
  | {
      kind: "result";
      tone: "success" | "warning" | "error";
      title: string;
      message: string;
      back: "main" | "resets";
    };

export type UsageOverlayRenderState = {
  view: UsageView;
  page: UsageOverlayPage;
};

function percent(value: number): string {
  return `${formatPercent(value)}%`;
}

function relativeTime(timestampSeconds: number, now = Date.now()): string {
  const deltaMinutes = Math.ceil((timestampSeconds * 1000 - now) / 60_000);
  if (deltaMinutes <= 0) return "due now";
  if (deltaMinutes < 60) return `in ${deltaMinutes}m`;
  const hours = Math.floor(deltaMinutes / 60);
  const minutes = deltaMinutes % 60;
  if (hours < 24) return `in ${hours}h${minutes ? ` ${minutes}m` : ""}`;
  const days = Math.floor(hours / 24);
  const remainingHours = hours % 24;
  return `in ${days}d${remainingHours ? ` ${remainingHours}h` : ""}`;
}

function absoluteTime(timestampSeconds: number, includeTime = true): string {
  return new Intl.DateTimeFormat(undefined, includeTime
    ? { dateStyle: "medium", timeStyle: "short" }
    : { dateStyle: "medium" }).format(new Date(timestampSeconds * 1000));
}

function sourceTimestamp(snapshot: CodexUsageSnapshot): string {
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "medium",
  }).format(new Date(snapshot.fetchedAt));
}

function windowWithDuration(snapshot: CodexUsageSnapshot, minutes: number): RateLimitWindow | null {
  return [snapshot.rateLimits.primary, snapshot.rateLimits.secondary]
    .find((window) => window?.windowDurationMins === minutes) ?? null;
}

function allowanceTone(snapshot: CodexUsageSnapshot): "info" | "warning" | "error" {
  const used = [snapshot.rateLimits.primary, snapshot.rateLimits.secondary]
    .flatMap((window) => window ? [window.usedPercent] : []);
  const maximum = used.length ? Math.max(...used) : 0;
  if (maximum >= 95) return "error";
  if (maximum >= 80) return "warning";
  return "info";
}

function errorMessage(error: unknown): string {
  if (error instanceof CodexUsageError || error instanceof UsageResetCardError) return error.message;
  if (error instanceof Error) return `Unexpected usage error: ${error.message}`;
  return "Unknown usage error";
}

async function refresh(signal?: AbortSignal): Promise<CodexUsageSnapshot> {
  if (!inFlight) {
    inFlight = fetchCodexUsage({ signal }).finally(() => {
      inFlight = undefined;
    });
  }
  return inFlight;
}

function acceptFresh(snapshot: CodexUsageSnapshot): CodexUsageSnapshot {
  cached = snapshot;
  return snapshot;
}

async function fetchFresh(signal?: AbortSignal): Promise<CodexUsageSnapshot> {
  return acceptFresh(await refresh(signal));
}

async function fetchFreshAfterPending(signal?: AbortSignal): Promise<CodexUsageSnapshot> {
  if (inFlight) {
    try {
      await inFlight;
    } catch {
      // A failed earlier refresh must not suppress the required post-activity read.
    }
  }
  const operation = fetchCodexUsage({ signal });
  inFlight = operation;
  try {
    return acceptFresh(await operation);
  } finally {
    if (inFlight === operation) inFlight = undefined;
  }
}

async function refreshUsage(signal?: AbortSignal): Promise<UsageView> {
  try {
    return { kind: "snapshot", snapshot: await fetchFresh(signal) };
  } catch (error) {
    const message = errorMessage(error);
    if (cached) return { kind: "snapshot", snapshot: cached, staleReason: message };
    return { kind: "unavailable", message };
  }
}

function progressLines(theme: Theme, width: number, label: string, window: RateLimitWindow | null): string[] {
  const lines = [frameRow(theme, width, theme.fg("text", theme.bold(label)))];
  if (!window) {
    lines.push(frameRow(theme, width, theme.fg("warning", "Window unavailable in the provider response")));
    return lines;
  }

  const used = clampPercent(window.usedPercent);
  const contentWidth = Math.max(12, width - 4);
  const suffix = `${percent(used)} used`;
  const barWidth = Math.max(8, Math.min(38, contentWidth - visibleWidth(suffix) - 1));
  const filled = Math.max(0, Math.min(barWidth, Math.round((used / 100) * barWidth)));
  const color = severityColor(used);
  const bar = `${theme.fg(color, "█".repeat(filled))}${theme.fg("border", "░".repeat(barWidth - filled))}`;
  lines.push(frameRow(theme, width, `${bar} ${theme.fg(color, theme.bold(suffix))}`));

  const remaining = `${percent(100 - used)} remaining`;
  if (window.resetsAt === null) {
    lines.push(frameRow(theme, width, `${theme.fg("text", remaining)}${theme.fg("muted", " · reset time unavailable")}`));
  } else {
    lines.push(frameRow(theme, width, `${theme.fg("text", remaining)}${theme.fg("muted", ` · resets ${relativeTime(window.resetsAt)}`)}`));
    lines.push(frameRow(theme, width, theme.fg("muted", absoluteTime(window.resetsAt))));
  }
  return lines;
}

function resetCardsSummaryLines(theme: Theme, width: number, snapshot: CodexUsageSnapshot): string[] {
  const summary = snapshot.resetCards;
  const count = summary?.availableCount;
  const value = count === undefined || count === null
    ? theme.fg("warning", "unavailable")
    : count > 0
      ? theme.fg("success", theme.bold(`${count} available`))
      : theme.fg("muted", "none available");
  const lines = [frameColumns(theme, width, theme.fg("text", theme.bold("Usage reset cards")), value)];
  if (count && count > 0) {
    lines.push(frameRow(theme, width, `${theme.fg("accent", "r")} ${theme.fg("text", "inspect or apply")}${theme.fg("muted", " · resets five-hour + weekly allowance")}`));
  } else {
    lines.push(frameRow(theme, width, theme.fg("muted", "Press r to refresh card availability")));
  }
  return lines;
}

function loadingLines(theme: Theme, width: number, message: string): string[] {
  return [
    frameTop(theme, width, "π  CODEX / ACCOUNT", "accent"),
    frameColumns(theme, width, theme.fg("text", theme.bold("Allowance service")), theme.fg("warning", "REFRESHING")),
    frameRow(theme, width),
    frameRow(theme, width, `${theme.fg("accent", "∴")} ${theme.fg("text", message)}`),
    frameRow(theme, width, theme.fg("muted", "Reading account metadata through the local Codex CLI")),
    frameRow(theme, width),
    frameBottom(theme, width, "Esc close"),
  ];
}

function snapshotLines(
  theme: Theme,
  width: number,
  view: Extract<UsageView, { kind: "snapshot" }>,
  verbose: boolean,
): string[] {
  const snapshot = view.snapshot;
  const tone = allowanceTone(snapshot);
  const color: UiColor = view.staleReason
    ? "warning"
    : tone === "error"
      ? "error"
      : tone === "warning"
        ? "warning"
        : "accent";
  const plan = safeText(snapshot.rateLimits.planType ?? "plan unavailable", 28).toUpperCase();
  const state = view.staleReason ? "STALE" : view.cachedOnly ? "CACHED" : "LIVE";
  const lines = [
    frameTop(theme, width, "π  CODEX / ALLOWANCE", color),
    frameColumns(
      theme,
      width,
      `${theme.fg("muted", "Plan ")}${theme.fg("text", theme.bold(plan))}`,
      theme.fg(view.staleReason ? "warning" : "success", theme.bold(state)),
    ),
  ];

  if (view.staleReason) {
    lines.push(frameRow(theme, width, theme.fg("warning", `Live refresh failed · ${safeText(view.staleReason, 120)}`)));
  } else if (tone === "error") {
    lines.push(frameRow(theme, width, theme.fg("error", theme.bold("Critical · at least one window is 95% used"))));
  } else if (tone === "warning") {
    lines.push(frameRow(theme, width, theme.fg("warning", theme.bold("Elevated · at least one window is 80% used"))));
  }

  lines.push(frameRow(theme, width));
  lines.push(...progressLines(theme, width, "Five-hour window", windowWithDuration(snapshot, 300)));
  lines.push(frameRow(theme, width));
  lines.push(...progressLines(theme, width, "Weekly window", windowWithDuration(snapshot, 10_080)));
  lines.push(frameRow(theme, width));
  lines.push(...resetCardsSummaryLines(theme, width, snapshot));

  const addOn = snapshot.rateLimits.credits;
  if (addOn?.unlimited) {
    lines.push(frameRow(theme, width, `${theme.fg("text", "Add-on credits")}  ${theme.fg("success", "unlimited")}`));
  } else if (addOn?.hasCredits) {
    const balance = addOn.balance === null ? "available" : `balance ${safeText(addOn.balance, 32)}`;
    lines.push(frameRow(theme, width, `${theme.fg("text", "Add-on credits")}  ${theme.fg("success", balance)}`));
  }

  lines.push(frameRow(theme, width));
  lines.push(frameRow(theme, width, theme.fg("muted", `Refreshed ${sourceTimestamp(snapshot)}`)));
  lines.push(frameRow(theme, width, `${theme.fg("text", "ChatGPT/Codex subscription allowance")}${theme.fg("muted", " · not API billing")}`));

  if (verbose) {
    lines.push(frameDivider(theme, width));
    const details = [
      `Read source: official Codex CLI app-server ${snapshot.sourceMethod}.`,
      snapshot.serverUserAgent ? `Server: ${safeText(snapshot.serverUserAgent, 220)}.` : "Server user-agent unavailable.",
      "The local Codex CLI login may differ from Pi's login. The maintained app-server interface is currently experimental.",
      "Usage reset cards are applied only after a fresh revalidation and deliberate preview through account/rateLimitResetCredit/consume.",
      "Opaque card IDs and idempotency keys remain in memory and are never displayed or written to disk.",
    ];
    for (const detail of details) {
      for (const wrapped of wrapPlain(detail, Math.max(12, width - 4))) {
        lines.push(frameRow(theme, width, theme.fg("muted", wrapped)));
      }
    }
  }

  lines.push(frameBottom(theme, width, `${verbose ? "v hide details" : "v details"} · r reset cards · Esc close`));
  return lines;
}

function unavailableLines(theme: Theme, width: number, message: string, verbose: boolean): string[] {
  const lines = [
    frameTop(theme, width, "π  CODEX / ALLOWANCE", "error"),
    frameColumns(theme, width, theme.fg("text", theme.bold("Allowance unavailable")), theme.fg("error", "OFFLINE")),
    frameRow(theme, width),
  ];
  for (const wrapped of wrapPlain(message, Math.max(12, width - 4))) {
    lines.push(frameRow(theme, width, theme.fg("warning", wrapped)));
  }
  lines.push(
    frameRow(theme, width),
    frameRow(theme, width, `${theme.fg("accent", "1.")} ${theme.fg("text", "Run codex login status")}`),
    frameRow(theme, width, `${theme.fg("accent", "2.")} ${theme.fg("text", "Retry /usage")}`),
    frameRow(theme, width),
    frameRow(theme, width, `${theme.fg("text", "No credentials were read or logged")}${theme.fg("muted", " · not API billing")}`),
  );
  if (verbose) {
    lines.push(frameRow(theme, width, theme.fg("muted", "Source: account/rateLimits/read through the local Codex CLI app-server.")));
  }
  lines.push(frameBottom(theme, width, `${verbose ? "v hide details" : "v details"} · Esc close`));
  return lines;
}

function resetCardTitle(selection: UsageResetCardSelection): string {
  return safeText(selection.title ?? "Full usage reset", 60) || "Full usage reset";
}

function resetListLines(theme: Theme, width: number, view: UsageView, selected: number): string[] {
  if (view.kind !== "snapshot") {
    return view.kind === "loading"
      ? loadingLines(theme, width, view.message)
      : unavailableLines(theme, width, view.message, false);
  }
  const cards = selectableUsageResetCards(view.snapshot);
  const reported = view.snapshot.resetCards?.availableCount ?? 0;
  const lines = [
    frameTop(theme, width, "π  USAGE RESET CARDS", "warning"),
    frameColumns(
      theme,
      width,
      theme.fg("text", theme.bold("Five-hour + weekly allowance")),
      theme.fg(cards.length ? "success" : "warning", `${reported} reported`),
    ),
    frameRow(theme, width, theme.fg("muted", "Select a freshly retrieved card; provider identifiers stay hidden.")),
    frameRow(theme, width),
  ];

  if (!cards.length) {
    const detailsMissing = reported > 0 && view.snapshot.resetCards?.cards === null;
    lines.push(frameRow(
      theme,
      width,
      theme.fg("warning", detailsMissing
        ? "Cards are reported, but selectable details are unavailable. Retry after updating Codex CLI."
        : "No unexpired, available Codex reset card can be selected."),
    ));
  } else {
    const safeSelected = Math.max(0, Math.min(cards.length - 1, selected));
    const start = Math.max(0, Math.min(safeSelected - 2, cards.length - MAX_VISIBLE_RESET_CARDS));
    const visible = cards.slice(start, start + MAX_VISIBLE_RESET_CARDS);
    for (const [offset, card] of visible.entries()) {
      const index = start + offset;
      const active = index === safeSelected;
      const prefix = active ? theme.fg("accent", "›") : theme.fg("muted", " ");
      const number = `${card.displayIndex}.`;
      const title = resetCardTitle(card);
      lines.push(frameRow(
        theme,
        width,
        `${prefix} ${theme.fg(active ? "accent" : "text", active ? theme.bold(number) : number)} ${theme.fg(active ? "text" : "muted", active ? theme.bold(title) : title)}`,
      ));
      const expiry = card.expiresAt === null ? "no expiry reported" : `expires ${absoluteTime(card.expiresAt)}`;
      lines.push(frameRow(
        theme,
        width,
        `    ${theme.fg("success", "five-hour + weekly")}${theme.fg("muted", ` · ${expiry}`)}`,
      ));
    }
    if (cards.length > visible.length) {
      lines.push(frameRow(theme, width, theme.fg("muted", `${start} above · ${cards.length - start - visible.length} below`)));
    }
  }

  lines.push(frameRow(theme, width));
  lines.push(frameBottom(theme, width, cards.length ? "↑↓ navigate · Enter preview · Esc back" : "Esc back"));
  return lines;
}

function previewLines(theme: Theme, width: number, selection: UsageResetCardSelection): string[] {
  const expiry = selection.expiresAt === null ? "No expiry was reported." : `Expires ${absoluteTime(selection.expiresAt)}.`;
  return [
    frameTop(theme, width, `π  APPLY USAGE RESET CARD ${selection.displayIndex}?`, "warning"),
    frameRow(theme, width, theme.fg("text", theme.bold(resetCardTitle(selection)))),
    frameRow(theme, width, theme.fg("muted", usageResetCardEffect(selection))),
    frameRow(theme, width),
    frameRow(theme, width, `${theme.fg("success", "•")} ${theme.fg("text", "Reset five-hour allowance")}`),
    frameRow(theme, width, `${theme.fg("success", "•")} ${theme.fg("text", "Reset weekly allowance")}`),
    frameRow(theme, width),
    frameRow(theme, width, theme.fg("text", expiry)),
    frameRow(theme, width, theme.fg("warning", theme.bold("Applying consumes the card and cannot be undone."))),
    frameRow(theme, width, theme.fg("muted", "Availability and effect will be revalidated immediately before application.")),
    frameRow(theme, width),
    frameBottom(theme, width, "Enter apply · Esc cancel"),
  ];
}

function applyingLines(theme: Theme, width: number, selection: UsageResetCardSelection): string[] {
  return [
    frameTop(theme, width, `π  APPLYING CARD ${selection.displayIndex}`, "warning"),
    frameRow(theme, width),
    frameRow(theme, width, `${theme.fg("warning", "∴")} ${theme.fg("text", theme.bold("Revalidating and applying once…"))}`),
    frameRow(theme, width, theme.fg("muted", "Repeated input is disabled; an idempotency key protects this attempt.")),
    frameRow(theme, width, theme.fg("muted", "Do not close Pi until the provider returns a definite outcome.")),
    frameRow(theme, width),
    frameBottom(theme, width, "application in progress"),
  ];
}

function resultLines(
  theme: Theme,
  width: number,
  page: Extract<UsageOverlayPage, { kind: "result" }>,
): string[] {
  const color: UiColor = page.tone === "success" ? "success" : page.tone === "warning" ? "warning" : "error";
  const lines = [
    frameTop(theme, width, `π  ${page.title.toUpperCase()}`, color),
    frameRow(theme, width),
  ];
  for (const wrapped of wrapPlain(page.message, Math.max(12, width - 4))) {
    lines.push(frameRow(theme, width, theme.fg(color, wrapped)));
  }
  lines.push(frameRow(theme, width));
  lines.push(frameBottom(theme, width, `Esc ${page.back === "main" ? "allowance" : "back to cards"}`));
  return lines;
}

export function renderUsageOverlay(theme: Theme, width: number, state: UsageOverlayRenderState): string[] {
  const safeWidth = Math.max(1, width);
  if (safeWidth < 36) {
    const title = state.page.kind === "resets" || state.page.kind === "preview" || state.page.kind === "applying"
      ? "π reset cards"
      : "π Codex allowance";
    const detail = state.view.kind === "snapshot"
      ? `5h ${windowWithDuration(state.view.snapshot, 300) ? percent(windowWithDuration(state.view.snapshot, 300)!.usedPercent) : "—"} · wk ${windowWithDuration(state.view.snapshot, 10_080) ? percent(windowWithDuration(state.view.snapshot, 10_080)!.usedPercent) : "—"} used`
      : state.view.kind === "loading"
        ? state.view.message
        : state.view.message;
    return [theme.fg("accent", theme.bold(title)), theme.fg("text", truncateToWidth(detail, safeWidth, "")), theme.fg("muted", "Esc close/back")]
      .map((line) => truncateToWidth(line, safeWidth, ""));
  }

  switch (state.page.kind) {
    case "loading":
      return loadingLines(theme, safeWidth, state.page.message);
    case "resets":
      return resetListLines(theme, safeWidth, state.view, state.page.selected);
    case "preview":
      return previewLines(theme, safeWidth, state.page.selection);
    case "applying":
      return applyingLines(theme, safeWidth, state.page.selection);
    case "result":
      return resultLines(theme, safeWidth, state.page);
    case "main":
      if (state.view.kind === "loading") return loadingLines(theme, safeWidth, state.view.message);
      return state.view.kind === "snapshot"
        ? snapshotLines(theme, safeWidth, state.view, state.page.verbose)
        : unavailableLines(theme, safeWidth, state.view.message, state.page.verbose);
  }
}

function plainResetCards(snapshot: CodexUsageSnapshot): string {
  const cards = selectableUsageResetCards(snapshot);
  const lines = [
    "Usage reset cards",
    `Available: ${snapshot.resetCards?.availableCount ?? "unavailable"}`,
  ];
  if (!cards.length) {
    lines.push("No unexpired card with selectable details is available.");
  } else {
    for (const card of cards) {
      const expiry = card.expiresAt === null ? "no expiry reported" : absoluteTime(card.expiresAt);
      lines.push(`${card.displayIndex}. ${resetCardTitle(card)} · five-hour + weekly · expires ${expiry}`);
    }
  }
  lines.push("Application requires interactive TUI confirmation: `/usage resets` or `/usage reset <number>`. No provider ID is displayed.");
  return lines.join("\n");
}

function plainReport(view: UsageView, verbose = false): string {
  if (view.kind === "loading") return `Codex allowance\n${view.message}`;
  if (view.kind === "unavailable") {
    return [
      "Codex allowance unavailable",
      safeText(view.message),
      "Run `codex login status`, then retry `/usage`.",
      "No credentials were read or logged. This is not API billing.",
    ].join("\n");
  }

  const snapshot = view.snapshot;
  const line = (label: string, window: RateLimitWindow | null) => {
    if (!window) return `${label}: unavailable`;
    const reset = window.resetsAt === null
      ? "reset time unavailable"
      : `resets ${relativeTime(window.resetsAt)} (${absoluteTime(window.resetsAt)})`;
    return `${label}: ${percent(window.usedPercent)} used · ${percent(100 - window.usedPercent)} remaining · ${reset}`;
  };
  const lines = [
    `Codex allowance${view.staleReason ? " · stale" : view.cachedOnly ? " · cached" : ""}`,
    `Plan: ${safeText(snapshot.rateLimits.planType ?? "unavailable")}`,
    line("Five-hour", windowWithDuration(snapshot, 300)),
    line("Weekly", windowWithDuration(snapshot, 10_080)),
    `Usage reset cards: ${snapshot.resetCards ? `${snapshot.resetCards.availableCount} available` : "unavailable"}`,
    `Refreshed: ${sourceTimestamp(snapshot)}`,
    "ChatGPT/Codex subscription allowance · not OpenAI API billing",
  ];
  if (view.staleReason) lines.splice(1, 0, `Live refresh failed: ${safeText(view.staleReason)}`);
  if (verbose) {
    lines.push(
      `Read source: ${snapshot.sourceMethod}${snapshot.serverUserAgent ? ` · ${safeText(snapshot.serverUserAgent)}` : ""}`,
      "Reset-card application uses account/rateLimitResetCredit/consume only after fresh revalidation and interactive confirmation.",
      "The app-server interface is maintained by OpenAI but currently experimental.",
    );
  }
  return lines.join("\n");
}

function usageHelp(): string {
  return [
    "Codex allowance commands",
    "/usage — refresh and open allowance",
    "/usage cached — open the in-memory snapshot without a request",
    "/usage verbose — open with protocol details",
    "/usage resets — refresh and list usage reset cards",
    "/usage reset <number> — refresh and preview one card",
    "Inside allowance: v details · r reset cards · Esc close",
    "Inside cards: ↑↓ navigate · Enter preview/apply · Esc back/cancel",
  ].join("\n");
}

class UsageOverlayController {
  private view: UsageView = { kind: "loading", message: "Refreshing Codex allowance…" };
  private page: UsageOverlayPage = { kind: "loading", message: "Refreshing Codex allowance…" };
  private disposed = false;
  private generation = 0;
  private previousMain?: UsageView;
  private readonly tui: TUI;
  private readonly theme: Theme;
  private readonly done: (value: void) => void;
  private readonly start: { mode: "refresh" | "cached" | "verbose" | "resets" | "reset"; index?: number };

  constructor(
    tui: TUI,
    theme: Theme,
    done: (value: void) => void,
    start: { mode: "refresh" | "cached" | "verbose" | "resets" | "reset"; index?: number },
  ) {
    this.tui = tui;
    this.theme = theme;
    this.done = done;
    this.start = start;
  }

  begin(): void {
    if (this.start.mode === "cached" && cached) {
      this.view = { kind: "snapshot", snapshot: cached, cachedOnly: true };
      this.page = { kind: "main", verbose: false };
      this.requestRender();
      return;
    }
    if (this.start.mode === "cached") {
      this.view = { kind: "unavailable", message: "No in-memory allowance snapshot yet. Run /usage." };
      this.page = { kind: "main", verbose: false };
      this.requestRender();
      return;
    }
    const target = this.start.mode === "resets"
      ? "resets"
      : this.start.mode === "reset"
        ? "reset"
        : "main";
    void this.load(target, this.start.mode === "verbose", this.start.index);
  }

  render(width: number): string[] {
    const cardWidth = Math.max(4, Math.min(CARD_WIDTH, width));
    return centerLines(renderUsageOverlay(this.theme, cardWidth, { view: this.view, page: this.page }), width);
  }

  invalidate(): void {}

  dispose(): void {
    this.disposed = true;
    this.generation += 1;
  }

  handleInput(data: string): void {
    if (this.page.kind === "applying") return;
    if (matchesKey(data, "ctrl+c")) {
      this.close();
      return;
    }
    if (matchesKey(data, "escape")) {
      this.goBack();
      return;
    }

    if (this.page.kind === "main") {
      if (data.toLowerCase() === "v") {
        this.page.verbose = !this.page.verbose;
        this.requestRender();
      } else if (data.toLowerCase() === "r") {
        this.previousMain = this.view;
        void this.load("resets", false);
      }
      return;
    }

    if (this.page.kind === "resets") {
      const cards = this.cards();
      if (matchesKey(data, "up")) {
        this.page.selected = Math.max(0, this.page.selected - 1);
        this.requestRender();
      } else if (matchesKey(data, "down")) {
        this.page.selected = Math.min(Math.max(0, cards.length - 1), this.page.selected + 1);
        this.requestRender();
      } else if (/^[1-9]$/.test(data)) {
        const index = Number(data) - 1;
        if (index < cards.length) {
          this.page.selected = index;
          this.requestRender();
        }
      } else if (matchesKey(data, "enter") && cards[this.page.selected]) {
        this.page = { kind: "preview", selection: cards[this.page.selected]! };
        this.requestRender();
      }
      return;
    }

    if (this.page.kind === "preview" && matchesKey(data, "enter")) {
      void this.apply(this.page.selection);
    }
  }

  private requestRender(): void {
    if (!this.disposed) this.tui.requestRender();
  }

  private close(): void {
    if (this.disposed) return;
    this.disposed = true;
    this.generation += 1;
    this.done(undefined);
  }

  private goBack(): void {
    switch (this.page.kind) {
      case "main":
        this.close();
        return;
      case "loading":
        if (this.previousMain) {
          this.generation += 1;
          this.view = this.previousMain;
          this.page = { kind: "main", verbose: false };
          this.previousMain = undefined;
          this.requestRender();
        } else {
          this.close();
        }
        return;
      case "resets":
        this.page = { kind: "main", verbose: false };
        this.requestRender();
        return;
      case "preview":
        this.page = { kind: "resets", selected: Math.max(0, this.page.selection.displayIndex - 1) };
        this.requestRender();
        return;
      case "result":
        this.page = this.page.back === "resets"
          ? { kind: "resets", selected: 0 }
          : { kind: "main", verbose: false };
        this.requestRender();
        return;
      case "applying":
        return;
    }
  }

  private cards(): UsageResetCardSelection[] {
    return this.view.kind === "snapshot" ? selectableUsageResetCards(this.view.snapshot) : [];
  }

  private async load(target: "main" | "resets" | "reset", verbose: boolean, requestedIndex?: number): Promise<void> {
    const generation = ++this.generation;
    const message = target === "main" ? "Refreshing Codex allowance…" : "Refreshing usage reset-card availability…";
    this.page = { kind: "loading", message };
    this.requestRender();
    const view = await refreshUsage();
    if (this.disposed || generation !== this.generation) return;
    this.view = view;

    if (target === "main" || view.kind !== "snapshot") {
      this.page = { kind: "main", verbose };
      this.requestRender();
      return;
    }
    if (view.staleReason) {
      this.page = {
        kind: "result",
        tone: "error",
        title: "Fresh card list unavailable",
        message: "Usage reset cards cannot be selected from stale data. Retry after the live allowance refresh succeeds.",
        back: "main",
      };
      this.requestRender();
      return;
    }

    const cards = selectableUsageResetCards(view.snapshot);
    if (target === "reset") {
      const index = Math.max(1, requestedIndex ?? 1) - 1;
      if (!cards[index]) {
        this.page = {
          kind: "result",
          tone: "warning",
          title: "Card unavailable",
          message: `Usage reset card ${index + 1} is not present in the freshly retrieved list.`,
          back: "resets",
        };
      } else {
        this.page = { kind: "preview", selection: cards[index]! };
      }
    } else {
      this.page = { kind: "resets", selected: 0 };
    }
    this.requestRender();
  }

  private async apply(selection: UsageResetCardSelection): Promise<void> {
    if (resetOperation) {
      this.page = {
        kind: "result",
        tone: "warning",
        title: "Application already active",
        message: "Another usage reset-card application is already in progress. No second request was sent.",
        back: "resets",
      };
      this.requestRender();
      return;
    }

    this.page = { kind: "applying", selection };
    this.requestRender();
    const operation = applyUsageResetCard(selection, {
      fetchFresh: () => fetchFresh(),
      fetchUpdated: () => fetchFreshAfterPending(),
      consume: ({ creditId, idempotencyKey }) => consumeCodexUsageResetCard({ creditId, idempotencyKey }),
      makeIdempotencyKey: randomUUID,
    });
    resetOperation = operation;

    try {
      const result = await operation;
      if (this.disposed) return;
      if (result.kind === "success") {
        if (result.snapshot) {
          acceptFresh(result.snapshot);
          this.view = { kind: "snapshot", snapshot: result.snapshot };
        } else {
          cached = undefined;
          this.view = { kind: "unavailable", message: result.refreshError ?? "Updated allowance unavailable" };
        }
        this.page = {
          kind: "result",
          tone: "success",
          title: "Usage reset card applied",
          message: result.outcome === "alreadyRedeemed"
            ? "The provider confirmed that this idempotent application had already completed successfully. Allowance was refreshed."
            : `The provider confirmed the reset. Five-hour and weekly allowance were refreshed.${result.refreshError ? ` ${result.refreshError}` : ""}`,
          back: "main",
        };
      } else {
        acceptFresh(result.snapshot);
        this.view = { kind: "snapshot", snapshot: result.snapshot };
        this.page = {
          kind: "result",
          tone: "warning",
          title: "Card not applied",
          message: result.message,
          back: "resets",
        };
      }
    } catch (error) {
      if (this.disposed) return;
      if (cached) this.view = { kind: "snapshot", snapshot: cached };
      const ambiguous = error instanceof UsageResetCardError && error.kind === "ambiguous";
      this.page = {
        kind: "result",
        tone: "error",
        title: ambiguous ? "Outcome not confirmed" : "Card application failed",
        message: ambiguous
          ? `${errorMessage(error)} Do not submit a different attempt blindly; reopen the refreshed card list first.`
          : errorMessage(error),
        back: "resets",
      };
    } finally {
      if (resetOperation === operation) resetOperation = undefined;
      this.requestRender();
    }
  }
}

async function showUsageOverlay(
  ctx: ExtensionCommandContext,
  start: { mode: "refresh" | "cached" | "verbose" | "resets" | "reset"; index?: number },
): Promise<void> {
  await showAboveEditorModal(ctx, "naldo:codex-usage-card", (tui, theme, done) => {
    const controller = new UsageOverlayController(tui, theme, done, start);
    controller.begin();
    return controller;
  });
}

export default function codexUsageExtension(pi: ExtensionAPI) {
  pi.on("session_shutdown", async () => {
    cached = undefined;
    inFlight = undefined;
    resetOperation = undefined;
  });

  pi.registerCommand("usage", {
    description: "Inspect Codex allowance and apply usage reset cards",
    getArgumentCompletions: (prefix) => {
      const values = ["refresh", "cached", "verbose", "resets", "reset 1", "help"];
      if (cached) {
        for (const card of selectableUsageResetCards(cached)) values.push(`reset ${card.displayIndex}`);
      }
      return [...new Set(values)]
        .filter((value) => value.startsWith(prefix))
        .map((value) => ({ value, label: value }));
    },
    handler: async (args, ctx) => {
      const input = args.trim().toLowerCase();
      if (input === "help") {
        if (ctx.hasUI) ctx.ui.notify(usageHelp(), "info");
        return;
      }

      const resetMatch = input.match(/^reset\s+([1-9][0-9]*)$/);
      const mode = input || "refresh";
      const valid = ["refresh", "cached", "verbose", "resets"].includes(mode) || resetMatch !== null;
      if (!valid) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /usage [refresh|cached|verbose|resets|reset <number>|help]", "warning");
        return;
      }

      if (ctx.mode === "tui") {
        await showUsageOverlay(ctx, resetMatch
          ? { mode: "reset", index: Number(resetMatch[1]) }
          : { mode: mode as "refresh" | "cached" | "verbose" | "resets" });
        return;
      }

      if (mode === "cached") {
        if (cached && ctx.hasUI) ctx.ui.notify(plainReport({ kind: "snapshot", snapshot: cached, cachedOnly: true }), "info");
        else if (ctx.hasUI) ctx.ui.notify("No in-memory allowance snapshot yet; run /usage", "warning");
        return;
      }

      const view = await refreshUsage();
      if (!ctx.hasUI) return;
      if (mode === "resets" || resetMatch) {
        if (view.kind === "snapshot" && !view.staleReason) ctx.ui.notify(plainResetCards(view.snapshot), "info");
        else ctx.ui.notify("A fresh usage reset-card list is unavailable. Application was not attempted.", "warning");
        return;
      }
      const tone = view.kind === "unavailable"
        ? "error"
        : view.kind === "snapshot" && view.staleReason
          ? "warning"
          : view.kind === "snapshot"
            ? allowanceTone(view.snapshot)
            : "info";
      ctx.ui.notify(plainReport(view, mode === "verbose"), tone);
    },
  });
}
