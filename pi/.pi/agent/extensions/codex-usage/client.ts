import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";

export type RateLimitWindow = {
  usedPercent: number;
  windowDurationMins: number | null;
  resetsAt: number | null;
};

export type CreditsSnapshot = {
  hasCredits: boolean;
  unlimited: boolean;
  balance: string | null;
};

export type SpendControlLimit = {
  limit: string;
  used: string;
  remainingPercent: number;
  resetsAt: number;
};

export type RateLimitSnapshot = {
  limitId: string | null;
  limitName: string | null;
  primary: RateLimitWindow | null;
  secondary: RateLimitWindow | null;
  credits: CreditsSnapshot | null;
  individualLimit: SpendControlLimit | null;
  planType: string | null;
  rateLimitReachedType: string | null;
};

/** Opaque IDs remain only in the active in-memory snapshot. */
export type UsageResetCard = {
  id: string;
  resetType: "codexRateLimits" | "unknown";
  status: "available" | "redeeming" | "redeemed" | "unknown";
  grantedAt: number;
  expiresAt: number | null;
  title: string | null;
  description: string | null;
};

export type UsageResetCardsSummary = {
  availableCount: number;
  cards: UsageResetCard[] | null;
};

export type CodexUsageSnapshot = {
  rateLimits: RateLimitSnapshot;
  resetCards: UsageResetCardsSummary | null;
  fetchedAt: number;
  serverUserAgent: string | null;
  sourceMethod: "account/rateLimits/read";
};

export type ConsumeResetCardOutcome = "reset" | "nothingToReset" | "noCredit" | "alreadyRedeemed";

export type ConsumeResetCardResponse = {
  outcome: ConsumeResetCardOutcome;
  consumedAt: number;
  serverUserAgent: string | null;
  sourceMethod: "account/rateLimitResetCredit/consume";
};

export type CodexAppServerOptions = {
  executable?: string;
  timeoutMs?: number;
  signal?: AbortSignal;
  env?: NodeJS.ProcessEnv;
};

export type ConsumeResetCardOptions = CodexAppServerOptions & {
  creditId: string;
  idempotencyKey: string;
};

type JsonObject = Record<string, unknown>;
type PendingRequest = {
  resolve(value: unknown): void;
  reject(error: Error): void;
};

export class CodexUsageError extends Error {
  readonly kind: "unavailable" | "timeout" | "protocol" | "server" | "cancelled";

  constructor(
    message: string,
    kind: "unavailable" | "timeout" | "protocol" | "server" | "cancelled",
  ) {
    super(message);
    this.name = "CodexUsageError";
    this.kind = kind;
  }
}

function object(value: unknown): JsonObject | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonObject)
    : null;
}

function finiteNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function text(value: unknown): string | null {
  return typeof value === "string" ? value : null;
}

function cleanDiagnostic(value: unknown): string {
  if (typeof value !== "string") return "unknown server error";
  return value
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/\b(bearer|token|api[_ -]?key)\s*[:=]\s*\S+/gi, "$1=[redacted]")
    .replace(/\b[0-9a-f]{8}-[0-9a-f-]{27,}\b/gi, "[redacted-id]")
    .replace(/[A-Za-z0-9_./+=-]{24,}/g, "[redacted]")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 240);
}

function parseWindow(value: unknown): RateLimitWindow | null {
  const raw = object(value);
  const usedPercent = finiteNumber(raw?.usedPercent);
  if (!raw || usedPercent === null) return null;
  return {
    usedPercent,
    windowDurationMins: finiteNumber(raw.windowDurationMins),
    resetsAt: finiteNumber(raw.resetsAt),
  };
}

function parseCredits(value: unknown): CreditsSnapshot | null {
  const raw = object(value);
  if (!raw || typeof raw.hasCredits !== "boolean" || typeof raw.unlimited !== "boolean") return null;
  return {
    hasCredits: raw.hasCredits,
    unlimited: raw.unlimited,
    balance: text(raw.balance),
  };
}

