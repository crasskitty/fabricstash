# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

A person who sews, at home, keeping track of cloth they already own. They open the app to see what is on the shelf, whether a piece will cover a pattern, and where that piece is stored. Confirmed by the app, the README, and the owner's brief.

## Product Purpose

Bolt & Bobbin is a private catalog of fabric on one iPhone or iPad. Success is a shelf the owner can scan, with photos, fiber, stretch, yardage, and a place for each piece, plus a check for whether they have enough and a record of what a project used.

## Positioning

The catalog stays on the device. There is no account. The owner identifies a color by photographing the cloth and tapping it, and the same photo is the fabric's photo.

## Operating Context

The owner stands at a shelf, bin, or cutting table with the cloth in hand. They photograph the fabric, tap the color, and file the piece. Later they search and filter, check yardage against a pattern, and deduct a cut. Lengths are stored in yards and widths in inches. The on-screen unit is one imperial or metric switch. Weight is stored as GSM.

## Capabilities and Constraints

- iOS 17, iPhone and iPad. Scheme FabricStash. Bundle id com.ashleyneale.fabricstash.
- Free shelf holds 25 fabrics. The unlock product id is com.ashleyneale.fabricstash.unlock.
- No account, no iCloud, no CloudKit, no analytics, no tracking.
- A fabric keeps a color name and a stored color value used by swatches, filters, and export. The owner does not type that value.
- The camera is the primary way to identify a color. Choosing an existing photo is second. One photo is both the fabric photo and the color source.
- Sample fabrics are invented and labeled as samples.

## Brand Commitments

The name is Bolt & Bobbin. The owner rejected Stash and FabricStash as the public name, and rejected the brown, kraft, camel, mud, and dark-wood look. The replacement is pretty, soothing, and organized: a calm paper ground, soft ink, and one gentle accent for actions and selection. Cloth photos carry the color. The chrome stays quiet. These constraints are pinned by the owner.

## Evidence on Hand

The iOS app in this repository, its tests, and the sample stash. A browser preview of the same shelf lives on the deploy-fabric branch and is updated with this work. It is not the App Store app. Do not invent customers, reviews, or prices beyond the StoreKit product the app already loads.

## Product Principles

- The shelf is the product: aligned, labeled, and scannable.
- The cloth shows its own color. The interface does not compete with it.
- Measurements stay honest: yards, inches, GSM, and a stretch test the phone does not pretend to perform.
- What is stored stays on the device.
- The free limit and the unlock id do not move.

## Accessibility & Inclusion

Dynamic Type, VoiceOver labels on swatches and the color sample, and light and dark appearances. Touch targets stay at least 44 points.
