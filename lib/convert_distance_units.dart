String convertDistanceUnits(int distanceMetres, String preferredDistanceUnits) {
  String distanceToDestination = "Distance conversion error";

  if (preferredDistanceUnits == "metric") {

    if (distanceMetres <= 999) {
      distanceToDestination = '$distanceMetres m';
    } else {
      final distanceKilometresRounded = (distanceMetres / 1000).toStringAsFixed(2);
      distanceToDestination = '$distanceKilometresRounded km';
    }

  } else if (preferredDistanceUnits == "imperial") {

    if (distanceMetres <= 161) {
      final distanceFeetRounded = (distanceMetres * 3.28084).toStringAsFixed(0);
      distanceToDestination = '$distanceFeetRounded ft';
    } else {
      final distanceMilesRounded = (distanceMetres / 1609.34).toStringAsFixed(2);
      distanceToDestination = '$distanceMilesRounded miles';
    }
  }

  return distanceToDestination;
}
