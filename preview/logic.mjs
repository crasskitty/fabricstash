// Shelf rules copied from FabricStash/Logic so this preview matches the iOS app.
// Stored length is yards. Stored width is inches. 1 yard = 0.9144 m. GSM = oz/yd² × 33.906.

export const METERS_PER_YARD = 0.9144;
export const CENTIMETERS_PER_INCH = 2.54;
export const INCHES_PER_YARD = 36;
export const GSM_PER_OZ = 33.906;
export const FREE_LIMIT = 25;
export const ENOUGH_TOLERANCE = 0.000001;
export const YARDAGE_TOLERANCE = 0.0000001;
export const STRETCH_MARK_INCHES = 4;
export const STRETCH_MARK_CM = 10;
export const MEANINGFUL_STRETCH = 15;

const SAMPLE_NOTE =
  "Fictional cloth for trying FabricStash. It is not from your shelf. Delete it anytime.";

export function canAddFabric(currentCount, isUnlocked) {
  if (isUnlocked) return true;
  return currentCount < FREE_LIMIT;
}

export function metersFromYards(yards) {
  return yards * METERS_PER_YARD;
}

export function yardsFromMeters(meters) {
  return meters / METERS_PER_YARD;
}

export function centimetersFromInches(inches) {
  return inches * CENTIMETERS_PER_INCH;
}

export function inchesFromCentimeters(centimeters) {
  return centimeters / CENTIMETERS_PER_INCH;
}

export function gsmFromOz(ounces) {
  return ounces * GSM_PER_OZ;
}

export function ozFromGsm(gsm) {
  return gsm / GSM_PER_OZ;
}

export function numberString(value, fractionDigits = 2) {
  if (!Number.isFinite(value)) return "";
  const negative = value < 0;
  const absolute = Math.abs(value);
  const fixed = absolute.toFixed(fractionDigits);
  const trimmed = fixed.replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
  return negative ? `-${trimmed}` : trimmed;
}

export function posixNumber(value) {
  return numberString(value, 4);
}

function truncatingRemainder(value, divisor) {
  return value - Math.trunc(value / divisor) * divisor;
}

function gcd(a, b) {
  let x = Math.abs(a);
  let y = Math.abs(b);
  while (y !== 0) {
    const remainder = x % y;
    x = y;
    y = remainder;
  }
  return Math.max(x, 1);
}

function parseFractionToken(token) {
  const bits = token.split("/");
  if (bits.length !== 2) return null;
  const numerator = Number(bits[0]);
  const denominator = Number(bits[1]);
  if (!Number.isFinite(numerator) || !Number.isFinite(denominator)) return null;
  if (denominator === 0 || numerator < 0 || denominator <= 0) return null;
  if (bits[0].trim() === "" || bits[1].trim() === "") return null;
  return numerator / denominator;
}

export function fractionValue(text) {
  const trimmed = text.trim();
  if (!trimmed) return null;
  if (!trimmed.includes("/")) {
    const value = Number(trimmed);
    return Number.isFinite(value) ? value : null;
  }
  const parts = trimmed.replaceAll("-", " ").split(/\s+/).filter(Boolean);
  if (parts.length === 1) return parseFractionToken(parts[0]);
  if (parts.length === 2) {
    const whole = Number(parts[0]);
    const part = parseFractionToken(parts[1]);
    if (Number.isFinite(whole) && whole >= 0 && part != null) return whole + part;
  }
  return null;
}

export function fractionString(value) {
  if (!Number.isFinite(value)) return "";
  const negative = value < 0;
  const absolute = Math.abs(value);
  const whole = Math.floor(absolute + 1e-10);
  const remainder = absolute - whole;
  const sixteenths = Math.round(remainder * 16);
  const snapped = Math.abs(remainder * 16 - sixteenths) < 0.000001 && sixteenths >= 0 && sixteenths <= 16;
  let body;
  if (snapped) {
    if (sixteenths === 0 || sixteenths === 16) {
      body = numberString(sixteenths === 16 ? whole + 1 : whole, 0);
    } else {
      const divisor = gcd(sixteenths, 16);
      const fraction = `${sixteenths / divisor}/${16 / divisor}`;
      body = whole === 0 ? fraction : `${whole} ${fraction}`;
    }
  } else {
    body = numberString(absolute, 4);
  }
  return negative ? `-${body}` : body;
}

