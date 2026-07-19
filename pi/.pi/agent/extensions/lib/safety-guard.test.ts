import assert from "node:assert/strict";
import { afterEach, beforeEach, describe, it } from "node:test";
import { authenticateSudoInTerminal, registerSafetyGuard } from "../safety-guard.ts";

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

type SudoHarnessOptions = {
  validationResults?: boolean[];
  authenticationDecision?: boolean;
  mode?: "tui" | "rpc" | "json" | "print";
};

function harness(yoloFlag = false, hasUI = true, sudoOptions: SudoHarnessOptions = {}) {
  const handlers = new Map<string, Handler[]>();
  const commands = new Map<string, Command>();
  const statuses = new Map<string, string>();
  const notifications: string[] = [];
  const validationResults = [...(sudoOptions.validationResults ?? [true])];
  let confirmationCount = 0;
  let confirmationDecision = true;
  let sudoAuthenticationCount = 0;
  let sudoValidationCount = 0;

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
    mode: sudoOptions.mode ?? (hasUI ? "tui" : "print"),
    signal: undefined,
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

  registerSafetyGuard(pi as never, {
    async validateSudoCredential() {
      sudoValidationCount += 1;
      return validationResults.shift() ?? false;
    },
    async authenticateSudo() {
      sudoAuthenticationCount += 1;
      return sudoOptions.authenticationDecision ?? true;
    },
  });

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
    sudoAuthenticationCount: () => sudoAuthenticationCount,
    sudoValidationCount: () => sudoValidationCount,
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

describe("sudo authentication", () => {
  const sudoCall = (toolCallId: string, command = "/usr/bin/sudo -n true") => ({
    toolName: "bash",
    toolCallId,
    input: { command },
  });

  it("confirms the exact call and reuses an existing sudo credential", async () => {
    for (const command of [
      "/usr/bin/sudo -n true",
      "/usr/bin/sudoedit -n /tmp/example",
    ]) {
      const app = harness(false, true, { validationResults: [true] });
      await app.emit("session_start", {});

      assert.equal(await app.emit("tool_call", sudoCall(`sudo-cached-${command}`, command)), undefined);
      assert.equal(app.confirmationCount(), 1);
      assert.equal(app.sudoValidationCount(), 1);
      assert.equal(app.sudoAuthenticationCount(), 0);
    }
  });

  it("opens the trusted prompt only when needed and revalidates afterward", async () => {
    const app = harness(false, true, {
      validationResults: [false, true],
      authenticationDecision: true,
    });
    await app.emit("session_start", {});

    assert.equal(await app.emit("tool_call", sudoCall("sudo-auth")), undefined);
    assert.equal(app.confirmationCount(), 1);
    assert.equal(app.sudoValidationCount(), 2);
    assert.equal(app.sudoAuthenticationCount(), 1);
  });

  it("blocks when authentication is cancelled or cannot be reused", async () => {
    const cancelled = harness(false, true, {
      validationResults: [false],
      authenticationDecision: false,
    });
    await cancelled.emit("session_start", {});
    const cancelledResult = await cancelled.emit("tool_call", sudoCall("sudo-cancelled")) as {
      block?: boolean;
      reason?: string;
    };
    assert.equal(cancelledResult.block, true);
    assert.match(cancelledResult.reason!, /cancelled or failed/);

    const unavailable = harness(false, true, {
      validationResults: [false, false],
      authenticationDecision: true,
    });
    await unavailable.emit("session_start", {});
    const unavailableResult = await unavailable.emit("tool_call", sudoCall("sudo-unavailable")) as {
      block?: boolean;
      reason?: string;
    };
    assert.equal(unavailableResult.block, true);
    assert.match(unavailableResult.reason!, /reusable noninteractive credential/);
  });

  it("fails closed when authentication is needed outside the TUI", async () => {
    const app = harness(false, true, {
      validationResults: [false],
      authenticationDecision: true,
      mode: "rpc",
    });
    await app.emit("session_start", {});

    const result = await app.emit("tool_call", sudoCall("sudo-rpc")) as { block?: boolean; reason?: string };
    assert.equal(result.block, true);
    assert.match(result.reason!, /interactive TUI/);
    assert.equal(app.sudoAuthenticationCount(), 0);
  });

  it("hands terminal input only to the fixed native sudo validation process", async () => {
    const writes: string[] = [];
    const calls: Array<{ binary: string; args: string[] }> = [];
    let stopped = 0;
    let started = 0;
    let rendered = 0;
    const ctx = {
      mode: "tui",
      ui: {
        async custom(factory: Function) {
          let result: number | null | undefined;
          factory(
            {
              stop() { stopped += 1; },
              start() { started += 1; },
              requestRender(force: boolean) { if (force) rendered += 1; },
            },
            {},
            {},
            (value: number | null) => { result = value; },
          );
          return result;
        },
      },
    };

    const authenticated = await authenticateSudoInTerminal(
      ctx as never,
      "printf ok\u001b[31m\u202e",
      {
        runSudo(binary, args) {
          calls.push({ binary, args });
          return 0;
        },
        write(text) { writes.push(text); },
      },
    );

    assert.equal(authenticated, true);
    assert.deepEqual(calls, [{
      binary: "/usr/bin/sudo",
      args: ["-p", "[sudo] password for %p: ", "-v"],
    }]);
    assert.equal(stopped, 1);
    assert.equal(started, 1);
    assert.equal(rendered, 1);
    assert.equal(writes[0], "\u001b[2J\u001b[H");
    assert.doesNotMatch(writes[1]!, /[\u001b\u202e]/);
    assert.match(writes[1]!, /\\u001b\[31m\\u202e/);
    assert.match(writes[1]!, /never stored by Pi/);
  });

  it("blocks alternate password paths and timestamp invalidation before prompting", async () => {
    for (const command of [
      "sudo -n true",
      "/usr/bin/sudo true",
      "printf placeholder | /usr/bin/sudo -nS true",
      "/usr/bin/sudo -n --askpass true",
      "/usr/bin/sudo -nk true",
      "/usr/bin/sudo -n --remove-timestamp true",
    ]) {
      const app = harness(false, true, { validationResults: [true] });
      await app.emit("session_start", {});
      const result = await app.emit("tool_call", sudoCall(`unsafe-${command}`, command)) as {
        block?: boolean;
        reason?: string;
      };
      assert.equal(result.block, true, command);
      assert.match(result.reason!, /blocked/, command);
      assert.equal(app.confirmationCount(), 0, command);
      assert.equal(app.sudoValidationCount(), 0, command);
      assert.equal(app.sudoAuthenticationCount(), 0, command);
    }
  });

  it("blocks unsupported doas authentication", async () => {
    const app = harness(false, true);
    await app.emit("session_start", {});
    const result = await app.emit("tool_call", sudoCall("doas", "doas true")) as {
      block?: boolean;
      reason?: string;
    };
    assert.equal(result.block, true);
    assert.match(result.reason!, /doas authentication is not supported/);
    assert.equal(app.confirmationCount(), 0);
  });
});
