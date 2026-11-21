# FabricStash

FabricStash is a local iOS catalog for a sewist's fabric. Publisher: Ashley Neale. Version 1 keeps the shelf on the device: no account, no CloudKit, no analytics, and no tracking.

The in-app name is the constant `AppIdentity.displayName` in `FabricStash/AppIdentity.swift`. The home-screen name is `CFBundleDisplayName` in `FabricStash/Info.plist` (also set as `INFOPLIST_KEY_CFBundleDisplayName` on the target). The Xcode project, scheme, and target are named FabricStash.

| | |
| --- | --- |
| Bundle id | `com.ashleyneale.fabricstash` |
| Unlock product id | `com.ashleyneale.fabricstash.unlock` |
| Minimum system | iOS 17 |
| Devices | iPhone and iPad |
| Store | SwiftData on the device only |

The unlock is a StoreKit 2 non-consumable. Its price is set in App Store Connect, not in code. The paywall shows `Product.displayPrice` from StoreKit. `FabricStash/Products.storekit` is only for local Xcode testing. The $4.99 in that file is a stand-in so the purchase sheet has a price in the simulator. It is not the App Store price.

The free shelf holds 25 fabrics at a time. Editing an existing fabric is always allowed. Deleting one frees a slot. `Transaction.currentEntitlements` decides whether the unlock is active.

Lengths are stored in yards and widths in inches. The screen converts when Settings is set to meters or centimeters (1 yard = 0.9144 m). Weight is stored as GSM. Ounces per square yard convert with GSM = oz/yd² × 33.906.

## Requirements

- A Mac with Xcode 16 or later, which includes the iOS 17 SDK
- An Apple Developer team for signing on a device

This repository was prepared on a machine without the iOS SDK. `xcodebuild` is not available here, so nothing in this repo has been compiled. Build and run it in Xcode before treating it as checked.

## Open it

1. Open `FabricStash.xcodeproj`.
2. Select the **FabricStash** scheme.
3. Select the **FabricStash** target, then **Signing & Capabilities**. Choose your team. Leave the bundle id as `com.ashleyneale.fabricstash`. Do not add iCloud or CloudKit.
4. Confirm the **FabricStashTests** target uses `com.ashleyneale.fabricstash.tests`.

Xcode 16 synchronized folders pick up new Swift files inside `FabricStash/` and `FabricStashTests/` without editing the project file. `Info.plist` and `Products.storekit` are excluded from the app target on purpose: the plist is the target's Info.plist, and the StoreKit file is selected by the scheme rather than copied into the app.

## Verify in Xcode

Do these on your Mac. This environment did not run them.

### Compile and sign

1. Product > Destination: an iPhone simulator (iOS 17 or later).
2. Product > Build (⌘B). The target that must compile is **FabricStash**, then **FabricStashTests** when you test.
3. Product > Test (⌘U). The test bundle is **FabricStashTests**. It covers yard/meter and GSM/oz conversion, yardage deduction (including the refusal when a cut would go below zero), "Do I have enough?" matching for bolts and scraps, and the 25-fabric free limit.
4. Change the destination to an iPad simulator and Product > Build again.
5. For a device: connect the iPhone, select it as the destination, set your team if Xcode asks, and Product > Run. The camera check needs a device. The simulator has no camera; the editor says so and still accepts the photo library.

### Scheme and the local purchase

1. Product > Scheme > Edit Scheme… (or ⌘<).
2. Select **Run**, then **Options**.
3. Set **StoreKit Configuration** to `FabricStash/Products.storekit`. The shared scheme already points at that file. If the menu is empty, choose the file on disk.
4. Close the scheme editor.

### Click through

Run the app and do each of these. The shelf starts empty.

1. Read the empty state. Tap **Load sample fabrics**. The samples are fictional, their names start with "Sample:", and a banner on each one says so. They count toward the free 25.
2. On iPhone, confirm the gallery is two columns. Open a swatch, go back, and open another. On iPad, confirm the list stays beside the detail and that the grid uses more than two columns when the column is wide.
3. Search for `gingham`, then `elastane`, then `stars`, then `Sample Knit`. Open **Filter** and limit by type, stretch, color, minimum yardage, and location. Clear the filters.
4. Tap **Do I have enough?** Enter a length and width the gingham can cover, and one it cannot. Confirm a covering fabric is listed under **Enough**, and a short one under **Close, but short** with the shortfall. Try a size the madder linen scrap can cover on its 18 by 22 inch piece, including turned the other way.
5. Open **Sample: Picnic Gingham**. Tap **Mark yardage used**, create a project inline, and deduct a cut that fits. Try a cut larger than what is left and confirm the app refuses it and leaves the yardage unchanged. Remove the cut and confirm the yardage returns.
6. Tap **Walk through a stretch test**. Read that the phone is not measuring anything. Enter a stretched length in centimeters, judge recovery, repeat lengthwise, and save 2-way, 4-way, or no stretch.
7. Tap **Edit fabric**. Add a photo from the library. If you are on a device, take one with the camera and allow the camera prompt. Reorder photos and delete one. Tap **Suggest a color from the first photo**, then accept or edit the name and hex. Change GSM and confirm ounces per square yard follow, and the other way around. Save.
8. Open **Locations** from the more menu. Add a bin, shelf, or room, rename it, reorder, and delete one. Fabrics should remain, without that place.
9. Open **Projects**. Confirm the sample tote and the cut you recorded. Delete a project only if you want its cuts put back on the cloth.
10. Open **Settings**. Switch length to meters and width to centimeters, then check a fabric's numbers changed on screen and that a new edit converts back into yards and inches. Switch back to yards and inches. Tap **Export CSV** and share the file. Confirm the row includes fiber, yardage in yards, width in inches, color, source, price, tags, and location.
11. Add fabrics until the shelf shows 25. Tap **Add fabric** again. The paywall should appear. Existing fabrics still open and save. Buy **Unlock** in the local StoreKit sheet (the test price, not the App Store price). Add another fabric. Delete one and confirm the count drops. Tap **Restore purchases**.
12. In Settings, tap **Remove sample fabrics**. The invented cloth, the sample project, and the empty sample places go away.
13. Turn on a larger Dynamic Type size and VoiceOver and read a swatch, a color chip, and the add button. Switch to Dark Mode and confirm the linen, card, ink, madder, and green colors stay readable.

There is no iCloud capability to turn on. Do not add a CloudKit entitlement for this version.