export function lengthText(yards, system) {
  if (system === "imperial") return fractionString(yards);
  return numberString(metersFromYards(yards), 6);
}

export function widthText(inches, system) {
  if (system === "imperial") return fractionString(inches);
  return numberString(centimetersFromInches(inches), 6);
}

export function formatLength(yards, system) {
  const unit = system === "imperial" ? "yd" : "m";
  return `${lengthText(yards, system)} ${unit}`;
}

export function formatWidth(inches, system) {
  const unit = system === "imperial" ? "in" : "cm";
  return `${widthText(inches, system)} ${unit}`;
}

function entered(text, system) {
  if (system === "imperial") return fractionValue(text);
  const value = Number(text.trim());
  return text.trim() && Number.isFinite(value) ? value : null;
}

export function yardsFromDisplay(text, system) {
  const value = entered(text, system);
  if (value == null) return null;
  return system === "imperial" ? value : yardsFromMeters(value);
}

export function inchesFromDisplay(text, system) {
  const value = entered(text, system);
  if (value == null) return null;
  return system === "imperial" ? value : inchesFromCentimeters(value);
}

export function deduct(remainingYards, amountYards) {
  if (!Number.isFinite(remainingYards) || !Number.isFinite(amountYards)) {
    return { ok: false, reason: "notANumber" };
  }
  if (!(amountYards > 0)) return { ok: false, reason: "amountMustBePositive" };
  if (amountYards > remainingYards + YARDAGE_TOLERANCE) {
    return { ok: false, reason: "wouldBeNegative", shortfall: Math.max(amountYards - remainingYards, 0) };
  }
  const next = remainingYards - amountYards;
  return { ok: true, remaining: next <= YARDAGE_TOLERANCE ? 0 : next };
}

export function restore(remainingYards, usedYards) {
  if (!Number.isFinite(remainingYards) || !Number.isFinite(usedYards)) return remainingYards;
  return remainingYards + Math.max(0, usedYards);
}

function covers(have, need) {
  return Number.isFinite(have) && have + ENOUGH_TOLERANCE >= need;
}

function matchBolt(need, piece) {
  const widthOK = covers(piece.width, need.widthInches);
  const yardsOK = covers(piece.yardage, need.yards);
  if (widthOK && yardsOK) return { piece, kind: "covers" };
  if (widthOK && piece.yardage > ENOUGH_TOLERANCE) {
    const short = need.yards - piece.yardage;
    if (short > ENOUGH_TOLERANCE) return { piece, kind: "short", shortfall: { type: "yardage", yards: short } };
  }
  if (yardsOK && piece.width > ENOUGH_TOLERANCE) {
    const short = need.widthInches - piece.width;
    if (short > ENOUGH_TOLERANCE) return { piece, kind: "short", shortfall: { type: "width", inches: short } };
  }
  return null;
}

function matchScrap(need, piece) {
  const needLength = need.yards * INCHES_PER_YARD;
  const orientations = [
    [piece.scrapWidth, piece.scrapLength],
    [piece.scrapLength, piece.scrapWidth],
  ];
  let bestShort = null;
  for (const [haveWidth, haveLength] of orientations) {
    const widthOK = covers(haveWidth, need.widthInches);
    const lengthOK = covers(haveLength, needLength);
    if (widthOK && lengthOK) return { piece, kind: "covers" };
    if (widthOK && haveLength > ENOUGH_TOLERANCE) {
      const short = needLength - haveLength;
      if (short > ENOUGH_TOLERANCE && (bestShort == null || short < bestShort)) bestShort = short;
    }
  }
  if (bestShort != null) {
    return { piece, kind: "short", shortfall: { type: "scrapEdge", inches: bestShort } };
  }
  return null;
}

function shortfallRatio(match, need) {
  const shortfall = match.shortfall;
  if (shortfall.type === "yardage") return need.yards > 0 ? shortfall.yards / need.yards : shortfall.yards;
  if (shortfall.type === "width") return need.widthInches > 0 ? shortfall.inches / need.widthInches : shortfall.inches;
  const length = need.yards * INCHES_PER_YARD;
  return length > 0 ? shortfall.inches / length : shortfall.inches;
}

