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

8. Pass the same configuration file to Flutter from your terminal or IDE:
```shell
flutter run --dart-define-from-file=.env
```
In Android Studio, put `--dart-define-from-file=.env` in Additional run args. In VS Code, put it in `toolArgs` in your local `.vscode/launch.json`. No signing environment variables are needed. Local launch configurations are ignored by Git.

9. Create `android/app/google-services.json` by copying `android/app/google-services-dev.json`. Debug and profile builds automatically use the development Firebase project in Dart, so this keeps the native configuration aligned with it.

10. Run the app. Debug and profile builds use Android's debug signing configuration; you do not need a release keystore or `android/key.properties`.

### How configuration works

- `.env` is the source for app settings. `--dart-define-from-file=.env` passes those settings to the compiler; Dart reads them through `lib/app_config.dart`. Android Gradle reads the same defines for the native Maps SDK key only. The `.env` file is no longer packaged as an asset or loaded at runtime. Restart/rebuild after changing values; hot reload does not update compilation settings.
- Missing app settings default to empty strings (apart from the iOS bundle ID). Supply the API URL/key to fetch listings and the Maps keys to use maps/directions. Unit tests use mock clients and can run with `flutter test` without `.env` or release credentials.
- `SIGNING_KEY` is the public certificate SHA-1 fingerprint sent in the Google Directions `X-Android-Cert` header. It is not a release signing password. Use the certificate matching the installed app and configure your API key restrictions accordingly.
- `android/key.properties` is the single, build-only source for Android release signing, following [Flutter's signing guidance](https://docs.flutter.dev/deployment/android#reference-the-keystore-from-the-app). It is intentionally separate because these credentials must not be passed into Dart or packaged with the app. Shell and IDE `KEYSTORE_*` / `KEY_*` variables are no longer used.
- iOS native Maps configuration still uses the existing ignored `ios/Flutter/APIkeys.xcconfig` with `IOS_GOOGLE_MAPS_SDK_API_KEY`. Keep that value aligned with `.env`; the Android changes do not alter Xcode configuration. Firebase retains its platform configuration files and build-mode project selection.

## Google Cloud Platform
The app currently uses the the Google Maps Platform within GCP in order to access the following API(s):
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
flutter build appbundle --release --dart-define-from-file=.env
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
