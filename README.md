# Mill Road Winter Fair App
An Android & iOS app for use by attendees of the Mill Road Winter Fair in Cambridge.

## Purpose
The app itself is a Flutter project which connects to external database via an API, you can find the relevant links at the bottom of this document.

Currently the aim is for the app to provides listings of the various stalls, musical performances, events and services. The app also provides directions to each of these. 

### Potential Future Development Ideas
- TBD

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
GOOGLE_MAPS_API_KEY=\\Google Maps Platform API key
```

9. Ensure that your run target for `main.dart` is using the following arg(s):
```txt
--dart-define-from-file=.env
```

10. You should now have everything you need to run the app locally.

## Google Cloud Platform
The app currently uses the the Google Maps Platform within GCP in order to access two APIs:
1. Geocoding API (To converts Google Maps Plus Codes into Lat/Long coordinates.)
2. Maps SDK for Android (To render the interactive map on the app's homepage.)

## Other Links
- [Mill Road Winter Fair App DB & API](https://github.com/MarauderOne/mill_road_winter_fair_app_db_api) (the app's "backend")
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter online documentation](https://docs.flutter.dev/)
