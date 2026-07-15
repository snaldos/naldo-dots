import { existsSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, resolve, sep } from "node:path";

export type SafetyAction = "allow" | "ask";

export type SafetyIssue = {
  category: string;
  reason: string;
  effect: string;
  target?: string;
};

export type SafetyClassification = {
  action: SafetyAction;
  issues: SafetyIssue[];
  command: string;
};

export type ClassifierOptions = {
  home?: string;
};

type Token = {
  kind: "word" | "operator" | "redirect";
  value: string;
};

type Segment = {
  words: string[];
  redirects: Array<{ operator: string; target?: string }>;
  operatorAfter?: string;
};

type Variables = ReadonlyMap<string, string>;

type ExecutableInfo = {
  executable: string;
  args: string[];
  elevated: boolean;
};

const SYSTEM_PATHS = ["/boot", "/efi", "/etc", "/opt", "/usr", "/var/lib", "/proc", "/sys", "/dev"];
const SAFE_DEVICE_WRITES = new Set(["/dev/null", "/dev/stdout", "/dev/stderr", "/dev/tty"]);
const SHELLS = new Set(["bash", "dash", "fish", "sh", "zsh"]);
const METADATA_READERS = new Set([
  "file",
  "ls",
  "readlink",
  "sha1sum",
  "sha256sum",
  "sha512sum",
  "stat",
  "test",
  "[",
]);
const CONTENT_READERS = new Set([
  "awk",
  "base64",
  "bat",
  "cat",
  "cmp",
  "cp",
  "curl",
  "diff",
  "grep",
  "head",
  "jq",
  "less",
  "more",
  "mv",
  "od",
  "openssl",
  "perl",
  "python",
  "python3",
  "rg",
  "rsync",
  "scp",
  "sed",
  "strings",
  "tail",
  "tar",
  "tee",
  "wget",
  "xxd",
  "zip",
]);

function isWithin(path: string, root: string): boolean {
  return path === root || path.startsWith(`${root}${sep}`);
}

function issue(category: string, reason: string, effect: string, target?: string): SafetyIssue {
  return { category, reason, effect, target };
}

function homeFor(options: ClassifierOptions): string {
  return options.home ?? homedir();
}

function canonicalPath(rawPath: string, cwd: string): string {
  const absolute = resolve(cwd, rawPath);
  let existing = absolute;
  const suffix: string[] = [];

  while (!existsSync(existing)) {
    const parent = dirname(existing);
    if (parent === existing) return absolute;
    suffix.unshift(basename(existing));
    existing = parent;
  }

  try {
    return resolve(realpathSync(existing), ...suffix);
  } catch {
    return absolute;
  }
}

