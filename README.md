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

7. Create a `.env` file containing the following:
```txt
HEROKU_API=https://mrwf.theberridge.com/listings
ANDROID_GOOGLE_MAPS_SDK_API_KEY=\\API Key for Google Maps SDK for Android
ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY=\\API Key for Google Maps Directions API for Android
IOS_GOOGLE_MAPS_SDK_API_KEY=\\API Key for Google Maps SDK for iOS
IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY=\\API Key for Google Maps Directions API for iOS
SIGNING_KEY=\\Signing key for the app
IOS_BUNDLE_ID=com.theberridge.mill_road_winter_fair_app
```

8. Ensure that your run target for `main.dart` is using the following arg(s):
```txt
--dart-define-from-file=.env
```

9. Create a keystore (to manage signing keys), by using the below command. This will prompt you to enter a keystore password, your name, organisation and location details.
```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

10. Move the generated `.jks` keystore file to a secure location outside of the repository.  

11. Ensure that your run target for `main.dart` is using the following environment variables. The values should correspond to what you entered when you configured your keystore.
```txt
KEYSTORE_FILE=\\The path to your keystore file
KEYSTORE_PASSWORD=\\The password you set when generating the keystore
KEY_ALIAS=upload
KEY_PASSWORD=\\The password you set when generating the keystore
```

12. You should now have everything you need to run the app locally.

## Google Cloud Platform
The app currently uses the the Google Maps Platform within GCP in order to access the following API(s):
1. Maps SDK for Android (To render the interactive map on the app's homepage.)
2. Google Maps Directions API

## Android Release Steps

1. Increment the version number and build number in `pubspec.yaml`.

2. Run the tests with coverage. 

3. Add & commit the changes to Git and push to an MR.

4. Merge the MR into `main`.

5. Create a release titled with the version number, detail all of the changes made. 

6. Set environment variables for the signing key store.
```shell
$env:KEYSTORE_FILE='C:\Users\alexb\Development\google_play_keystore\upload-keystore.jks'
$env:KEYSTORE_PASSWORD=REDACTED
$env:KEY_ALIAS='upload'
$env:KEY_PASSWORD=REDACTED
```

7. Run the following command in the terminal:
```shell
flutter build appbundle --release --dart-define-from-file=.env
```

8. Upload the following file to the Google Play Console as a new release: `/build/app/outputs/bundle/release/app-release.aab`

9. If required, add the following folder to a `.zip` file and upload it to the Release as a Debug Symbols artifact: `build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/x86_64`

## Other Links
- [Mill Road Winter Fair Caching API](https://github.com/MarauderOne/mill_road_winter_fair_app_db_api)
- [Test Data Spreadsheet](https://docs.google.com/spreadsheets/d/1-Dk_K8tvDJ4C9vSx0OJSEYhvhGrt6IEkabVRP83n0OM/edit?usp=sharing)
- [Prod Data Spreadsheet](https://docs.google.com/spreadsheets/d/1hkx3d4eVw2roFIEDdrYkpT0wwHKBdx7YaZP8vc-Cg2o/edit?usp=sharing)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter online documentation](https://docs.flutter.dev/)
