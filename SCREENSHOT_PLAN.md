# Screenshot plan — Bolt & Bobbin

Capture these on a **6.7-inch iPhone** simulator or device and on a **13-inch iPad** simulator or device. Use the same order and the same sample stash on both.

Apple requires real screenshots of the running app, from Simulator or from hardware. A designed mockup, a browser frame, or a cropped marketing render does not qualify. Upload the PNG files Simulator or the device writes.

This environment cannot make them. It is Linux, `xcodebuild` is not installed, and there is no iOS SDK. Checked 21 November 2026. Ashley captures them on her Mac after the app builds.

## Sizes

| Slot | Simulator to use | Pixels, portrait |
| --- | --- | --- |
| 6.7-inch iPhone | iPhone 15 Pro Max, or iPhone 14 Pro Max | 1290 × 2796 |
| 13-inch iPad | iPad Pro 13-inch | 2064 × 2752 |

A 6.9-inch capture (iPhone 16 Pro Max and later, 1320 × 2868) is a different App Store Connect slot. It does not fill the 6.7-inch slot. If Connect marks another iPad size as required when she uploads, she captures that size too. Start with these two.

Portrait only. Use the system status bar from the simulator. Do not draw a fake clock or a fake carrier.

## Captions

Captions are optional. If she burns a caption into the image, keep it under 30 characters, set it in the margin, and leave the sample data readable. The six captions below are already counted.

She can also upload the raw captures with no caption text.

## Order

Use this order on iPhone and on iPad. The first image is the gallery.

| # | Screen | Caption | Characters |
| --- | --- | --- | --- |
| 1 | Gallery | The cloth you already own | 25 |
| 2 | Fabric detail, with photos | Photos, fiber, and stretch | 26 |
| 3 | Stretch-test guide | Test the stretch | 16 |
| 4 | Search and filters | Search your shelves | 19 |
| 5 | Do I have enough? | Do I have enough? | 17 |
| 6 | Paywall | Free for 25 fabrics | 19 |

Six screenshots are enough. Ten is the App Store maximum. Do not add a title card or a splash screen as image 1.

## Sample stash that must be visible

Stage one stash and reuse it for every shot. Use cloth Ashley is allowed to photograph. The names below are labels for the sample rows, not a claim that any particular brand is in the binary.

Load these six, which is under the free cap, so the gallery shot is honest and the paywall shot is a separate state:

| Fabric | Amount | Fiber | Stretch | Location |
| --- | --- | --- | --- | --- |
| Indigo linen | 2.75 yd | 100% linen | None | Hall closet, top |
| Black ponte | 1.6 m | Ponte knit | 40% crosswise | Studio bin 2 |
| Rust lawn | 3 yd | 100% cotton | None | Drawer A |
| Olive twill | 1.25 yd | 100% cotton | None | Under the table |
| Cream viscose | 2 m | Viscose | Slight | Studio bin 2 |
| Navy shirting | 1.5 yd | Cotton | None | Hall closet, top |

Project used in shot 5: **Wide-leg trousers.**

- Indigo linen needs 2.5 yd. On hand: 2.75 yd. The screen should read as enough.
- Olive twill needs 2 yd. On hand: 1.25 yd. The screen should show the shortfall, 0.75 yd.

Show yards on the linen and meters on the ponte in the same stash, so both units are visible across the set.

## What each shot has to show

**1. Gallery.** The six fabrics as a grid or list, with a photo on each row, the name, and the amount (2.75 yd, 1.6 m, and the rest). Location text on at least two rows if the layout has room: Hall closet, top, and Studio bin 2.

**2. Fabric detail.** Open **Black ponte**. The photo is large enough to see the cloth. On the same screen: fiber (ponte knit), stretch (40% crosswise), amount (1.6 m), location (Studio bin 2). If the detail screen can also show a project line without hiding the photo, add “Wide-leg trousers” only on a fabric that still has its full amount in this shot. Do not show the deduction here if it makes the ponte amount look already reduced. Shot 5 carries the “enough” question.

**3. Stretch-test guide.** The guide itself, not another catalog row. A sewist should see that she is being told how to test stretch (crosswise, and what 40% means on the ponte). If the guide is a sheet over the ponte detail, that is the right screen. The words “stretch” and a concrete figure from the sample (40%) should be on screen.

**4. Search and filters.** Search text that narrows this sample, for example `linen` or `closet`, with Indigo linen still visible and the other rows filtered out. If filters are chips rather than a typed query, turn on a fiber or location filter that leaves a readable subset. The search field or the active filter must be visible. Do not photograph an empty result.

**5. Do I have enough?** Project name Wide-leg trousers. Both lines visible if the layout allows: indigo linen, 2.5 yd needed, enough; olive twill, 2 yd needed, short 0.75 yd. If only one result fits, show the olive twill shortfall. That is the sentence a sewist cares about in the shop.

If deducting yardage is a separate step from this check, take this shot before the deduction so the “on hand” numbers still match the table. Then, if she has a spare slot and the detail screen shows project history, an extra capture of indigo linen after a 2.5 yd deduction (0.25 yd left, labeled Wide-leg trousers) can be image 6, and the paywall moves to image 7. Only do that if the deduction is actually on screen. Do not fake the numbers in a caption.

**6. Paywall.** Show the free cap in the interface: 25 fabrics, then a one-time unlock. The button label should match the build. Restore Purchase should be visible, because reviewers look for it. Let the price be the price StoreKit returns. Do not paint “$6.99” into the screenshot by hand. $6.99 in `SUBMISSION.md` is a starting price she can change. If she sets a different price, the screenshot should show that price.

The paywall shot can be staged at the cap. It does not have to be the same six-row gallery as shot 1. Do not imply the six sample fabrics already require payment.

## iPhone and iPad

Take the full set twice. On the 13-inch iPad, use the iPad layout, not a blown-up iPhone window. Check that the gallery, the detail photo, and the paywall use the width instead of leaving a narrow phone column in a large empty page. That check is also in `SUBMISSION.md`.

## Before upload

- Status bar is the system bar, with no personal notifications.
- Sample names match across the set. Do not call it indigo linen in one shot and blue linen in the next.
- No debug banners, no placeholder “Lorem”, no empty photo boxes.
- No frame chrome from a design tool.
- File type PNG or JPEG, as App Store Connect accepts for that slot.
