import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import { lstat, readFile, readdir } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { fetchCodexUsage } from "./codex-usage/client.ts";
import { showReport } from "./lib/report.ts";

type Status = "pass" | "warn" | "fail";
type Check = {
  status: Status;
  label: string;
  detail: string;
  action?: string;
};
type JsonObject = Record<string, unknown>;

const home = homedir();
const root = resolve(home, ".pi/agent");
const expectedPrompts = [
  "coach",
  "data-analysis",
  "derive",
  "experiment",
  "mental-model",
  "oral-exam",
  "paper",
  "proof-review",
  "python",
  "typst-notes",
  "verify",
  "write",
];
const expectedSkills = [
  "academic-writing",
  "computational-neuroscience",
  "linux-research-workflow",
  "mathematical-reasoning",
  "ml-experimentation",
  "paper-reading-reproduction",
  "scientific-documents",
  "scientific-python",
  "statistical-data-analysis",
  "study-coach",
  "typst-math-authoring",
];

function object(value: unknown): JsonObject | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonObject)
    : null;
}

function clean(value: string, maxLength = 500): string {
  return value
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxLength);
}

function firstLine(stdout: string, stderr: string): string {
  return clean(`${stdout}\n${stderr}`.split(/\r?\n/).find((line) => line.trim()) ?? "");
}

async function readJson(path: string): Promise<JsonObject> {
  const parsed = JSON.parse(await readFile(path, "utf8"));
  const value = object(parsed);
  if (!value) throw new Error("top-level value is not an object");
  return value;
}

async function configurationCheck(): Promise<{ check: Check; settings?: JsonObject }> {
  const files = ["settings.json", "keybindings.json", "themes/noctalia.json", "trust.json"];
  try {
    const [settings, keybindings, theme] = await Promise.all(files.map((file) => readJson(join(root, file))));
    const colors = object(theme.colors);
    const compaction = object(settings.compaction);
    const keybindingsValid = Object.values(keybindings).every(
      (value) => typeof value === "string" || (Array.isArray(value) && value.every((key) => typeof key === "string")),
    );
    const valid = settings.defaultProjectTrust === "ask"
      && settings.theme === "noctalia"
      && settings.quietStartup === true
      && settings.enableAnalytics === false
      && settings.enableInstallTelemetry === false
      && typeof compaction?.reserveTokens === "number"
      && typeof compaction?.keepRecentTokens === "number"
      && theme.name === "noctalia"
      && typeof colors?.accent === "string"
      && colors?.dim === "fgMuted"
      && colors?.mdCodeBlockBorder === "fgMuted"
      && colors?.borderMuted === "outline"
      && typeof colors?.thinkingXhigh === "string"
      && keybindingsValid;

    return {
      settings,
      check: valid
        ? { status: "pass", label: "Configuration", detail: "settings, keybindings, Noctalia theme, and trust JSON are valid" }
        : { status: "fail", label: "Configuration", detail: "JSON parsed, but one or more required policy/theme fields are invalid", action: "Inspect ~/.pi/agent/settings.json and run jq on all four JSON files." },
    };
  } catch (error) {
    return {
      check: {
        status: "fail",
        label: "Configuration",
        detail: `could not parse required JSON: ${clean(error instanceof Error ? error.message : String(error))}`,
        action: "Fix the first JSON parse error, then run /reload.",
      },
    };
  }
}

function resourceCheck(pi: ExtensionAPI, ctx: ExtensionCommandContext): Check {
  const commands = pi.getCommands();
  const names = new Set(commands.map((command) => command.name));
  const expected = ["doctor", "usage", "pi-buddy", "safety", ...expectedPrompts, ...expectedSkills.map((name) => `skill:${name}`)];
  if (ctx.isProjectTrusted() && objectExists(join(ctx.cwd, ".pi"))) {
    expected.push("focus", "check", "start", "exercise", "diagnostic", "finish", "weekly-review", "skill:learning-workspace");
  }
  const missing = expected.filter((name) => !names.has(name));
  const duplicates = commands.filter((command) => /:\d+$/.test(command.name)).map((command) => command.name);
  const sourceCounts = commands.reduce<Record<string, number>>((counts, command) => {
    counts[command.source] = (counts[command.source] ?? 0) + 1;
    return counts;
  }, {});

  if (missing.length || duplicates.length) {
    return {
      status: "fail",
      label: "Resources",
      detail: `${missing.length ? `missing ${missing.join(", ")}` : "all expected commands present"}${duplicates.length ? `; duplicate commands ${duplicates.join(", ")}` : ""}`,
      action: "Run /reload and inspect Pi startup diagnostics for the first resource error.",
    };
  }
  return {
    status: "pass",
    label: "Resources",
    detail: `${sourceCounts.extension ?? 0} extension commands · ${sourceCounts.prompt ?? 0} prompts · ${sourceCounts.skill ?? 0} skill commands; no collisions`,
  };
}