function expandKnownValue(rawValue: string, cwd: string, home: string, variables: Variables): string | undefined {
  let value = rawValue.replace(/^@(?=[~/.$]|[A-Za-z_][A-Za-z0-9_]*\$)/, "");
  if (value.startsWith("file://")) {
    try {
      value = new URL(value).pathname;
    } catch {
      return undefined;
    }
  }
  if (/^[A-Za-z][A-Za-z0-9+.-]*:\/\//.test(value) || /^[^/\s]+:[^/]/.test(value)) return undefined;

  value = value
    .replace(/^~(?=\/|$)/, home)
    .replace(/\$\{HOME\}|\$HOME\b/g, home)
    .replace(/\$\{PWD\}|\$PWD\b/g, cwd);

  let unresolved = false;
  for (let pass = 0; pass < 8; pass += 1) {
    let changed = false;
    value = value.replace(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)\b/g, (match, braced, plain) => {
      const replacement = variables.get(braced ?? plain);
      if (replacement === undefined) {
        unresolved = true;
        return match;
      }
      changed = true;
      return replacement;
    });
    if (!changed) break;
  }

  if (unresolved || /[`$]/.test(value)) return undefined;
  return canonicalPath(value, cwd);
}

function sensitiveReason(path: string, home: string): string | undefined {
  const agentRoot = resolve(home, ".pi/agent");
  const exact = new Set([
    resolve(agentRoot, "auth.json"),
    resolve(agentRoot, "agent.db"),
    resolve(agentRoot, "trust.json"),
    resolve(home, ".codex/auth.json"),
    resolve(home, ".docker/config.json"),
    resolve(home, ".config/gh/hosts.yml"),
    resolve(home, ".kube/config"),
    resolve(home, ".git-credentials"),
    resolve(home, ".netrc"),
    resolve(home, ".npmrc"),
    resolve(home, ".pypirc"),
    "/etc/shadow",
    "/etc/gshadow",
  ]);
  const roots = [
    resolve(home, ".gnupg"),
    resolve(home, ".aws"),
    resolve(home, ".config/gcloud"),
    resolve(agentRoot, "sessions"),
    resolve(home, ".codex/sessions"),
  ];

  if (exact.has(path)) return "credential or private runtime state";
  if (roots.some((root) => isWithin(path, root))) return "credential or private-session content";
  if (isWithin(path, resolve(home, ".ssh"))) {
    const name = basename(path);
    const publicMetadata = name.endsWith(".pub") || ["config", "known_hosts"].includes(name);
    if (!publicMetadata) return "private SSH material";
  }

  const name = basename(path);
  if (/^\.env(?:\..+)?$/i.test(name) && !/\.(?:example|sample|template)$/i.test(name)) return "environment secrets";
  if (/\.(?:pem|key|p12|pfx)$/i.test(name)) return "private key material";
  if (/^(?:credentials|secrets?)(?:\.[^.]+)?$/i.test(name)) return "credential content";
  if (/^(?:Login Data|logins\.json|key4\.db|cookies\.sqlite)$/i.test(name)) return "browser credential or session data";
  return undefined;
}

function systemPathReason(path: string): string | undefined {
  if (path === "/") return "the filesystem root";
  if (SAFE_DEVICE_WRITES.has(path) || isWithin(path, "/dev/fd")) return undefined;
  const root = SYSTEM_PATHS.find((candidate) => isWithin(path, candidate));
  if (!root) return undefined;
  if (root === "/dev") return "device state";
  if (root === "/proc" || root === "/sys") return "kernel runtime state";
  if (root === "/boot" || root === "/efi") return "boot state";
  return "system or package-managed state";
}

function isGitMetadata(path: string): boolean {
  return path.split(sep).includes(".git");
}

function classifyResolvedPath(path: string, operation: "read" | "mutate", home: string): SafetyIssue[] {
  const sensitive = sensitiveReason(path, home);
  if (sensitive) {
    return [issue(
      operation === "read" ? "private content access" : "private state change",
      `The target contains ${sensitive}.`,
      operation === "read"
        ? `Would expose ${path} to the model context or command output.`
        : `Would modify or remove ${path}.`,
      path,
    )];
  }
  if (operation === "read") return [];

  if (isGitMetadata(path)) {
    return [issue(
      "Git metadata change",
      "Direct changes below .git can corrupt repository metadata or bypass Git's recovery mechanisms.",
      `Would modify or remove ${path}.`,
      path,
    )];
  }

  const system = systemPathReason(path);
  if (system) {
    return [issue(
      "critical system change",
      `The target is ${system}.`,
      `Would modify or remove ${path}.`,
      path,
    )];
  }
  return [];
}

export function classifyPathTool(
  tool: "read" | "write" | "edit",
  rawPath: string,
  cwd: string,
  options: ClassifierOptions = {},
): SafetyClassification {
  const home = homeFor(options);
  const path = canonicalPath(
    rawPath
      .replace(/^@/, "")
      .replace(/^~(?=\/|$)/, home)
      .replace(/^\$\{HOME\}(?=\/|$)|^\$HOME(?=\/|$)/, home),
    cwd,
  );
  const issues = classifyResolvedPath(path, tool === "read" ? "read" : "mutate", home);
  return finalize(rawPath, issues);
}

function lexShell(source: string): Token[] {
  const tokens: Token[] = [];
  let word = "";
  let quote: "single" | "double" | null = null;
  let atBoundary = true;

  const pushWord = () => {
    if (!word) return;
    tokens.push({ kind: "word", value: word });
    word = "";
    atBoundary = false;
  };

  for (let index = 0; index < source.length; index += 1) {
    const character = source[index]!;
    const next = source[index + 1];
    const third = source[index + 2];

    if (quote === "single") {
      if (character === "'") quote = null;
      else word += character;
      continue;
    }
    if (quote === "double") {
      if (character === '"') quote = null;
      else if (character === "\\" && next !== undefined) word += source[++index]!;
      else word += character;
      continue;
    }
    if (character === "'") {
      quote = "single";
      continue;
    }
    if (character === '"') {
      quote = "double";
      continue;
    }
    if (character === "\\" && next !== undefined) {
      word += source[++index]!;
      continue;
    }
    if (character === "#" && (atBoundary || word === "")) {
      pushWord();
      while (index < source.length && source[index] !== "\n") index += 1;
      tokens.push({ kind: "operator", value: "\n" });
      atBoundary = true;
      continue;
    }
    if (/\s/.test(character)) {
      pushWord();
      if (character === "\n") tokens.push({ kind: "operator", value: "\n" });
      atBoundary = true;
      continue;
    }

    const triple = `${character}${next ?? ""}${third ?? ""}`;
    const pair = `${character}${next ?? ""}`;
    if (["&>>", "<<<"].includes(triple)) {
      pushWord();
      tokens.push({ kind: "redirect", value: triple });
      index += 2;
      atBoundary = true;
      continue;
    }
    if (["&&", "||", ";;"].includes(pair)) {
      pushWord();
      tokens.push({ kind: "operator", value: pair });
      index += 1;
      atBoundary = true;
      continue;
    }
    if ([">>", "<<", ">|", "<&", ">&", "&>"].includes(pair)) {
      pushWord();
      tokens.push({ kind: "redirect", value: pair });
      index += 1;
      atBoundary = true;
      continue;
    }
    if ([";", "|", "&", "(", ")"].includes(character)) {
      pushWord();
      tokens.push({ kind: "operator", value: character });
      atBoundary = true;
      continue;
    }
    if ([">", "<"].includes(character)) {
      pushWord();
      tokens.push({ kind: "redirect", value: character });
      atBoundary = true;
      continue;
    }

    word += character;
    atBoundary = false;
  }
  pushWord();
  return tokens;
}

function shellSegments(tokens: Token[]): Segment[] {
  const result: Segment[] = [];
  let words: string[] = [];
  let redirects: Segment["redirects"] = [];

  const push = (operatorAfter?: string) => {
    if (words.length || redirects.length) result.push({ words, redirects, operatorAfter });
    words = [];
    redirects = [];
  };

  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index]!;
    if (token.kind === "operator") {
      push(token.value);
      continue;
    }
    if (token.kind === "redirect") {
      const target = tokens[index + 1]?.kind === "word" ? tokens[++index]!.value : undefined;
      redirects.push({ operator: token.value, target });
      continue;
    }
    words.push(token.value);
  }
  push();
  return result;
}

function executableInfo(words: string[]): ExecutableInfo | null {
  let index = 0;
  let elevated = false;
  while (index < words.length && /^[A-Za-z_][A-Za-z0-9_]*=.*/.test(words[index]!)) index += 1;

  while (index < words.length) {
    const wrapper = basename(words[index]!).toLowerCase();
    if (["if", "then", "elif", "else", "do", "while", "until", "!"].includes(wrapper)) {
      index += 1;
      continue;
    }
    if (wrapper === "sudo" || wrapper === "doas") {
      elevated = true;
      index += 1;
      while (index < words.length && words[index]!.startsWith("-")) {
        const option = words[index++]!;
        if (["-u", "-g", "-h", "-p", "-C", "-T", "--user", "--group", "--host", "--prompt", "--chdir", "--command-timeout"].includes(option)) {
          index += 1;
        }
      }
      continue;
    }
    if (wrapper === "env") {
      index += 1;
      while (index < words.length && (words[index]!.startsWith("-") || /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[index]!))) index += 1;
      continue;
    }
    if (wrapper === "busybox") {
      index += 1;
      break;
    }
    if (["command", "builtin", "nice", "nohup", "setsid", "time"].includes(wrapper)) {
      index += 1;
      while (index < words.length && words[index]!.startsWith("-")) index += 1;
      continue;
    }
    break;
  }

  if (index >= words.length) return null;
  return {
    executable: basename(words[index]!).toLowerCase(),
    args: words.slice(index + 1),
    elevated,
  };
}

function updateVariables(words: string[], variables: Map<string, string>, cwd: string, home: string): void {
  let index = 0;
  if (["export", "readonly", "local", "declare", "typeset"].includes(words[0] ?? "")) index += 1;
  for (; index < words.length; index += 1) {
    const match = words[index]!.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/s);
    if (!match) break;
    const expanded = expandKnownValue(match[2]!, cwd, home, variables);
    if (expanded) variables.set(match[1]!, expanded);
    else variables.delete(match[1]!);
  }
}

function commandSubstitutions(source: string): string[] {
  const nested: string[] = [];
  let quote: "single" | "double" | null = null;

  for (let index = 0; index < source.length; index += 1) {
    const character = source[index]!;
    if (quote === "single") {
      if (character === "'") quote = null;
      continue;
    }
    if (quote === "double" && character === '"') {
      quote = null;
      continue;
    }
    if (!quote && character === "'") {
      quote = "single";
      continue;
    }
    if (!quote && character === '"') {
      quote = "double";
      continue;
    }
    if (character === "\\") {
      index += 1;
      continue;
    }
    if (character === "$" && source[index + 1] === "(" && source[index + 2] !== "(") {
      let depth = 1;
      let cursor = index + 2;
      let innerQuote: "single" | "double" | null = null;
      for (; cursor < source.length; cursor += 1) {
        const current = source[cursor]!;
        if (innerQuote === "single") {
          if (current === "'") innerQuote = null;
          continue;
        }
        if (innerQuote === "double") {
          if (current === '"') innerQuote = null;
          if (current === "\\") cursor += 1;
          continue;
        }
        if (current === "'") innerQuote = "single";
        else if (current === '"') innerQuote = "double";
        else if (current === "(") depth += 1;
        else if (current === ")" && --depth === 0) break;
      }
      if (depth === 0) {
        nested.push(source.slice(index + 2, cursor));
        index = cursor;
      }
    } else if (character === "`") {
      const end = source.indexOf("`", index + 1);
      if (end > index) {
        nested.push(source.slice(index + 1, end));
        index = end;
      }
    }
  }
  return nested;
}

