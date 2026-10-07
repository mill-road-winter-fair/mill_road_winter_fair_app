// App settings supplied by --dart-define-from-file=.env at build time.
// Never put release keystore passwords in this file or in Dart defines.
abstract final class AppConfig {
  static const herokuApi = String.fromEnvironment('HEROKU_API');
  static const herokuApiKey = String.fromEnvironment('HEROKU_API_KEY');
  static const androidDirectionsApiKey =
      String.fromEnvironment('ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY');
  static const iosDirectionsApiKey =
      String.fromEnvironment('IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY');
  // Public certificate fingerprint for Google Maps request restrictions,
  // not the private key or password used to sign an Android release.
  static const androidCertificateFingerprint = String.fromEnvironment('SIGNING_KEY');
  static const iosBundleId = String.fromEnvironment(
    'IOS_BUNDLE_ID',
    defaultValue: 'com.theberridge.mill_road_winter_fair_app',
  );
}
