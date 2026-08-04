import {
  CodexUsageError,
  type CodexUsageSnapshot,
  type ConsumeResetCardOptions,
  type ConsumeResetCardResponse,
  type UsageResetCard,
} from "./client.ts";

export type UsageResetCardSelection = UsageResetCard & {
  displayIndex: number;
};

export type ResetApplicationResult =
  | {
      kind: "success";
      outcome: "reset" | "alreadyRedeemed";
      snapshot: CodexUsageSnapshot | null;
      refreshError?: string;
    }
  | {
      kind: "rejected";
      outcome: "nothingToReset" | "noCredit";
      message: string;
      snapshot: CodexUsageSnapshot;
    };

export type ResetFlowDependencies = {
  fetchFresh(): Promise<CodexUsageSnapshot>;
  fetchUpdated?(): Promise<CodexUsageSnapshot>;
  consume(options: Pick<ConsumeResetCardOptions, "creditId" | "idempotencyKey">): Promise<ConsumeResetCardResponse>;
  makeIdempotencyKey(): string;
  now?: () => number;
};

export class UsageResetCardError extends Error {
  readonly kind: "stale" | "expired" | "unsupported" | "provider" | "ambiguous";

  constructor(
    message: string,
    kind: "stale" | "expired" | "unsupported" | "provider" | "ambiguous",
  ) {
    super(message);
    this.name = "UsageResetCardError";
    this.kind = kind;
  }
}

export function usageResetCardEffect(card: UsageResetCard): string {
  return card.resetType === "codexRateLimits"
    ? "Resets five-hour and weekly Codex allowance"
    : "Unsupported reset-card effect";
}

export function selectableUsageResetCards(
  snapshot: CodexUsageSnapshot,
  now = Date.now(),
): UsageResetCardSelection[] {
  const nowSeconds = Math.floor(now / 1000);
  return (snapshot.resetCards?.cards ?? [])
    .filter((card) => card.status === "available")
    .filter((card) => card.resetType === "codexRateLimits")
    .filter((card) => card.expiresAt === null || card.expiresAt > nowSeconds)
    .sort((left, right) => {
      const leftExpiry = left.expiresAt ?? Number.MAX_SAFE_INTEGER;
      const rightExpiry = right.expiresAt ?? Number.MAX_SAFE_INTEGER;
      return leftExpiry - rightExpiry || left.grantedAt - right.grantedAt || left.id.localeCompare(right.id);
    })
    .map((card, index) => ({ ...card, displayIndex: index + 1 }));
}

function sameDescription(selection: UsageResetCardSelection, current: UsageResetCard): boolean {
  return selection.id === current.id
    && selection.resetType === current.resetType
    && selection.title === current.title
    && selection.description === current.description
    && selection.grantedAt === current.grantedAt
    && selection.expiresAt === current.expiresAt;
}

function cleanError(error: unknown): string {
  if (error instanceof Error) return error.message.replace(/\s+/g, " ").trim().slice(0, 240);
  return "Unknown Codex reset-card error";
}

function retryable(error: unknown): boolean {
  return error instanceof CodexUsageError
    && (error.kind === "timeout" || error.kind === "unavailable" || error.kind === "protocol");
}

export async function applyUsageResetCard(
  selection: UsageResetCardSelection,
  dependencies: ResetFlowDependencies,
): Promise<ResetApplicationResult> {
  const fresh = await dependencies.fetchFresh();
  const now = dependencies.now?.() ?? Date.now();
  const current = fresh.resetCards?.cards?.find((card) => card.id === selection.id);

  if (!current || !sameDescription(selection, current) || current.status !== "available") {
    throw new UsageResetCardError(
      "The selected usage reset card changed or disappeared. Reopen the list and choose from the refreshed snapshot.",
      "stale",
    );
  }
  if (current.resetType !== "codexRateLimits") {
    throw new UsageResetCardError("The selected card has an unsupported reset effect.", "unsupported");
  }
  if (current.expiresAt !== null && current.expiresAt <= Math.floor(now / 1000)) {
    throw new UsageResetCardError("The selected usage reset card has expired.", "expired");
  }

  const idempotencyKey = dependencies.makeIdempotencyKey();
  let response: ConsumeResetCardResponse;
  try {
    response = await dependencies.consume({ creditId: current.id, idempotencyKey });
  } catch (firstError) {
    if (!retryable(firstError)) {
      throw new UsageResetCardError(cleanError(firstError), "provider");
    }
    try {
      response = await dependencies.consume({ creditId: current.id, idempotencyKey });
    } catch (secondError) {
      throw new UsageResetCardError(
        `The provider did not confirm whether the card was applied after an idempotent retry: ${cleanError(secondError)}`,
        "ambiguous",
      );
    }
  }

  if (response.outcome === "nothingToReset") {
    return {
      kind: "rejected",
      outcome: response.outcome,
      message: "No current allowance window was eligible for a reset. The provider did not report a successful application.",
      snapshot: fresh,
    };
  }
  if (response.outcome === "noCredit") {
    return {
      kind: "rejected",
      outcome: response.outcome,
      message: "The provider reports that no earned usage reset card is available. Refresh the card list.",
      snapshot: fresh,
    };
  }

  try {
    return {
      kind: "success",
      outcome: response.outcome,
      snapshot: await (dependencies.fetchUpdated ?? dependencies.fetchFresh)(),
    };
  } catch (error) {
    return {
      kind: "success",
      outcome: response.outcome,
      snapshot: null,
      refreshError: `The card was applied, but updated allowance could not be fetched: ${cleanError(error)}`,
    };
  }
}