function stripHereDocs(source: string): { command: string; shellBodies: string[] } {
  const lines = source.split("\n");
  const kept: string[] = [];
  const shellBodies: string[] = [];

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index]!;
    kept.push(line);
    const match = line.match(/<<-?\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?/);
    if (!match) continue;

    const body: string[] = [];
    let cursor = index + 1;
    for (; cursor < lines.length; cursor += 1) {
      if (lines[cursor]!.trim() === match[1]) break;
      body.push(lines[cursor]!);
    }
    const opening = shellSegments(lexShell(line)).map((segment) => executableInfo(segment.words));
    if (opening.some((info) => info && SHELLS.has(info.executable))) shellBodies.push(body.join("\n"));
    index = cursor;
  }
  return { command: kept.join("\n"), shellBodies };
}

function operands(args: string[]): string[] {
  return args.filter((argument) => argument !== "--" && !argument.startsWith("-"));
}

function contentPathCandidates(args: string[]): string[] {
  return args.flatMap((argument) => {
    const attachedFile = argument.match(/^(?:[^=\s]+[=@]|@)(.+)$/);
    if (attachedFile) return [attachedFile[1]!];
    return argument !== "--" && !argument.startsWith("-") ? [argument] : [];
  });
}

function optionValue(args: string[], short: string, long: string): string | undefined {
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index]!;
    if (argument === short || argument === long) return args[index + 1];
    if (argument.startsWith(`${long}=`)) return argument.slice(long.length + 1);
  }
  return undefined;
}

