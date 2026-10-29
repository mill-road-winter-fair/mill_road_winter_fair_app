# Mill Road Winter Fair App (2024)
An Android & iOS app for use by attendees of the 2024 Mill Road Winter Fair in Cambridge.

## Purpose
The app itself is a Flutter project which connects to a Google Sheet via an API. The API is a simple caching system which calls the Google Sheets API and caches the response, this API is managed in another repository. You can find the relevant links at the bottom of this document.

Currently the aim is for the app to provides listings of the various stalls, musical performances, events and services. The app also provides directions to each of these. 

### Developers
* Alexander Berridge (Android)
* Matt Whiting (iOS)

### Potential Future Development Ideas
- Development goals are currently listed [here](https://github.com/MarauderOne/mill_road_winter_fair_app/issues).

## Setting Up Your Local Environment

### Prerequisites

1. Install [Git for Windows](https://git-scm.com/downloads/win).

2. Clone this repository to your local environment using `git clone`.

3. Install [Flutter](https://flutter.dev/).

4. Install [Android Studio](https://developer.android.com/studio).

5. Create a virtual Android Phone.

6. Run `flutter pub get` to get all of the relevant dependencies listed in `pubsepc.yaml`. 

7. Copy `.env.example` to `.env` in the repository root and fill in the API settings for your platform. `.env` is ignored by Git. It contains app settings, never keystore passwords.

8. Request the testing/development API keys by emailing [app@millroadwinterfair.org](mailto:app@millroadwinterfair.org). Android developers must include their local debug signing certificate's SHA-1 fingerprint in the request. The Android API keys are restricted by package name and signing certificate fingerprint, so the maintainers need this fingerprint to update the API key restrictions before you can use the keys. Set `SIGNING_KEY` in `.env` to the same fingerprint.

9. Pass the same configuration file to Flutter from your terminal or IDE:
```shell
flutter run --dart-define-from-file=.env
```
In Android Studio, put `--dart-define-from-file=.env` in Additional run args. In VS Code, put it in `toolArgs` in your local `.vscode/launch.json`. No signing environment variables are needed. Local launch configurations are ignored by Git.

10. Create `android/app/google-services.json` by copying `android/app/google-services-dev.json`. Debug and profile builds automatically use the development Firebase project in Dart, so this keeps the native configuration aligned with it.

11. Run the app. Debug and profile builds use Android's debug signing configuration; you do not need a release keystore or `android/key.properties`.

### How configuration works

- `.env` is the source for app settings. `--dart-define-from-file=.env` passes those settings to the compiler; Dart reads them through `lib/app_config.dart`. Android Gradle reads the same defines for the native Maps SDK key only. The `.env` file is no longer packaged as an asset or loaded at runtime. Restart/rebuild after changing values; hot reload does not update compilation settings.
- Missing app settings default to empty strings (apart from the iOS bundle ID). Supply the API URL/key to fetch listings and the Maps keys to use maps/directions. Unit tests use mock clients and can run with `flutter test` without `.env` or release credentials.
- `SIGNING_KEY` is the public certificate SHA-1 fingerprint sent in the Google Directions `X-Android-Cert` header. It is not a release signing password. Use the certificate matching the installed app and configure your API key restrictions accordingly.
- `android/key.properties` is the single, build-only source for Android release signing, following [Flutter's signing guidance](https://docs.flutter.dev/deployment/android#reference-the-keystore-from-the-app). It is intentionally separate because these credentials must not be passed into Dart or packaged with the app. Shell and IDE `KEYSTORE_*` / `KEY_*` variables are no longer used.
- iOS native Maps configuration still uses the existing ignored `ios/Flutter/APIkeys.xcconfig` with `IOS_GOOGLE_MAPS_SDK_API_KEY`. Keep that value aligned with `.env`; the Android changes do not alter Xcode configuration. Firebase retains its platform configuration files and build-mode project selection.

### Run configurations and analytics

Shared run configurations are provided for Android Studio in `.run/` and VS Code in `.vscode/launch.json`. They correspond to these commands:

No analytics (the default development mode):

```shell
flutter run --dart-define-from-file=.env
```

Analytics sent to the development Firebase project (in Firebase debug mode):

```shell
flutter run --dart-define-from-file=.env --dart-define=DEV_ANALYTICS=true
```

Analytics sent to the production Firebase project:

```shell
flutter run --dart-define-from-file=.env --release
```

The matching configurations are named `MRWF: no analytics`, `MRWF: dev analytics` and `MRWF: production release`. The development-analytics configuration first enables Firebase Analytics DebugView for the app with `adb shell setprop debug.firebase.analytics.app com.theberridge.mill_road_winter_fair_app`. An analytics-free run does not initialise Firebase analytics and does not change the user's saved consent preference.

## In-app notifications

Set `HEROKU_NOTIFICATIONS_API` in `.env` to
`https://mrwf.theberridge.com/dev-notifications` for development, or
`https://mrwf.theberridge.com/notifications` for production. The app sends
`HEROKU_API_KEY` as the `x-api-key` header.

Both Google Sheets must have these exact headers (column order is flexible):

| Column | Required value                                                                    |
| --- |-----------------------------------------------------------------------------------|
| `id` | Unique permanent text ID, e.g. `2026-road-update-01`. **Never reuse an ID.**      |
| `title` | Short plain-text heading.                                                         |
| `body` | Plain-text message; **no HTML or Markdown**.                                      |
| `starts_at` | First eligible display time, ISO 8601 with timezone, e.g. `2026-12-05T10:00:00Z`. |
| `expires_at` | Exclusive expiry time in the same format; later than `starts_at`.                 |
| `enabled` | Google Sheets checkbox (`TRUE`/`FALSE`); only `TRUE` publishes a row.             |

Format date columns as plain text to preserve the timezone. Use `Z` for UTC or
an explicit offset such as `+01:00` for British Summer Time. The API must return
the same shape as the listings endpoint: `{"values":[["id","title","body","starts_at","expires_at","enabled"],["2026-road-update-01","Road update","Please use the next crossing.","2026-12-05T10:00:00Z","2026-12-05T12:00:00Z",true]]}`.
Missing/invalid fields, duplicate IDs, disabled rows, future rows and expired
rows are skipped. Messages also stop being eligible 24 hours after `starts_at`,
even if a later expiry is accidentally entered. Editing an existing ID does not
show it again; a deliberate new announcement needs a new ID.

After onboarding, the app checks on opening and every five minutes while in the
foreground. Resuming or restarting respects the saved next-check time. Failed
requests back off to 10, 20, 40 and then 60 minutes; numeric `Retry-After` headers
can extend that delay. Requests time out after 15 seconds. There is no background
polling, push delivery, sound or additional OS notification permission prompt.
Five minutes is an application policy, not an Apple/Google prescribed interval.
It follows their guidance to minimise networking and unnecessary background work:
[Apple energy guidance](https://developer.apple.com/documentation/xcode/reducing-networking-and-bluetooth-power-usage)
and [Android battery guidance](https://developer.android.com/develop/connectivity/preserving-battery).

The newest eligible unseen message appears as an accessible, scrollable,
dialog with an OK button at the bottom right. At most one message is presented
per poll. Once shown, a dialog remains until OK is tapped, including across
background/resume and expiry; outside taps and Back do not dismiss it. Expiry
is checked before presentation. Content is never cached on
the device, and failed/offline requests display nothing. The API's own cache
should refresh promptly and respect expiry; dates are also checked on-device.
Clock accuracy depends on the device clock.

Seen IDs are stored per endpoint before presentation, favouring no duplicates
over guaranteed delivery if the app closes at that exact moment. History survives
normal restarts and upgrades, but clearing app data/reinstalling may reset it.
Cross-device or reinstall-proof deduplication would require server-side identity.
Keep IDs permanent; do not repurpose old rows. Disabling a row takes effect at
the API and for subsequent presentation, rather than recalling a visible dialog.

The API key is bundled with this mobile app and can be extracted; use a scoped,
read-only key and server-side rate limiting, never an administrative credential.
Urgent delivery while the app is closed would require APNs/FCM push notifications.

## Google Cloud Platform
The app currently uses the Google Maps Platform within GCP in order to access the following API(s):
1. Maps SDK for Android (To render the interactive map on the app's homepage.)
2. Google Maps Directions API

## Android Release Steps

1. Increment the version number and build number in `pubspec.yaml`.

2. Run the tests with coverage. 

3. Add & commit the changes to Git and push to an MR.

4. Merge the MR into `main`.

5. Create a GitHub release titled with the version number, detail all of the changes made. 

6. Ensure that the contents of `android/app/google-services.json` match `android/app/google-services-prod.json`. Release builds automatically use the production Firebase project in Dart, so this keeps the native configuration aligned with it.

7. Release publishers only: copy `android/key.properties.example` to `android/key.properties` and fill in `storeFile`, `storePassword`, `keyAlias` and `keyPassword` for your existing upload keystore. Use an absolute path with forward slashes (also on Windows). Relative paths resolve from `android/`. Keep the keystore outside the repository. Both the properties file and keystores are ignored by Git. Do not put these values in `.env` or Dart defines.

   If setting up signing for a new app, create an upload keystore with:
```shell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
   For an existing Play app, use its existing upload key. Release builds fail with an actionable error if signing settings are missing; they never fall back to debug signing.

8. Run the following command in the terminal:
```shell
flutter build appbundle --release --dart-define-from-file=.env --dart-define=HEROKU_NOTIFICATIONS_API=https://mrwf.theberridge.com/notifications
```

9. Upload the following file to the Google Play Console as a new release: `/build/app/outputs/bundle/release/app-release.aab`

10. If required, add the following folder to a `.zip` file and upload it to the Release as a Debug Symbols artifact: `build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/x86_64`

## iOS Release Steps

1-5. Same steps as (and aligned with) Android 
    NB the build number has to have increased from the last one uploaded to Apple. 

6. Run
    flutter build ios --config-only --release --dart-define-from-file=.env
    
7. To get screen shots without 'DEBUG' (which Apple will reject) add this line to main.dart within MaterialApp() debugShowCheckedModeBanner:false
   Get screen shots at the largest iPhone and iPad sizes (latest 6.9" Pro Max and 13" Pro), then remove the above.
   
8. In Xcode, go to Product -> Archive, and you will eventually see a new build in the Organiser window

9. Click Distribute App, choose App Store Connect then click Distribute

10. In App Store Connect on the web, go to the app, then Distribution and click the + under iOS app

11. Fill in the version, add the screen shots, what's new etc., add the build, Save, then hit Add for Review, and wait for up to 48 hours

12. Back in Xcode organiser, right-click on the new build, click Show in Finder, and upload this file to the Github release


## Other Links
- [Mill Road Winter Fair Caching API](https://github.com/MarauderOne/mill_road_winter_fair_app_db_api)
- [Test Data Spreadsheet](https://docs.google.com/spreadsheets/d/1-Dk_K8tvDJ4C9vSx0OJSEYhvhGrt6IEkabVRP83n0OM/edit?usp=sharing)
- [Prod Data Spreadsheet](https://docs.google.com/spreadsheets/d/1hkx3d4eVw2roFIEDdrYkpT0wwHKBdx7YaZP8vc-Cg2o/edit?usp=sharing)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter online documentation](https://docs.flutter.dev/)
