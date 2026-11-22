import {
  COLOR_TITLES,
  FREE_LIMIT,
  STRETCH_TITLES,
  TYPE_TITLES,
  canAddFabric,
  classifyEnough,
  combinedRecovery,
  deduct,
  formatLength,
  formatWidth,
  inchesFromDisplay,
  lengthText,
  matchesQuery,
  ozFromGsm,
  recoveryTitle,
  renderCsv,
  restore,
  sampleShelf,
  stretchExplanation,
  stretchKind,
  fractionValue,
  stretchPercent,
  stretchTitle,
  typeTitle,
  widthText,
  yardsFromDisplay,
} from "./logic.mjs";

const STORAGE_KEY = "fabricstash-preview-v1";

const state = load();

const app = document.querySelector("#app");

function load() {
  const blank = {
    system: "imperial",
    screen: "shelf",
    selectedId: null,
    menuOpen: false,
    queryText: "",
    filters: { type: "", stretch: "", colorFamily: "", minimum: "", location: "any" },
    fabrics: [],
    locations: [],
    projects: [],
    uses: [],
    editor: null,
    stretch: null,
    deduct: null,
    enoughLength: "",
    enoughWidth: "",
    notice: "",
    locationName: "",
  };
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null");
    if (!saved || !Array.isArray(saved.fabrics)) return blank;
    return { ...blank, ...saved, screen: "shelf", menuOpen: false, notice: "", editor: null, stretch: null, deduct: null };
  } catch {
    return blank;
  }
}

function save() {
  const { screen, menuOpen, notice, editor, stretch, deduct, ...rest } = state;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(rest));
  } catch {
    state.notice = "This browser did not keep the shelf. The preview still works until you reload.";
  }
}

function uid(prefix) {
  return `${prefix}-${crypto.randomUUID()}`;
}

