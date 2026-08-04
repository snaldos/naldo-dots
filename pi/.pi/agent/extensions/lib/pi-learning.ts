import { randomInt } from "node:crypto";

export type TypstFormula = {
  source: string;
  compactSource: string;
  meaning: string;
  syntax: string;
};

export type GermanSentence = {
  german: string;
  english: string;
  note: string;
};

export type BuddyConcept = {
  field: "Mathematics" | "Machine learning" | "Physics" | "Statistics" | "Neuroscience";
  title: string;
  intuition: string;
  formal: string;
};

export type AnimeRecommendation = {
  title: string;
  why: string;
};

// Curated local lines: none is attributed to an external person or source.
export const PI_QUOTES = [
  "A tensor is an array until its axes acquire meaning.",
  "A model can fit the data and still miss the question.",
  "Good notation is compression with a decoder.",
  "Every metric chooses what failure looks like.",
  "Uncertainty is information, not an apology.",
  "A clean train/test split is part of the model.",
  "The Hessian knows which way the valley bends.",
  "If the baseline wins, the experiment has already taught you something.",
  "The shortest proof is not always the shortest path to understanding.",
  "A gradient walks downhill because local information is all it has.",
  "Regularization is a prior wearing an optimization hat.",
  "Measure twice; backpropagate once.",
  "A useful abstraction hides detail, not assumptions.",
  "Reproducibility begins where lucky seeds stop.",
  "A matrix changes coordinates; a good explanation changes perspective.",
  "The loss is a number, but the failure mode is a story.",
] as const;

export const GERMAN_SENTENCES: readonly GermanSentence[] = [
  {
    german: "Übung macht den Meister.",
    english: "Practice makes perfect.",
    note: "Literally: practice makes the master. German nouns such as `Meister` are capitalized.",
  },
  {
    german: "Der Beweis beginnt mit einer klaren Annahme.",
    english: "The proof begins with a clear assumption.",
    note: "The preposition `mit` takes the dative case: `mit einer Annahme`.",
  },
  {
    german: "Das Modell lernt aus den Daten.",
    english: "The model learns from the data.",
    note: "The preposition `aus` takes the dative; plural `die Daten` becomes `den Daten`.",
  },
  {
    german: "Wir prüfen zuerst die einfachste Erklärung.",
    english: "We test the simplest explanation first.",
    note: "The direct object is accusative: `die einfachste Erklärung`.",
  },
  {
    german: "Ein kleiner Schritt kann viel verändern.",
    english: "A small step can change a lot.",
    note: "With a modal verb, the lexical verb moves to the end: `kann ... verändern`.",
  },
  {
    german: "Die Unsicherheit gehört zum Ergebnis.",
    english: "Uncertainty is part of the result.",
    note: "`zum` contracts `zu dem`; the verb `gehören zu` means to be part of.",
  },
  {
    german: "Gute Fragen führen zu besseren Experimenten.",
    english: "Good questions lead to better experiments.",
    note: "`zu` takes the dative, here plural: `zu besseren Experimenten`.",
  },
  {
    german: "Ich lerne jeden Tag etwas Neues.",
    english: "I learn something new every day.",
    note: "`Neues` is a nominalized adjective, so it is capitalized.",
  },
  {
    german: "Der Gradient zeigt in die steilste Richtung.",
    english: "The gradient points in the steepest direction.",
    note: "Direction after `in` uses the accusative: `in die Richtung`.",
  },
  {
    german: "Ohne Vergleich ist ein Ergebnis schwer einzuordnen.",
    english: "Without comparison, a result is difficult to interpret.",
    note: "The infinitive with `zu` stays together here: `einzuordnen`.",
  },
  {
    german: "Manchmal ist das einfachste Modell das beste.",
    english: "Sometimes the simplest model is the best.",
    note: "The finite verb remains second even when `Manchmal` occupies the first position.",
  },
  {
    german: "Die Matrix hat drei Zeilen und zwei Spalten.",
    english: "The matrix has three rows and two columns.",
    note: "`Zeile` means row and `Spalte` means column in linear algebra and tables.",
  },
  {
    german: "Bevor wir optimieren, definieren wir das Ziel.",
    english: "Before we optimize, we define the objective.",
    note: "`Bevor` sends the subordinate-clause verb to the end: `wir optimieren`.",
  },
  {
    german: "Was bedeutet diese Variable?",
    english: "What does this variable mean?",
    note: "German asks this directly with `bedeuten`; it needs no auxiliary like English `does`.",
  },
  {
    german: "Können Sie den letzten Schritt erklären?",
    english: "Can you explain the last step?",
    note: "`Sie` is the formal you; `erklären` moves to the end after the modal verb.",
  },
  {
    german: "Ich bin mir noch nicht sicher.",
    english: "I am not sure yet.",
    note: "The idiom uses the dative reflexive pronoun `mir`.",
  },
  {
    german: "Aus Fehlern entstehen oft gute Fragen.",
    english: "Good questions often arise from mistakes.",
    note: "Starting with `Aus Fehlern` keeps the verb second and places the subject after it.",
  },
  {
    german: "Die Vorlesung beginnt um zehn Uhr.",
    english: "The lecture begins at ten o'clock.",
    note: "Clock times use `um`; `Uhr` is written once after the number.",
  },
] as const;

