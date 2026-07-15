import type { ExtensionCommandContext, Theme } from "@earendil-works/pi-coding-agent";
import { matchesKey, type Component, type TUI } from "@earendil-works/pi-tui";
import { randomInt } from "node:crypto";
import { showAboveEditorModal } from "./above-editor-modal.ts";
import {
  randomAnimeRecommendation,
  randomBuddyConcept,
  randomGermanSentence,
  randomPiQuote,
  randomRockPaperScissors,
  randomTypstFormula,
  type AnimeRecommendation,
  type BuddyConcept,
  type GermanSentence,
  type TypstFormula,
} from "./pi-learning.ts";
import { piMascot, PI_MASCOT_WIDTH } from "./pi-mascot.ts";
import { centerLines, frameBottom, frameRow, frameTop, padAnsi, wrapPlain } from "./ui-kit.ts";

export const PI_BUDDY_MODES = ["german", "typst", "concept", "quote", "rps", "anime"] as const;
export type PiBuddyMode = (typeof PI_BUDDY_MODES)[number];

type PiBuddyRequest = PiBuddyMode | "random";
type RpsChoice = "rock" | "paper" | "scissors";

let previousRandomMode: PiBuddyMode | undefined;

function randomMode(avoid?: PiBuddyMode): PiBuddyMode {
  if (PI_BUDDY_MODES.length === 1) return PI_BUDDY_MODES[0]!;
  let mode = PI_BUDDY_MODES[randomInt(PI_BUDDY_MODES.length)]!;
  while (mode === avoid) mode = PI_BUDDY_MODES[randomInt(PI_BUDDY_MODES.length)]!;
  return mode;
}

function outcome(user: RpsChoice, pi: RpsChoice): "You win" | "Pi wins" | "Draw" {
  if (user === pi) return "Draw";
  if (
    (user === "rock" && pi === "scissors") ||
    (user === "paper" && pi === "rock") ||
    (user === "scissors" && pi === "paper")
  ) return "You win";
  return "Pi wins";
}

class PiBuddyCard implements Component {
  private readonly request: PiBuddyRequest;
  private readonly tui: TUI;
  private readonly theme: Theme;
  private readonly done: (value: void) => void;
  private mode: PiBuddyMode = "quote";
  private german?: GermanSentence;
  private formula?: TypstFormula;
  private concept?: BuddyConcept;
  private quote?: string;
  private anime?: AnimeRecommendation;
  private userChoice?: RpsChoice;
  private piChoice?: RpsChoice;

  constructor(request: PiBuddyRequest, tui: TUI, theme: Theme, done: (value: void) => void) {
    this.request = request;
    this.tui = tui;
    this.theme = theme;
    this.done = done;
    this.nextFeature();
  }

  render(width: number): string[] {
    const cardWidth = Math.max(4, Math.min(92, width));
    const innerWidth = Math.max(1, cardWidth - 4);
    const useMascot = cardWidth >= 58;
    const leftWidth = useMascot ? 17 : 0;
    const dividerWidth = useMascot ? 3 : 0;
    const textWidth = Math.max(1, innerWidth - leftWidth - dividerWidth);
    const content = this.contentLines(textWidth);
    const body = useMascot
      ? this.twoColumnBody(content, leftWidth, textWidth)
      : content.map((line) => frameRow(this.theme, cardWidth, line));
    return centerLines([
      frameTop(this.theme, cardWidth, `π BUDDY · ${this.mode.toUpperCase()}`, "accent"),
      ...body,
      frameBottom(this.theme, cardWidth, this.controls()),
    ], width);
  }