function pathIssues(
  rawPaths: Array<string | undefined>,
  operation: "read" | "mutate",
  cwd: string,
  home: string,
  variables: Variables,
): SafetyIssue[] {
  return rawPaths.flatMap((rawPath) => {
    if (!rawPath) return [];
    const path = expandKnownValue(rawPath, cwd, home, variables);
    return path ? classifyResolvedPath(path, operation, home) : [];
  });
}

function destructiveRootIssue(path: string, cwd: string, home: string): SafetyIssue | undefined {
  if (path !== cwd && path !== home && path !== "/home" && path !== "/") return undefined;
  return issue(
    "broad destructive change",
    path === cwd
      ? "The target is the active workspace root."
      : path === home
        ? "The target is the user home directory."
        : "The target covers a major filesystem root.",
    `Would remove or destructively replace ${path}.`,
    path,
  );
}

function classifyMutationTargets(
  executable: string,
  args: string[],
  cwd: string,
  home: string,
  variables: Variables,
): SafetyIssue[] {
  let targets: string[] = [];
  let destructive = false;

  if (["rm", "rmdir", "unlink", "shred"].includes(executable)) {
    targets = operands(args);
    destructive = true;
  } else if (executable === "mv") {
    targets = operands(args);
    destructive = true;
  } else if (["cp", "install", "ln", "rsync"].includes(executable)) {
    const explicitTarget = optionValue(args, "-t", "--target-directory");
    targets = explicitTarget ? [explicitTarget] : operands(args).slice(-1);
  } else if (["tee", "truncate", "touch", "mkdir", "mkfifo"].includes(executable)) {
    targets = operands(args);
  } else if (["chmod", "chown", "chgrp", "chattr", "setfacl"].includes(executable)) {
    targets = operands(args).slice(1);
  } else if (executable === "sed" && args.some((argument) => argument === "-i" || argument.startsWith("-i"))) {
    targets = operands(args).slice(1);
  } else if (executable === "perl" && args.some((argument) => /^-[^-]*i/.test(argument))) {
    targets = operands(args).slice(-1);
  } else if (executable === "dd") {
    targets = args.filter((argument) => argument.startsWith("of=")).map((argument) => argument.slice(3));
  } else if (executable === "find" && (args.includes("-delete") || args.some((argument) => argument === "-exec" || argument === "-execdir"))) {
    targets = [operands(args)[0] ?? "."];
    destructive = true;
  } else if (["tar", "unzip"].includes(executable)) {
    const destination = executable === "tar"
      ? optionValue(args, "-C", "--directory")
      : optionValue(args, "-d", "--directory");
    if (destination) targets = [destination];
  }

  const issues = pathIssues(targets, "mutate", cwd, home, variables);
  if (destructive) {
    for (const target of targets) {
      const path = expandKnownValue(target, cwd, home, variables);
      const broad = path ? destructiveRootIssue(path, cwd, home) : undefined;
      if (broad) issues.push(broad);
      const broadWildcard = /^\/(?:\*|\*\*)/.test(target)
        || /^\/home\/(?:\*|\*\*)/.test(target)
        || path === `${home}/*`
        || path === `${home}/.*`
        || path === `${cwd}/*`
        || path === `${cwd}/.*`;
      if (broadWildcard) {
        issues.push(issue(
          "broad destructive change",
          "The wildcard covers a major filesystem tree.",
          `Would remove paths matched by ${target}.`,
          target,
        ));
      }
    }
  }

  if (["chmod", "chown", "chgrp"].includes(executable) && args.some((argument) => argument === "-R" || argument === "--recursive")) {
    for (const target of targets) {
      const path = expandKnownValue(target, cwd, home, variables);
      if (path === cwd || path === home) {
        issues.push(issue(
          "broad metadata change",
          path === cwd ? "The target is the active workspace root." : "The target is the user home directory.",
          `Would recursively change permissions or ownership below ${path}.`,
          path,
        ));
      }
    }
  }
  return issues;
}