export const TYPST_FORMULAS: readonly TypstFormula[] = [
  {
    source: "$nabla_theta cal(L)(theta) = 0$",
    compactSource: "$nabla_theta L(theta) = 0$",
    meaning: "A differentiable optimum has zero gradient with respect to theta.",
    syntax: "Use `nabla_theta` for a subscripted gradient and `cal(L)` for a calligraphic loss.",
  },
  {
    source: "$x_(t+1) = x_t - eta nabla f(x_t)$",
    compactSource: "$x_(t+1) = x_t - eta nabla f(x_t)$",
    meaning: "One gradient-descent update with learning rate eta.",
    syntax: "Parentheses group a multi-character subscript: `x_(t+1)`.",
  },
  {
    source: "$theta^* = op(\"argmin\")_theta cal(L)(theta)$",
    compactSource: "$theta^* = op(\"argmin\")_theta L(theta)$",
    meaning: "Theta star minimizes the objective over theta.",
    syntax: "Named operators use `op(\"argmin\")`; `^*` adds a superscript.",
  },
  {
    source: "$p(y|x) = (p(x|y) p(y)) / p(x)$",
    compactSource: "$p(y|x) = (p(x|y) p(y)) / p(x)$",
    meaning: "Bayes' rule relates posterior, likelihood, prior, and evidence.",
    syntax: "Fractions use `/`; parentheses control the numerator and denominator.",
  },
  {
    source: "$integral_a^b f(x) dif x$",
    compactSource: "$integral_a^b f(x) dif x$",
    meaning: "The definite integral of f from a to b.",
    syntax: "Typst uses `integral` and the differential symbol `dif x`.",
  },
  {
    source: "$mat(a, b; c, d) mat(x; y) = mat(a x + b y; c x + d y)$",
    compactSource: "$mat(a, b; c, d) mat(x; y)$",
    meaning: "A two-by-two matrix acting on a two-dimensional column vector.",
    syntax: "Commas separate columns and semicolons separate rows inside `mat(...)`.",
  },
  {
    source: "$E[X] = sum_x x p(x)$",
    compactSource: "$E[X] = sum_x x p(x)$",
    meaning: "The expectation of a discrete random variable.",
    syntax: "Square brackets are literal; `sum_x` places x below the summation sign.",
  },
  {
    source: "$op(\"Var\")(X) = E[(X - E[X])^2]$",
    compactSource: "$op(\"Var\")(X) = E[(X - E[X])^2]$",
    meaning: "Variance is expected squared deviation from the mean.",
    syntax: "Use `op(\"Var\")` for a custom upright operator and `^2` for a power.",
  },
  {
    source: "$norm(x)_2 = sqrt(sum_(i=1)^n x_i^2)$",
    compactSource: "$norm(x)_2 = sqrt(sum_i x_i^2)$",
    meaning: "The Euclidean norm of an n-dimensional vector.",
    syntax: "Use `norm(x)`, `sqrt(...)`, and `sum_(i=1)^n` for bounded sums.",
  },
  {
    source: "$op(\"softmax\")(z)_i = e^(z_i) / sum_j e^(z_j)$",
    compactSource: "$op(\"softmax\")(z)_i = e^(z_i) / sum_j e^(z_j)$",
    meaning: "Softmax converts logits into normalized positive scores.",
    syntax: "Custom multi-letter operators need `op(...)`; group exponents with parentheses.",
  },
  {
    source: "$cal(L) = - sum_(i=1)^n y_i log hat(y)_i$",
    compactSource: "$L = - sum_i y_i log hat(y)_i$",
    meaning: "Multiclass cross-entropy for one-hot targets.",
    syntax: "Typst recognizes `log`; `hat(y)_i` combines an accent and a subscript.",
  },
  {
    source: "$W in RR^(m times n), x in RR^n, W x in RR^m$",
    compactSource: "$W in RR^(m times n), x in RR^n$",
    meaning: "A shape check for a matrix-vector product.",
    syntax: "Use `in`, `RR`, and `times`; group a matrix dimension as `^(m times n)`.",
  },
  {
    source: "$partial f / partial x_i$",
    compactSource: "$partial f / partial x_i$",
    meaning: "The partial derivative of f with respect to coordinate i.",
    syntax: "Partial derivatives use the native `partial` symbol on both sides of `/`.",
  },
  {
    source: "$A = U Sigma V^T$",
    compactSource: "$A = U Sigma V^T$",
    meaning: "A singular-value decomposition.",
    syntax: "Greek symbols are written by name, such as `Sigma`; transpose is `^T`.",
  },
  {
    source: "$f(x + h) approx f(x) + h f'(x)$",
    compactSource: "$f(x+h) approx f(x) + h f'(x)$",
    meaning: "The first-order Taylor approximation near x.",
    syntax: "Use `approx` for the approximation symbol and `'` for a derivative mark.",
  },
  {
    source: "$dif y / dif x = (dif y / dif u) (dif u / dif x)$",
    compactSource: "$dif y / dif x = (dif y / dif u) (dif u / dif x)$",
    meaning: "The scalar chain rule through an intermediate variable u.",
    syntax: "Ordinary differentials use `dif`; adjacent parenthesized terms multiply.",
  },
  {
    source: "$x dot y = sum_(i=1)^n x_i y_i$",
    compactSource: "$x dot y = sum_i x_i y_i$",
    meaning: "The dot product as a sum of coordinatewise products.",
    syntax: "Write the centered dot as `dot` and use bounded sum syntax when needed.",
  },
  {
    source: "$op(\"ReLU\")(z) = max(0, z)$",
    compactSource: "$op(\"ReLU\")(z) = max(0, z)$",
    meaning: "The rectified linear activation.",
    syntax: "Custom names use `op(...)`; `max` is a built-in mathematical operator.",
  },
] as const;

