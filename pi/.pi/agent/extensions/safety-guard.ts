import {
  createBashTool,
  type BashOperations,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { chmodSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, resolve, sep } from "node:path";
import {
  classifyBash,
  classifyPathTool,
  INTERACTIVE_SUDO_CATEGORY,
  PRIVILEGE_ELEVATION_CATEGORY,
  type SafetyClassification,
  type SafetyIssue,
  UNSAFE_SUDO_AUTH_CATEGORY,
  UNSUPPORTED_SUDO_TIMESTAMP_CATEGORY,
  UNTRUSTED_SUDO_BINARY_CATEGORY,
} from "./lib/safety-classifier.ts";

const home = homedir();
const agentRoot = resolve(home, ".pi/agent");
const sessionsRoot = resolve(agentRoot, "sessions");
const modeEnvironmentVariable = "PI_SAFETY_GUARD";
const sudoBinary = "/usr/bin/sudo";
const sudoValidationTimeoutMs = 5_000;
const runtimeProcess = process as typeof process & { __naldoPiSafetyYoloFlagApplied?: boolean };

function isWithin(path: string, root: string): boolean {
  return path === root || path.startsWith(`${root}${sep}`);
}

function privateMode(path: string, mode: number): void {
  try {
    const stats = statSync(path);
    if (typeof process.getuid === "function" && stats.uid !== process.getuid()) return;
    chmodSync(path, mode);
  } catch {
    // /doctor reports missing or inaccessible state; safety loading must stay quiet.
  }
}

function hardenSessionTree(path: string): void {
  privateMode(path, 0o700);
  try {
    for (const entry of readdirSync(path, { withFileTypes: true })) {
      const child = resolve(path, entry.name);
      if (entry.isDirectory()) hardenSessionTree(child);
      else if (entry.isFile()) privateMode(child, 0o600);
    }
  } catch {
    // Missing/inaccessible paths are reported by /doctor without exposing content.
  }
}

function hardenPrivateState(sessionFile?: string): void {
  privateMode(resolve(home, ".pi"), 0o700);
  privateMode(agentRoot, 0o700);
  privateMode(resolve(agentRoot, "auth.json"), 0o600);
  privateMode(resolve(agentRoot, "agent.db"), 0o600);
  privateMode(resolve(agentRoot, "trust.json"), 0o600);
  hardenSessionTree(sessionsRoot);

  if (sessionFile && isWithin(resolve(sessionFile), sessionsRoot)) {
    privateMode(dirname(sessionFile), 0o700);
    privateMode(sessionFile, 0o600);
  }
}

function guardEnabledFromEnvironment(): boolean {
  return !/^(?:0|false|off|yolo)$/i.test(process.env[modeEnvironmentVariable] ?? "on");
}

function compactCommand(command: string, maxLength = 1_000): string {
  const escaped = command.replace(
    /[\u0000-\u001f\u007f-\u009f\u061c\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]/g,
    (character) => `\\u${character.codePointAt(0)!.toString(16).padStart(4, "0")}`,
  );
  return escaped.length <= maxLength ? escaped : `${escaped.slice(0, maxLength - 1)}…`;
}

function issueSummary(issue: SafetyIssue): string[] {
  return [
    `Risk: ${issue.category}`,
    ...(issue.target ? [`Target: ${issue.target}`] : []),
    `Why: ${issue.reason}`,
    `Effect: ${issue.effect}`,
  ];
}

export function formatConfirmation(command: string, issues: SafetyIssue[]): string {
  const shown = issues.slice(0, 4);
  const omitted = issues.length - shown.length;
  return [
    ...shown.map((candidate) => issueSummary(candidate).join("\n")),
    ...(omitted > 0 ? [`Plus ${omitted} additional high-impact target${omitted === 1 ? "" : "s"}.`] : []),
    "Command:",
    compactCommand(command),
    "Allow this tool call once?",
  ].join("\n\n");
}

function denialReason(classification: SafetyClassification): string {
  const primary = classification.issues[0];
  return primary
    ? `Confirmation required for ${primary.category}: ${primary.reason}`
    : "Confirmation required by the safety guard";
}

type SafetyGuardDependencies = {
  validateSudoCredential: (pi: ExtensionAPI, ctx: ExtensionContext) => Promise<boolean>;
  authenticateSudo: (ctx: ExtensionContext, command: string) => Promise<boolean>;
};

async function validateSudoCredential(pi: ExtensionAPI, ctx: ExtensionContext): Promise<boolean> {
  try {
    const result = await pi.exec(sudoBinary, ["-n", "-v"], {
      signal: ctx.signal,
      timeout: sudoValidationTimeoutMs,
    });
    return result.code === 0;
  } catch {
    return false;
  }
}

type NativeSudoOptions = {
  runSudo?: (binary: string, args: string[]) => number | null;
  write?: (text: string) => void;
};

export async function authenticateSudoInTerminal(
  ctx: ExtensionContext,
  command: string,
  options: NativeSudoOptions = {},
): Promise<boolean> {
  if (ctx.mode !== "tui") return false;
  const runSudo = options.runSudo ?? ((binary: string, args: string[]) =>
    spawnSync(binary, args, { stdio: "inherit" }).status);
  const write = options.write ?? ((text: string) => { process.stdout.write(text); });

  const status = await ctx.ui.custom<number | null>((tui, _theme, _keybindings, done) => {
    let exitCode: number | null = 1;
    let stopped = false;
    try {
      tui.stop();
      stopped = true;
      write("\x1b[2J\x1b[H");
      write([
        "Pi is paused for trusted sudo authentication.",
        "The password is read directly by /usr/bin/sudo and is never stored by Pi.",
        "Press Ctrl+C to cancel.",
        "",
        "Approved command:",
        compactCommand(command),
        "",
      ].join("\n"));
      exitCode = runSudo(sudoBinary, ["-p", "[sudo] password for %p: ", "-v"]);
    } catch {
      exitCode = 1;
    } finally {
      try {
        if (stopped) {
          tui.start();
          tui.requestRender(true);
        }
      } finally {
        done(exitCode);
      }
    }

    return { render: () => [], invalidate: () => {} };
  });

  return status === 0;
}

const defaultDependencies: SafetyGuardDependencies = {
  validateSudoCredential,
  authenticateSudo: authenticateSudoInTerminal,
};

export function createCredentialAwareBashOperations(
  pi: Pick<ExtensionAPI, "exec">,
): BashOperations {
  return {
    async exec(command, cwd, { onData, signal, timeout }) {
      let result;
      try {
        result = await pi.exec("/usr/bin/bash", ["-c", command], {
          cwd,
          signal,
          ...(timeout ? { timeout: timeout * 1_000 } : {}),
        });
      } catch (error) {
        if (signal?.aborted) throw new Error("aborted");
        throw error;
      }

      if (result.stdout) onData(Buffer.from(result.stdout));
      if (result.stderr) onData(Buffer.from(result.stderr));
      if (signal?.aborted) throw new Error("aborted");
      if (result.killed && timeout) throw new Error(`timeout:${timeout}`);
      return { exitCode: result.code ?? 1 };
    },
  };
}

async function ensureSudoAuthentication(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  command: string,
  dependencies: SafetyGuardDependencies,
): Promise<string | undefined> {
  if (ctx.signal?.aborted) return "Sudo authentication was cancelled before the command ran";
  if (await dependencies.validateSudoCredential(pi, ctx)) return undefined;
  if (ctx.mode !== "tui") {
    return "Sudo needs authentication, but only Pi's interactive TUI can open the trusted native terminal prompt";
  }

  let authenticated = false;
  pi.events.emit("herdr:blocked", { active: true, label: "Sudo authentication" });
  try {
    authenticated = await dependencies.authenticateSudo(ctx, command);
  } catch {
    authenticated = false;
  } finally {
    pi.events.emit("herdr:blocked", { active: false, label: "Sudo authentication" });
  }
  if (!authenticated) return "Sudo authentication was cancelled or failed; the command was not executed";
  if (ctx.signal?.aborted) return "Sudo authentication was cancelled before the command ran";
  if (!await dependencies.validateSudoCredential(pi, ctx)) {
    return "Sudo did not provide a reusable noninteractive credential for this tool call; run the command manually";
  }
  return undefined;
}

export function registerSafetyGuard(
  pi: ExtensionAPI,
  dependencyOverrides: Partial<SafetyGuardDependencies> = {},
) {
  const dependencies: SafetyGuardDependencies = {
    validateSudoCredential: dependencyOverrides.validateSudoCredential ?? defaultDependencies.validateSudoCredential,
    authenticateSudo: dependencyOverrides.authenticateSudo ?? defaultDependencies.authenticateSudo,
  };
  let enabled = guardEnabledFromEnvironment();
  const completedConfirmations = new Map<string, boolean>();
  const pendingConfirmations = new Map<string, Promise<boolean>>();
  const approvedSudoCommands = new Map<string, string>();

  hardenPrivateState();

  // Pi's built-in bash worker starts in a detached terminal session. Sudo's
  // default tty-scoped timestamp therefore cannot follow the credential that
  // this extension obtains in Pi's native terminal. Keep ordinary bash calls
  // on the built-in backend, but execute the exact approved sudo call through
  // pi.exec(), which remains in Pi's terminal session and can reuse the ticket.
  const bashTool = createBashTool(process.cwd());
  pi.registerTool({
    ...bashTool,
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const approvedCommand = approvedSudoCommands.get(toolCallId);
      try {
        if (approvedCommand === undefined) {
          return createBashTool(ctx.cwd).execute(toolCallId, params, signal, onUpdate);
        }
        if (approvedCommand !== params.command) {
          throw new Error("Approved sudo command changed after safety validation");
        }
        const tool = createBashTool(ctx.cwd, {
          operations: createCredentialAwareBashOperations(pi),
        });
        return tool.execute(toolCallId, params, signal, onUpdate);
      } finally {
        approvedSudoCommands.delete(toolCallId);
      }
    },
  });

  pi.registerFlag("yolo", {
    description: "Disable the high-impact safety gate for this Pi process",
    type: "boolean",
    default: false,
  });

  const publishMode = (ctx: ExtensionContext): void => {
    if (ctx.hasUI) {
      ctx.ui.setStatus(
        "safety-guard",
        enabled ? undefined : ctx.ui.theme.fg("error", ctx.ui.theme.bold("YOLO")),
      );
    }
  };

  const setEnabled = (next: boolean, ctx: ExtensionContext, notify = true): void => {
    enabled = next;
    process.env[modeEnvironmentVariable] = next ? "on" : "off";
    completedConfirmations.clear();
    pendingConfirmations.clear();
    approvedSudoCommands.clear();
    publishMode(ctx);
    if (!notify || !ctx.hasUI) return;
    ctx.ui.notify(
      next
        ? "Safety guard ON · only high-impact operations ask"
        : "YOLO mode ON · safety prompts and blocks are disabled for this Pi process",
      next ? "info" : "warning",
    );
  };

  pi.registerCommand("safety", {
    description: "Toggle high-impact confirmations or inspect safety mode",
    getArgumentCompletions: (prefix) => ["on", "off", "toggle", "status"]
      .filter((value) => value.startsWith(prefix))
      .map((value) => ({ value, label: value })),
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase();
      if (action === "" || action === "toggle") setEnabled(!enabled, ctx);
      else if (action === "on") setEnabled(true, ctx);
      else if (action === "off" || action === "yolo") setEnabled(false, ctx);
      else if (action === "status") {
        publishMode(ctx);
        if (ctx.hasUI) {
          ctx.ui.notify(
            enabled
              ? "Safety guard ON · high-impact tool calls require one confirmation"
              : "YOLO mode ON · every tool call passes through without safety confirmation",
            enabled ? "info" : "warning",
          );
        }
      } else if (ctx.hasUI) {
        ctx.ui.notify("Usage: /safety [on|off|toggle|status]", "warning");
      }
    },
  });

  const rememberDecision = (toolCallId: string, decision: boolean): void => {
    completedConfirmations.set(toolCallId, decision);
    if (completedConfirmations.size > 256) {
      const first = completedConfirmations.keys().next().value;
      if (typeof first === "string") completedConfirmations.delete(first);
    }
  };

  const confirmOnce = async (
    toolCallId: string,
    ctx: ExtensionContext,
    classification: SafetyClassification,
  ): Promise<boolean> => {
    const completed = completedConfirmations.get(toolCallId);
    if (completed !== undefined) return completed;
    const pending = pendingConfirmations.get(toolCallId);
    if (pending) return pending;
    if (!ctx.hasUI) {
      rememberDecision(toolCallId, false);
      return false;
    }

    const primary = classification.issues[0]?.category ?? "high-impact operation";
    const confirmation = (async () => {
      pi.events.emit("herdr:blocked", { active: true, label: `Approval: ${primary}` });
      try {
        const allowed = await ctx.ui.confirm(
          `Confirm ${primary}`,
          formatConfirmation(classification.command, classification.issues),
        );
        rememberDecision(toolCallId, allowed);
        return allowed;
      } finally {
        pi.events.emit("herdr:blocked", { active: false, label: `Approval: ${primary}` });
        pendingConfirmations.delete(toolCallId);
      }
    })();
    pendingConfirmations.set(toolCallId, confirmation);
    return confirmation;
  };

  pi.on("session_start", async (_event, ctx) => {
    if (pi.getFlag("yolo") === true && runtimeProcess.__naldoPiSafetyYoloFlagApplied !== true) {
      process.env[modeEnvironmentVariable] = "off";
      runtimeProcess.__naldoPiSafetyYoloFlagApplied = true;
    }
    enabled = guardEnabledFromEnvironment();
    completedConfirmations.clear();
    pendingConfirmations.clear();
    approvedSudoCommands.clear();
    hardenPrivateState(ctx.sessionManager.getSessionFile());
    publishMode(ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    hardenPrivateState(ctx.sessionManager.getSessionFile());
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    approvedSudoCommands.clear();
    hardenPrivateState(ctx.sessionManager.getSessionFile());
    if (ctx.hasUI) ctx.ui.setStatus("safety-guard", undefined);
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!enabled) return;

    let classification: SafetyClassification | undefined;
    if (event.toolName === "read" || event.toolName === "write" || event.toolName === "edit") {
      const path = (event.input as { path?: unknown }).path;
      if (typeof path !== "string") return;
      classification = classifyPathTool(event.toolName, path, ctx.cwd, { home });
    } else if (event.toolName === "bash") {
      const command = (event.input as { command?: unknown }).command;
      if (typeof command !== "string") return;
      classification = classifyBash(command, ctx.cwd, { home });
    } else {
      return;
    }

    const unsafeSudo = classification.issues.find((candidate) =>
      candidate.category === UNTRUSTED_SUDO_BINARY_CATEGORY
      || candidate.category === INTERACTIVE_SUDO_CATEGORY
      || candidate.category === UNSAFE_SUDO_AUTH_CATEGORY
      || candidate.category === UNSUPPORTED_SUDO_TIMESTAMP_CATEGORY
    );
    if (unsafeSudo) {
      return {
        block: true,
        reason: `${unsafeSudo.category} blocked: ${unsafeSudo.reason} Use Pi's native sudo authentication flow instead.`,
      };
    }

    const unsupportedElevation = classification.issues.find((candidate) =>
      candidate.category === PRIVILEGE_ELEVATION_CATEGORY && candidate.target === "doas"
    );
    if (unsupportedElevation) {
      return {
        block: true,
        reason: "Interactive doas authentication is not supported by Pi's trusted sudo flow; run this command manually",
      };
    }

    if (classification.action === "allow") return;
    const allowed = await confirmOnce(event.toolCallId, ctx, classification);
    if (!allowed) return { block: true, reason: denialReason(classification) };

    const needsSudo = classification.issues.some((candidate) =>
      candidate.category === PRIVILEGE_ELEVATION_CATEGORY
      && (candidate.target === "sudo" || candidate.target === "sudoedit")
    );
    if (needsSudo) {
      const failure = await ensureSudoAuthentication(pi, ctx, classification.command, dependencies);
      if (failure) return { block: true, reason: failure };
      approvedSudoCommands.set(event.toolCallId, classification.command);
    }
  });
}

export default function safetyGuard(pi: ExtensionAPI) {
  registerSafetyGuard(pi);
}