function esc(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function fabricById(id) {
  return state.fabrics.find((fabric) => fabric.id === id) || null;
}

function locationName(id) {
  return state.locations.find((location) => location.id === id)?.name || "No location";
}

function query() {
  const minimumText = state.filters.minimum.trim();
  let minimumYards = null;
  if (minimumText) {
    const yards = yardsFromDisplay(minimumText, state.system);
    if (yards != null && yards >= 0) minimumYards = yards;
  }
  return {
    text: state.queryText,
    type: state.filters.type || null,
    stretch: state.filters.stretch || null,
    colorFamily: state.filters.colorFamily || null,
    minimumYards,
    location: state.filters.location || "any",
  };
}

function shownFabrics() {
  return state.fabrics.filter((fabric) => matchesQuery(fabric, query()));
}

function filtering() {
  const current = query();
  return Boolean(current.text.trim() || current.type || current.stretch || current.colorFamily || current.minimumYards != null || current.location !== "any");
}

function wide() {
  if (typeof window.matchMedia === "function") return window.matchMedia("(min-width: 900px)").matches;
  return window.innerWidth >= 900;
}

function detailVisible() {
  return wide() && state.screen === "detail" && state.selectedId && fabricById(state.selectedId);
}

function columnCount() {
  const page = Math.min(window.innerWidth, 1100);
  const width = detailVisible() ? page / 2 : page;
  if (width >= 900) return 4;
  if (width >= 640) return 3;
  return 2;
}

function amountLine(fabric) {
  if (fabric.isScrap) return `${formatWidth(fabric.scrapWidth, state.system)} × ${formatWidth(fabric.scrapLength, state.system)}`;
  return formatLength(fabric.yardage, state.system);
}

function countLine(shown) {
  const visible = shown.length === state.fabrics.length
    ? `${state.fabrics.length} ${state.fabrics.length === 1 ? "fabric" : "fabrics"}`
    : `${shown.length} of ${state.fabrics.length}`;
  return `${visible} · ${state.fabrics.length} of ${FREE_LIMIT} on the free shelf`;
}

function options(map, current, anyLabel) {
  const head = `<option value="">${esc(anyLabel)}</option>`;
  const rest = Object.entries(map).map(([value, label]) => {
    const selected = current === value ? " selected" : "";
    return `<option value="${esc(value)}"${selected}>${esc(label)}</option>`;
  }).join("");
  return head + rest;
}

function render() {
  const focus = captureFocus();
  app.innerHTML = shell(body());
  restoreFocus(focus);
}

function captureFocus() {
  const el = document.activeElement;
  if (!el || !el.id || !app.contains(el)) return null;
  return { id: el.id, start: el.selectionStart, end: el.selectionEnd };
}

function restoreFocus(focus) {
  if (!focus) return;
  const next = document.getElementById(focus.id);
  if (!next) return;
  next.focus();
  if (typeof focus.start === "number" && next.setSelectionRange) {
    try { next.setSelectionRange(focus.start, focus.end); } catch { /* number inputs */ }
  }
}

function shell(content) {
  return `
    <div class="top">
      <div class="menu">
        <button class="icon-button" type="button" data-action="toggle-menu" aria-expanded="${state.menuOpen}" aria-label="More">More</button>
        ${state.menuOpen ? menuPanel() : ""}
      </div>
      <h1>FabricStash</h1>
      <button class="icon-button" type="button" data-action="open-filters" aria-label="Filter fabrics">${filtering() ? "Filter on" : "Filter"}</button>
      <button class="icon-button" type="button" data-action="add" aria-label="Add fabric">Add</button>
    </div>
    ${state.notice ? `<p class="notice" role="status">${esc(state.notice)}</p>` : ""}
    ${content}
  `;
}

function menuPanel() {
  return `
    <div class="menu-panel">
      <button type="button" data-action="open-enough">Do I have enough?</button>
      <button type="button" data-action="open-locations">Locations</button>
      <button type="button" data-action="open-projects">Projects</button>
      <button type="button" data-action="export">Export CSV</button>
      <button type="button" data-action="open-settings">Settings</button>
    </div>
  `;
}

function body() {
  if (state.screen === "enough") return enoughView();
  if (state.screen === "filters") return filtersView();
  if (state.screen === "locations") return locationsView();
  if (state.screen === "projects") return projectsView();
  if (state.screen === "settings") return settingsView();
  if (state.screen === "editor") return editorView();
  if (state.screen === "stretch") return stretchView();
  if (state.screen === "deduct") return deductView();
  if (state.screen === "paywall") return paywallView();
  const detailOpen = state.screen === "detail" && state.selectedId && fabricById(state.selectedId);
  if (detailOpen && !wide()) return detailView(fabricById(state.selectedId));
  return `
    <div class="split ${detailOpen ? "with-detail" : ""}">
      ${shelfView()}
      ${detailOpen ? detailView(fabricById(state.selectedId)) : ""}
    </div>
  `;
}

function shelfView() {
  if (state.fabrics.length === 0) {
    return `
      <section class="empty stack">
        <h2>The shelf is empty</h2>
        <p class="muted">Add a fabric you want to remember, or load a clearly fake set of samples to click around FabricStash.</p>
        <button class="madder" type="button" data-action="add">Add a fabric</button>
        <button class="green" type="button" data-action="load-samples">Load sample fabrics</button>
        <p class="muted">Samples are invented cloth for screenshots and practice. They count toward the free ${FREE_LIMIT}.</p>
      </section>
    `;
  }
  const shown = shownFabrics();
  if (shown.length === 0) {
    return `
      <section class="empty stack">
        <h2>Nothing matches</h2>
        <p class="muted">Try another word, or clear the filters.</p>
        <button class="madder" type="button" data-action="clear-filters">Clear search and filters</button>
      </section>
    `;
  }
  const cols = columnCount();
  return `
    <section class="stack">
      <p class="muted">${esc(countLine(shown))}</p>
      <button type="button" data-action="open-enough">Do I have enough?</button>
      <label>Search
        <input id="q" class="search" type="search" placeholder="Name, fiber, tag, store, print" value="${esc(state.queryText)}">
      </label>
      <div class="grid" style="grid-template-columns: repeat(${cols}, minmax(0, 1fr))">
        ${shown.map(swatch).join("")}
      </div>
    </section>
  `;
}

function swatch(fabric) {
  const selected = fabric.id === state.selectedId ? " selected" : "";
  const badges = [
    fabric.isSample ? "Sample" : "",
    fabric.isScrap ? "Scrap" : "",
    !fabric.isScrap && fabric.yardage <= 0 ? "Used up" : "",
  ].filter(Boolean);
  return `
    <button class="swatch${selected}" type="button" data-action="open-fabric" data-id="${esc(fabric.id)}" aria-label="${esc(`${fabric.name}, ${amountLine(fabric)}`)}">
      <span class="face" style="background:${esc(fabric.hex || "#3e5c4e")}">
        <span class="badges">${badges.map((badge) => `<span class="badge">${esc(badge)}</span>`).join("")}</span>
      </span>
      <h3>${esc(fabric.name)}</h3>
      <span class="amount"><span class="dot" style="background:${esc(fabric.hex || "#3e5c4e")}"></span>${esc(amountLine(fabric))}</span>
    </button>
  `;
}

function detailView(fabric) {
  const uses = state.uses.filter((use) => use.fabricId === fabric.id);
  const ounces = fabric.gsm == null ? "" : `${numberish(ozFromGsm(fabric.gsm))} oz/yd²`;
  return `
    <article class="card stack">
      ${wide() ? "" : `<button type="button" data-action="back">Back</button>`}
      <div class="face" style="background:${esc(fabric.hex || "#3e5c4e")}"></div>
      <h2>${esc(fabric.name)}</h2>
      ${fabric.isSample ? `<p class="badge" style="align-self:start">Sample</p>` : ""}
      <p>${esc(onHand(fabric))}</p>
      <p class="muted">${esc(fabric.fiber)} · ${esc(typeTitle(fabric.type))} · ${esc(fabric.structure === "knit" ? "Knit" : "Woven")}</p>
      <p class="muted">${esc(fabric.colorName)} ${esc(fabric.hex)} · ${esc(fabric.print || "solid")}</p>
      <p class="muted">${esc(locationName(fabric.locationId))}</p>
      <p>${esc(stretchTitle(fabric.stretch))}${fabric.recovery !== "untested" ? ` · ${esc(recoveryTitle(fabric.recovery))}` : ""}</p>
      ${fabric.gsm == null ? "" : `<p class="muted">${esc(String(fabric.gsm))} GSM · ${esc(ounces)}</p>`}
      <p class="muted">${esc(fabric.care)}</p>
      <h3>Cuts</h3>
      ${uses.length === 0 ? `<p class="muted">No yardage marked used yet.</p>` : uses.map(useRow).join("")}
      <button class="madder" type="button" data-action="open-deduct" data-id="${esc(fabric.id)}">Mark yardage used</button>
      <button type="button" data-action="open-stretch" data-id="${esc(fabric.id)}">Walk through a stretch test</button>
      <button type="button" data-action="open-edit" data-id="${esc(fabric.id)}">Edit fabric</button>
      <button type="button" data-action="delete-fabric" data-id="${esc(fabric.id)}">Delete fabric</button>
    </article>
  `;
}

function onHand(fabric) {
  if (fabric.isScrap) {
    return `Scrap ${formatWidth(fabric.scrapWidth, state.system)} × ${formatWidth(fabric.scrapLength, state.system)}`;
  }
  if (fabric.yardage <= 0) return "Nothing left on this piece.";
  return `${formatLength(fabric.yardage, state.system)} on hand · ${formatWidth(fabric.width, state.system)} wide`;
}

function useRow(use) {
  const project = state.projects.find((item) => item.id === use.projectId);
  return `
    <div class="use">
      <span>${esc(formatLength(use.yards, state.system))} · ${esc(project?.name || "Project")} ${use.note ? `· ${esc(use.note)}` : ""}</span>
      <button type="button" data-action="remove-use" data-id="${esc(use.id)}">Remove cut</button>
    </div>
  `;
}

function numberish(value) {
  return String(Math.round(value * 100) / 100);
}

function enoughView() {
  const yards = yardsFromDisplay(state.enoughLength, state.system);
  const inches = inchesFromDisplay(state.enoughWidth, state.system);
  const need = yards > 0 && inches > 0 ? { yards, widthInches: inches } : null;
  let result = "";
  if (!state.enoughLength && !state.enoughWidth) {
    result = `<p class="muted">Enter a length and a width. FabricStash will list cloth that covers it, and cloth that is close but short.</p>`;
  } else if (!need) {
    result = `<p class="notice">Use numbers greater than zero for both length and width.</p>`;
  } else {
    const pieces = state.fabrics.map((fabric) => ({
      id: fabric.id,
      name: fabric.name,
      yardage: fabric.yardage,
      width: fabric.width,
      isScrap: fabric.isScrap,
      scrapWidth: fabric.scrapWidth,
      scrapLength: fabric.scrapLength,
    }));
    const classified = classifyEnough(need, pieces);
    result = `
      <h3>Enough</h3>
      ${classified.covers.length ? classified.covers.map(matchRow).join("") : `<p class="muted">Nothing on the shelf covers this.</p>`}
      <h3>Close, but short</h3>
      ${classified.close.length ? classified.close.map(matchRow).join("") : `<p class="muted">No close matches.</p>`}
    `;
  }
  const unit = state.system === "imperial" ? "yd" : "m";
  const widthUnit = state.system === "imperial" ? "in" : "cm";
  return `
    <section class="card stack">
      <button type="button" data-action="back">Done</button>
      <h2>Do I have enough?</h2>
      <label>Length needed (${unit})
        <input id="enough-length" value="${esc(state.enoughLength)}" inputmode="decimal">
      </label>
      <label>Width needed (${widthUnit})
        <input id="enough-width" value="${esc(state.enoughWidth)}" inputmode="decimal">
      </label>
      <p class="muted">Bolts need enough length left and a wide enough piece. Scraps are checked on their own width and length, turned if that fits better.</p>
      ${result}
    </section>
  `;
}

function matchRow(match) {
  const piece = match.piece;
  const onHandText = piece.isScrap
    ? `Scrap ${formatWidth(piece.scrapWidth, state.system)} × ${formatWidth(piece.scrapLength, state.system)}`
    : `${formatLength(piece.yardage, state.system)} left, ${formatWidth(piece.width, state.system)} wide`;
  let detail = `${onHandText}. Covers this cut.`;
  if (match.kind === "short") {
    const shortfall = match.shortfall;
    if (shortfall.type === "yardage") detail = `${onHandText}. Short by ${formatLength(shortfall.yards, state.system)}.`;
    if (shortfall.type === "width") detail = `${onHandText}. Narrow by ${formatWidth(shortfall.inches, state.system)}.`;
    if (shortfall.type === "scrapEdge") detail = `${onHandText}. Short by ${formatWidth(shortfall.inches, state.system)} along the scrap.`;
  }
  return `<p><strong>${esc(piece.name)}</strong><br><span class="muted">${esc(detail)}</span></p>`;
}

function filtersView() {
  const places = [`<option value="any"${state.filters.location === "any" ? " selected" : ""}>Anywhere</option>`, `<option value="unassigned"${state.filters.location === "unassigned" ? " selected" : ""}>No location</option>`]
    .concat(state.locations.map((location) => `<option value="${esc(location.id)}"${state.filters.location === location.id ? " selected" : ""}>${esc(location.name)}</option>`))
    .join("");
  return `
    <section class="card stack">
      <button type="button" data-action="back">Done</button>
      <h2>Filter</h2>
      <label>Type
        <select id="filter-type">${options(TYPE_TITLES, state.filters.type, "Any type")}</select>
      </label>
      <label>Stretch
        <select id="filter-stretch">${options(STRETCH_TITLES, state.filters.stretch, "Any stretch")}</select>
      </label>
      <label>Color
        <select id="filter-color">${options(COLOR_TITLES, state.filters.colorFamily, "Any color")}</select>
      </label>
      <label>Minimum on hand (${state.system === "imperial" ? "yd" : "m"})
        <input id="filter-min" value="${esc(state.filters.minimum)}">
      </label>
      <p class="muted">Compared with yardage still on the shelf, after cuts.</p>
      <label>Place
        <select id="filter-location">${places}</select>
      </label>
      <button type="button" data-action="clear-filters">Clear</button>
    </section>
  `;
}

function locationsView() {
  const rows = [...state.locations].sort((a, b) => a.sortOrder - b.sortOrder).map((location, index, list) => `
    <div class="card stack">
      <label>Name
        <input data-location-name="${esc(location.id)}" value="${esc(location.name)}">
      </label>
      <p class="muted">${esc(location.kind)}</p>
      <div class="row">
        <button type="button" data-action="move-location" data-id="${esc(location.id)}" data-dir="-1" ${index === 0 ? "disabled" : ""}>Up</button>
        <button type="button" data-action="move-location" data-id="${esc(location.id)}" data-dir="1" ${index === list.length - 1 ? "disabled" : ""}>Down</button>
        <button type="button" data-action="delete-location" data-id="${esc(location.id)}">Delete</button>
      </div>
    </div>
  `).join("");
  return `
    <section class="stack">
      <button type="button" data-action="back">Done</button>
      <h2>Locations</h2>
      ${rows || `<p class="muted">No places yet.</p>`}
      <label>New place
        <input id="location-name" value="${esc(state.locationName)}" placeholder="Bin, shelf, or room">
      </label>
      <button class="madder" type="button" data-action="add-location">Add location</button>
    </section>
  `;
}

function projectsView() {
  const cards = state.projects.map((project) => {
    const uses = state.uses.filter((use) => use.projectId === project.id);
    return `
      <article class="card stack">
        <h3>${esc(project.name)}</h3>
        <p class="muted">${esc(project.notes || "")}</p>
        ${uses.length === 0 ? `<p class="muted">No cuts.</p>` : uses.map((use) => {
          const fabric = fabricById(use.fabricId);
          return `<p>${esc(formatLength(use.yards, state.system))} from ${esc(fabric?.name || "a fabric")}${use.note ? ` · ${esc(use.note)}` : ""}</p>`;
        }).join("")}
        <button type="button" data-action="delete-project" data-id="${esc(project.id)}">Delete project</button>
      </article>
    `;
  }).join("");
  return `
    <section class="stack">
      <button type="button" data-action="back">Done</button>
      <h2>Projects</h2>
      ${cards || `<p class="muted">No projects yet. Mark yardage used on a fabric to start one.</p>`}
    </section>
  `;
}

function settingsView() {
  const imperial = state.system === "imperial";
  return `
    <section class="card stack">
      <button type="button" data-action="back">Done</button>
      <h2>Settings</h2>
      <p>Measurement</p>
      <div class="choice">
        <button type="button" data-action="set-system" data-system="imperial" aria-pressed="${imperial}">Imperial</button>
        <button type="button" data-action="set-system" data-system="metric" aria-pressed="${!imperial}">Metric</button>
      </div>
      <p class="muted">${imperial ? "Inches and yards." : "Centimeters and meters."} Switching changes what you see. The stored cloth stays in yards and inches.</p>
      <button type="button" data-action="export">Export CSV</button>
      <button type="button" data-action="remove-samples">Remove sample fabrics</button>
      <p class="muted">The iOS app’s unlock is a StoreKit purchase. This preview cannot buy it.</p>
    </section>
  `;
}

function paywallView() {
  return `
    <section class="card stack">
      <button type="button" data-action="back">Close</button>
      <h2>Free shelf is full</h2>
      <p>Twenty-five fabrics are on the shelf. Editing and deleting still work. Deleting one frees a slot.</p>
      <p class="muted">On iPhone, Unlock is a one-time StoreKit purchase. This browser preview cannot take payment, so it stays on the free shelf.</p>
    </section>
  `;
}

function editorView() {
  const editor = state.editor;
  if (!editor) return "";
  const places = [`<option value="">No location</option>`].concat(state.locations.map((location) => `<option value="${esc(location.id)}"${editor.locationId === location.id ? " selected" : ""}>${esc(location.name)}</option>`)).join("");
  const gsm = Number(editor.gsmText);
  const ounces = Number.isFinite(gsm) && editor.gsmText.trim() ? `${numberish(ozFromGsm(gsm))} oz/yd²` : "";
  return `
    <form class="card stack" data-form="editor">
      <button type="button" data-action="back">Cancel</button>
      <h2>${editor.mode === "create" ? "Add fabric" : "Edit fabric"}</h2>
      <label>Name <input id="ed-name" name="name" required value="${esc(editor.name)}"></label>
      <label>Fiber <input id="ed-fiber" name="fiber" value="${esc(editor.fiber)}"></label>
      <label>Structure
        <select id="ed-structure" name="structure">
          <option value="woven"${editor.structure === "woven" ? " selected" : ""}>Woven</option>
          <option value="knit"${editor.structure === "knit" ? " selected" : ""}>Knit</option>
        </select>
      </label>
      <label>Type <select id="ed-type" name="type">${Object.entries(TYPE_TITLES).map(([value, label]) => `<option value="${esc(value)}"${editor.type === value ? " selected" : ""}>${esc(label)}</option>`).join("")}</select></label>
      <label>On hand (${state.system === "imperial" ? "yd" : "m"}) <input id="ed-yards" name="yardage" value="${esc(editor.yardageText)}"></label>
      <label>Width (${state.system === "imperial" ? "in" : "cm"}) <input id="ed-width" name="width" value="${esc(editor.widthText)}"></label>
      <label>GSM <input id="ed-gsm" name="gsm" value="${esc(editor.gsmText)}"></label>
      ${ounces ? `<p class="muted">${esc(ounces)}. Ounces per square yard follow GSM. Stored weight stays GSM.</p>` : ""}
      <label>Color name <input id="ed-color" name="colorName" value="${esc(editor.colorName)}"></label>
      <label>Hex <input id="ed-hex" name="hex" value="${esc(editor.hex)}" placeholder="#B4332A"></label>
      <label>Print <input id="ed-print" name="print" value="${esc(editor.print)}"></label>
      <label>Place <select id="ed-location" name="locationId">${places}</select></label>
      ${editor.error ? `<p class="notice">${esc(editor.error)}</p>` : ""}
      <button class="madder" type="submit">Save</button>
    </form>
  `;
}

function deductView() {
  const draft = state.deduct;
  const fabric = draft && fabricById(draft.fabricId);
  if (!fabric) return "";
  const yards = yardsFromDisplay(draft.amount, state.system);
  const outcome = yards == null ? null : deduct(fabric.yardage, yards);
  let warning = "";
  if (draft.amount.trim() && yards == null) warning = "That amount is not a number.";
  else if (outcome && !outcome.ok && outcome.reason === "amountMustBePositive") warning = "Enter an amount greater than zero.";
  else if (outcome && !outcome.ok && outcome.reason === "wouldBeNegative") {
    warning = `That would take it below zero. You are short by ${formatLength(outcome.shortfall, state.system)}. Nothing was deducted.`;
  }
  const projectOptions = state.projects.map((project) => `<option value="${esc(project.id)}"${draft.projectId === project.id ? " selected" : ""}>${esc(project.name)}</option>`).join("");
  return `
    <form class="card stack" data-form="deduct">
      <button type="button" data-action="back">Cancel</button>
      <h2>Mark yardage used</h2>
      <p>${esc(formatLength(fabric.yardage, state.system))} on hand</p>
      <label>Amount (${state.system === "imperial" ? "yd" : "m"}) <input id="deduct-amount" value="${esc(draft.amount)}"></label>
      ${outcome && outcome.ok ? `<p class="muted">${esc(formatLength(outcome.remaining, state.system))} would remain.</p>` : ""}
      ${warning ? `<p class="notice">${esc(warning)}</p>` : ""}
      <label>Project
        <select id="deduct-project">
          ${projectOptions}
          <option value="__new" ${draft.projectId === "__new" ? "selected" : ""}>New project</option>
        </select>
      </label>
      ${draft.projectId === "__new" ? `<label>Project name <input id="deduct-new" value="${esc(draft.newName)}"></label>` : ""}
      <label>Note <input id="deduct-note" value="${esc(draft.note)}"></label>
      ${draft.error ? `<p class="notice">${esc(draft.error)}</p>` : ""}
      <button class="madder" type="submit" ${outcome && outcome.ok ? "" : "disabled"}>Save cut</button>
    </form>
  `;
}

function stretchView() {
  const draft = state.stretch;
  const fabric = draft && fabricById(draft.fabricId);
  if (!fabric) return "";
  const mark = state.system === "imperial" ? "4 inches" : "10 centimeters";
  const marked = state.system === "imperial" ? 4 : 10;
  const steps = [
    `<h2>A tape-measure test</h2>
     <p>FabricStash does not use the phone’s sensors to measure stretch. You mark the cloth, pull it by hand, read a tape, and type what you see.</p>
     <p>${state.system === "imperial" ? "Four inches is the mark because the math is easy: if 4 inches becomes 5 inches, that is 25% stretch." : "Ten centimeters is the mark because the math is easy: if 10 cm becomes 13 cm, that is 30% stretch."}</p>
     <p>You will do it twice. First across the fabric (crosswise), then along it (lengthwise). After both, you can save 2-way, 4-way, or no stretch.</p>`,
    `<h2>Crosswise</h2><p>Mark ${mark} from selvedge toward selvedge, across the cloth. Hold one end of the mark and pull the other until the fabric resists and you would not want to pull harder. Measure the mark again and type that length.</p>
     <label>Stretched length <input id="stretch-cross" value="${esc(draft.crosswise)}"></label>`,
    `<h2>Did it spring back?</h2><p>Let go. If the mark returns close to ${mark}, recovery is good. If it stays long, wavy, or baggy, recovery is poor.</p>${recoveryChoices("crosswise", draft.crosswiseRecovery)}`,
    `<h2>Lengthwise</h2><p>Mark a fresh ${mark} parallel to the selvedge, along the length of the cloth. Pull until it resists, then measure the mark again.</p>
     <label>Stretched length <input id="stretch-length" value="${esc(draft.lengthwise)}"></label>`,
    `<h2>Lengthwise recovery</h2><p>Let go again. Judge this direction on its own.</p>${recoveryChoices("lengthwise", draft.lengthwiseRecovery)}`,
    summaryStep(draft, marked),
  ];
  return `
    <section class="card stack">
      <button type="button" data-action="close-stretch">Close</button>
      <p class="muted">Step ${draft.step + 1} of 6 · ${esc(fabric.name)}</p>
      ${steps[draft.step]}
      ${draft.error ? `<p class="notice">${esc(draft.error)}</p>` : ""}
      <div class="row">
        ${draft.step > 0 ? `<button type="button" data-action="stretch-back">Back</button>` : ""}
        ${draft.step < 5 ? `<button class="madder" type="button" data-action="stretch-next">Continue</button>` : `<button class="madder" type="button" data-action="stretch-save">Save stretch</button>`}
      </div>
    </section>
  `;
}

function recoveryChoices(which, current) {
  return `<div class="choice">
    ${["good", "poor", "untested"].map((value) => `<button type="button" data-action="set-recovery" data-which="${which}" data-value="${value}" aria-pressed="${current === value}">${esc(recoveryTitle(value))}</button>`).join("")}
  </div>`;
}

function markValue(text) {
  if (state.system === "imperial") return fractionValue(text);
  const value = Number(String(text).trim());
  return Number.isFinite(value) ? value : null;
}

function summaryStep(draft, marked) {
  const cross = stretchPercent(markValue(draft.crosswise), marked);
  const length = stretchPercent(markValue(draft.lengthwise), marked);
  if (cross == null || length == null) return `<p class="notice">Enter both stretched lengths before saving. A length shorter than the mark does not count.</p>`;
  const kind = stretchKind(cross, length);
  return `<h2>${esc(stretchTitle(kind))}</h2><p>${esc(stretchExplanation(kind, cross, length))}</p><p class="muted">${esc(recoveryTitle(combinedRecovery(draft.crosswiseRecovery, draft.lengthwiseRecovery)))}</p>`;
}

function go(screen) {
  state.screen = screen;
  state.menuOpen = false;
  state.notice = "";
  render();
}

function attemptAdd() {
  if (!canAddFabric(state.fabrics.length, false)) {
    go("paywall");
    return;
  }
  state.editor = {
    mode: "create",
    id: null,
    name: "",
    fiber: "",
    structure: "woven",
    type: "cotton",
    yardageText: "",
    widthText: "",
    gsmText: "",
    colorName: "",
    hex: "",
    print: "",
    locationId: "",
    canonicalYards: null,
    canonicalInches: null,
    error: "",
  };
  go("editor");
}

function openEdit(id) {
  const fabric = fabricById(id);
  if (!fabric) return;
  state.editor = {
    mode: "edit",
    id,
    name: fabric.name,
    fiber: fabric.fiber,
    structure: fabric.structure,
    type: fabric.type,
    yardageText: lengthText(fabric.yardage, state.system),
    widthText: widthText(fabric.width, state.system),
    gsmText: fabric.gsm == null ? "" : String(fabric.gsm),
    colorName: fabric.colorName,
    hex: fabric.hex,
    print: fabric.print,
    locationId: fabric.locationId || "",
    canonicalYards: fabric.yardage,
    canonicalInches: fabric.width,
    error: "",
  };
  go("editor");
}

function snapshotEditor() {
  const form = document.querySelector('form[data-form="editor"]');
  if (!form || !state.editor) return;
  const data = Object.fromEntries(new FormData(form).entries());
  state.editor.name = data.name ?? "";
  state.editor.fiber = data.fiber ?? "";
  state.editor.structure = data.structure || state.editor.structure;
  state.editor.type = data.type || state.editor.type;
  state.editor.yardageText = data.yardage ?? "";
  state.editor.widthText = data.width ?? "";
  state.editor.colorName = data.colorName ?? "";
  state.editor.hex = data.hex ?? "";
  state.editor.print = data.print ?? "";
  state.editor.locationId = data.locationId ?? "";
}

function readEditor(form) {
  const data = Object.fromEntries(new FormData(form).entries());
  const editor = state.editor;
  const yards = resolved(data.yardage, editor.canonicalYards, (text) => lengthText(editor.canonicalYards, state.system), (text) => yardsFromDisplay(text, state.system));
  const inches = resolved(data.width, editor.canonicalInches, () => widthText(editor.canonicalInches, state.system), (text) => inchesFromDisplay(text, state.system));
  if (!data.name.trim()) return { error: "Name the fabric before saving." };
  if (yards == null || inches == null || yards < 0 || inches <= 0) return { error: "Enter the amount on hand and a width greater than zero." };
  const gsmText = String(data.gsm || "").trim();
  const gsm = gsmText ? Number(gsmText) : null;
  if (gsmText && !Number.isFinite(gsm)) return { error: "GSM has to be a number." };
  return { data, yards, inches, gsm };
}

function resolved(text, canonical, shown, parse) {
  if (canonical != null && text === shown()) return canonical;
  return parse(text);
}

function saveEditor(form) {
  const read = readEditor(form);
  if (read.error) {
    state.editor.error = read.error;
    state.editor = { ...state.editor, ...Object.fromEntries(new FormData(form).entries()), yardageText: form.yardage.value, widthText: form.width.value, gsmText: form.gsm.value, error: read.error };
    render();
    return;
  }
  const { data, yards, inches, gsm } = read;
  const now = new Date().toISOString();
  if (state.editor.mode === "create") {
    if (!canAddFabric(state.fabrics.length, false)) {
      go("paywall");
      return;
    }
    const id = uid("fabric");
    state.fabrics.unshift({
      id,
      name: data.name.trim(),
      fiber: data.fiber.trim(),
      structure: data.structure,
      type: data.type,
      yardage: yards,
      width: inches,
      gsm,
      colorName: data.colorName.trim(),
      hex: data.hex.trim() || "#8AA58B",
      print: data.print.trim(),
      stretchCrosswise: null,
      stretchLengthwise: null,
      stretch: "none",
      recovery: "untested",
      source: "",
      price: null,
      prewashed: false,
      tags: [],
      care: "",
      isSample: false,
      isScrap: false,
      scrapWidth: 0,
      scrapLength: 0,
      locationId: data.locationId || null,
      createdAt: now,
      updatedAt: now,
    });
    state.selectedId = id;
  } else {
    const fabric = fabricById(state.editor.id);
    if (!fabric) return;
    Object.assign(fabric, {
      name: data.name.trim(),
      fiber: data.fiber.trim(),
      structure: data.structure,
      type: data.type,
      yardage: yards,
      width: inches,
      gsm,
      colorName: data.colorName.trim(),
      hex: data.hex.trim() || fabric.hex,
      print: data.print.trim(),
      locationId: data.locationId || null,
      updatedAt: now,
    });
    state.selectedId = fabric.id;
  }
  state.editor = null;
  state.screen = "detail";
  save();
  render();
}

function loadSamples() {
  if (state.fabrics.some((fabric) => fabric.isSample)) {
    state.notice = "Samples are already on the shelf.";
    render();
    return;
  }
  const shelf = sampleShelf();
  state.fabrics.push(...shelf.fabrics);
  state.locations.push(...shelf.locations);
  state.projects.push(...shelf.projects);
  state.uses.push(...shelf.uses);
  state.notice = "";
  save();
  render();
}

function removeSamples() {
  const sampleIds = new Set(state.fabrics.filter((fabric) => fabric.isSample).map((fabric) => fabric.id));
  state.fabrics = state.fabrics.filter((fabric) => !fabric.isSample);
  state.uses = state.uses.filter((use) => !sampleIds.has(use.fabricId));
  state.projects = state.projects.filter((project) => {
    if (!project.name.startsWith("Sample:")) return true;
    return state.uses.some((use) => use.projectId === project.id && !sampleIds.has(use.fabricId));
  });
  state.locations = state.locations.filter((location) => {
    if (!location.name.startsWith("Sample ")) return true;
    return state.fabrics.some((fabric) => fabric.locationId === location.id && !fabric.isSample);
  });
  if (state.selectedId && !fabricById(state.selectedId)) state.selectedId = null;
  state.screen = "shelf";
  save();
  render();
}

function saveDeduct(form) {
  const draft = state.deduct;
  const fabric = fabricById(draft.fabricId);
  if (!fabric) return;
  draft.amount = document.getElementById("deduct-amount").value;
  draft.note = document.getElementById("deduct-note").value;
  draft.projectId = document.getElementById("deduct-project").value;
  if (draft.projectId === "__new") draft.newName = document.getElementById("deduct-new")?.value || "";
  const yards = yardsFromDisplay(draft.amount, state.system);
  const outcome = yards == null ? null : deduct(fabric.yardage, yards);
  if (!outcome || !outcome.ok) {
    draft.error = "That cut no longer fits what is left.";
    render();
    return;
  }
  let projectId = draft.projectId;
  if (projectId === "__new") {
    const name = draft.newName.trim();
    if (!name) {
      draft.error = "Name the project before saving the cut.";
      render();
      return;
    }
    projectId = uid("project");
    state.projects.unshift({ id: projectId, name, notes: "", createdAt: new Date().toISOString(), isSample: false });
  }
  if (!state.projects.some((project) => project.id === projectId)) {
    draft.error = "That project is no longer here.";
    render();
    return;
  }
  fabric.yardage = outcome.remaining;
  fabric.updatedAt = new Date().toISOString();
  state.uses.unshift({
    id: uid("use"),
    yards,
    note: draft.note.trim(),
    fabricId: fabric.id,
    projectId,
    createdAt: fabric.updatedAt,
  });
  state.deduct = null;
  state.selectedId = fabric.id;
  state.screen = "detail";
  save();
  render();
}

function removeUse(id) {
  const use = state.uses.find((item) => item.id === id);
  if (!use) return;
  const fabric = fabricById(use.fabricId);
  if (fabric) fabric.yardage = restore(fabric.yardage, use.yards);
  state.uses = state.uses.filter((item) => item.id !== id);
  save();
  render();
}

function deleteProject(id) {
  for (const use of state.uses.filter((item) => item.projectId === id)) {
    const fabric = fabricById(use.fabricId);
    if (fabric) fabric.yardage = restore(fabric.yardage, use.yards);
  }
  state.uses = state.uses.filter((item) => item.projectId !== id);
  state.projects = state.projects.filter((project) => project.id !== id);
  save();
  render();
}

function exportCsv() {
  const csv = renderCsv(state.fabrics, state.locations, state.uses, state.system);
  const blob = new Blob([csv], { type: "text/csv" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "FabricStash.csv";
  link.click();
  URL.revokeObjectURL(url);
}

function syncStretchInputs() {
  const draft = state.stretch;
  if (!draft) return;
  const cross = document.getElementById("stretch-cross");
  const length = document.getElementById("stretch-length");
  if (cross) draft.crosswise = cross.value;
  if (length) draft.lengthwise = length.value;
}

function continueStretch() {
  syncStretchInputs();
  const draft = state.stretch;
  const marked = state.system === "imperial" ? 4 : 10;
  if (draft.step === 1 && stretchPercent(markValue(draft.crosswise), marked) == null) {
    draft.error = "Type the stretched length. It cannot be shorter than the mark.";
    render();
    return;
  }
  if (draft.step === 3 && stretchPercent(markValue(draft.lengthwise), marked) == null) {
    draft.error = "Type the stretched length. It cannot be shorter than the mark.";
    render();
    return;
  }
  draft.error = "";
  draft.step += 1;
  render();
}

function saveStretch() {
  syncStretchInputs();
  const draft = state.stretch;
  const fabric = fabricById(draft.fabricId);
  const marked = state.system === "imperial" ? 4 : 10;
  const cross = stretchPercent(markValue(draft.crosswise), marked);
  const length = stretchPercent(markValue(draft.lengthwise), marked);
  if (!fabric || cross == null || length == null) {
    draft.error = "Enter both stretched lengths before saving.";
    render();
    return;
  }
  fabric.stretchCrosswise = cross;
  fabric.stretchLengthwise = length;
  fabric.stretch = stretchKind(cross, length);
  fabric.recovery = combinedRecovery(draft.crosswiseRecovery, draft.lengthwiseRecovery);
  fabric.updatedAt = new Date().toISOString();
  state.stretch = null;
  state.selectedId = fabric.id;
  state.screen = "detail";
  save();
  render();
}

function renameLocation(id, name) {
  const location = state.locations.find((item) => item.id === id);
  if (!location) return;
  location.name = name;
  save();
}

function addLocation() {
  const name = state.locationName.trim();
  if (!name) return;
  const sortOrder = state.locations.reduce((max, location) => Math.max(max, location.sortOrder), -1) + 1;
  state.locations.push({ id: uid("loc"), name, kind: "bin", sortOrder });
  state.locationName = "";
  save();
  render();
}

function moveLocation(id, dir) {
  const list = [...state.locations].sort((a, b) => a.sortOrder - b.sortOrder);
  const index = list.findIndex((location) => location.id === id);
  const next = index + dir;
  if (index < 0 || next < 0 || next >= list.length) return;
  const order = list[index].sortOrder;
  list[index].sortOrder = list[next].sortOrder;
  list[next].sortOrder = order;
  save();
  render();
}

document.addEventListener("click", (event) => {
  const target = event.target.closest("[data-action]");
  if (!target || !app.contains(target)) return;
  const action = target.dataset.action;
  const id = target.dataset.id;
  if (action === "toggle-menu") {
    state.menuOpen = !state.menuOpen;
    render();
  } else if (action === "add") attemptAdd();
  else if (action === "load-samples") loadSamples();
  else if (action === "open-fabric") {
    state.selectedId = id;
    state.screen = "detail";
    state.menuOpen = false;
    render();
  } else if (action === "back") {
    state.screen = "shelf";
    state.menuOpen = false;
    state.notice = "";
    save();
    render();
  } else if (action === "open-enough") go("enough");
  else if (action === "open-locations") go("locations");
  else if (action === "open-projects") go("projects");
  else if (action === "open-settings") go("settings");
  else if (action === "open-filters") go("filters");
  else if (action === "clear-filters") {
    state.queryText = "";
    state.filters = { type: "", stretch: "", colorFamily: "", minimum: "", location: "any" };
    state.screen = "shelf";
    render();
  } else if (action === "export") exportCsv();
  else if (action === "set-system") {
    state.system = target.dataset.system;
    save();
    render();
  } else if (action === "remove-samples") removeSamples();
  else if (action === "open-edit") openEdit(id);
  else if (action === "delete-fabric") {
    state.fabrics = state.fabrics.filter((fabric) => fabric.id !== id);
    state.uses = state.uses.filter((use) => use.fabricId !== id);
    if (state.selectedId === id) state.selectedId = null;
    state.screen = "shelf";
    save();
    render();
  } else if (action === "open-deduct") {
    state.deduct = {
      fabricId: id,
      amount: "",
      projectId: state.projects[0]?.id || "__new",
      newName: "",
      note: "",
      error: "",
    };
    go("deduct");
  } else if (action === "remove-use") removeUse(id);
  else if (action === "delete-project") deleteProject(id);
  else if (action === "delete-location") {
    state.locations = state.locations.filter((location) => location.id !== id);
    for (const fabric of state.fabrics) if (fabric.locationId === id) fabric.locationId = null;
    save();
    render();
  } else if (action === "move-location") moveLocation(id, Number(target.dataset.dir));
  else if (action === "add-location") addLocation();
  else if (action === "open-stretch") {
    state.stretch = {
      fabricId: id,
      step: 0,
      crosswise: "",
      lengthwise: "",
      crosswiseRecovery: "untested",
      lengthwiseRecovery: "untested",
      error: "",
    };
    go("stretch");
  } else if (action === "close-stretch") {
    state.stretch = null;
    state.screen = "detail";
    render();
  } else if (action === "stretch-back") {
    syncStretchInputs();
    state.stretch.step = Math.max(0, state.stretch.step - 1);
    state.stretch.error = "";
    render();
  } else if (action === "stretch-next") continueStretch();
  else if (action === "stretch-save") saveStretch();
  else if (action === "set-recovery") {
    if (target.dataset.which === "crosswise") state.stretch.crosswiseRecovery = target.dataset.value;
    else state.stretch.lengthwiseRecovery = target.dataset.value;
    render();
  }
});

document.addEventListener("input", (event) => {
  const el = event.target;
  if (!app.contains(el)) return;
  if (el.id === "q") {
    state.queryText = el.value;
    render();
  } else if (el.id === "enough-length") {
    state.enoughLength = el.value;
    render();
  } else if (el.id === "enough-width") {
    state.enoughWidth = el.value;
    render();
  } else if (el.id === "deduct-amount" || el.id === "deduct-note" || el.id === "deduct-new") {
    if (!state.deduct) return;
    if (el.id === "deduct-amount") state.deduct.amount = el.value;
    if (el.id === "deduct-note") state.deduct.note = el.value;
    if (el.id === "deduct-new") state.deduct.newName = el.value;
    state.deduct.error = "";
    render();
  } else if (el.id === "location-name") {
    state.locationName = el.value;
  } else if (el.dataset.locationName) {
    renameLocation(el.dataset.locationName, el.value);
  } else if (el.id === "filter-min") {
    state.filters.minimum = el.value;
  } else if (el.id === "ed-gsm" && state.editor) {
    snapshotEditor();
    state.editor.gsmText = el.value;
    render();
  }
});

document.addEventListener("change", (event) => {
  const el = event.target;
  if (!app.contains(el)) return;
  if (el.id === "filter-type") state.filters.type = el.value;
  if (el.id === "filter-stretch") state.filters.stretch = el.value;
  if (el.id === "filter-color") state.filters.colorFamily = el.value;
  if (el.id === "filter-location") state.filters.location = el.value;
  if (el.id === "deduct-project" && state.deduct) {
    state.deduct.projectId = el.value;
    render();
  }
  if (el.id === "filter-type" || el.id === "filter-stretch" || el.id === "filter-color" || el.id === "filter-location") {
    save();
  }
});

document.addEventListener("submit", (event) => {
  const form = event.target;
  if (!(form instanceof HTMLFormElement) || !app.contains(form)) return;
  event.preventDefault();
  if (form.dataset.form === "editor") saveEditor(form);
  if (form.dataset.form === "deduct") saveDeduct(form);
});

window.addEventListener("resize", () => render());
render();
