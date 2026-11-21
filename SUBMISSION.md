# Submitting FabricStash

Ashley publishes this herself, on her Mac, with her active Apple Developer membership and Xcode. The public name is **FabricStash**. Do these in order.

The listing text is in `APP_STORE_LISTING.md`. The screenshots are in `SCREENSHOT_PLAN.md`. The policy she must host is in `PRIVACY_POLICY.md`. The name check is in `NAME_CANDIDATES.md`.

This kit was prepared on a machine with no iOS SDK. `xcodebuild` was not installed, and no iPhone or iPad simulator was available (checked 21 November 2026). Nothing here was built, signed, or purchased. The last section is the list she has to verify on her Mac because of that.

Identifiers she must make match, in Xcode, in App Store Connect, and in the StoreKit product:

| Item | Value |
| --- | --- |
| App Store name and home-screen name | FabricStash |
| Bundle id | `com.ashleyneale.fabricstash` |
| Unlock product id | `com.ashleyneale.fabricstash.unlock` |
| Unlock type | Non-consumable, one time |
| Free cap | 25 fabrics |

If the project still says Stash, or the bundle id is still `com.ashleyneale.stash`, change it before she creates the App Store record. A bundle id and a product id cannot be quietly swapped after Apple has accepted them.

## 1. Open the project and set the team