function parseIndividualLimit(value: unknown): SpendControlLimit | null {
  const raw = object(value);
  const remainingPercent = finiteNumber(raw?.remainingPercent);
  const resetsAt = finiteNumber(raw?.resetsAt);
  if (!raw || text(raw.limit) === null || text(raw.used) === null || remainingPercent === null || resetsAt === null) {
    return null;
  }
  return {
    limit: text(raw.limit)!,
    used: text(raw.used)!,
    remainingPercent,
    resetsAt,
  };
}

function parseRateLimits(value: unknown): RateLimitSnapshot {
  const raw = object(value);
  if (!raw) throw new CodexUsageError("Codex returned no rate-limit snapshot", "protocol");
  return {
    limitId: text(raw.limitId),
    limitName: text(raw.limitName),
    primary: parseWindow(raw.primary),
    secondary: parseWindow(raw.secondary),
    credits: parseCredits(raw.credits),
    individualLimit: parseIndividualLimit(raw.individualLimit),
    planType: text(raw.planType),
    rateLimitReachedType: text(raw.rateLimitReachedType),
  };
}

function resetType(value: unknown): UsageResetCard["resetType"] {
  return value === "codexRateLimits" ? "codexRateLimits" : "unknown";
}

function resetStatus(value: unknown): UsageResetCard["status"] {
  return value === "available" || value === "redeeming" || value === "redeemed"
    ? value
    : "unknown";
}

function parseResetCards(value: unknown): UsageResetCardsSummary | null {
  const raw = object(value);
  const availableCount = finiteNumber(raw?.availableCount);
  if (!raw || availableCount === null) return null;

  const cards = Array.isArray(raw.credits)
    ? raw.credits.flatMap((value): UsageResetCard[] => {
        const card = object(value);
        const id = text(card?.id);
        const grantedAt = finiteNumber(card?.grantedAt);
        if (!card || id === null || grantedAt === null) return [];
        return [{
          id,
          resetType: resetType(card.resetType),
          status: resetStatus(card.status),
          grantedAt,
          expiresAt: finiteNumber(card.expiresAt),
          title: text(card.title),
          description: text(card.description),
        }];
      })
    : null;

  return { availableCount, cards };
}

class JsonLineRpcClient {
  private readonly child: ChildProcessWithoutNullStreams;
  private readonly pending = new Map<number, PendingRequest>();
  private buffer = "";
  private closed = false;
  private readonly timeout: NodeJS.Timeout;
  private readonly signal?: AbortSignal;
  private readonly abortHandler?: () => void;

  constructor(options: CodexAppServerOptions) {
    this.signal = options.signal;
    const executable = options.executable ?? "codex";
    this.child = spawn(executable, ["app-server", "--stdio"], {
      env: options.env ?? process.env,
      stdio: ["pipe", "pipe", "pipe"],
      windowsHide: true,
    });

    this.child.stdout.setEncoding("utf8");
    this.child.stdout.on("data", (chunk: string) => this.consume(chunk));
    this.child.stderr.on("data", () => undefined);
    this.child.on("error", (error) => {
      this.fail(new CodexUsageError(`Could not start Codex CLI: ${cleanDiagnostic(error.message)}`, "unavailable"));
    });
    this.child.on("exit", (code, signal) => {
      if (this.closed || this.pending.size === 0) return;
      const detail = code === null ? `signal ${signal ?? "unknown"}` : `exit code ${code}`;
      this.fail(new CodexUsageError(`Codex app-server ended before replying (${detail})`, "unavailable"));
    });

    this.timeout = setTimeout(() => {
      this.fail(new CodexUsageError("Codex app-server request timed out", "timeout"));
    }, options.timeoutMs ?? 15_000);

    if (options.signal) {
      this.abortHandler = () => this.fail(new CodexUsageError("Codex app-server request was cancelled", "cancelled"));
      if (options.signal.aborted) this.abortHandler();
      else options.signal.addEventListener("abort", this.abortHandler, { once: true });
    }
  }