function objectExists(path: string): boolean {
  return existsSync(path);
}

function runtimeCheck(pi: ExtensionAPI, ctx: ExtensionCommandContext, settings?: JsonObject): Check {
  const model = ctx.model;
  const thinking = pi.getThinkingLevel();
  const activeTools = pi.getActiveTools();
  const missingTools = ["read", "bash", "edit", "write"].filter((tool) => !activeTools.includes(tool));
  const configuredModel = `${settings?.defaultProvider ?? "?"}/${settings?.defaultModel ?? "?"}`;
  const currentModel = model ? `${model.provider}/${model.id}` : "none";
  const contextWindow = model && typeof model.contextWindow === "number"
    ? `${Math.round(model.contextWindow / 1000)}K context`
    : "context size unavailable";

  if (!model || missingTools.length || currentModel !== configuredModel || thinking !== settings?.defaultThinkingLevel) {
    return {
      status: "warn",
      label: "Runtime",
      detail: `${currentModel} · thinking ${thinking} · ${contextWindow}${missingTools.length ? ` · missing tools ${missingTools.join(", ")}` : ""}`,
      action: "Use /model or /settings if the current runtime differs intentionally; otherwise restart Pi after /reload.",
    };
  }
  return { status: "pass", label: "Runtime", detail: `${currentModel} · thinking ${thinking} · ${contextWindow} · ${activeTools.length} active tools` };
}

async function walkModes(path: string): Promise<{ insecure: number; checked: number }> {
  let insecure = 0;
  let checked = 0;
  const visit = async (current: string) => {
    let stats;
    try {
      stats = await lstat(current);
    } catch {
      return;
    }
    checked += 1;
    if ((stats.mode & 0o077) !== 0) insecure += 1;
    if (!stats.isDirectory() || stats.isSymbolicLink()) return;
    for (const entry of await readdir(current)) await visit(join(current, entry));
  };
  await visit(path);
  return { insecure, checked };
}

async function singleMode(path: string): Promise<{ insecure: number; checked: number }> {
  try {
    const stats = await lstat(path);
    return { insecure: (stats.mode & 0o077) === 0 ? 0 : 1, checked: 1 };
  } catch {
    return { insecure: 0, checked: 0 };
  }
}

async function privacyCheck(): Promise<Check> {
  const privatePaths = [
    resolve(home, ".pi"),
    root,
    join(root, "auth.json"),
    join(root, "agent.db"),
    join(root, "trust.json"),
    resolve(home, ".codex/auth.json"),
  ];
  let insecure = 0;
  let checked = 0;
  for (const path of privatePaths) {
    const result = await singleMode(path);
    insecure += result.insecure;
    checked += result.checked;
  }
  const sessions = await walkModes(join(root, "sessions"));
  insecure += sessions.insecure;
  checked += sessions.checked;

  if (insecure > 0) {
    return {
      status: "fail",
      label: "Private state",
      detail: `${insecure} of ${checked} Pi state paths are group/world accessible`,
      action: "Reload Pi so safety-guard can harden the active session, then inspect modes with stat (never print credential contents).",
    };
  }
  return { status: "pass", label: "Private state", detail: `${checked} credential/database/trust/session path modes are private; contents were not read` };
}

