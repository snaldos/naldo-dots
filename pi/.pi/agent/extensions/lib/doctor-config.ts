import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

export type JsonObject = Record<string, unknown>;

function object(value: unknown): JsonObject | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonObject)
    : null;
}

async function readJson(path: string): Promise<JsonObject> {
  const parsed = JSON.parse(await readFile(path, "utf8"));
  const value = object(parsed);
  if (!value) throw new Error("top-level value is not an object");
  return value;
}

export async function loadDoctorConfiguration(agentDir: string): Promise<{
  settings: JsonObject;
  trustPresent: boolean;
  valid: boolean;
}> {
  const [settings, keybindings, theme] = await Promise.all(
    ["settings.json", "keybindings.json", "themes/noctalia.json"]
      .map((file) => readJson(join(agentDir, file))),
  );
  const trustPath = join(agentDir, "trust.json");
  const trustPresent = existsSync(trustPath);
  if (trustPresent) await readJson(trustPath);

  const colors = object(theme.colors);
  const compaction = object(settings.compaction);
  const keybindingsValid = Object.values(keybindings).every(
    (value) => typeof value === "string"
      || (Array.isArray(value) && value.every((key) => typeof key === "string")),
  );
  const valid = settings.defaultProjectTrust === "ask"
    && settings.theme === "noctalia"
    && settings.quietStartup === true
    && settings.externalEditor === "hx"
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

  return { settings, trustPresent, valid };
}