export const BUDDY_CONCEPTS: readonly BuddyConcept[] = [
  {
    field: "Mathematics",
    title: "Fundamental theorem of calculus",
    intuition: "Accumulation and instantaneous change undo one another.",
    formal: "If f is continuous on [a, b] and F(x) = integral_a^x f(t) dif t, then F'(x) = f(x).",
  },
  {
    field: "Mathematics",
    title: "Spectral theorem",
    intuition: "A real symmetric matrix stretches space along mutually perpendicular directions.",
    formal: "For A = A^T in RR^(n times n), there is an orthogonal Q and real diagonal Lambda with A = Q Lambda Q^T.",
  },
  {
    field: "Mathematics",
    title: "Banach fixed-point theorem",
    intuition: "A map that always pulls points closer has one destination, and repeated application finds it.",
    formal: "A contraction on a nonempty complete metric space has a unique fixed point; its iterates converge to that point.",
  },
  {
    field: "Statistics",
    title: "Law of large numbers",
    intuition: "Independent averaging suppresses sample noise and reveals the population mean.",
    formal: "For iid variables with finite mean mu, the sample mean converges in probability to mu.",
  },
  {
    field: "Statistics",
    title: "Central limit theorem",
    intuition: "Many small independent fluctuations produce an approximately Gaussian aggregate.",
    formal: "For iid variables with finite nonzero variance, the centered, normalized sample mean converges in distribution to N(0, 1).",
  },
  {
    field: "Statistics",
    title: "Bias–variance decomposition",
    intuition: "Squared prediction error separates systematic miss, sensitivity to data, and irreducible noise.",
    formal: "Under squared loss, expected test error decomposes into bias squared + variance + noise, pointwise in the input.",
  },
  {
    field: "Machine learning",
    title: "Data-processing inequality",
    intuition: "Post-processing cannot create information about a hidden variable that the input did not contain.",
    formal: "For a Markov chain X -> Y -> Z, mutual information satisfies I(X; Z) <= I(X; Y).",
  },
  {
    field: "Machine learning",
    title: "Bellman optimality principle",
    intuition: "An optimal plan remains optimal after its first action, relative to the state that action reaches.",
    formal: "For a discounted MDP, V^*(s) = max_a E[r + gamma V^*(S') | s, a].",
  },
  {
    field: "Machine learning",
    title: "Universal approximation theorem",
    intuition: "A sufficiently wide neural network can approximate a broad class of functions, but the theorem does not promise easy learning or generalization.",
    formal: "Under suitable nonpolynomial activations, one-hidden-layer networks are dense in common spaces of continuous functions on compact domains.",
  },
  {
    field: "Physics",
    title: "Noether's theorem",
    intuition: "Every continuous symmetry of the action carries a conserved quantity.",
    formal: "Time-translation symmetry yields energy conservation; spatial-translation symmetry yields momentum conservation, under the theorem's variational assumptions.",
  },
  {
    field: "Physics",
    title: "Nyquist–Shannon sampling theorem",
    intuition: "To reconstruct the fastest oscillation, sample more than twice per cycle.",
    formal: "A signal band-limited below B hertz is determined by uniform samples taken at a rate greater than 2B, under ideal sampling assumptions.",
  },
  {
    field: "Physics",
    title: "Heisenberg uncertainty relation",
    intuition: "Quantum position and momentum do not admit arbitrarily sharp simultaneous distributions.",
    formal: "Their standard deviations obey sigma_x sigma_p >= hbar / 2 for states where both variances are defined.",
  },
  {
    field: "Neuroscience",
    title: "Hebbian plasticity",
    intuition: "Coordinated pre- and postsynaptic activity can strengthen a connection.",
    formal: "A basic rate model writes Delta w proportional to x y; biological rules add timing, normalization, saturation, and other constraints.",
  },
] as const;

