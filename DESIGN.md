---
name: "My Fabric Cuts"
description: A quiet shelf of cloth, on cool paper, with one sea-glass accent.
colors:
  sea-glass: "#215E70"
  sea-glass-fill-dark: "#2C6E82"
  sea-glass-tint-dark: "#9ED0DC"
  on-accent: "#F7FBFC"
  cool-paper: "#E6EEF0"
  cool-paper-dark: "#152024"
  card: "#F7FBFC"
  card-dark: "#1C262B"
  ink: "#1E2C31"
  ink-dark: "#E7F1F3"
  ink-secondary: "#4E6068"
  ink-secondary-dark: "#A8BCC3"
  caution: "#8B3A48"
  caution-dark: "#F3C1C8"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "34px"
    fontWeight: 600
    lineHeight: 1.15
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: 1.2
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.3
rounded:
  card: "16px"
  control: "14px"
  photo: "16px"
  shelf-photo: "12px"
  swatch: "8px"
spacing:
  unit: "12px"
  card: "16px"
  screen: "16px"
components:
  button-primary:
    backgroundColor: "{colors.sea-glass}"
    textColor: "{colors.on-accent}"
    rounded: "{rounded.control}"
    padding: "14px 18px"
  button-quiet:
    backgroundColor: "{colors.card}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "14px 18px"
  card-shelf:
    backgroundColor: "{colors.card}"
    textColor: "{colors.ink}"
    rounded: "{rounded.card}"
    padding: "12px"
  swatch-chip:
    backgroundColor: "{colors.cool-paper}"
    rounded: "{rounded.swatch}"
    size: "44px"
---

# Design System: My Fabric Cuts

## Overview

**Creative North Star: "A coastal morning shelf"**

My Fabric Cuts is a shelf you can scan in north light. The ground is cool paper, the type is soft blue-charcoal, and one sea-glass accent marks the action and the selected card. The cloth photos carry the color. The chrome stays quiet.

The brown, kraft, camel, and dark-wood studio is gone, including its serif titles and madder buttons. San Francisco (the system face) carries every label so the shelf follows the reading size the owner already set. Depth comes from a card lifted one step off the paper, not from a shadow.

**Key Characteristics:**

- Cool paper ground, soft ink, one accent
- The photograph is the color field of a card
- A ring and a loupe mark the spot tapped on the cloth
- Aligned cards, the name and the amount in the same place, spacing on a 12-point measure
- Native iOS controls on iPhone and iPad, with the same palette in the browser preview

## Colors

Light is the cutting table. Dark is the same shelf after the room lights go down: cool, not brown-black.

### Primary

- **Sea glass** (`colors.sea-glass`): actions, selection stroke, links, and the tint. In dark mode the button fill deepens so the label stays light (`colors.sea-glass-fill-dark`), and text and selection use the lighter tint (`colors.sea-glass-tint-dark`).

### Neutral

- **Cool paper** (`colors.cool-paper`, dark `colors.cool-paper-dark`): the screen ground.
- **Card** (`colors.card`, dark `colors.card-dark`): shelf cards and grouped surfaces.
- **Ink** (`colors.ink`, dark `colors.ink-dark`): titles and body.
- **Secondary ink** (`colors.ink-secondary`, dark `colors.ink-secondary-dark`): counts, footnotes, and hints.
- **On accent** (`colors.on-accent`): label on a sea-glass button or badge.
- **Caution** (`colors.caution`, dark `colors.caution-dark`): a refused cut, a bad number, or a save that cannot proceed. It is not a second brand color.

**The Cloth Carries the Color Rule.** Sea glass never tints a fabric photo or stands in for a fabric that has its own swatch. A missing photo with a sampled color shows that color. A missing color shows paper.

**The One Accent Rule.** Sea glass is for the action and the selection. Caution is only for a problem. Nothing else gets a brand hue.

## Typography

**Display Font:** San Francisco, the iOS system face (Avenir Next, then Segoe UI, in the browser preview)
**Body Font:** the same face

