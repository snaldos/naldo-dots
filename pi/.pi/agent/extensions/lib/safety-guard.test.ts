import assert from "node:assert/strict";
import { afterEach, beforeEach, describe, it } from "node:test";
import safetyGuard from "../safety-guard.ts";

type Handler = (event: any, ctx: any) => Promise<unknown> | unknown;
type Command = { handler: (args: string, ctx: any) => Promise<void> | void };

const runtimeProcess = process as typeof process & { __naldoPiSafetyYoloFlagApplied?: boolean };
const originalMode = process.env.PI_SAFETY_GUARD;
const originalFlagMarker = runtimeProcess.__naldoPiSafetyYoloFlagApplied;

beforeEach(() => {
  delete process.env.PI_SAFETY_GUARD;
  delete runtimeProcess.__naldoPiSafetyYoloFlagApplied;
});

afterEach(() => {
  if (originalMode === undefined) delete process.env.PI_SAFETY_GUARD;
  else process.env.PI_SAFETY_GUARD = originalMode;
  if (originalFlagMarker === undefined) delete runtimeProcess.__naldoPiSafetyYoloFlagApplied;
  else runtimeProcess.__naldoPiSafetyYoloFlagApplied = originalFlagMarker;
});

function harness(yoloFlag = false, hasUI = true) {
  const handlers = new Map<string, Handler[]>();
  const commands = new Map<string, Command>();
  const statuses = new Map<string, string>();
  const notifications: string[] = [];
  let confirmationCount = 0;
  let confirmationDecision = true;

  const pi = {
    registerFlag() {},
    registerCommand(name: string, command: Command) {
      commands.set(name, command);
    },
    on(name: string, handler: Handler) {
      handlers.set(name, [...(handlers.get(name) ?? []), handler]);
    },
    getFlag(name: string) {
      return name === "yolo" && yoloFlag;
    },
    events: { emit() {} },
  };

  const ctx = {
    cwd: "/home/tester/project",
    hasUI,
    sessionManager: { getSessionFile: () => undefined },
    ui: {
      theme: {
        fg: (_color: string, text: string) => text,
        bold: (text: string) => text,
      },
      setStatus(name: string, value: string | undefined) {
        if (value === undefined) statuses.delete(name);
        else statuses.set(name, value);
      },
      notify(message: string) {
        notifications.push(message);
      },
      async confirm() {
        confirmationCount += 1;
        return confirmationDecision;
      },
    },
  };

  safetyGuard(pi as never);

  const emit = async (name: string, event: unknown) => {
    let result: unknown;
    for (const handler of handlers.get(name) ?? []) result = await handler(event, ctx);
    return result;
  };

  return {
    commands,
    statuses,
    notifications,
    ctx,
    emit,
    confirmationCount: () => confirmationCount,
    setConfirmationDecision: (decision: boolean) => { confirmationDecision = decision; },
  };
}

describe("safety gate mode", () => {
  it("confirms once while guarded and passes every tool call in YOLO mode", async () => {
    const app = harness();
    await app.emit("session_start", {});

    const riskyCall = {
      toolName: "bash",
      toolCallId: "risk-1",
      input: { command: "printf test > /etc/hosts" },
    };
    assert.equal(await app.emit("tool_call", riskyCall), undefined);
    assert.equal(app.confirmationCount(), 1);

    assert.equal(await app.emit("tool_call", riskyCall), undefined);
    assert.equal(app.confirmationCount(), 1, "the same tool call should reuse its decision");

    await app.commands.get("safety")!.handler("off", app.ctx);
    assert.equal(app.statuses.get("safety-guard"), "YOLO");
    assert.match(app.notifications.at(-1)!, /YOLO mode ON/);

    await app.emit("tool_call", {
      ...riskyCall,
      toolCallId: "risk-2",
      input: { command: "mkfs.ext4 /dev/sda1" },
    });
    assert.equal(app.confirmationCount(), 1, "YOLO must bypass classification and confirmation");

    await app.commands.get("safety")!.handler("on", app.ctx);
    assert.equal(app.statuses.has("safety-guard"), false);
    app.setConfirmationDecision(false);
    const denied = await app.emit("tool_call", {
      ...riskyCall,
      toolCallId: "risk-3",
    }) as { block?: boolean; reason?: string };
    assert.equal(denied.block, true);
    assert.match(denied.reason!, /Confirmation required/);
  });

  it("honors --yolo at startup", async () => {
    const app = harness(true);
    await app.emit("session_start", {});
    assert.equal(app.statuses.get("safety-guard"), "YOLO");

    await app.emit("tool_call", {
      toolName: "bash",
      toolCallId: "risk-yolo",
      input: { command: "rm -rf /" },
    });
    assert.equal(app.confirmationCount(), 0);

    await app.commands.get("safety")!.handler("on", app.ctx);
    const reloaded = harness(true);
    await reloaded.emit("session_start", {});
    assert.equal(reloaded.statuses.has("safety-guard"), false, "a runtime toggle should survive reload");
    await reloaded.emit("tool_call", {
      toolName: "bash",
      toolCallId: "risk-after-reload",
      input: { command: "rm -rf /" },
    });
    assert.equal(reloaded.confirmationCount(), 1);
  });

  it("fails closed without a confirmation UI unless YOLO is active", async () => {
    const guarded = harness(false, false);
    await guarded.emit("session_start", {});
    const denied = await guarded.emit("tool_call", {
      toolName: "bash",
      toolCallId: "risk-print",
      input: { command: "pacman -Rns systemd" },
    }) as { block?: boolean };
    assert.equal(denied.block, true);

    delete runtimeProcess.__naldoPiSafetyYoloFlagApplied;
    const yolo = harness(true, false);
    await yolo.emit("session_start", {});
    assert.equal(await yolo.emit("tool_call", {
      toolName: "bash",
      toolCallId: "risk-print-yolo",
      input: { command: "pacman -Rns systemd" },
    }), undefined);
  });
});
