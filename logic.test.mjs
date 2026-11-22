import assert from "node:assert/strict";
import test from "node:test";
import {
  canAddFabric,
  classifyEnough,
  colorFamily,
  deduct,
  formatLength,
  fractionValue,
  gsmFromOz,
  matchesQuery,
  metersFromYards,
  ozFromGsm,
  renderCsv,
  restore,
  sampleShelf,
  stretchExplanation,
  stretchKind,
  stretchPercent,
  yardsFromDisplay,
} from "./logic.mjs";

test("imperial fractions and metric length stay on the stored yards", () => {
  assert.equal(fractionValue("44 1/2"), 44.5);
  assert.equal(fractionValue("3/8"), 0.375);
  assert.equal(formatLength(2.5, "imperial"), "2 1/2 yd");
  assert.equal(formatLength(2.5, "metric"), `${metersFromYards(2.5)} m`);
  assert.equal(yardsFromDisplay("1", "metric"), 1 / 0.9144);
  assert.equal(gsmFromOz(1), 33.906);
  assert.ok(Math.abs(ozFromGsm(145) - 145 / 33.906) < 1e-9);
});

test("yardage deduction refuses a cut below zero and restore puts it back", () => {
  assert.deepEqual(deduct(2.5, 0.5), { ok: true, remaining: 2 });
  const refused = deduct(0.4, 0.5);
  assert.equal(refused.ok, false);
  assert.equal(refused.reason, "wouldBeNegative");
  assert.equal(restore(2, 0.5), 2.5);
});

test("bolts and the madder scrap match the iOS enough-fabric rules", () => {
  const { fabrics } = sampleShelf();
  const pieces = fabrics.map((fabric) => ({
    id: fabric.id,
    name: fabric.name,
    yardage: fabric.yardage,
    width: fabric.width,
    isScrap: fabric.isScrap,
    scrapWidth: fabric.scrapWidth,
    scrapLength: fabric.scrapLength,
  }));
  const covered = classifyEnough({ yards: 2, widthInches: 44 }, pieces);
  assert.ok(covered.covers.some((match) => match.piece.name === "Sample: Picnic Gingham"));
  const shortBolt = classifyEnough({ yards: 3, widthInches: 44 }, pieces);
  const gingham = shortBolt.close.find((match) => match.piece.name === "Sample: Picnic Gingham");
  assert.equal(gingham.shortfall.type, "yardage");
  assert.ok(Math.abs(gingham.shortfall.yards - 0.5) < 1e-9);
  const scrapFits = classifyEnough({ yards: 18 / 36, widthInches: 20 }, pieces);
  assert.ok(scrapFits.covers.some((match) => match.piece.name === "Sample: Madder Linen Scrap"));
  const scrapShort = classifyEnough({ yards: 25.2 / 36, widthInches: 18 }, pieces);
  const scrap = scrapShort.close.find((match) => match.piece.name === "Sample: Madder Linen Scrap");
  assert.equal(scrap.shortfall.type, "scrapEdge");
  assert.ok(Math.abs(scrap.shortfall.inches - 3.2) < 1e-9);
});

test("search finds gingham, elastane, stars, and Sample Knit", () => {
  const { fabrics } = sampleShelf();
  const names = (text) => fabrics.filter((fabric) => matchesQuery(fabric, { text, location: "any" })).map((fabric) => fabric.name);
  assert.deepEqual(names("gingham"), ["Sample: Picnic Gingham"]);
  assert.ok(names("elastane").includes("Sample: Sea Glass Jersey"));
  assert.deepEqual(names("stars"), ["Sample: Costume Spandex"]);
  assert.deepEqual(names("Sample Knit"), ["Sample: Sea Glass Jersey"]);
  assert.equal(colorFamily("#B4332A"), "reds");
});

test("stretch test uses a 4 inch mark and does not invent a sensor", () => {
  assert.equal(stretchPercent(5, 4), 25);
  assert.equal(stretchKind(25, 30), "fourWay");
  assert.equal(stretchKind(40, 5), "twoWay");
  assert.equal(stretchKind(5, 5), "none");
  assert.match(stretchExplanation("none", 5, 5), /no stretch/);
});

test("free shelf stops at 25", () => {
  assert.equal(canAddFabric(24, false), true);
  assert.equal(canAddFabric(25, false), false);
  assert.equal(canAddFabric(25, true), true);
});

test("csv headers name yards and inches", () => {
  const shelf = sampleShelf();
  const csv = renderCsv(shelf.fabrics, shelf.locations, shelf.uses, "imperial");
  assert.match(csv.split("\n")[0], /yardage_on_hand_yards/);
  assert.match(csv.split("\n")[0], /width_inches/);
  assert.match(csv, /Sample: Picnic Gingham/);
});