**Character:** One quiet grotesque. No display serif. Dynamic Type text styles on iOS, so the sizes below are the default point sizes, not locked sizes.

### Hierarchy

- **Display** (semibold, 34px, large title): an empty shelf, a fabric name on its page, the unlock headline.
- **Title** (semibold, 28px): a stretch-test step, the unlock price.
- **Headline** (semibold, 17px): the name under a shelf card.
- **Body** (regular, 17px): facts, fields, and buttons.
- **Label** (regular, 12px): captions under a fact.

**The System Face Rule.** Labels, buttons, and titles use the platform face. A second face is not part of this shelf.

## Layout

The shelf is a grid: two columns on a phone, three from 640 points, four from 900. The gap is 12 points. Each card is the photo, then the name, then the amount with a 12-point color dot. The count line sits above the grid. Search and add stay in the navigation bar.

On iPad the shelf column stays beside the fabric. Sheets hold a new fabric, a filter, a stretch test, and the unlock. The color sampler is 260 points tall on a compact width and 360 on a regular width, and the whole photo stays visible so the owner can tap the cloth rather than a crop.

## Elevation & Depth

The shelf is flat. A card is a lighter surface on the paper, with a 1-point hairline at 8% ink. The loupe on the color sampler is the one soft shadow, so the magnified spot reads as sitting above the photo.

**The Flat Shelf Rule.** Do not add a drop shadow to a fabric card. The photo is the depth.

## Shapes

Cards use a continuous 16-point corner. The photo on a shelf card is inset at 12. The color sampler photo uses 16. Buttons use 14. The sampled-color chip and photo thumbs use 8. Badges are capsules. The sample mark is a 28-point ring with a short crosshair, and the loupe is a 56-point circle.

## Components

### Buttons

- **Shape:** gently rounded (14px).
- **Primary:** sea-glass fill, on-accent label, semibold, 14-by-18-point padding. Pressed state lowers the fill to 86% opacity.
- **Quiet:** card fill, ink label, 1-point hairline. Used for a second action such as loading samples, restoring a purchase, or an unselected stretch recovery.
- **Destructive:** the system destructive role, used for delete.

### Cards / Containers

- **Corner Style:** 16-point continuous corners.
- **Background:** card.
- **Shadow Strategy:** none. A 1-point ink hairline at 8% opacity. Selection replaces that hairline with a 2-point sea-glass stroke.
- **Internal Padding:** 12 points on a shelf card, 16 on a fact card.

### Inputs / Fields

- **Style:** system fields on the paper ground. Grouped form rows stay the platform's.
- **Color:** there is no hex field. A 44-point swatch shows the sampled color beside an optional color name.

### Navigation

- **Style:** a large title on the shelf, an inline title on a fabric and in a sheet. The bar is opaque cool paper, with the hairline removed. The tint is sea glass.

### Color sampler

The first photo is the color source. Take a photo is the first action. Choose a photo is the second. Tapping the cloth writes the stored color from a small neighborhood of pixels and moves a ring and a loupe to that spot. A new photo with no color yet starts at the center, so the ring is already there to correct. VoiceOver moves the sample through a small set of spots on the cloth.

### Shelf card

The face is the photo, or the sampled color when there is no photo. Sample, scrap, and used-up badges sit on the photo in sea glass. The name does not wrap past three lines. The amount sits on one line with the color dot.

## Do's and Don'ts

### Do:

- **Do** keep the ground on cool paper and the action on sea glass.
- **Do** let the fabric photo be the color of the card.
- **Do** keep names, amounts, and spacing aligned from card to card.
- **Do** use caution only when something the owner typed cannot be saved or a cut would pass zero.

### Don't:

- **Don't** use brown, kraft, camel, mud, dark wood, or a terracotta accent.
- **Don't** ask the owner to type or edit a hex code.
- **Don't** make a second photo the price of knowing the color when one photo is already on the fabric.
- **Don't** set fabric titles in a serif.