function gitInfo(args: string[]): { subcommand: string; args: string[] } | null {
  let index = 0;
  const consumesValue = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix", "--config-env"]);
  while (index < args.length) {
    const argument = args[index]!;
    if (consumesValue.has(argument)) index += 2;
    else if (argument.startsWith("-")) index += 1;
    else break;
  }
  return index < args.length
    ? { subcommand: args[index]!.toLowerCase(), args: args.slice(index + 1) }
    : null;
}

function gitIssue(category: string, reason: string, args: string[]): SafetyIssue {
  return issue(category, reason, `Would run a repository-mutating Git operation: git ${args.join(" ")}.`);
}

function classifyGit(args: string[]): SafetyIssue[] {
  const info = gitInfo(args);
  if (!info) return [];
  const subcommand = info.subcommand;
  const rest = info.args;
  const all = [subcommand, ...rest];
  const dryRun = rest.includes("--dry-run")
    || subcommand === "clean" && rest.some((argument) => /^-[^-]*n/.test(argument))
    || subcommand === "push" && rest.includes("-n");

  if (subcommand === "push" && !dryRun) {
    const force = rest.some((argument) => argument === "-f" || argument === "--force" || argument.startsWith("--force-with-lease"));
    return [gitIssue(
      force ? "force push" : "Git push",
      force ? "This can replace shared remote history." : "This publishes repository state to a remote.",
      all,
    )];
  }

  if (["commit", "merge", "rebase", "reset", "cherry-pick", "revert", "pull", "am"].includes(subcommand) && !dryRun) {
    return [gitIssue(
      "Git history change",
      `${subcommand} creates, combines, replaces, or moves repository history.`,
      all,
    )];
  }

  if (subcommand === "clean" && !dryRun) {
    return [gitIssue("destructive Git cleanup", "git clean permanently removes untracked files.", all)];
  }
  if (subcommand === "restore") {
    return [gitIssue("destructive Git restore", "git restore can discard worktree or index changes.", all)];
  }
  if (subcommand === "checkout" && (rest.includes("--") || rest.includes("-f") || rest.includes("--force") || rest.includes("-b") || rest.includes("-B"))) {
    return [gitIssue("Git worktree or metadata change", "This checkout form discards files or creates/replaces a branch ref.", all)];
  }
  if (subcommand === "switch" && rest.some((argument) => ["-c", "-C", "--create", "--force-create", "--discard-changes"].includes(argument))) {
    return [gitIssue("Git metadata change", "This switch form creates/replaces a branch or discards worktree changes.", all)];
  }
  if (subcommand === "stash" && ["drop", "clear", "pop"].includes(rest[0]?.toLowerCase() ?? "")) {
    return [gitIssue("destructive stash change", "This can remove saved recovery state from the stash.", all)];
  }

  if (subcommand === "branch") {
    const readOnly = rest.length === 0
      || rest.every((argument) => argument.startsWith("-"))
      || rest.some((argument) => ["-a", "-r", "--all", "--remotes", "--list", "--show-current", "--contains", "--no-contains", "--merged", "--no-merged", "--format"].includes(argument));
    if (!readOnly) return [gitIssue("Git ref change", "This creates, renames, copies, or deletes a branch ref.", all)];
  }
  if (subcommand === "tag") {
    const readOnly = rest.length === 0
      || rest.every((argument) => argument.startsWith("-"))
      || rest.some((argument) => ["-l", "--list", "-n", "--contains", "--no-contains", "--merged", "--no-merged", "--points-at", "--format"].includes(argument));
    if (!readOnly) return [gitIssue("Git ref change", "This creates, replaces, or deletes a tag ref.", all)];
  }

  if (subcommand === "config") {
    const mutatingFlag = rest.some((argument) => /^(?:--unset(?:-all)?|--rename-section|--remove-section|--add|--replace-all|--edit|-e)$/.test(argument));
    const positional = rest.filter((argument) => !argument.startsWith("-"));
    if (mutatingFlag || positional.length >= 2) {
      return [gitIssue("Git configuration change", "This changes persistent repository or user Git configuration.", all)];
    }
  }
  if (subcommand === "remote" && rest.length && !["-v", "show", "get-url"].includes(rest[0]!.toLowerCase())) {
    return [gitIssue("Git remote metadata change", "This changes remote configuration or deletes remote-tracking metadata.", all)];
  }

  if (["update-ref", "symbolic-ref", "replace", "notes", "reflog", "prune", "gc", "filter-branch", "filter-repo"].includes(subcommand)) {
    return [gitIssue("Git metadata or history rewrite", `${subcommand} changes or discards repository recovery metadata or history.`, all)];
  }
  if (subcommand === "worktree" && rest.length && !["list"].includes(rest[0]!.toLowerCase())) {
    return [gitIssue("Git worktree metadata change", "This changes linked-worktree metadata.", all)];
  }
  return [];
}

