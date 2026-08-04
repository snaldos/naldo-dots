import assert from "node:assert/strict";
import { afterEach, describe, it } from "node:test";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadDoctorConfiguration } from "./doctor-config.ts";

const temporaryDirectories: string[] = [];

async function configurationFixture(trust?: string): Promise<string> {
  const agentDir = await mkdtemp(join(tmpdir(), "pi-doctor-test."));
  temporaryDirectories.push(agentDir);
  await mkdir(join(agentDir, "themes"));
  await Promise.all([
    writeFile(join(agentDir, "settings.json"), JSON.stringify({
      defaultProjectTrust: "ask",
      theme: "noctalia",
      quietStartup: true,
      externalEditor: "hx",
      enableAnalytics: false,
      enableInstallTelemetry: false,
      compaction: { reserveTokens: 65_536, keepRecentTokens: 40_000 },
    })),
    writeFile(join(agentDir, "keybindings.json"), "{}"),
    writeFile(join(agentDir, "themes/noctalia.json"), JSON.stringify({
      name: "noctalia",
      colors: {
        accent: "#ffffff",
        dim: "fgMuted",
        mdCodeBlockBorder: "fgMuted",
        borderMuted: "outline",
        thinkingXhigh: "#ffffff",
      },
    })),
  ]);
  if (trust !== undefined) await writeFile(join(agentDir, "trust.json"), trust);
  return agentDir;
}

afterEach(async () => {
  await Promise.all(temporaryDirectories.splice(0).map((path) => rm(path, { recursive: true, force: true })));
});

describe("Pi doctor configuration", () => {
  it("accepts an absent optional trust store", async () => {
    const result = await loadDoctorConfiguration(await configurationFixture());
    assert.equal(result.valid, true);
    assert.equal(result.trustPresent, false);
  });

  it("accepts a valid trust store", async () => {
    const result = await loadDoctorConfiguration(await configurationFixture("{}"));
    assert.equal(result.valid, true);
    assert.equal(result.trustPresent, true);
  });

  it("rejects a malformed existing trust store", async () => {
    await assert.rejects(
      loadDoctorConfiguration(await configurationFixture("{")),
      SyntaxError,
    );
  });

  it("matches the durable Noctalia template", async () => {
    const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../../..");
    const template = JSON.parse(await readFile(
      join(repositoryRoot, "noctalia/.config/noctalia/templates/pi-noctalia.json"),
      "utf8",
    ));
    assert.equal(template.colors.dim, "fgMuted");
    assert.equal(template.colors.mdCodeBlockBorder, "fgMuted");
    assert.equal(template.colors.borderMuted, "outline");
  });
});
