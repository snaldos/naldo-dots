import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { describe, it } from "node:test";
import {
  GitStatusMonitor,
  gitStateFromPorcelainV2,
  type GitState,
} from "./git-status.ts";

const execFileAsync = promisify(execFile);

async function runGit(cwd: string, args: string[]): Promise<{ stdout: string; code: number }> {
  try {
    const result = await execFileAsync("git", ["-C", cwd, ...args], { encoding: "utf8" });
    return { stdout: result.stdout, code: 0 };
  } catch (error) {
    const failure = error as { stdout?: string; code?: number };
    return { stdout: failure.stdout ?? "", code: failure.code ?? 1 };
  }
}

async function waitFor(predicate: () => boolean, timeoutMs = 2_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (!predicate()) {
    if (Date.now() >= deadline) throw new Error("Timed out waiting for Git status update");
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
}

describe("Git porcelain v2 parsing", () => {
  it("extracts branch and tracked/untracked path counts", () => {
    const state = gitStateFromPorcelainV2([
      "# branch.oid abc123",
      "# branch.head main",
      "1 M. N... 100644 100644 100644 abc abc file.ts",
      "2 R. N... 100644 100644 100644 abc abc R100 new.ts\told.ts",
      "u UU N... 100644 100644 100644 100644 abc abc abc conflict.ts",
      "? notes.txt",
      "! ignored.bin",
    ].join("\n"));

    assert.deepEqual(state, {
      available: true,
      branch: "main",
      tracked: 3,
      untracked: 1,
    });
  });

  it("labels a detached worktree", () => {
    const state = gitStateFromPorcelainV2("# branch.head (detached)\n");
    assert.equal(state.branch, "detached");
  });
});

describe("GitStatusMonitor", () => {
  it("reacts to index changes without a Pi reload", async () => {
    const cwd = await mkdtemp(join(tmpdir(), "pi-git-monitor-"));
    const states: GitState[] = [];
    const monitor = new GitStatusMonitor(runGit, (state) => states.push(state), {
      debounceMs: 20,
      pollMs: 60_000,
    });

    try {
      await runGit(cwd, ["init", "--quiet"]);
      await monitor.start(cwd);
      await writeFile(join(cwd, "file.txt"), "fixture\n", "utf8");
      await runGit(cwd, ["add", "file.txt"]);

      await waitFor(() => states.some((state) => state.tracked === 1));
      assert.equal(states.at(-1)?.untracked, 0);
    } finally {
      monitor.stop();
      await rm(cwd, { recursive: true, force: true });
    }
  });
});