function packageIssue(manager: string, action: string, args: string[]): SafetyIssue {
  return issue(
    "package transaction",
    `${manager} would ${action} installed software or system package metadata.`,
    `Would run ${manager} ${args.join(" ")}.`,
  );
}

function classifyPackageManager(executable: string, args: string[], elevated: boolean): SafetyIssue[] {
  if (["pacman", "paru", "yay"].includes(executable)) {
    const longAction = args.find((argument) => ["--remove", "--sync", "--sysupgrade", "--upgrade"].includes(argument));
    if (longAction) return [packageIssue(executable, "change", args)];
    const action = args.find((argument) => /^-[A-Za-z]/.test(argument));
    if (!action) return [];
    if (/^-R/.test(action)) return [packageIssue(executable, "remove", args)];
    if (/^-U/.test(action)) return [packageIssue(executable, "install", args)];
    if (action === "-S" || /^-S(?=.*[uy])/.test(action)) return [packageIssue(executable, "install or upgrade", args)];
    return [];
  }

  const action = args.find((argument) => !argument.startsWith("-"))?.toLowerCase();
  if (!action) return [];
  const actions: Record<string, Set<string>> = {
    apt: new Set(["install", "remove", "purge", "upgrade", "full-upgrade", "dist-upgrade", "autoremove"]),
    "apt-get": new Set(["install", "remove", "purge", "upgrade", "dist-upgrade", "autoremove"]),
    dnf: new Set(["install", "remove", "upgrade", "update", "distro-sync", "autoremove"]),
    yum: new Set(["install", "remove", "upgrade", "update", "autoremove"]),
    zypper: new Set(["install", "remove", "update", "dist-upgrade", "dup"]),
    brew: new Set(["install", "uninstall", "remove", "upgrade", "reinstall"]),
    flatpak: new Set(["install", "uninstall", "remove", "update"]),
    snap: new Set(["install", "remove", "refresh", "revert"]),
  };
  if (actions[executable]?.has(action)) return [packageIssue(executable, action, args)];

  if (elevated && ["pip", "pip3"].includes(executable) && ["install", "uninstall"].includes(action)) {
    return [packageIssue(executable, action, args)];
  }
  if (elevated && ["npm", "pnpm", "yarn"].includes(executable)
      && ["install", "uninstall", "remove", "add", "update"].includes(action)) {
    return [packageIssue(executable, action, args)];
  }
  return [];
}

function classifySystemctl(args: string[]): SafetyIssue[] {
  if (args.includes("--user")) return [];
  const action = args.find((argument) => !argument.startsWith("-"))?.toLowerCase();
  const readOnly = new Set(["status", "show", "is-active", "is-enabled", "list-units", "list-unit-files", "cat", "help"]);
  if (!action || readOnly.has(action)) return [];
  return [issue(
    "system service change",
    "This changes system-wide service state and can interrupt login, networking, or the desktop.",
    `Would run systemctl ${args.join(" ")}.`,
  )];
}

