import {
  CustomEditor,
  VERSION,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import {
  CURSOR_MARKER,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";
import { basename } from "node:path";
import {
  isPiBuddyMode,
  PI_BUDDY_MODES,
  randomPiBuddyText,
  showPiBuddy,
} from "./lib/pi-buddy.ts";
import {
  randomGermanSentence,
  randomHeaderTypstFormula,
  type GermanSentence,
  type TypstFormula,
} from "./lib/pi-learning.ts";
import { piMascot } from "./lib/pi-mascot.ts";
import {
  EMPTY_GIT_STATE,
  GitStatusMonitor,
  type GitState,
} from "./lib/git-status.ts";
import {
  formatPercent,
  frameTop,
  padAnsi,
  safeText,
  severityColor,
} from "./lib/ui-kit.ts";
import { useTerminalCursorLines } from "./lib/terminal-cursor.ts";

export type { GitState } from "./lib/git-status.ts";

type RuntimePhase = "idle" | "reasoning" | "tool";

type RuntimeUiState = {
  phase: RuntimePhase;
  activeTools: Map<string, string>;
  thinking: string;
  requestRender?: () => void;
};

export type SessionUsageData = {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  latestCacheHitPercent: number | null;
  cost: number;
};

export type StatusData = {
  project: string;
  cwd: string;
  sessionName?: string;
  git: GitState;
  modelId: string | null;
  thinking: string;
  contextUsedPercent: number | null;
  contextTokens: number | null;
  contextWindow: number | null;
  usage: SessionUsageData;
  yoloMode?: boolean;
  permissionLabel?: string;
  activityLabel?: string;
};

type Segment = {
  styled: string;
  priority: number;
  required?: boolean;
};

type ThinkingColor =
  | "thinkingOff"
  | "thinkingMinimal"
  | "thinkingLow"
  | "thinkingMedium"
  | "thinkingHigh"
  | "thinkingXhigh"
  | "thinkingMax";

function modelLabel(modelId: string | null, compact: boolean): string {
  if (!modelId) return "no model";
  if (compact && /gpt-5\.6-sol$/i.test(modelId)) return "sol";
  return truncateToWidth(modelId, compact ? 12 : 24).toUpperCase();
}

function cwdLabel(cwd: string, maxLength: number): string {
  const home = process.env.HOME;
  const abbreviated =
    home && cwd.startsWith(`${home}/`) ? `~${cwd.slice(home.length)}` : cwd;
  if (visibleWidth(abbreviated) <= maxLength) return abbreviated;
  const leaf = abbreviated.split("/").filter(Boolean).at(-1) ?? abbreviated;
  const compact = abbreviated.startsWith("~/") ? `~/…/${leaf}` : `…/${leaf}`;
  return truncateToWidth(compact, maxLength, "");
}

function dirtyMark(git: GitState): string {
  return [git.tracked > 0 ? `!${git.tracked}` : "", git.untracked > 0 ? `?${git.untracked}` : ""]
    .filter(Boolean)
    .join(" ");
}

function segment(styled: string, priority: number, required = false): Segment {
  return { styled, priority, required };
}

function separator(theme: Theme): string {
  return theme.fg("border", "  ");
}

function joinedWidth(theme: Theme, segments: Segment[]): number {
  return segments.reduce(
    (total, entry) => total + visibleWidth(entry.styled),
    Math.max(0, segments.length - 1) * visibleWidth(separator(theme)),
  );
}

function fitSegments(
  theme: Theme,
  segments: Segment[],
  width: number,
): Segment[] {
  const result = [...segments];
  while (result.length > 2 && joinedWidth(theme, result) > width) {
    const removable = result
      .map((entry, index) => ({ ...entry, index }))
      .filter((entry) => !entry.required)
      .sort(
        (left, right) =>
          left.priority - right.priority || right.index - left.index,
      )[0];
    if (!removable) break;
    result.splice(removable.index, 1);
  }
  return result;
}

function formatTokens(value: number): string {
  const safe = Math.max(0, value);
  if (safe < 1_000) return String(Math.round(safe));
  if (safe < 1_000_000)
    return `${(safe / 1_000).toFixed(safe < 10_000 ? 1 : 0)}k`;
  return `${(safe / 1_000_000).toFixed(safe < 10_000_000 ? 1 : 0)}m`;
}

function usageSegment(theme: Theme, usage: SessionUsageData): Segment {
  const metric = (symbol: string, value: string) =>
    `${theme.fg("muted", symbol)}${theme.fg("text", value)}`;
  const cacheHit =
    usage.latestCacheHitPercent === null
      ? "—"
      : `${Math.round(usage.latestCacheHitPercent)}%`;
  const cost = usage.cost < 10 ? usage.cost.toFixed(4) : usage.cost.toFixed(2);
  return segment(
    [
      metric("↑", formatTokens(usage.input)),
      metric("↓", formatTokens(usage.output)),
      metric("R", formatTokens(usage.cacheRead)),
      metric("W", formatTokens(usage.cacheWrite)),
      metric("CH", cacheHit),
      metric("$", cost),
    ].join(theme.fg("muted", " ")),
    110,
    true,
  );
}

export function sessionUsage(
  branch: ReturnType<ExtensionCommandContext["sessionManager"]["getBranch"]>,
): SessionUsageData {
  let input = 0;
  let output = 0;
  let cacheRead = 0;
  let cacheWrite = 0;
  let cost = 0;
  let latestCacheHitPercent: number | null = null;
  for (const entry of branch) {
    if (entry.type !== "message" || entry.message.role !== "assistant")
      continue;
    const message = entry.message as AssistantMessage;
    const messageInput = Number.isFinite(message.usage?.input)
      ? message.usage.input
      : 0;
    const messageOutput = Number.isFinite(message.usage?.output)
      ? message.usage.output
      : 0;
    const messageCacheRead = Number.isFinite(message.usage?.cacheRead)
      ? message.usage.cacheRead
      : 0;
    const messageCacheWrite = Number.isFinite(message.usage?.cacheWrite)
      ? message.usage.cacheWrite
      : 0;
    input += messageInput;
    output += messageOutput;
    cacheRead += messageCacheRead;
    cacheWrite += messageCacheWrite;
    cost += Number.isFinite(message.usage?.cost?.total)
      ? message.usage.cost.total
      : 0;
    const latestInput = messageInput + messageCacheRead;
    latestCacheHitPercent =
      latestInput > 0 ? (messageCacheRead / latestInput) * 100 : null;
  }
  return { input, output, cacheRead, cacheWrite, latestCacheHitPercent, cost };
}

export function renderStatusBar(
  theme: Theme,
  width: number,
  data: StatusData,
): string[] {
  const safeWidth = Math.max(1, width);
  const project =
    safeText(data.project, safeWidth < 60 ? 14 : 24) || "workspace";
  const dirty = dirtyMark(data.git);
  const segments: Segment[] = [
    segment(theme.fg("accent", theme.bold("π")), 130, true),
  ];

  const compactModel = safeWidth < 82;
  segments.push(
    segment(
      `${theme.fg("warning", modelLabel(data.modelId, compactModel))}${theme.fg("muted", compactModel ? "/" : " · ")}${theme.fg("warning", data.thinking)}`,
      120,
      true,
    ),
  );

  if (data.yoloMode) {
    segments.push(segment(theme.fg("error", theme.bold("YOLO")), 129, true));
  }

  if (safeWidth >= 48) {
    const location = safeWidth >= 112
      ? cwdLabel(data.cwd, safeWidth >= 150 ? 34 : 24)
      : project;
    segments.push(segment(theme.fg("accent", location), 118, true));
  }

  if (data.sessionName && safeWidth >= 96) {
    segments.push(
      segment(theme.fg("muted", safeText(data.sessionName, 22)), 42),
    );
  }

  if (safeWidth >= 62 && data.git.available && data.git.branch) {
    const branch = safeText(data.git.branch, safeWidth >= 140 ? 26 : 14);
    segments.push(
      segment(
        `${theme.fg("warning", branch)}${dirty ? ` ${theme.fg("error", dirty)}` : ""}`,
        82,
      ),
    );
  }

  if (data.permissionLabel) {
    const label = safeText(
      data.permissionLabel.replace(/^Permission:\s*/i, "approval"),
      32,
    );
    segments.push(segment(theme.fg("warning", theme.bold(label)), 125));
  } else if (data.activityLabel) {
    segments.push(
      segment(theme.fg("success", safeText(data.activityLabel, 24)), 105),
    );
  }

  if (data.contextUsedPercent === null) {
    segments.push(
      segment(
        theme.fg("warning", safeWidth < 58 ? "ctx —" : "ctx unavailable"),
        115,
        true,
      ),
    );
  } else {
    const value = formatPercent(data.contextUsedPercent);
    const color = severityColor(data.contextUsedPercent, 70, 85);
    const capacity =
      data.contextTokens !== null &&
      data.contextWindow !== null &&
      safeWidth >= 84
        ? theme.fg(
            "muted",
            ` · ${formatTokens(data.contextTokens)}/${formatTokens(data.contextWindow)}`,
          )
        : "";
    segments.push(
      segment(
        `${theme.fg("muted", "ctx ")}${theme.fg(color, theme.bold(`${value}%`))}${capacity}`,
        115,
        true,
      ),
    );
  }

  const tokens = usageSegment(theme, data.usage);
  if (safeWidth >= 100) segments.push(tokens);
  const fitted = fitSegments(theme, segments, safeWidth);
  const primary = truncateToWidth(
    fitted.map((entry) => entry.styled).join(separator(theme)),
    safeWidth,
    "",
  );
  if (safeWidth >= 100) return [primary];
  return [primary, truncateToWidth(`  ${tokens.styled}`, safeWidth, "")];
}

function headerLine(theme: Theme, width: number, content: string): string {
  return truncateToWidth(`  ${content}`, width, "");
}

function centerAnsi(value: string, width: number): string {
  const gap = Math.max(0, width - visibleWidth(value));
  const left = Math.floor(gap / 2);
  return `${" ".repeat(left)}${value}${" ".repeat(gap - left)}`;
}

function dashboardHeader(
  theme: Theme,
  width: number,
  data: HeaderLearning,
  version: string,
  hints: string,
): string[] {
  const margin = 2;
  const panelWidth = Math.max(4, width - 2 * margin);
  const contentWidth = Math.max(1, panelWidth - 4);
  const separatorWidth = 3;
  const available = Math.max(1, contentWidth - separatorWidth);
  const leftWidth = Math.max(1, Math.floor(available / 2));
  const rightWidth = Math.max(1, available - leftWidth);
  const indent = " ".repeat(margin);
  const mascot = piMascot(theme);
  const formula = data.formula.source.length <= Math.max(1, rightWidth - 10)
    ? data.formula.source
    : data.formula.compactSource;
  const entry = (
    name: string,
    value: string,
    labelColor: "accent" | "warning" | "success",
    valueColor: "text" | "muted" | "success" = "text",
  ) => truncateToWidth(
    `${theme.fg(labelColor, theme.bold(name.padEnd(9)))}${theme.fg(valueColor, value)}`,
    rightWidth,
    "…",
  );
  const divider = theme.fg("border", "─".repeat(rightWidth));
  const left = [
    "",
    centerAnsi(theme.fg("text", theme.bold("Welcome back, Naldo!")), leftWidth),
    "",
    ...mascot.map((line) => centerAnsi(line, leftWidth)),
    "",
  ];
  const right = [
    "",
    entry("DEUTSCH", data.german.german, "accent"),
    entry("ENGLISH", data.german.english, "warning", "muted"),
    "",
    divider,
    entry("TYPST", formula, "success", "success"),
    "",
    divider,
    entry("DISCOVER", hints, "accent", "muted"),
    "",
  ];
  const rows = Array.from({ length: Math.max(left.length, right.length) }, (_, index) =>
    `${indent}${theme.fg("borderAccent", "│")} ${padAnsi(left[index] ?? "", leftWidth)}${theme.fg("border", " │ ")}${padAnsi(right[index] ?? "", rightWidth)} ${theme.fg("borderAccent", "│")}`,
  );
  const title = `${theme.fg("accent", theme.bold("π"))} ${theme.fg("muted", version)}`;
  return [
    `${indent}${frameTop(theme, panelWidth, title, "accent")}`,
    ...rows,
    `${indent}${theme.fg("borderAccent", `╰${"─".repeat(Math.max(0, panelWidth - 2))}╯`)}`,
  ];
}

export type HeaderLearning = {
  formula: TypstFormula;
  german: GermanSentence;
};

export function renderHeader(
  theme: Theme,
  width: number,
  data: HeaderLearning & { version?: string },
): string[] {
  const safeWidth = Math.max(1, width);
  const version = data.version ?? VERSION;
  const hints = "/usage · /safety · /pi-buddy";

  if (safeWidth >= 88) {
    return ["", ...dashboardHeader(theme, safeWidth, data, version, hints), ""];
  }

  const row = (
    name: string,
    value: string,
    labelColor: "accent" | "warning" | "success",
    valueColor: "text" | "muted" | "success" = "text",
  ) => truncateToWidth(
    `  ${theme.fg(labelColor, theme.bold(name.padEnd(9)))}${theme.fg(valueColor, value)}`,
    safeWidth,
    "…",
  );
  const formula = safeWidth >= 64 ? data.formula.source : data.formula.compactSource;
  return [
    "",
    headerLine(theme, safeWidth, `${theme.fg("accent", theme.bold("π"))} ${theme.fg("muted", version)}`),
    headerLine(theme, safeWidth, theme.fg("text", theme.bold("Welcome back, Naldo!"))),
    row("DEUTSCH", data.german.german, "accent"),
    row("ENGLISH", data.german.english, "warning", "muted"),
    row("TYPST", formula, "success", "success"),
    row("DISCOVER", hints, "accent", "muted"),
    "",
  ];
}

function thinkingColor(level: string): ThinkingColor {
  const normalized = level.toLowerCase();
  if (normalized === "off") return "thinkingOff";
  if (normalized === "minimal") return "thinkingMinimal";
  if (normalized === "low") return "thinkingLow";
  if (normalized === "medium") return "thinkingMedium";
  if (normalized === "high") return "thinkingHigh";
  if (normalized === "xhigh") return "thinkingXhigh";
  return "thinkingMax";
}

function stripControls(value: string): string {
  return value
    .replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "")
    .replace(/\x1b_.*?\x07/g, "");
}

function isRule(value: string): boolean {
  const plain = stripControls(value);
  return plain.length > 0 && [...plain].every((character) => character === "─");
}

function composerTop(
  theme: Theme,
  width: number,
  title: string,
  color: ThinkingColor | "bashMode" | "warning",
): string {
  const label = truncateToWidth(` ${title} `, Math.max(1, width - 2), "");
  const trailing = Math.max(0, width - 2 - visibleWidth(label));
  return `${theme.fg(color, "──")}${theme.fg(color, theme.bold(label))}${theme.fg(color, "─".repeat(trailing))}`;
}

function composerBottom(
  theme: Theme,
  width: number,
  color: ThinkingColor | "bashMode" | "warning",
): string {
  return theme.fg(color, "─".repeat(Math.max(1, width)));
}

class ScholarEditor extends CustomEditor {
  private scholarTheme?: Theme;
  private runtime?: RuntimeUiState;

  configure(theme: Theme, runtime: RuntimeUiState): this {
    this.scholarTheme = theme;
    this.runtime = runtime;
    return this;
  }

  private renderBase(width: number): string[] {
    return useTerminalCursorLines(
      super.render(width),
      CURSOR_MARKER,
      this.focused,
    );
  }

  render(width: number): string[] {
    const theme = this.scholarTheme;
    const runtime = this.runtime;
    if (!theme || !runtime || width < 28) return this.renderBase(width);

    const text = this.getText();
    const shellMode = /^\s*!/.test(text);
    const phase = runtime.phase;
    const mode = shellMode
      ? "shell"
      : phase === "tool"
        ? "tools"
        : phase === "reasoning"
          ? "steer"
          : text.trim()
            ? "compose"
            : "ask";
    const color: ThinkingColor | "bashMode" | "warning" = shellMode
      ? "bashMode"
      : phase === "tool"
        ? "warning"
        : thinkingColor(runtime.thinking);
    const composerWidth = width;
    const contentWidth = Math.max(12, composerWidth - 2);
    const base = this.renderBase(contentWidth);
    const bottomIndex = base.findIndex(
      (line, index) => index > 0 && isRule(line),
    );
    if (bottomIndex < 2) return this.renderBase(width);

    const body = base.slice(1, bottomIndex);
    const completion = base.slice(bottomIndex + 1);
    const title = `π ${mode}`;
    const bodyLines = body.map((line) => {
      const content = line.startsWith(" ") ? line.slice(1) : line;
      return truncateToWidth(`  ${content}`, composerWidth, "");
    });
    const completionLines = completion.map((line) => {
      const content = line.startsWith(" ") ? line.slice(1) : line;
      return truncateToWidth(`  ${content}`, composerWidth, "");
    });
    const completionDivider = completion.length
      ? [
          `${theme.fg(color, "──")}${theme.fg("muted", " matches ")}${theme.fg(color, "─".repeat(Math.max(0, composerWidth - 11)))}`,
        ]
      : [];

    return [
      composerTop(theme, composerWidth, title, color),
      ...bodyLines,
      ...completionDivider,
      ...completionLines,
      composerBottom(theme, composerWidth, color),
    ];
  }
}

export default function uiExtension(pi: ExtensionAPI) {
  let git = EMPTY_GIT_STATE;
  let headerLearning: HeaderLearning = {
    formula: randomHeaderTypstFormula(),
    german: randomGermanSentence(),
  };
  let permissionCount = 0;
  let permissionLabel: string | undefined;
  let requestRender: (() => void) | undefined;
  let restoreHardwareCursor: (() => void) | undefined;
  const runtime: RuntimeUiState = {
    phase: "idle",
    activeTools: new Map(),
    thinking: "max",
  };

  const updateRender = () => {
    requestRender?.();
    runtime.requestRender?.();
  };

  const gitMonitor = new GitStatusMonitor(
    async (cwd, args) => pi.exec("git", ["-C", cwd, ...args], { timeout: 5_000 }),
    (state) => {
      git = state;
      updateRender();
    },
  );

  pi.registerCommand("pi-buddy", {
    description: "Ask Pi for a random learning break, game, thought, or anime pick",
    getArgumentCompletions: (prefix) => ["random", ...PI_BUDDY_MODES]
      .filter((value) => value.startsWith(prefix))
      .map((value) => ({ value, label: value })),
    handler: async (args, ctx) => {
      const input = args.trim().toLowerCase();
      const request = input === "" || input === "random"
        ? "random"
        : isPiBuddyMode(input)
          ? input
          : null;
      if (!request) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /pi-buddy [german|typst|concept|quote|rps|anime]", "warning");
        return;
      }
      if (ctx.mode === "tui") await showPiBuddy(ctx, request);
      else if (ctx.hasUI) ctx.ui.notify(randomPiBuddyText(request), "info");
    },
  });

  pi.events.on("herdr:blocked", (value) => {
    const event = value as { active?: boolean; label?: string } | undefined;
    if (event?.active) {
      permissionCount += 1;
      permissionLabel = event.label ?? "approval required";
    } else {
      permissionCount = Math.max(0, permissionCount - 1);
      if (permissionCount === 0) permissionLabel = undefined;
    }
    updateRender();
  });

  const activityLabel = (): string | undefined => {
    if (runtime.phase === "tool") {
      const tool = [...runtime.activeTools.values()].at(-1);
      return tool ? `tool ${tool}` : "tool running";
    }
    return runtime.phase === "reasoning" ? "∴ reasoning" : undefined;
  };

  pi.on("user_bash", () => {
    // This event precedes execution. A short delayed hint covers ordinary shell
    // edits; Git metadata watches independently catch long-running Git actions.
    gitMonitor.requestRefresh(250);
  });

  pi.on("session_start", async (_event, ctx) => {
    const project = safeText(basename(ctx.cwd) || "workspace", 32);
    git = EMPTY_GIT_STATE;
    headerLearning = {
      formula: randomHeaderTypstFormula(headerLearning.formula),
      german: randomGermanSentence(headerLearning.german),
    };
    runtime.phase = "idle";
    runtime.activeTools.clear();
    runtime.thinking = pi.getThinkingLevel();
    if (ctx.mode === "tui") {
      ctx.ui.setTitle(`π · ${project}`);
      ctx.ui.setWorkingIndicator({
        frames: [
          ctx.ui.theme.fg("muted", "·"),
          ctx.ui.theme.fg("accent", "∴"),
          ctx.ui.theme.fg("warning", "∵"),
          ctx.ui.theme.fg("accent", "∴"),
        ],
        intervalMs: 180,
      });
      ctx.ui.setHeader((_tui, theme) => ({
        render: (width: number) => renderHeader(theme, width, headerLearning),
        invalidate() {},
      }));
      ctx.ui.setEditorComponent((tui, theme, keybindings) => {
        runtime.requestRender = () => tui.requestRender();
        if (!restoreHardwareCursor) {
          const wasVisible = tui.getShowHardwareCursor();
          restoreHardwareCursor = () => tui.setShowHardwareCursor(wasVisible);
        }
        tui.setShowHardwareCursor(true);
        return new ScholarEditor(tui, theme, keybindings).configure(
          ctx.ui.theme,
          runtime,
        );
      });
      ctx.ui.setFooter((tui, theme, footerData) => {
        const footerRequestRender = () => tui.requestRender();
        requestRender = footerRequestRender;
        return {
          dispose() {
            if (requestRender === footerRequestRender) requestRender = undefined;
          },
          invalidate() {},
          render(width: number): string[] {
            const usage = ctx.getContextUsage();
            const contextPercent =
              usage && ctx.model?.contextWindow
                ? (usage.tokens / ctx.model.contextWindow) * 100
                : null;
            return renderStatusBar(theme, width, {
              project,
              cwd: ctx.cwd,
              sessionName: ctx.sessionManager.getSessionName(),
              git,
              modelId: ctx.model?.id ?? null,
              thinking: pi.getThinkingLevel(),
              contextUsedPercent: contextPercent,
              contextTokens: usage?.tokens ?? null,
              contextWindow: ctx.model?.contextWindow ?? null,
              usage: sessionUsage(ctx.sessionManager.getBranch()),
              yoloMode: footerData.getExtensionStatuses().has("safety-guard"),
              permissionLabel:
                permissionCount > 0 ? permissionLabel : undefined,
              activityLabel: activityLabel(),
            });
          },
        };
      });
      await gitMonitor.start(ctx.cwd);
    }
  });

  pi.on("agent_start", async (_event, ctx) => {
    runtime.phase = "reasoning";
    if (ctx.mode === "tui") ctx.ui.setWorkingMessage("reasoning");
    updateRender();
  });

  pi.on("tool_execution_start", async (event, ctx) => {
    runtime.activeTools.set(event.toolCallId, event.toolName);
    runtime.phase = "tool";
    if (ctx.mode === "tui")
      ctx.ui.setWorkingMessage(`tool · ${event.toolName}`);
    updateRender();
  });

  pi.on("tool_execution_end", async (event, ctx) => {
    runtime.activeTools.delete(event.toolCallId);
    runtime.phase = runtime.activeTools.size ? "tool" : "reasoning";
    if (ctx.mode === "tui" && runtime.phase === "reasoning")
      ctx.ui.setWorkingMessage("synthesizing");
    // Custom and namespaced tools can mutate the worktree too.
    gitMonitor.requestRefresh();
    updateRender();
  });

  pi.on("agent_settled", async (_event, ctx) => {
    runtime.phase = "idle";
    runtime.activeTools.clear();
    if (ctx.mode === "tui") ctx.ui.setWorkingMessage();
    gitMonitor.requestRefresh();
    updateRender();
  });

  pi.on("model_select", async () => updateRender());
  pi.on("session_info_changed", async () => updateRender());
  pi.on("session_tree", async () => updateRender());
  pi.on("session_compact", async () => updateRender());
  pi.on("thinking_level_select", async (event) => {
    runtime.thinking = event.level;
    updateRender();
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    gitMonitor.stop();
    requestRender = undefined;
    runtime.requestRender = undefined;
    runtime.activeTools.clear();
    runtime.phase = "idle";
    if (ctx.mode === "tui") {
      ctx.ui.setWorkingMessage();
      ctx.ui.setWorkingIndicator();
      ctx.ui.setEditorComponent(undefined);
      restoreHardwareCursor?.();
      restoreHardwareCursor = undefined;
    }
  });
}
