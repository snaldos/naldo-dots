import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { chmodSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, resolve, sep } from "node:path";
import {
  classifyBash,
  classifyPathTool,
  type SafetyClassification,
  type SafetyIssue,
} from "./lib/safety-classifier.ts";

const home = homedir();
const agentRoot = resolve(home, ".pi/agent");
const sessionsRoot = resolve(agentRoot, "sessions");
const modeEnvironmentVariable = "PI_SAFETY_GUARD";
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
  const normalized = command.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").replace(/\s+/g, " ").trim();
  return normalized.length <= maxLength ? normalized : `${normalized.slice(0, maxLength - 1)}…`;
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

export default function safetyGuard(pi: ExtensionAPI) {
  let enabled = guardEnabledFromEnvironment();
  const completedConfirmations = new Map<string, boolean>();
  const pendingConfirmations = new Map<string, Promise<boolean>>();

  hardenPrivateState();

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
    hardenPrivateState(ctx.sessionManager.getSessionFile());
    publishMode(ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    hardenPrivateState(ctx.sessionManager.getSessionFile());
  });

  pi.on("session_shutdown", async (_event, ctx) => {
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

    if (classification.action === "allow") return;
    const allowed = await confirmOnce(event.toolCallId, ctx, classification);
    if (!allowed) return { block: true, reason: denialReason(classification) };
  });
}