function classifySystemOperation(executable: string, args: string[]): SafetyIssue[] {
  if (["reboot", "shutdown", "poweroff", "halt", "systemctl-poweroff"].includes(executable)) {
    return [issue("power or session change", "This ends or restarts the active machine session.", `Would run ${executable} ${args.join(" ")}.`)];
  }
  if (executable === "systemctl") return classifySystemctl(args);
  if (executable === "service" && args.some((argument) => /^(?:start|stop|restart|reload|enable|disable)$/i.test(argument))) {
    return [issue("system service change", "This changes system-wide service state.", `Would run service ${args.join(" ")}.`)];
  }

  const readOnlyDiskTool = executable === "fdisk" && args.includes("-l")
    || executable === "parted" && args.some((argument) => argument === "-l" || argument === "--list")
    || executable === "wipefs" && !args.some((argument) => ["-a", "--all", "-o", "--offset"].includes(argument))
    || executable === "fsck" && args.some((argument) => argument === "-N" || argument === "-n");
  if (!readOnlyDiskTool && (/^mkfs(?:\.|$)/.test(executable)
      || ["blkdiscard", "cfdisk", "fsck", "parted", "sfdisk", "fdisk", "wipefs"].includes(executable))) {
    return [issue("disk or filesystem change", "This can overwrite filesystem, partition, or block-device metadata.", `Would run ${executable} ${args.join(" ")}.`)];
  }
  if (["mount", "umount", "swapon", "swapoff", "losetup", "cryptsetup", "pvcreate", "vgcreate", "lvcreate", "lvremove"].includes(executable)) {
    const readOnlyStorage = executable === "mount" && (args.length === 0 || args.every((argument) => ["-l", "--show-labels", "--help", "--version"].includes(argument)))
      || executable === "losetup" && (args.length === 0 || args.some((argument) => ["-a", "--all", "-l", "--list", "-j", "--associated"].includes(argument)))
      || executable === "swapon" && args.some((argument) => argument === "--show" || argument.startsWith("--show="))
      || executable === "cryptsetup" && ["status", "luksdump", "benchmark"].includes(args[0]?.toLowerCase() ?? "");
    if (!readOnlyStorage) return [issue("storage topology change", "This changes mounted, encrypted, swap, loop, or volume state.", `Would run ${executable} ${args.join(" ")}.`)];
  }

  if (["mkinitcpio", "dracut", "grub-install", "grub-mkconfig", "kernel-install"].includes(executable)) {
    return [issue("boot configuration change", "This regenerates or replaces boot-critical artifacts.", `Would run ${executable} ${args.join(" ")}.`)];
  }
  if (executable === "bootctl") {
    const action = args.find((argument) => !argument.startsWith("-"))?.toLowerCase();
    if (action && !["status", "list", "is-installed"].includes(action)) {
      return [issue("boot configuration change", "This changes boot-loader state or the selected boot target.", `Would run bootctl ${args.join(" ")}.`)];
    }
  }

  if (["useradd", "userdel", "usermod", "groupadd", "groupdel", "groupmod", "passwd", "chpasswd", "visudo"].includes(executable)) {
    return [issue("account or privilege change", "This changes login, identity, authentication, or privilege state.", `Would run ${executable} ${args.join(" ")}.`)];
  }
  if (["insmod", "rmmod", "modprobe"].includes(executable)) {
    return [issue("kernel module change", "This changes code loaded into the running kernel.", `Would run ${executable} ${args.join(" ")}.`)];
  }
  if (executable === "sysctl" && args.some((argument) => argument === "-w" || /^[A-Za-z0-9_.]+=.*/.test(argument))) {
    return [issue("kernel setting change", "This changes running kernel parameters.", `Would run sysctl ${args.join(" ")}.`)];
  }

  if (["iptables", "ip6tables", "ebtables"].includes(executable)
      && !args.some((argument) => ["-L", "-S", "--list", "--list-rules"].includes(argument) || /^-[^-]*[LS]/.test(argument))) {
    return [issue("firewall change", "This can interrupt local or remote network access.", `Would run ${executable} ${args.join(" ")}.`)];
  }
  if (executable === "nft") {
    const action = args.find((argument) => !argument.startsWith("-"))?.toLowerCase();
    if (action && action !== "list") {
      return [issue("firewall change", "This can interrupt local or remote network access.", `Would run nft ${args.join(" ")}.`)];
    }
  }
  if (executable === "ip" && args.some((argument) => /^(?:add|append|change|delete|del|flush|replace|set)$/i.test(argument))) {
    return [issue("network configuration change", "This can interrupt connectivity or routing.", `Would run ip ${args.join(" ")}.`)];
  }
  if (executable === "nmcli" && args.some((argument) => /^(?:add|delete|modify|reload|up|down)$/i.test(argument))) {
    return [issue("network configuration change", "This can interrupt connectivity or alter saved network profiles.", `Would run nmcli ${args.join(" ")}.`)];
  }
  if (executable === "tailscale" && args.some((argument) => /^(?:up|down|logout|set|switch|serve|funnel)$/i.test(argument))) {
    return [issue("remote access change", "This can alter or sever the workstation's remote access path.", `Would run tailscale ${args.join(" ")}.`)];
  }
  if (executable === "wg-quick" && /^(?:up|down)$/i.test(args[0] ?? "")) {
    return [issue("network configuration change", "This changes a WireGuard interface and can interrupt connectivity.", `Would run wg-quick ${args.join(" ")}.`)];
  }

  if (executable === "hyprctl" && /\bdispatch\s+exit\b/i.test(args.join(" "))) {
    return [issue("graphical session termination", "This exits Hyprland and can close the active desktop session.", `Would run hyprctl ${args.join(" ")}.`)];
  }
  if (executable === "loginctl" && args.some((argument) => /^(?:terminate-user|terminate-session|kill-user)$/i.test(argument))) {
    return [issue("login session termination", "This terminates a login session and its processes.", `Would run loginctl ${args.join(" ")}.`)];
  }
  if (["pkill", "killall"].includes(executable)) {
    const target = operands(args).at(-1) ?? "";
    if (/(?:hyprland|greetd|systemd|wayland|ghostty|herdr|sshd|tailscaled)/i.test(target)) {
      return [issue("critical process termination", "The target may own login, networking, the terminal, or the active agent session.", `Would terminate processes matching ${target}.`, target)];
    }
  }
  return [];
}