export function classifyEnough(need, pieces) {
  if (!(need.yards > 0) || !(need.widthInches > 0) || !Number.isFinite(need.yards) || !Number.isFinite(need.widthInches)) {
    return { covers: [], close: [] };
  }
  const coversList = [];
  const close = [];
  for (const piece of pieces) {
    const match = piece.isScrap ? matchScrap(need, piece) : matchBolt(need, piece);
    if (!match) continue;
    if (match.kind === "covers") coversList.push(match);
    else close.push(match);
  }
  coversList.sort((a, b) => a.piece.name.localeCompare(b.piece.name, undefined, { sensitivity: "base", numeric: true }));
  close.sort((a, b) => shortfallRatio(a, need) - shortfallRatio(b, need));
  return { covers: coversList, close };
}

export function stretchPercent(stretched, marked) {
  if (!Number.isFinite(stretched) || !(marked > 0) || !Number.isFinite(marked)) return null;
  if (stretched + 0.0001 < marked) return null;
  return ((stretched - marked) / marked) * 100;
}

export function stretchKind(crosswisePercent, lengthwisePercent) {
  const crosswise = crosswisePercent >= MEANINGFUL_STRETCH;
  const lengthwise = lengthwisePercent >= MEANINGFUL_STRETCH;
  if (crosswise && lengthwise) return "fourWay";
  if (!crosswise && !lengthwise) return "none";
  return "twoWay";
}

export function combinedRecovery(crosswise, lengthwise) {
  if (crosswise === "poor" || lengthwise === "poor") return "poor";
  if (crosswise === "good" || lengthwise === "good") return "good";
  return "untested";
}

export function stretchExplanation(kind, crosswise, lengthwise) {
  if (kind === "fourWay") {
    return `It stretches both ways, so this is 4-way. Crosswise is ${numberString(crosswise)}%, lengthwise is ${numberString(lengthwise)}%.`;
  }
  if (kind === "twoWay") {
    if (crosswise >= lengthwise) return "It stretches crosswise and barely along the length, so this is 2-way.";
    return "It stretches along the length and barely crosswise, so this is 2-way.";
  }
  return "It barely moves in either direction, so record it as no stretch.";
}