1. Open the Xcode project (or the workspace, if the project has one) on her Mac.
2. Select the app target. Under **Signing & Capabilities**, set **Team** to her Apple Developer team. Leave **Automatically manage signing** on.
3. On the **General** tab, set **Display Name** to `FabricStash`, **Bundle Identifier** to `com.ashleyneale.fabricstash`, **Version** to `1.0`, and **Build** to `1`.
4. Confirm the target’s In-App Purchase capability is on. Do not add iCloud for version 1.
5. Search the project for `com.ashleyneale.stash` and for the product id. The purchase code must use `com.ashleyneale.fabricstash.unlock` and nothing else.
6. Let Xcode register the App ID, or register it herself at [developer.apple.com](https://developer.apple.com) → Identifiers → App IDs, explicit, `com.ashleyneale.fabricstash`. A successful signed build is the check that the team and the bundle id agree.

## 2. Create the App Store Connect record

Paid apps need a contract even when the download is free, because the unlock is a purchase.

1. In App Store Connect, open **Business** → **Agreements, Tax, and Banking**. Accept the Paid Applications agreement and finish banking and tax. Until that agreement is active, the unlock cannot be submitted for sale.
2. **Apps** → **New App**.
   - Platforms: iOS
   - Name: `FabricStash`
   - Primary language: English (U.S.)
   - Bundle ID: `com.ashleyneale.fabricstash` (it appears in the menu only after the App ID exists)
   - SKU: `fabricstash-ios` (any SKU she has not used; she cannot change it later)
   - User access: Full Access
3. Create version **1.0**. Paste the name, subtitle, promotional text, description, keywords, what’s new, category, age-rating answers, copyright line, and URLs from `APP_STORE_LISTING.md`.
4. The support URL, marketing URL, and privacy policy URL are still TODOs. Host them first. Fill in the contact email in `PRIVACY_POLICY.md` before that page goes public.

## 3. Create the non-consumable

1. In the app record, open **In-App Purchases** (or **Subscriptions** → **Non-Consumable**, depending on the current Connect sidebar) and create a purchase.
2. Type: **Non-Consumable**.
3. Reference name: `FabricStash Unlock`. This name is only for her in Connect.
4. Product ID: `com.ashleyneale.fabricstash.unlock`. Copy it. Apple will not let her edit it later, and it will not match the app if a single character differs.
5. Price is her decision. A reasonable starting point is **$6.99 USD**. Pick that price point, or another one, in Connect. She can change the price later without a new binary. $6.99 is a suggestion, not a requirement of this kit.
6. Add an English (U.S.) localization. Display name: `Full catalog`. Description: `One-time unlock for more than 25 fabrics.`
7. Add a review screenshot of the paywall once she has captured it (`SCREENSHOT_PLAN.md`, shot 6).
8. Attach this purchase to version 1.0 and clear it for sale.
9. Confirm the app’s own Restore Purchase button calls StoreKit restore. Apple expects that button on a non-consumable.

## 4. Test the purchase locally, then in sandbox

Local StoreKit test, on the simulator, before sandbox:

1. If the project has a StoreKit configuration file, select it in **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration**.
2. If it does not, create one with **File → New → File → StoreKit Configuration File**. Add a non-consumable whose product id is exactly `com.ashleyneale.fabricstash.unlock`.
3. Run the app. Buy the unlock. Confirm the cap lifts. Use **Debug → StoreKit → Manage Transactions** to refund or delete the local transaction, then tap **Restore Purchase** in the app and confirm the unlock returns.
4. Turn the StoreKit configuration file off in the scheme before a sandbox or archive build, or the app will keep talking to the local file instead of Apple.

Sandbox, on a device, after the product exists in Connect:

1. App Store Connect → **Users and Access → Sandbox → Testers**. Create a sandbox tester. Use an email that is not already an Apple Account.
2. On the iPhone, sign into that tester under the sandbox account setting (Settings → App Store → Sandbox Account, or Settings → Developer → Sandbox Apple Account, depending on the iOS version). Do not sign that tester into iCloud.
3. Install a build that is using the App Store product, not the local StoreKit file. Buy the unlock. Delete the app, reinstall it, and tap Restore Purchase. The unlock should come back without a second charge.

## 5. Privacy manifest and nutrition labels

1. The app target needs `PrivacyInfo.xcprivacy` in the bundle that gets archived.
2. For this version the manifest should say tracking is off, the tracking-domain list is empty, and collected data types are empty.
3. Required-reason API entries belong in that file only for APIs the binary actually calls, each with an Apple reason code. Open the file and compare it to the code. This kit could not compile the app, so that comparison is hers.
4. In App Store Connect, open **App Privacy** and publish the answers from `APP_STORE_LISTING.md`: **Data Not Collected**, and data **not used to track**.
5. Those answers and the hosted privacy policy have to say the same thing.

## 6. Archive, upload, screenshots, and review notes

1. In Xcode, set the run destination to **Any iOS Device (arm64)**, not a simulator.
2. **Product → Archive**. When it finishes, **Distribute App → App Store Connect → Upload**.
3. Wait until the build finishes processing and select it on version 1.0.
4. Export compliance: if the app’s only encryption is the HTTPS already in Apple’s operating system, answer that it does not use non-exempt encryption. Confirm that against the binary. If it is true, `ITSAppUsesNonExemptEncryption` = `NO` in Info.plist stops the question on later uploads.
5. Capture screenshots with the plan in `SCREENSHOT_PLAN.md` and upload the 6.7-inch iPhone set and the 13-inch iPad set. They have to be Simulator or device captures. This repo does not contain them.
6. Paste the review notes from `APP_STORE_LISTING.md` into **App Review Information**. Leave the username and password empty.
7. Finish the age-rating questionnaire with the “none” answers in the listing file. Copyright: `© 2026 Ashley Neale`.
8. Use her own photos in the sample stash and in the screenshots.
9. Submit version 1.0 with the unlock attached.

## 7. What she must verify herself

This environment had no iOS SDK, so none of the following was run here. On her Mac, before she submits:

- The project builds and launches.
- Display name is FabricStash, bundle id is `com.ashleyneale.fabricstash`, and a search of the project finds no leftover `com.ashleyneale.stash`.
- The purchase product id in code is `com.ashleyneale.fabricstash.unlock`.
- The camera permission prompt appears, and the purpose string says why a sewing catalog wants the camera.
- The photo picker opens and a chosen photo stays on the fabric.
- Color suggestion behaves the way the build intends, on a real photo.
- The stretch-test guide matches shot 3 of the screenshot plan.
- Search, filters, “Do I have enough?”, and a project deduction all change the on-screen yardage in yards and in meters.
- The free cap stops at 25 fabrics.
- Purchase and restore both work, first against the local StoreKit file and then against a sandbox tester.
- CSV export opens the system share sheet and the file contains the catalog.
- The 13-inch iPad layout uses the iPad width for the gallery, the fabric detail, and the paywall.
- The sample stash described in the review notes is actually in the build she uploads. If it is not, change the review notes.
- Version 1 has no iCloud sync control and no account screen.