function classifyRemoteOperation(executable: string, args: string[]): SafetyIssue[] {
  const joined = args.join(" ");
  if (executable === "gh" && /^(?:repo\s+(?:create|delete)|issue\s+(?:create|comment|close|delete)|pr\s+(?:create|comment|close|merge)|release\s+(?:create|delete)|gist\s+create)\b/i.test(joined)) {
    return [issue("remote publication or mutation", "This creates, publishes, merges, closes, or deletes GitHub state.", `Would run gh ${joined}.`)];
  }
  if (["aws", "az", "gcloud", "kubectl", "terraform", "tofu"].includes(executable)
      && /\b(?:apply|create|delete|destroy|remove|rm|terminate|update|replace)\b/i.test(joined)) {
    return [issue("remote infrastructure change", "This can create, alter, or destroy remote resources.", `Would run ${executable} ${joined}.`)];
  }
  if ((executable === "npm" || executable === "cargo") && args[0]?.toLowerCase() === "publish"
      || executable === "twine" && args[0]?.toLowerCase() === "upload") {
    return [issue("package publication", "Published artifacts may be public, immutable, or immediately consumed.", `Would run ${executable} ${joined}.`)];
  }
  return [];
}

function classifySegment(
  segment: Segment,
  cwd: string,
  home: string,
  variables: Map<string, string>,
  depth: number,
): SafetyIssue[] {
  updateVariables(segment.words, variables, cwd, home);
  const issues: SafetyIssue[] = [];

  for (const redirect of segment.redirects) {
    if (!redirect.target || ![">", ">>", ">|", "&>", "&>>"].includes(redirect.operator)) continue;
    issues.push(...pathIssues([redirect.target], "mutate", cwd, home, variables));
  }

  const info = executableInfo(segment.words);
  if (!info) return issues;
  const { executable, args, elevated } = info;

  issues.push(...classifyMutationTargets(executable, args, cwd, home, variables));
  if (executable === "git") issues.push(...classifyGit(args));
  issues.push(...classifyPackageManager(executable, args, elevated));
  issues.push(...classifySystemOperation(executable, args));
  issues.push(...classifyRemoteOperation(executable, args));

  if (CONTENT_READERS.has(executable) && !METADATA_READERS.has(executable)) {
    issues.push(...pathIssues(contentPathCandidates(args), "read", cwd, home, variables));
  }

  if (executable === "xargs") {
    const nested = operands(args);
    if (nested.length) issues.push(...classifySegment({ words: nested, redirects: [] }, cwd, home, variables, depth));
  }
  if (depth < 4 && SHELLS.has(executable)) {
    const commandIndex = args.findIndex((argument) => argument === "-c" || argument === "--command");
    if (commandIndex >= 0 && args[commandIndex + 1]) {
      issues.push(...classifyBashInternal(args[commandIndex + 1]!, cwd, home, depth + 1));
    }
  }
  if (depth < 4 && executable === "eval" && args.length) {
    issues.push(...classifyBashInternal(args.join(" "), cwd, home, depth + 1));
  }
  return issues;
}

function deduplicate(issues: SafetyIssue[]): SafetyIssue[] {
  const seen = new Set<string>();
  return issues.filter((candidate) => {
    const key = `${candidate.category}\0${candidate.target ?? ""}\0${candidate.effect}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function classifyBashInternal(rawCommand: string, cwd: string, home: string, depth: number): SafetyIssue[] {
  const heredoc = stripHereDocs(rawCommand);
  const segments = shellSegments(lexShell(heredoc.command));
  const variables = new Map<string, string>([["HOME", home], ["PWD", cwd]]);
  const issues: SafetyIssue[] = [];

  for (const segment of segments) {
    issues.push(...classifySegment(segment, cwd, home, variables, depth));
  }

  for (let index = 0; index + 1 < segments.length; index += 1) {
    if (segments[index]!.operatorAfter !== "|") continue;
    const left = executableInfo(segments[index]!.words);
    const right = executableInfo(segments[index + 1]!.words);
    if (left && right && ["curl", "wget"].includes(left.executable) && SHELLS.has(right.executable)) {
      issues.push(issue(
        "downloaded code execution",
        "Downloaded content is piped directly into a shell.",
        `Would execute code produced by ${left.executable}.`,
      ));
    }
  }

  if (depth < 4) {
    for (const nested of [...heredoc.shellBodies, ...commandSubstitutions(heredoc.command)]) {
      issues.push(...classifyBashInternal(nested, cwd, home, depth + 1));
    }
  }
  return deduplicate(issues);
}

function finalize(command: string, issues: SafetyIssue[]): SafetyClassification {
  const unique = deduplicate(issues);
  return { action: unique.length ? "ask" : "allow", issues: unique, command };
}

export function classifyBash(
  rawCommand: string,
  cwd: string,
  options: ClassifierOptions = {},
): SafetyClassification {
  return finalize(rawCommand, classifyBashInternal(rawCommand, cwd, homeFor(options), 0));
}