function rgb(hex) {
  let cleaned = hex.trim().replace(/^#/, "");
  if (cleaned.length === 3) cleaned = cleaned.split("").map((part) => part + part).join("");
  if (!/^[0-9a-fA-F]{6}$/.test(cleaned)) return null;
  const value = Number.parseInt(cleaned, 16);
  return { r: ((value >> 16) & 255) / 255, g: ((value >> 8) & 255) / 255, b: (value & 255) / 255 };
}

function hsl(color) {
  const maxC = Math.max(color.r, color.g, color.b);
  const minC = Math.min(color.r, color.g, color.b);
  const lightness = (maxC + minC) / 2;
  const delta = maxC - minC;
  if (delta <= 0.00001) return { h: 0, s: 0, l: lightness };
  const saturation = delta / (1 - Math.abs(2 * lightness - 1));
  let hue;
  if (maxC === color.r) hue = 60 * truncatingRemainder((color.g - color.b) / delta, 6);
  else if (maxC === color.g) hue = 60 * ((color.b - color.r) / delta + 2);
  else hue = 60 * ((color.r - color.g) / delta + 4);
  if (hue < 0) hue += 360;
  return { h: hue, s: saturation, l: lightness };
}

export function colorFamily(hex) {
  const color = rgb(hex);
  if (!color) return null;
  const { h: hue, s: saturation, l: lightness } = hsl(color);
  if (lightness <= 0.1) return "black";
  if (lightness >= 0.92 && saturation <= 0.14) return "white";
  if (saturation <= 0.12) return lightness >= 0.82 ? "white" : "neutrals";
  if (hue >= 15 && hue <= 50 && lightness < 0.55 && saturation < 0.8) return "browns";
  if (hue < 15 || hue >= 345) return lightness > 0.72 ? "pinks" : "reds";
  if (hue < 45) return "oranges";
  if (hue < 75) return "yellows";
  if (hue < 170) return "greens";
  if (hue < 255) return "blues";
  if (hue < 295) return "purples";
  return "pinks";
}

export function matchesQuery(fabric, query) {
  if (query.type && fabric.type !== query.type) return false;
  if (query.stretch && fabric.stretch !== query.stretch) return false;
  if (query.minimumYards != null && fabric.yardage + 0.000001 < query.minimumYards) return false;
  if (query.location === "unassigned" && fabric.locationId) return false;
  if (query.location && query.location !== "any" && query.location !== "unassigned" && fabric.locationId !== query.location) {
    return false;
  }
  if (query.colorFamily && colorFamily(fabric.hex) !== query.colorFamily) return false;
  const needle = (query.text || "").trim().toLocaleLowerCase();
  if (!needle) return true;
  const fields = [fabric.name, fabric.fiber, fabric.source, fabric.print, fabric.colorName];
  if (fields.some((field) => field.toLocaleLowerCase().includes(needle))) return true;
  return fabric.tags.some((tag) => tag.toLocaleLowerCase().includes(needle));
}

function csvField(value) {
  const text = String(value ?? "");
  if (/[",\n\r]/.test(text)) return `"${text.replaceAll('"', '""')}"`;
  return text;
}

export function csvHeaders(system) {
  const length = system === "imperial" ? "yards" : "meters";
  const width = system === "imperial" ? "inches" : "centimeters";
  return [
    "name",
    "fiber_content",
    "structure",
    "type",
    `yardage_on_hand_${length}`,
    `width_${width}`,
    "is_scrap",
    `scrap_width_${width}`,
    `scrap_length_${width}`,
    "weight_gsm",
    "weight_oz_per_sq_yd",
    "color_name",
    "color_hex",
    "print_pattern",
    "stretch_crosswise_percent",
    "stretch_lengthwise_percent",
    "stretch",
    "recovery",
    "source",
    "price_paid",
    "currency_code",
    "prewashed",
    "care_notes",
    "tags",
    "storage_location",
    "storage_kind",
    "created_at",
    "updated_at",
    `recorded_use_${length}`,
  ];
}

export function renderCsv(fabrics, locations, uses, system) {
  const lines = [csvHeaders(system).join(",")];
  for (const fabric of fabrics) {
    const location = locations.find((item) => item.id === fabric.locationId);
    const recorded = uses.filter((use) => use.fabricId === fabric.id).reduce((sum, use) => sum + use.yards, 0);
    const length = (yards) => (system === "imperial" ? yards : metersFromYards(yards));
    const width = (inches) => (system === "imperial" ? inches : centimetersFromInches(inches));
    const columns = [
      fabric.name,
      fabric.fiber,
      fabric.structure === "knit" ? "Knit" : "Woven",
      typeTitle(fabric.type),
      posixNumber(length(fabric.yardage)),
      posixNumber(width(fabric.width)),
      fabric.isScrap ? "yes" : "no",
      fabric.isScrap ? posixNumber(width(fabric.scrapWidth)) : "",
      fabric.isScrap ? posixNumber(width(fabric.scrapLength)) : "",
      fabric.gsm == null ? "" : posixNumber(fabric.gsm),
      fabric.gsm == null ? "" : posixNumber(ozFromGsm(fabric.gsm)),
      fabric.colorName,
      fabric.hex,
      fabric.print,
      fabric.stretchCrosswise == null ? "" : posixNumber(fabric.stretchCrosswise),
      fabric.stretchLengthwise == null ? "" : posixNumber(fabric.stretchLengthwise),
      stretchTitle(fabric.stretch),
      recoveryTitle(fabric.recovery),
      fabric.source,
      fabric.price ?? "",
      fabric.price ? "USD" : "",
      fabric.prewashed ? "yes" : "no",
      fabric.care,
      fabric.tags.join("; "),
      location ? location.name : "",
      location ? location.kind.charAt(0).toUpperCase() + location.kind.slice(1) : "",
      fabric.createdAt,
      fabric.updatedAt,
      posixNumber(length(recorded)),
    ];
    lines.push(columns.map(csvField).join(","));
  }
  return `${lines.join("\n")}\n`;
}

function fabric(partial) {
  return {
    stretchCrosswise: null,
    stretchLengthwise: null,
    stretch: "none",
    recovery: "untested",
    source: "",
    price: null,
    prewashed: false,
    isScrap: false,
    scrapWidth: 0,
    scrapLength: 0,
    isSample: true,
    ...partial,
  };
}

export function sampleShelf(now = "2026-11-22T12:00:00Z") {
  const base = Date.parse(now);
  const at = (daysAgo) => new Date(base - daysAgo * 86400000).toISOString();
  const locations = [
    { id: "loc-bin", name: "Sample bin", kind: "bin", sortOrder: 0 },
    { id: "loc-shelf", name: "Sample shelf", kind: "shelf", sortOrder: 1 },
  ];
  const scrapNote = `${SAMPLE_NOTE} Matched by its 18 by 22 inch size, not as a bolt.`;
  const fabrics = [
    fabric({
      id: "sample-gingham",
      name: "Sample: Picnic Gingham",
      fiber: "100% cotton",
      structure: "woven",
      type: "quiltingCotton",
      yardage: 2.5,
      width: 44,
      gsm: 145,
      colorName: "Red",
      hex: "#B4332A",
      print: "large red gingham",
      source: "Sample Dry Goods",
      price: "12.5",
      prewashed: true,
      tags: ["sample", "cotton", "gingham"],
      care: SAMPLE_NOTE,
      createdAt: at(8),
      updatedAt: at(8),
      locationId: "loc-shelf",
    }),
    fabric({
      id: "sample-jersey",
      name: "Sample: Sea Glass Jersey",
      fiber: "95% cotton, 5% elastane",
      structure: "knit",
      type: "jersey",
      yardage: 2.25,
      width: 60,
      gsm: 180,
      colorName: "Teal",
      hex: "#2F6F6A",
      print: "solid",
      stretchCrosswise: 60,
      stretchLengthwise: 40,
      stretch: "fourWay",
      recovery: "good",
      source: "Sample Knit Co",
      price: "18",
      tags: ["sample", "jersey", "knit"],
      care: SAMPLE_NOTE,
      createdAt: at(7),
      updatedAt: at(7),
      locationId: "loc-bin",
    }),
    fabric({
      id: "sample-denim",
      name: "Sample: Studio Denim",
      fiber: "100% cotton",
      structure: "woven",
      type: "denim",
      yardage: 1.75,
      width: 58,
      gsm: 310,
      colorName: "Navy",
      hex: "#1E2A4A",
      print: "solid",
      source: "Sample Mill",
      price: "24",
      tags: ["sample", "denim"],
      care: SAMPLE_NOTE,
      createdAt: at(6),
      updatedAt: at(6),
      locationId: "loc-shelf",
    }),
    fabric({
      id: "sample-scrap",
      name: "Sample: Madder Linen Scrap",
      fiber: "100% linen",
      structure: "woven",
      type: "linen",
      yardage: 0.3,
      width: 18,
      gsm: 185,
      colorName: "Madder",
      hex: "#9C4A32",
      print: "solid",
      isScrap: true,
      scrapWidth: 18,
      scrapLength: 22,
      tags: ["sample", "scrap", "linen"],
      care: scrapNote,
      createdAt: at(5),
      updatedAt: at(5),
      locationId: "loc-bin",
    }),
    fabric({
      id: "sample-rib",
      name: "Sample: Rib Cuff",
      fiber: "98% cotton, 2% elastane",
      structure: "knit",
      type: "rib",
      yardage: 0.75,
      width: 24,
      gsm: 280,
      colorName: "Black",
      hex: "#1A1614",
      print: "solid",
      stretchCrosswise: 80,
      stretchLengthwise: 10,
      stretch: "twoWay",
      recovery: "good",
      tags: ["sample", "rib"],
      care: SAMPLE_NOTE,
      createdAt: at(4),
      updatedAt: at(4),
      locationId: "loc-bin",
    }),
    fabric({
      id: "sample-scuba",
      name: "Sample: Imaginary Scuba",
      fiber: "polyester and elastane blend",
      structure: "knit",
      type: "scuba",
      yardage: 1.5,
      width: 58,
      gsm: 310,
      colorName: "Purple",
      hex: "#5E3A6B",
      print: "solid",
      stretchCrosswise: 40,
      stretchLengthwise: 35,
      stretch: "fourWay",
      recovery: "poor",
      source: "Sample Activewear",
      price: "16",
      tags: ["sample", "scuba"],
      care: SAMPLE_NOTE,
      createdAt: at(3),
      updatedAt: at(3),
      locationId: "loc-bin",
    }),
    fabric({
      id: "sample-spandex",
      name: "Sample: Costume Spandex",
      fiber: "80% nylon, 20% elastane",
      structure: "knit",
      type: "spandexBlend",
      yardage: 1,
      width: 60,
      gsm: 200,
      colorName: "Gold",
      hex: "#C6A15B",
      print: "tiny stars",
      stretchCrosswise: 100,
      stretchLengthwise: 90,
      stretch: "fourWay",
      recovery: "good",
      source: "Sample Costume Cloth",
      price: "14",
      tags: ["sample", "spandex", "stars"],
      care: SAMPLE_NOTE,
      createdAt: at(2),
      updatedAt: at(2),
      locationId: "loc-shelf",
    }),
    fabric({
      id: "sample-flannel",
      name: "Sample: Fiction Flannel",
      fiber: "100% cotton",
      structure: "woven",
      type: "flannel",
      yardage: 4,
      width: 42,
      gsm: 170,
      colorName: "Sage",
      hex: "#8AA58B",
      print: "scattered pine trees",
      source: "Sample Flannel Works",
      price: "9.75",
      prewashed: true,
      tags: ["sample", "flannel"],
      care: SAMPLE_NOTE,
      createdAt: at(1),
      updatedAt: at(1),
      locationId: "loc-shelf",
    }),
  ];
  const projects = [
    {
      id: "proj-tote",
      name: "Sample: Practice tote",
      notes: "Fictional project. Half a yard is already marked used on the gingham.",
      createdAt: at(1),
      isSample: true,
    },
  ];
  const uses = [
    {
      id: "use-gingham-tote",
      yards: 0.5,
      note: "Sample cut for the tote body",
      fabricId: "sample-gingham",
      projectId: "proj-tote",
      createdAt: at(1),
    },
  ];
  return { fabrics, locations, projects, uses };
}

export const TYPE_TITLES = {
  jersey: "Jersey",
  rib: "Rib",
  scuba: "Scuba",
  spandexBlend: "Spandex blend",
  denim: "Denim",
  linen: "Linen",
  cotton: "Cotton",
  flannel: "Flannel",
  fleece: "Fleece",
  frenchTerry: "French terry",
  interlock: "Interlock",
  ponte: "Ponte",
  quiltingCotton: "Quilting cotton",
  rayon: "Rayon / viscose",
  satin: "Satin",
  chiffon: "Chiffon",
  twill: "Twill",
  canvas: "Canvas",
  corduroy: "Corduroy",
  wool: "Wool",
  silk: "Silk",
  lace: "Lace",
  mesh: "Mesh",
  velvet: "Velvet",
  shirting: "Shirting",
  doubleGauze: "Double gauze",
  custom: "Custom",
};

export const STRETCH_TITLES = { none: "No stretch", twoWay: "2-way", fourWay: "4-way" };
export const RECOVERY_TITLES = { untested: "Not tested", good: "Good recovery", poor: "Poor recovery" };
export const COLOR_TITLES = {
  reds: "Reds",
  oranges: "Oranges",
  yellows: "Yellows",
  greens: "Greens",
  blues: "Blues",
  purples: "Purples",
  pinks: "Pinks",
  browns: "Browns",
  neutrals: "Neutrals",
  black: "Black",
  white: "White",
};

export function typeTitle(type) {
  return TYPE_TITLES[type] || type;
}

export function stretchTitle(kind) {
  return STRETCH_TITLES[kind] || kind;
}

export function recoveryTitle(kind) {
  return RECOVERY_TITLES[kind] || kind;
}
