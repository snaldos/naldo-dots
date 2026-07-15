import { watch, type FSWatcher } from "node:fs";

export type GitState = {
  available: boolean;
  branch: string | null;
  tracked: number;
  untracked: number;
};

export const EMPTY_GIT_STATE: GitState = {
  available: false,
  branch: null,
  tracked: 0,
  untracked: 0,
};

type GitCommandResult = {
  stdout: string;
  code: number;
};

type GitCommandRunner = (
  cwd: string,
  args: string[],
) => Promise<GitCommandResult>;

type GitStatusMonitorOptions = {
  debounceMs?: number;
  pollMs?: number;
};

export function gitStateFromPorcelainV2(output: string): GitState {
  let branch: string | null = null;
  let tracked = 0;
  let untracked = 0;

  for (const line of output.split(/\r?\n/)) {
    if (line.startsWith("# branch.head ")) {
      const head = line.slice("# branch.head ".length).trim();
      branch = head === "(detached)" ? "detached" : head || null;
    } else if (line.startsWith("? ")) {
      untracked += 1;
    } else if (/^(?:1|2|u) /.test(line)) {
      tracked += 1;
    }
  }

  return { available: true, branch, tracked, untracked };
}

function sameGitState(left: GitState, right: GitState): boolean {
  return left.available === right.available
    && left.branch === right.branch
    && left.tracked === right.tracked
    && left.untracked === right.untracked;
}

/**
 * Keeps one Git snapshot for the active session.
 *
 * Git metadata watches make index/ref operations (add, reset, commit, checkout,
 * stash, rebase, etc.) reactive regardless of which Pi tool or external process
 * ran them. Event hints provide immediate working-tree refreshes, while a slow
 * poll is a fallback for dropped watcher events and non-Git file mutations.
 */
export class GitStatusMonitor {
  private readonly runGit: GitCommandRunner;
  private readonly onState: (state: GitState) => void;
  private readonly debounceMs: number;
  private readonly pollMs: number;
  private readonly watchers = new Set<FSWatcher>();
  private cwd: string | undefined;
  private debounceTimer: ReturnType<typeof setTimeout> | undefined;
  private pollTimer: ReturnType<typeof setInterval> | undefined;
  private epoch = 0;
  private refreshId = 0;
  private state: GitState = EMPTY_GIT_STATE;

  constructor(
    runGit: GitCommandRunner,
    onState: (state: GitState) => void,
    options: GitStatusMonitorOptions = {},
  ) {
    this.runGit = runGit;
    this.onState = onState;
    this.debounceMs = options.debounceMs ?? 100;
    this.pollMs = options.pollMs ?? 5_000;
  }

  async start(cwd: string): Promise<void> {
    this.stop();
    this.cwd = cwd;
    const epoch = this.epoch;

    const metadata = await this.runGit(cwd, [
      "rev-parse",
      "--path-format=absolute",
      "--git-dir",
      "--git-common-dir",
    ]).catch(() => ({ stdout: "", code: 1 }));
    if (this.epoch !== epoch || this.cwd !== cwd) return;

    if (metadata.code === 0) {
      const paths = new Set(
        metadata.stdout.split(/\r?\n/).map((path) => path.trim()).filter(Boolean),
      );
      for (const path of paths) this.watchMetadata(path);
      this.pollTimer = setInterval(() => this.requestRefresh(0), this.pollMs);
      this.pollTimer.unref?.();
    }

    await this.refreshNow();
  }

  requestRefresh(delayMs = this.debounceMs): void {
    if (!this.cwd) return;
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = undefined;
      void this.refreshNow();
    }, delayMs);
    this.debounceTimer.unref?.();
  }

  async refreshNow(): Promise<void> {
    const cwd = this.cwd;
    if (!cwd) return;
    const epoch = this.epoch;
    const refreshId = ++this.refreshId;
    const result = await this.runGit(cwd, [
      "status",
      "--porcelain=v2",
      "--branch",
      "--untracked-files=normal",
    ]).catch(() => ({ stdout: "", code: 1 }));
    if (this.epoch !== epoch || this.cwd !== cwd || refreshId !== this.refreshId) return;

    const next = result.code === 0
      ? gitStateFromPorcelainV2(result.stdout)
      : EMPTY_GIT_STATE;
    if (sameGitState(this.state, next)) return;
    this.state = next;
    this.onState(next);
  }

  stop(): void {
    this.epoch += 1;
    this.refreshId += 1;
    this.cwd = undefined;
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.debounceTimer = undefined;
    this.pollTimer = undefined;
    for (const watcher of this.watchers) watcher.close();
    this.watchers.clear();
    this.state = EMPTY_GIT_STATE;
  }

  private watchMetadata(path: string): void {
    try {
      const watcher = watch(path, { recursive: true }, () => this.requestRefresh());
      this.watchers.add(watcher);
      watcher.on("error", () => {
        watcher.close();
        this.watchers.delete(watcher);
      });
      watcher.unref?.();
    } catch {
      // The periodic fallback remains active if a repository cannot be watched.
    }
  }
}