  request(id: number, method: string, params?: JsonObject): Promise<unknown> {
    if (this.closed) return Promise.reject(new CodexUsageError("Codex app-server is unavailable", "unavailable"));
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      const payload = params === undefined ? { id, method } : { id, method, params };
      this.child.stdin.write(`${JSON.stringify(payload)}\n`, (error) => {
        if (error) this.fail(new CodexUsageError("Could not write to Codex app-server", "unavailable"));
      });
    });
  }

  notify(method: string): void {
    if (!this.closed) this.child.stdin.write(`${JSON.stringify({ method })}\n`);
  }

  close(): void {
    if (this.closed) return;
    this.closed = true;
    clearTimeout(this.timeout);
    this.child.stdin.end();
    this.child.kill("SIGTERM");
    if (this.signal && this.abortHandler) this.signal.removeEventListener("abort", this.abortHandler);
  }

  private consume(chunk: string): void {
    this.buffer += chunk;
    if (this.buffer.length > 2_000_000) {
      this.fail(new CodexUsageError("Codex app-server response exceeded the safety limit", "protocol"));
      return;
    }

    let newline = this.buffer.indexOf("\n");
    while (newline >= 0) {
      const line = this.buffer.slice(0, newline).replace(/\r$/, "");
      this.buffer = this.buffer.slice(newline + 1);
      if (line) this.consumeLine(line);
      newline = this.buffer.indexOf("\n");
    }
  }

  private consumeLine(line: string): void {
    let message: JsonObject;
    try {
      const parsed = object(JSON.parse(line));
      if (!parsed) throw new Error("not an object");
      message = parsed;
    } catch {
      this.fail(new CodexUsageError("Codex app-server returned malformed JSON", "protocol"));
      return;
    }

    const id = finiteNumber(message.id);
    if (id === null) return;
    const pending = this.pending.get(id);
    if (!pending) return;
    this.pending.delete(id);

    const rpcError = object(message.error);
    if (rpcError) {
      pending.reject(
        new CodexUsageError(`Codex app-server rejected the request: ${cleanDiagnostic(rpcError.message)}`, "server"),
      );
      return;
    }
    pending.resolve(message.result);
  }

  private fail(error: Error): void {
    if (this.closed) return;
    for (const request of this.pending.values()) request.reject(error);
    this.pending.clear();
    this.close();
  }
}

async function initialize(client: JsonLineRpcClient): Promise<string | null> {
  const response = object(await client.request(1, "initialize", {
    clientInfo: { name: "pi-codex-usage", version: "2.0.0" },
    capabilities: { experimentalApi: true },
  }));
  client.notify("initialized");
  return text(response?.userAgent);
}

export async function fetchCodexUsage(options: CodexAppServerOptions = {}): Promise<CodexUsageSnapshot> {
  const client = new JsonLineRpcClient(options);
  try {
    const serverUserAgent = await initialize(client);
    const result = object(await client.request(2, "account/rateLimits/read"));
    if (!result) throw new CodexUsageError("Codex returned an empty rate-limit response", "protocol");

    const byLimitId = object(result.rateLimitsByLimitId);
    const selected = byLimitId?.codex ?? result.rateLimits;
    return {
      rateLimits: parseRateLimits(selected),
      resetCards: parseResetCards(result.rateLimitResetCredits),
      fetchedAt: Date.now(),
      serverUserAgent,
      sourceMethod: "account/rateLimits/read",
    };
  } finally {
    client.close();
  }
}

export async function consumeCodexUsageResetCard(
  options: ConsumeResetCardOptions,
): Promise<ConsumeResetCardResponse> {
  const client = new JsonLineRpcClient(options);
  try {
    const serverUserAgent = await initialize(client);
    const result = object(await client.request(2, "account/rateLimitResetCredit/consume", {
      idempotencyKey: options.idempotencyKey,
      creditId: options.creditId,
    }));
    const outcome = text(result?.outcome);
    if (outcome !== "reset" && outcome !== "nothingToReset" && outcome !== "noCredit" && outcome !== "alreadyRedeemed") {
      throw new CodexUsageError("Codex returned an unknown usage reset-card outcome", "protocol");
    }
    return {
      outcome,
      consumedAt: Date.now(),
      serverUserAgent,
      sourceMethod: "account/rateLimitResetCredit/consume",
    };
  } finally {
    client.close();
  }
}
