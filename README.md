# Mill Road Winter Fair App
An Android & iOS app for use by attendees of the Mill Road Winter Fair in Cambridge.

## Purpose
The app itself is a Flutter project which connects to a spreadsheet via the Google Sheets API, you can find the relevant links at the bottom of this document.

Currently the aim is for the app to provides listings of the various stalls, musical performances, events and services. The app also provides directions to each of these. 

### Potential Future Development Ideas
- Development goals are currently listed [here](https://github.com/MarauderOne/mill_road_winter_fair_app/issues).

## Setting Up Your Local Environment

### Prerequisites

1. When running the app locally it calls your local instance of the Mill Road Winter Fair App DB & API, so make sure you have set this up first.

2. Install [Git for Windows](https://git-scm.com/downloads/win).

3. Clone this repository to your local environment using `git clone`.

4. Install [Flutter](https://flutter.dev/).

5. Install [Android Studio](https://developer.android.com/studio).

6. Create a virtual Android Phone.

7. Run `flutter pub get` to get all of the relevant dependencies listed in `pubsepc.yaml`. 

8. Create a `.env` file containing the following:
```txt
GOOGLE_MAPS_AND_SHEETS_API_KEY=\\Google Maps Platform API key
GOOGLE_SHEET_ID=1-Dk_K8tvDJ4C9vSx0OJSEYhvhGrt6IEkabVRP83n0OM
GOOGLE_SHEET_RANGE=A1:L200
```

9. Ensure that your run target for `main.dart` is using the following arg(s):
```txt
--dart-define-from-file=.env
```

10. Create a keystore (to manage signing keys), by using the below command. This will prompt you to enter a keystore password, your name, organisation and location details.
```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

11. Move the generated `.jks` keystore file to a secure location outside of the repository.  

12. Ensure that your run target for `main.dart` is using the following environment variables. The values should correspond to what you entered when you configured your keystore.
```txt
KEYSTORE_FILE=\\The path to your keystore file
KEYSTORE_PASSWORD=\\The password you set when generating the keystore
KEY_ALIAS=upload
KEY_PASSWORD=\\The password you set when generating the keystore
```

13. You should now have everything you need to run the app locally.

## Google Cloud Platform
The app currently uses the the Google Maps Platform within GCP in order to access the following API(s):
1. Maps SDK for Android (To render the interactive map on the app's homepage.)
2. Google Maps Directions API

## Other Links
- [Test Data Spreadsheet](https://docs.google.com/spreadsheets/d/1-Dk_K8tvDJ4C9vSx0OJSEYhvhGrt6IEkabVRP83n0OM/edit?usp=sharing)
- [Prod Data Spreadsheet](https://docs.google.com/spreadsheets/d/1hkx3d4eVw2roFIEDdrYkpT0wwHKBdx7YaZP8vc-Cg2o/edit?usp=sharing)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter online documentation](https://docs.flutter.dev/)