async function commandResult(
  pi: ExtensionAPI,
  command: string,
  args: string[],
  timeout = 10_000,
): Promise<{ ok: boolean; line: string }> {
  try {
    const result = await pi.exec(command, args, { timeout });
    return { ok: result.code === 0, line: firstLine(result.stdout, result.stderr) || `${command} exited ${result.code}` };
  } catch (error) {
    return { ok: false, line: clean(error instanceof Error ? error.message : String(error)) };
  }
}

async function toolchainCheck(pi: ExtensionAPI): Promise<Check> {
  const specs: Array<[string, string, string[]]> = [
    ["Pi", "pi", ["--version"]],
    ["Codex", "codex", ["--version"]],
    ["Typst", "typst", ["--version"]],
    ["Python", "python", ["--version"]],
    ["uv", "uv", ["--version"]],
    ["pixi", "pixi", ["--version"]],
    ["Neovim", "nvim", ["--version"]],
    ["Ghostty", "ghostty", ["--version"]],
    ["Herdr", "herdr", ["--version"]],
    ["Poppler", "pdftotext", ["-v"]],
  ];
  const results = await Promise.all(specs.map(async ([label, command, args]) => ({ label, ...(await commandResult(pi, command, args)) })));
  const missing = results.filter((result) => !result.ok).map((result) => result.label);
  const versions = results.filter((result) => result.ok).map((result) => {
    const normalized = result.line.replace(new RegExp(`^${result.label}\\s+`, "i"), "");
    return `${result.label} ${normalized}`;
  });
  return missing.length
    ? { status: "warn", label: "Toolchain", detail: `${versions.join(" · ")}; unavailable: ${missing.join(", ")}`, action: "Install only tools needed by the active project; do not modify system Python." }
    : { status: "pass", label: "Toolchain", detail: versions.join(" · ") };
}

async function integrationCheck(pi: ExtensionAPI): Promise<Check> {
  const [fish, ghostty, nvim, herdr] = await Promise.all([
    commandResult(pi, "fish", ["-n", resolve(home, ".config/fish/config.fish")]),
    commandResult(pi, "ghostty", ["+validate-config", `--config-file=${resolve(home, ".config/ghostty/config.ghostty")}`]),
    commandResult(pi, "nvim", ["--headless", "+qa"], 20_000),
    commandResult(pi, "herdr", ["integration", "status"]),
  ]);
  const failures = [
    ["Fish", fish],
    ["Ghostty", ghostty],
    ["Neovim", nvim],
    ["Herdr", { ...herdr, ok: herdr.ok && /^pi: current \(v\d+\)/m.test(herdr.line) }],
  ].filter(([, result]) => !(result as { ok: boolean }).ok).map(([label]) => label as string);

  if (failures.length) {
    return { status: "fail", label: "Integrations", detail: `failed: ${failures.join(", ")}`, action: "Run the failing validator directly; repair Herdr only with `herdr integration install pi`." };
  }
  return { status: "pass", label: "Integrations", detail: "Fish syntax · Ghostty config · Neovim headless load · Herdr Pi v4" };
}

async function usageCheck(): Promise<Check> {
  try {
    const usage = await fetchCodexUsage({ timeoutMs: 12_000 });
    const windows = [usage.rateLimits.primary, usage.rateLimits.secondary].filter(Boolean);
    const expected = [300, 10_080].every((duration) => windows.some((window) => window?.windowDurationMins === duration));
    return {
      status: expected ? "pass" : "warn",
      label: "Codex allowance",
      detail: `${usage.rateLimits.planType ?? "unknown plan"} · official ${usage.sourceMethod} available${expected ? " · 5-hour and weekly windows present" : " · one expected window is absent"} · ${usage.resetCards?.availableCount ?? "unknown"} usage reset card(s) reported`,
      action: expected ? undefined : "Run /usage for the exact unavailable-field report.",
    };
  } catch (error) {
    return {
      status: "warn",
      label: "Codex allowance",
      detail: clean(error instanceof Error ? error.message : String(error)),
      action: "Run `codex login status`, then /usage. This reports subscription allowance, not API billing.",
    };
  }
}

