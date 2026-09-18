# Investigation: the `onTest` flag

Reviewed against main at `8ad6de7653ff5547cf9e8529d430d8e9ab1e574f` on 18 September 2026.

## Recommendation

Removing `onTest` is sensible and appears feasible, but deleting the flag and its branches alone is not a safe migration. Replace each workaround with controlled test dependencies or normal widget lifecycle handling, and then remove the flag. This PR records the investigation; it does not implement removal.

The problem is not using a boolean in itself. It is a mutable, application-wide switch that makes tests run different settings, marker-selection and UI behaviour from production. It can also leave tests within the same isolate dependent on previous tests' state.

## Why it was introduced

The Git history provides a fairly clear progression:

- [e7d9457, 20 November 2024](https://github.com/mill-road-winter-fair/mill_road_winter_fair_app/commit/e7d945724a8db358c0672631975c0b7a2e80a585) introduced `loadSettings(bool onTest)`. The false branch read SharedPreferences; the true branch assigned hard-coded settings. This directly establishes its original purpose as a settings-loading workaround. The commit does not record a precise exception, so a specific original plugin error cannot be established.
- [ea4f716, 24 October 2025](https://github.com/mill-road-winter-fair/mill_road_winter_fair_app/commit/ea4f7166063cb63457eba28fee399cb30d251db7), titled “Fixing tests, making onTest a global variable. Honestly I'm amazed that worked.”, replaced passed flags with a global and bypassed marker bitmap creation during map initialisation.
- [985b61e, 25 October 2025](https://github.com/mill-road-winter-fair/mill_road_winter_fair_app/commit/985b61ed5c8b4824196b7d16de8e149a953cd63c) added the default-marker early return in `getColoredMarker`. The current renderer also contains comments reporting that `getNextFrame()` stalled or failed without an error in tests.
- [0b4c125, 25 October 2025](https://github.com/mill-road-winter-fair/mill_road_winter_fair_app/commit/0b4c125794c2b06a15ec2b5462ca4d5894733cbe) disabled onboarding auto-scroll in tests.

Together, these changes show a practical response to persistence, image rendering and asynchronous UI difficulties. They do not establish that those difficulties still require a global switch.

## Current behaviour and replacements

| Location | Behaviour with `onTest = true` | Proposed replacement |
| --- | --- | --- |
| `lib/settings_page.dart: loadSettings` | Skips SharedPreferences and installs a separate set of defaults, including a light theme instead of production's auto theme. It also skips loading analytics consent and first-execution state. | Initialise the Flutter test binding, seed `SharedPreferences.setMockInitialValues` before loading settings, and run the real loader. Explicitly seed light theme in tests that require it. |
| `lib/map_page.dart: addAllVisibleMarkers` | Skips bitmap creation. | Supply a marker-rendering dependency with the real renderer as its default; map widget tests can supply deterministic descriptors. Keep normal marker assembly running. |
| `lib/map_page.dart: addGroupMarker, addSpecificMarker, addSimpleMarker` | Substitutes hue-based default markers for the normal descriptor-selection rules. | Exercise normal selection using the supplied descriptors, including group, mixed-category and missing-descriptor cases. |
| `lib/themes.dart: getColoredMarker` | Returns a default marker before image decoding and canvas rendering (but after loading the backdrop asset). | Test the real renderer separately. Try `tester.runAsync` for engine image operations; verify rendered PNG descriptors rather than just non-null results. If host rendering proves unsuitable, cover it in an integration test. |
| `lib/welcome_screen.dart` | Disables the 150-second auto-scroll and infinite scrolling. | Use bounded pumps, explicitly unmount the widget, and verify timer cancellation. Test a scroll by advancing virtual time. If necessary, expose an ordinary auto-scroll duration option while preserving the production default. |
| `lib/listings_may_change_reminder.dart: maybeShowNotice` | Returns immediately, suppressing notices and their persistence/analytics behaviour. | Use mock preferences and deterministic dates. Unrelated map tests can seed recent notice timestamps or dismiss the real dialog. Inject a clock at the caller if needed for deterministic date-dependent startup. |

The existing notice tests already set `onTest = false`, use mock preferences, display the real dialogs and check analytics. That is useful evidence that this part can be tested without the bypass.

The existing themes test named “getColoredMarker exercises multiple category branches” expects a default marker for every category while the flag is true. It does not verify the actual renderer. Removing the bypass should improve what this test proves, rather than merely changing its expected result.

## Suggested migration order and acceptance checks

1. Migrate settings fixtures to mock preferences. Verify both empty-store defaults and persisted settings, including consent and first execution. Reset preferences and relevant global state between tests.
2. Introduce the narrow marker-rendering dependency and update map fixtures. Check ordinary/group/mixed-category selection and separately verify real image rendering. Account for asynchronous completion and widget disposal.
3. Run onboarding with its normal timer behaviour. Verify a timed advance and explicit disposal without pending timers.
4. Remove the notice bypass after making startup notice handling deterministic. Preserve pre-Fair dismissal, Fair-day/post-Fair notices, throttling and analytics checks.
5. Delete the declaration and all assignments. Run `flutter analyze` and the full `flutter test` suite, then smoke-test maps and onboarding on a device.

Do not replace this with another global, an environment test detector, or several unrelated “is testing” flags: those retain the same divergence.

## Validation and limits

This is a source-and-history investigation. All current `onTest` references in `lib/` and `test/` were inspected, along with the introduction commits above. No production or test code is changed and no Flutter tests were run for this documentation-only PR. The proposed image-rendering and timer approaches still need execution-based validation during implementation; this report does not claim a completed or verified removal.
