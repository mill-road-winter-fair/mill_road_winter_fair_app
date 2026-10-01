import 'package:mill_road_winter_fair_app/dependencies/launch_url_provider.dart';

// A fake implementation of launchUrl() for testing purposes
final class FakeUrlLauncher implements UrlLauncher {
  FakeUrlLauncher({this.canOpenResult = true, this.openResult = true});

  bool canOpenResult;
  bool openResult;
  final checkedUris = <Uri>[];
  final openedUris = <Uri>[];

  @override
  Future<bool> canOpen(Uri uri) async {
    checkedUris.add(uri);
    return canOpenResult;
  }

  @override
  Future<bool> open(Uri uri) async {
    openedUris.add(uri);
    return openResult;
  }
}