export const ANIME_RECOMMENDATIONS: readonly AnimeRecommendation[] = [
  { title: "Frieren: Beyond Journey's End", why: "Reflective fantasy about memory, time, learning, and relationships after the heroic quest is already over." },
  { title: "Mob Psycho 100", why: "Inventive animation wrapped around a warm story of emotional maturity, restraint, and self-worth." },
  { title: "Steins;Gate", why: "A character-driven time-travel thriller that rewards patience with tightly connected consequences." },
  { title: "Fullmetal Alchemist: Brotherhood", why: "A complete adventure with scientific ambition, political conflict, ethics, and a strong ensemble." },
  { title: "Cowboy Bebop", why: "A stylish episodic space western with jazz, melancholy, and characters haunted by unfinished histories." },
  { title: "Vinland Saga", why: "Historical drama that develops from revenge toward a serious examination of violence and purpose." },
  { title: "Violet Evergarden", why: "Visually meticulous, episodic stories about language, grief, empathy, and learning to communicate emotion." },
  { title: "Psycho-Pass", why: "A cyberpunk crime story about prediction, surveillance, moral agency, and automated judgment." },
  { title: "Planetes", why: "Grounded near-future science fiction about orbital-debris workers, institutions, ambition, and ordinary life in space." },
  { title: "The Apothecary Diaries", why: "Palace mysteries led by a sharply observant protagonist who reasons from medicine, incentives, and small clues." },
  { title: "Mushishi", why: "Quiet, self-contained supernatural stories with an ecological sensibility and room to think." },
  { title: "Neon Genesis Evangelion", why: "Psychological mecha drama about connection, avoidance, identity, and the burden placed on young people." },
] as const;

function choose<T>(items: readonly T[], avoid?: T): T {
  if (items.length === 0) throw new Error("Cannot choose from an empty collection");
  if (items.length === 1) return items[0]!;
  let selected = items[randomInt(items.length)]!;
  while (selected === avoid) selected = items[randomInt(items.length)]!;
  return selected;
}

export function randomPiQuote(avoid?: string): string {
  return choose(PI_QUOTES, avoid as (typeof PI_QUOTES)[number] | undefined);
}

export function randomTypstFormula(avoid?: TypstFormula): TypstFormula {
  return choose(TYPST_FORMULAS, avoid);
}

export function randomHeaderTypstFormula(avoid?: TypstFormula): TypstFormula {
  const headerSafe = TYPST_FORMULAS.filter((entry) => entry.compactSource.length <= 32);
  return choose(headerSafe, avoid);
}

export function randomGermanSentence(avoid?: GermanSentence): GermanSentence {
  return choose(GERMAN_SENTENCES, avoid);
}

export function randomBuddyConcept(avoid?: BuddyConcept): BuddyConcept {
  return choose(BUDDY_CONCEPTS, avoid);
}

export function randomAnimeRecommendation(avoid?: AnimeRecommendation): AnimeRecommendation {
  return choose(ANIME_RECOMMENDATIONS, avoid);
}

export function randomRockPaperScissors(): "rock" | "paper" | "scissors" {
  return choose(["rock", "paper", "scissors"] as const);
}