  handleInput(data: string): void {
    if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
      this.done(undefined);
      return;
    }
    if (this.mode === "rps" && /^[rps]$/i.test(data)) {
      this.userChoice = data.toLowerCase() === "r" ? "rock" : data.toLowerCase() === "p" ? "paper" : "scissors";
      this.piChoice = randomRockPaperScissors();
      this.tui.requestRender();
      return;
    }
    if (data.toLowerCase() === "n") {
      if (this.mode === "rps" && this.userChoice) this.resetRps();
      else this.nextFeature();
      this.tui.requestRender();
    }
  }

  invalidate(): void {}

  private nextFeature(): void {
    this.mode = this.request === "random" ? randomMode(previousRandomMode) : this.request;
    if (this.request === "random") previousRandomMode = this.mode;
    this.userChoice = undefined;
    this.piChoice = undefined;
    if (this.mode === "german") this.german = randomGermanSentence(this.german);
    else if (this.mode === "typst") this.formula = randomTypstFormula(this.formula);
    else if (this.mode === "concept") this.concept = randomBuddyConcept(this.concept);
    else if (this.mode === "quote") this.quote = randomPiQuote(this.quote);
    else if (this.mode === "anime") this.anime = randomAnimeRecommendation(this.anime);
  }

  private resetRps(): void {
    this.userChoice = undefined;
    this.piChoice = undefined;
  }

  private controls(): string {
    if (this.mode === "rps" && !this.userChoice) return "r rock · p paper · s scissors · Esc close";
    if (this.mode === "rps") return "n another round · Esc close";
    return this.request === "random" ? "n surprise me · Esc close" : "n another · Esc close";
  }

  private twoColumnBody(content: string[], leftWidth: number, textWidth: number): string[] {
    const mascot = piMascot(this.theme);
    const rowCount = Math.max(content.length, mascot.length + 2);
    const mascotOffset = Math.floor((rowCount - mascot.length) / 2);
    return Array.from({ length: rowCount }, (_, index) => {
      const mascotLine = index >= mascotOffset && index < mascotOffset + mascot.length
        ? mascot[index - mascotOffset]!
        : "";
      const centeredMascot = `${" ".repeat(Math.max(0, Math.floor((leftWidth - PI_MASCOT_WIDTH) / 2)))}${mascotLine}`;
      const line = `${padAnsi(centeredMascot, leftWidth)}${this.theme.fg("border", " │ ")}${padAnsi(content[index] ?? "", textWidth)}`;
      return frameRow(this.theme, leftWidth + textWidth + 7, line);
    });
  }

  private contentLines(width: number): string[] {
    const heading = (text: string, color: "accent" | "success" | "warning" = "accent") =>
      this.theme.fg(color, this.theme.bold(text));
    const styledWrap = (text: string, color: "text" | "muted" | "success" = "text", bold = false) =>
      wrapPlain(text, width).map((line) => this.theme.fg(color, bold ? this.theme.bold(line) : line));

    if (this.mode === "german") {
      const item = this.german ?? randomGermanSentence();
      return [
        heading("DEUTSCH"),
        ...styledWrap(item.german, "text", true),
        "",
        heading("ENGLISH", "warning"),
        ...styledWrap(item.english),
        "",
        heading("LANGUAGE NOTE", "success"),
        ...styledWrap(item.note, "muted"),
      ];
    }
    if (this.mode === "typst") {
      const item = this.formula ?? randomTypstFormula();
      return [
        heading("VALID TYPST MATH", "success"),
        ...styledWrap(item.source, "success", true),
        "",
        heading("MEANING"),
        ...styledWrap(item.meaning),
        "",
        heading("SYNTAX", "warning"),
        ...styledWrap(item.syntax, "muted"),
      ];
    }
    if (this.mode === "concept") {
      const item = this.concept ?? randomBuddyConcept();
      return [
        heading(item.field.toUpperCase(), "warning"),
        ...styledWrap(item.title, "text", true),
        "",
        heading("INTUITION"),
        ...styledWrap(item.intuition),
        "",
        heading("FORMAL STATEMENT", "success"),
        ...styledWrap(item.formal, "muted"),
      ];
    }
    if (this.mode === "anime") {
      const item = this.anime ?? randomAnimeRecommendation();
      return [
        heading("ANIME PICK", "warning"),
        ...styledWrap(item.title, "text", true),
        "",
        heading("WHY PI PICKED IT"),
        ...styledWrap(item.why),
        "",
        ...styledWrap("A curated suggestion; streaming availability is not checked.", "muted"),
      ];
    }
    if (this.mode === "rps") {
      if (!this.userChoice || !this.piChoice) {
        return [
          heading("ROCK · PAPER · SCISSORS", "warning"),
          "",
          ...styledWrap("Choose without peeking. Pi will reveal its move after yours.", "text", true),
          "",
          ...styledWrap("Press r, p, or s.", "accent"),
        ];
      }
      const result = outcome(this.userChoice, this.piChoice);
      const tone = result === "You win" ? "success" : result === "Pi wins" ? "warning" : "accent";
      return [
        heading("ROCK · PAPER · SCISSORS", "warning"),
        "",
        ...styledWrap(`You chose ${this.userChoice}.`, "text"),
        ...styledWrap(`Pi chose ${this.piChoice}.`, "text"),
        "",
        this.theme.fg(tone, this.theme.bold(`${result}!`)),
      ];
    }
    const item = this.quote ?? randomPiQuote();
    return [
      heading("A THOUGHT FROM PI", "warning"),
      "",
      ...styledWrap(`“${item}”`, "text", true),
      "",
      ...styledWrap("A curated, unattributed Pi line—not a historical quotation.", "muted"),
    ];
  }
}

export async function showPiBuddy(ctx: ExtensionCommandContext, request: PiBuddyRequest): Promise<void> {
  await showAboveEditorModal(
    ctx,
    "naldo:pi-buddy-card",
    (tui, theme, done) => new PiBuddyCard(request, tui, theme, done),
  );
}

export function randomPiBuddyText(request: PiBuddyRequest): string {
  const mode = request === "random" ? randomMode(previousRandomMode) : request;
  if (request === "random") previousRandomMode = mode;
  if (mode === "german") {
    const item = randomGermanSentence();
    return `DEUTSCH: ${item.german}\nENGLISH: ${item.english}\n\n${item.note}`;
  }
  if (mode === "typst") {
    const item = randomTypstFormula();
    return `${item.source}\n\n${item.meaning}\n\nTypst syntax: ${item.syntax}`;
  }
  if (mode === "concept") {
    const item = randomBuddyConcept();
    return `${item.field} · ${item.title}\n\n${item.intuition}\n\n${item.formal}`;
  }
  if (mode === "anime") {
    const item = randomAnimeRecommendation();
    return `Anime pick: ${item.title}\n\n${item.why}`;
  }
  if (mode === "rps") return "Rock, paper, scissors: use /pi-buddy rps in the TUI so Pi can play interactively.";
  return `“${randomPiQuote()}”\n\nA curated, unattributed Pi line.`;
}

export function isPiBuddyMode(value: string): value is PiBuddyMode {
  return (PI_BUDDY_MODES as readonly string[]).includes(value);
}
