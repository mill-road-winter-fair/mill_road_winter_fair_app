import 'package:url_launcher/url_launcher.dart' as url_launcher;

// External links used by behaviourally tested contact and navigation actions
abstract interface class UrlLauncher {
  Future<bool> canOpen(Uri uri);
  Future<bool> open(Uri uri);
}

final class SystemUrlLauncher implements UrlLauncher {
  const SystemUrlLauncher();

  @override
  Future<bool> canOpen(Uri uri) => url_launcher.canLaunchUrl(uri);

  @override
  Future<bool> open(Uri uri) => url_launcher.launchUrl(uri);
}