async function projectCheck(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<Check> {
  const hasProjectResources = objectExists(join(ctx.cwd, ".pi"));
  if (hasProjectResources && !ctx.isProjectTrusted()) {
    return {
      status: "warn",
      label: "Project",
      detail: "project-local .pi resources exist but are not active in this runtime",
      action: "Review the project .pi files, approve trust interactively, and restart Pi.",
    };
  }
  const status = await pi.exec("git", ["-C", ctx.cwd, "status", "--short"], { timeout: 10_000 });
  if (status.code !== 0) return { status: "warn", label: "Project", detail: "current directory is not a readable Git worktree" };
  const changes = status.stdout.split(/\r?\n/).filter(Boolean).length;
  return {
    status: "pass",
    label: "Project",
    detail: `${ctx.isProjectTrusted() ? "trusted project resources active" : "no active project trust required"} · Git readable · ${changes} changed path${changes === 1 ? "" : "s"}`,
  };
}

function cacheCheck(): Check {
  return process.env.PI_CACHE_RETENTION === "long"
    ? { status: "pass", label: "Prompt cache", detail: "PI_CACHE_RETENTION=long is active where the provider supports it" }
    : { status: "warn", label: "Prompt cache", detail: "PI_CACHE_RETENTION=long is not present in this Pi process", action: "Open a fresh Fish/Ghostty session, then restart Pi." };
}

function resourceInventory(pi: ExtensionAPI): string[] {
  const commands = pi.getCommands();
  const groups = (["extension", "prompt", "skill"] as const).map((source) => {
    const names = commands
      .filter((command) => command.source === source)
      .map((command) => `/${command.name}`)
      .sort();
    const label = source === "extension" ? "Extension commands" : source === "prompt" ? "Prompt templates" : "Skill commands";
    return `- **${label}:** ${names.join(", ") || "none"}`;
  });
  return ["## Resource inventory", ...groups];
}

function report(checks: Check[], inventory?: string[]): string {
  const label: Record<Status, string> = { pass: "PASS", warn: "WARN", fail: "FAIL" };
  const lines = checks.map((check) => `- \`${label[check.status]}\` **${check.label}** — ${clean(check.detail)}`);
  const actions = checks.filter((check) => check.action).map((check) => `- **${check.label}:** ${check.action}`);
  const totals = checks.reduce<Record<Status, number>>((count, check) => {
    count[check.status] += 1;
    return count;
  }, { pass: 0, warn: 0, fail: 0 });
  return [
    `**Summary:** ${totals.pass} pass · ${totals.warn} warning · ${totals.fail} fail`,
    "",
    ...lines,
    ...(actions.length ? ["", "## Actions", ...actions] : []),
    ...(inventory ? ["", ...inventory] : []),
    "",
    "Diagnostics inspect configuration and file modes, never credential contents. The Codex allowance check is the only account-metadata request.",
  ].join("\n");
}

export default function doctorExtension(pi: ExtensionAPI) {
  pi.registerCommand("doctor", {
    description: "Validate Pi, privacy, resources, allowance access, and research tooling",
    getArgumentCompletions: (prefix) => ["verbose"]
      .filter((value) => value.startsWith(prefix))
      .map((value) => ({ value, label: value })),
    handler: async (args, ctx) => {
      const mode = args.trim().toLowerCase();
      if (mode && mode !== "verbose") {
        if (ctx.hasUI) ctx.ui.notify("Usage: /doctor [verbose]", "warning");
        return;
      }
      if (ctx.hasUI) ctx.ui.notify("Running Pi doctor…", "info");
      const configuration = await configurationCheck();
      const checks = await Promise.all([
        Promise.resolve(configuration.check),
        Promise.resolve(resourceCheck(pi, ctx)),
        Promise.resolve(runtimeCheck(pi, ctx, configuration.settings)),
        privacyCheck(),
        toolchainCheck(pi),
        integrationCheck(pi),
        usageCheck(),
        projectCheck(pi, ctx),
        Promise.resolve(cacheCheck()),
      ]);
      const tone = checks.some((check) => check.status === "fail")
        ? "error"
        : checks.some((check) => check.status === "warn")
          ? "warning"
          : "info";
      await showReport(ctx, mode === "verbose" ? "Doctor · verbose" : "Doctor", report(checks, mode === "verbose" ? resourceInventory(pi) : undefined), tone);
    },
  });
}
