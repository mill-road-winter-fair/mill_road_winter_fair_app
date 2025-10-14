import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define a GlobalKey for MapPageState:
final GlobalKey<MapPageState> mapPageKey = GlobalKey<MapPageState>();

class MapPage extends StatefulWidget {
  final List<Map<String, dynamic>> listings;

  const MapPage({required this.listings, super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late Future<List<Map<String, dynamic>>> _fetchListings;
  late List<MarkerId> _foodMarkerIds;
  late List<MarkerId> _stallsMarkerIds;
  late List<MarkerId> _musicMarkerIds;
  late List<MarkerId> _eventMarkerIds;
  late List<MarkerId> _serviceMarkerIds;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{}; // For displaying the map markers
  final Set<Polygon> _polygons = {}; // For displaying the road closure polygon
  final Set<Polyline> _polylines = {}; // For displaying the route polyline
  late PolylinePoints _polylinePoints; // For decoding points
  Map<String, BitmapDescriptor> bitmapDescriptors = <String, BitmapDescriptor>{}; // Cache of custom BitmapDescriptors to use as map markers
  late double _mapBearing;
  late MapType mapType;
  late double _compassBearing;
  double? mapWidth;
  double? mapHeight;
  bool _navigationInProgress = false;
  String? _distanceToDestination;
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination; // To store the destination
  GoogleMapController? _controller;
  IconData _layersIcon = Icons.satellite_alt;
  bool isRefreshing = false;
  // Declare default filters
  final Map<String, bool> filterSettings = {
    'Food': true,
    'Stalls': true,
    'Music': true,
    'Events': true,
    'Services': true,
    'Road Closures': true,
  };

  @override
  void initState() {
    _polylinePoints = PolylinePoints();
    _fetchListings = fetchExistingListings(http.Client());
    setMarkerLists();
    createAllMarkerBitmaps();
    addAllVisibleMarkers(false);
    establishLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _polygons.add(roadClosurePolygon());
      ListingUpdateNotifier.maybeShowNotice(context);
    });
    super.initState();
  }

  Polygon roadClosurePolygon() {
    final List<LatLng> roadClosurePolygonPoints = [];
    roadClosurePolygonPoints.add(const LatLng(52.20254075342824, 0.1313161749264791));
    roadClosurePolygonPoints.add(const LatLng(52.20261969633759, 0.1313917057314096));
    roadClosurePolygonPoints.add(const LatLng(52.20259993531283, 0.1314696026806805));
    roadClosurePolygonPoints.add(const LatLng(52.20254472546262, 0.1314868382234935));
    roadClosurePolygonPoints.add(const LatLng(52.20247521539894, 0.1315214213159033));
    roadClosurePolygonPoints.add(const LatLng(52.20242057061196, 0.1315902755530551));
    roadClosurePolygonPoints.add(const LatLng(52.20224829724565, 0.1319285462879982));
    roadClosurePolygonPoints.add(const LatLng(52.20206515174812, 0.1323119685512175));
    roadClosurePolygonPoints.add(const LatLng(52.20185454575378, 0.1328105159771198));
    roadClosurePolygonPoints.add(const LatLng(52.20169794827473, 0.1332139649556652));
    roadClosurePolygonPoints.add(const LatLng(52.20147130548498, 0.1337708793287029));
    roadClosurePolygonPoints.add(const LatLng(52.20136415018508, 0.1340418871246474));
    roadClosurePolygonPoints.add(const LatLng(52.20119386878824, 0.1344600952157449));
    roadClosurePolygonPoints.add(const LatLng(52.20105986696787, 0.1347909619929011));
    roadClosurePolygonPoints.add(const LatLng(52.20078307327081, 0.1354527002267703));
    roadClosurePolygonPoints.add(const LatLng(52.20059307205757, 0.1359319144668403));
    roadClosurePolygonPoints.add(const LatLng(52.20047144533613, 0.1362334969400547));
    roadClosurePolygonPoints.add(const LatLng(52.20042002748038, 0.1363648534791406));
    roadClosurePolygonPoints.add(const LatLng(52.20018013859927, 0.1369842213403394));
    roadClosurePolygonPoints.add(const LatLng(52.19992802896265, 0.137619157984521));
    roadClosurePolygonPoints.add(const LatLng(52.1998942621177, 0.1376702944366537));
    roadClosurePolygonPoints.add(const LatLng(52.19964688595894, 0.1382915317326394));
    roadClosurePolygonPoints.add(const LatLng(52.19964711095794, 0.1383343897296108));
    roadClosurePolygonPoints.add(const LatLng(52.19966434458279, 0.1383629065319103));
    roadClosurePolygonPoints.add(const LatLng(52.19991644851812, 0.1384755654593772));
    roadClosurePolygonPoints.add(const LatLng(52.19989499442656, 0.1385915691997508));
    roadClosurePolygonPoints.add(const LatLng(52.19961633363751, 0.1384609097835643));
    roadClosurePolygonPoints.add(const LatLng(52.19959794246539, 0.1384539683605679));
    roadClosurePolygonPoints.add(const LatLng(52.19958128075782, 0.138462512110995));
    roadClosurePolygonPoints.add(const LatLng(52.19936268096583, 0.139001083566388));
    roadClosurePolygonPoints.add(const LatLng(52.19925068322033, 0.1393415969931433));
    roadClosurePolygonPoints.add(const LatLng(52.19915029243788, 0.1396790081582111));
    roadClosurePolygonPoints.add(const LatLng(52.19915304223409, 0.1397328062307679));
    roadClosurePolygonPoints.add(const LatLng(52.19917372815736, 0.1397797533989809));
    roadClosurePolygonPoints.add(const LatLng(52.19920422685124, 0.1397980766405849));
    roadClosurePolygonPoints.add(const LatLng(52.19962825242047, 0.1400058055244591));
    roadClosurePolygonPoints.add(const LatLng(52.19960980763582, 0.1400868111723486));
    roadClosurePolygonPoints.add(const LatLng(52.19915274889104, 0.1398693308612087));
    roadClosurePolygonPoints.add(const LatLng(52.1990880149875, 0.1398497023452761));
    roadClosurePolygonPoints.add(const LatLng(52.19898645858462, 0.140119947874171));
    roadClosurePolygonPoints.add(const LatLng(52.19888724329584, 0.14041677591206));
    roadClosurePolygonPoints.add(const LatLng(52.1986459940194, 0.1412828244357156));
    roadClosurePolygonPoints.add(const LatLng(52.19837659539876, 0.142132318039756));
    roadClosurePolygonPoints.add(const LatLng(52.19812441088278, 0.1429262684985133));
    roadClosurePolygonPoints.add(const LatLng(52.19811731385359, 0.1429954103082509));
    roadClosurePolygonPoints.add(const LatLng(52.1981275922431, 0.1430432155143446));
    roadClosurePolygonPoints.add(const LatLng(52.19815571438149, 0.1430949739943865));
    roadClosurePolygonPoints.add(const LatLng(52.19826234282362, 0.1431454909271435));
    roadClosurePolygonPoints.add(const LatLng(52.1982434583722, 0.1432241773547172));
    roadClosurePolygonPoints.add(const LatLng(52.19810969460801, 0.1431637442912237));
    roadClosurePolygonPoints.add(const LatLng(52.19807545165644, 0.1431658850174999));
    roadClosurePolygonPoints.add(const LatLng(52.19805422045154, 0.1432030876326484));
    roadClosurePolygonPoints.add(const LatLng(52.19803071783669, 0.1433450646325451));
    roadClosurePolygonPoints.add(const LatLng(52.19796914354562, 0.1436074902625917));
    roadClosurePolygonPoints.add(const LatLng(52.19790884627964, 0.1438367890516878));
    roadClosurePolygonPoints.add(const LatLng(52.19788631317846, 0.1438561059436538));
    roadClosurePolygonPoints.add(const LatLng(52.1978040219425, 0.1441697262048347));
    roadClosurePolygonPoints.add(const LatLng(52.19765605892718, 0.1447442927807518));
    roadClosurePolygonPoints.add(const LatLng(52.19758755638483, 0.1450385439451662));
    roadClosurePolygonPoints.add(const LatLng(52.19758689021684, 0.1450696557603104));
    roadClosurePolygonPoints.add(const LatLng(52.1975998122105, 0.1450872540417025));
    roadClosurePolygonPoints.add(const LatLng(52.19799570793265, 0.1453358752914902));
    roadClosurePolygonPoints.add(const LatLng(52.19797597064566, 0.1454087762289968));
    roadClosurePolygonPoints.add(const LatLng(52.19757506685507, 0.1451602305086719));
    roadClosurePolygonPoints.add(const LatLng(52.19755851778755, 0.1451691386492771));
    roadClosurePolygonPoints.add(const LatLng(52.19754500840483, 0.145220203650005));
    roadClosurePolygonPoints.add(const LatLng(52.19737103810903, 0.1459022880004657));
    roadClosurePolygonPoints.add(const LatLng(52.19732261659738, 0.1460977442994715));
    roadClosurePolygonPoints.add(const LatLng(52.19726364790859, 0.1463828765038788));
    roadClosurePolygonPoints.add(const LatLng(52.19720963271546, 0.1469302933376015));
    roadClosurePolygonPoints.add(const LatLng(52.19720986236625, 0.1473793710918647));
    roadClosurePolygonPoints.add(const LatLng(52.19719063243967, 0.1481162334732367));
    roadClosurePolygonPoints.add(const LatLng(52.19711421122692, 0.1481142475993913));
    roadClosurePolygonPoints.add(const LatLng(52.19713060600797, 0.1480654658668779));
    roadClosurePolygonPoints.add(const LatLng(52.19715354547725, 0.1470462484979351));
    roadClosurePolygonPoints.add(const LatLng(52.19718227394962, 0.1464673101252134));
    roadClosurePolygonPoints.add(const LatLng(52.19719002612763, 0.1464047976490579));
    roadClosurePolygonPoints.add(const LatLng(52.19721207774649, 0.1462748309669415));
    roadClosurePolygonPoints.add(const LatLng(52.19730897788475, 0.145888257656559));
    roadClosurePolygonPoints.add(const LatLng(52.19750706859988, 0.1451305805813585));
    roadClosurePolygonPoints.add(const LatLng(52.19759549302326, 0.1447746431018881));
    roadClosurePolygonPoints.add(const LatLng(52.1977614993117, 0.1440459479841416));
    roadClosurePolygonPoints.add(const LatLng(52.19787216612334, 0.1435831594610981));
    roadClosurePolygonPoints.add(const LatLng(52.19798038717068, 0.1431823586482595));
    roadClosurePolygonPoints.add(const LatLng(52.19807598996824, 0.1428656173202336));
    roadClosurePolygonPoints.add(const LatLng(52.19831606164318, 0.1421049953934705));
    roadClosurePolygonPoints.add(const LatLng(52.19845271652396, 0.1416533510732676));
    roadClosurePolygonPoints.add(const LatLng(52.19858659494182, 0.1412275335745261));
    roadClosurePolygonPoints.add(const LatLng(52.19878921084049, 0.1405109847349828));
    roadClosurePolygonPoints.add(const LatLng(52.19885329134258, 0.1402749520777236));
    roadClosurePolygonPoints.add(const LatLng(52.19904417951687, 0.1397593322572432));
    roadClosurePolygonPoints.add(const LatLng(52.19915436740541, 0.1394476865068373));
    roadClosurePolygonPoints.add(const LatLng(52.199152578514, 0.1394123594948815));
    roadClosurePolygonPoints.add(const LatLng(52.19913944633698, 0.1393881002748887));
    roadClosurePolygonPoints.add(const LatLng(52.19909541242669, 0.1393638644906492));
    roadClosurePolygonPoints.add(const LatLng(52.1988953170878, 0.1392708513549157));
    roadClosurePolygonPoints.add(const LatLng(52.19891477648421, 0.1391821416309291));
    roadClosurePolygonPoints.add(const LatLng(52.19916768877469, 0.1393066098677265));
    roadClosurePolygonPoints.add(const LatLng(52.19918324255147, 0.1393120158838812));
    roadClosurePolygonPoints.add(const LatLng(52.19919760102836, 0.1393005303683226));
    roadClosurePolygonPoints.add(const LatLng(52.19935112329669, 0.1388685253014832));
    roadClosurePolygonPoints.add(const LatLng(52.19953377305441, 0.1384164873823668));
    roadClosurePolygonPoints.add(const LatLng(52.19953023932666, 0.1383671387347585));
    roadClosurePolygonPoints.add(const LatLng(52.19951091074621, 0.1383274168555326));
    roadClosurePolygonPoints.add(const LatLng(52.19944614106137, 0.1382779096752973));
    roadClosurePolygonPoints.add(const LatLng(52.19935725209026, 0.1382260585596362));
    roadClosurePolygonPoints.add(const LatLng(52.1993819049462, 0.1381217151270819));
    roadClosurePolygonPoints.add(const LatLng(52.19953121312004, 0.1382222959885016));
    roadClosurePolygonPoints.add(const LatLng(52.19955546718475, 0.1382391921114623));
    roadClosurePolygonPoints.add(const LatLng(52.1995840121499, 0.1382359618848561));
    roadClosurePolygonPoints.add(const LatLng(52.19961451164613, 0.1382090889037357));
    roadClosurePolygonPoints.add(const LatLng(52.20005497403874, 0.137112103157595));
    roadClosurePolygonPoints.add(const LatLng(52.20012235199115, 0.1369456911634703));
    roadClosurePolygonPoints.add(const LatLng(52.20012175705094, 0.1369219172034497));
    roadClosurePolygonPoints.add(const LatLng(52.20011173891284, 0.1369040800929011));
    roadClosurePolygonPoints.add(const LatLng(52.20000900168141, 0.1368321370880476));
    roadClosurePolygonPoints.add(const LatLng(52.19995612855457, 0.1367971860240846));
    roadClosurePolygonPoints.add(const LatLng(52.19998168361176, 0.1367115175541866));
    roadClosurePolygonPoints.add(const LatLng(52.20014142209268, 0.136821493087147));
    roadClosurePolygonPoints.add(const LatLng(52.20015408345555, 0.1368315859241731));
    roadClosurePolygonPoints.add(const LatLng(52.20016960807662, 0.1368240548983701));
    roadClosurePolygonPoints.add(const LatLng(52.20038957945103, 0.1362771436122312));
    roadClosurePolygonPoints.add(const LatLng(52.20063318539734, 0.1356663529471058));
    roadClosurePolygonPoints.add(const LatLng(52.20087929742714, 0.1350566628936023));
    roadClosurePolygonPoints.add(const LatLng(52.20112819302744, 0.1344290062785203));
    roadClosurePolygonPoints.add(const LatLng(52.20129519031239, 0.1340194079493262));
    roadClosurePolygonPoints.add(const LatLng(52.20155752956228, 0.1333647887500788));
    roadClosurePolygonPoints.add(const LatLng(52.20185035491883, 0.1326393421300831));
    roadClosurePolygonPoints.add(const LatLng(52.20193460965858, 0.1324246308459509));
    roadClosurePolygonPoints.add(const LatLng(52.20193458551557, 0.1323929748093788));
    roadClosurePolygonPoints.add(const LatLng(52.20192451692444, 0.1323602807654067));
    roadClosurePolygonPoints.add(const LatLng(52.20119167603609, 0.1317515302485717));
    roadClosurePolygonPoints.add(const LatLng(52.20121977519274, 0.1316760001745765));
    roadClosurePolygonPoints.add(const LatLng(52.20196202888421, 0.1322881483854976));
    roadClosurePolygonPoints.add(const LatLng(52.20198179514806, 0.1322871261675873));
    roadClosurePolygonPoints.add(const LatLng(52.20200369610616, 0.1322702463012826));
    roadClosurePolygonPoints.add(const LatLng(52.20235288220132, 0.1314451366674452));
    roadClosurePolygonPoints.add(const LatLng(52.20236944429304, 0.1313356944462396));
    roadClosurePolygonPoints.add(const LatLng(52.20236990511643, 0.1312660333110593));
    roadClosurePolygonPoints.add(const LatLng(52.20235773113411, 0.1311910912154102));
    roadClosurePolygonPoints.add(const LatLng(52.20237005557306, 0.1311545554749172));
    roadClosurePolygonPoints.add(const LatLng(52.20254075342824, 0.1313161749264791));

    return Polygon(
        polygonId: const PolygonId('roadClosure'),
        points: roadClosurePolygonPoints,
        strokeWidth: 6,
        strokeColor: Theme.of(context).colorScheme.tertiary,
        fillColor: Colors.transparent);
  }

  void updateRoadClosurePolygonVisibility(bool visibleState) {
    setState(() {
      switch (visibleState) {
        case true:
          _polygons.add(roadClosurePolygon());
          break;
        case false:
          _polygons.clear();
      }
    });
  }

  void updateMarkerVisibility(List<MarkerId> idList, bool visibleState) {
    setState(() {
      for (var id in idList) {
        final currentMarker = markers[id];
        if (currentMarker == null) continue;

        markers[id] = currentMarker.copyWith(
          visibleParam: visibleState,
        );
      }
    });
  }

  void setMarkerLists() {
    // Reset marker lists
    _foodMarkerIds = [];
    _stallsMarkerIds = [];
    _musicMarkerIds = [];
    _eventMarkerIds = [];
    _serviceMarkerIds = [];

    final allListings = listings as List;
    for (var listing in allListings) {
      // Assign markerIds to maps for filtering
      if (listing['primaryType'] == "Food" || listing['primaryType'] == "Group-Food") {
        _foodMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Shopping" || listing['primaryType'] == "Group-Shopping") {
        _stallsMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Music" || listing['primaryType'] == "Group-Music") {
        _musicMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Event" || listing['primaryType'] == "Group-Event") {
        _eventMarkerIds.add(MarkerId(listing['id'].toString()));
      } else if (listing['primaryType'] == "Service" || listing['primaryType'] == "Group-Service") {
        _serviceMarkerIds.add(MarkerId(listing['id'].toString()));
      }
    }
  }

  void addAllVisibleMarkers(bool onTest) {
    // Ensure the markers list is empty
    markers.clear();

    for (var listing in listings) {
      if (listing['visibleOnMap'] == 'TRUE') {
        // Add Group markers
        if (listing['primaryType'].startsWith('Group-')) {
          addGroupMarker(listing, onTest);
        }
        // Add Specific markers
        if (!listing['primaryType'].startsWith('Group-')) {
          addSpecificMarker(listing, onTest);
        }
      }
    }
  }

  Future<bool> createAllMarkerBitmaps() async {
    for (var listingType in 'Food, Shopping, Music, Event, Service, Group-Food, Group-Shopping, Group-Music, Group-Event, Group-Service'.split(', ')) {
      BitmapDescriptor newBitmapDescriptor = await getColoredMarker(listingType, getCategoryColor(selectedThemeKey, listingType));
      bitmapDescriptors[listingType] = newBitmapDescriptor;
    }
    if (bitmapDescriptors.isEmpty) {
      debugPrint('Error: created zero bitmap descriptors');
      return false;
    } else {
      return true;
    }
  }

  void addGroupMarker(listing, bool onTest) async {
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;

    if (onTest == false) {
      customMarker = await getColoredMarker(listing['primaryType'], color);
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = bitmapDescriptors[listing['primaryType']] ?? BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        establishLocation();

        // Helper to normalise primaryType by stripping "Group-" prefix if present
        String normalisePrimaryType(String type) {
          return type.startsWith("Group-") ? type.substring(6) : type;
        }

        // Filter listings where both normalised primaryType and secondaryType match
        List<Map<String, dynamic>> relatedListings = listings.where((l) {
          final listingPrimary = normalisePrimaryType(l['primaryType'] ?? '');
          final targetPrimary = normalisePrimaryType(listing['primaryType'] ?? '');
          final listingSecondary = l['secondaryType'] ?? '';
          final targetSecondary = listing['secondaryType'] ?? '';

          return listingPrimary == targetPrimary && listingSecondary == targetSecondary;
        }).toList();

        // Sort listings: Group first → startTime → displayName
        relatedListings.sort((a, b) {
          if (a['primaryType'].startsWith("Group") && !b['primaryType'].startsWith("Group")) {
            return -1;
          } else if (b['primaryType'].startsWith("Group") && !a['primaryType'].startsWith("Group")) {
            return 1;
          }

          final timeCompare = a['startTime'].compareTo(b['startTime']);
          if (timeCompare != 0) return timeCompare;

          return a['name'].compareTo(b['name']);
        });

        showModalBottomSheet(
          context: context,
          showDragHandle: false,
          enableDrag: false,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext context) {
            double screenHeight = MediaQuery.of(context).size.height;
            // Estimate the height of a SimplifiedListingInfoSheet in pixels
            double estimatedItemHeight = 145;
            // Estimate the total height of the bottom sheet
            double estimatedSheetHeight = relatedListings.length * estimatedItemHeight;
            // Set the minimum size of the modalBottomSheet based on either the estimatedSheetHeight or 2/3 of the screen, whichever is lower
            double minFraction = min((estimatedSheetHeight / screenHeight), 0.66);
            // Set the maximum size of the modalBottomSheet based on either the estimatedSheetHeight or the whole screen, whichever is lower
            double maxFraction = min((estimatedSheetHeight / screenHeight), 0.9);

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: minFraction,
              minChildSize: minFraction,
              maxChildSize: maxFraction,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: false,
                    thickness: 4,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      controller: scrollController,
                      separatorBuilder: (BuildContext context, int index) => Divider(color: Colors.grey[350]),
                      itemCount: relatedListings.length,
                      itemBuilder: (context, index) {
                        final rel = relatedListings[index];
                        int approximateDistanceMetres = asTheCrowFlies(
                          currentLatLng,
                          stringToLatLng(rel['latLng']),
                        );

                        if (rel['primaryType'].startsWith("Group")) {
                          return GroupListingInfoSheet(
                            title: rel['displayName'],
                            categories: "${rel['tertiaryType']}",
                            openingTimes: "${rel['startTime']} - ${rel['endTime']}",
                            approxDistance: 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}',
                          );
                        } else {
                          return SimplifiedListingInfoSheet(
                            title: rel['displayName'],
                            categories: "${rel['secondaryType']} • ${rel['tertiaryType']}",
                            openingTimes: "${rel['startTime']} - ${rel['endTime']}",
                            phoneNumber: rel['phone'],
                            website: rel['website'],
                            onGetDirections: () => getDirections(
                              rel['id'],
                              stringToLatLng(rel['latLng']),
                              true,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    setState(() {
      markers[markerId] = newMarker;
    });
  }

  void addSpecificMarker(listing, bool onTest) async {
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;
    if (onTest == false) {
      customMarker = await getColoredMarker(listing['primaryType'], color);
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = bitmapDescriptors[listing['primaryType']] ?? BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        HapticFeedback.lightImpact();
        // Update user's location
        establishLocation();
        int approximateDistanceMetres = asTheCrowFlies(currentLatLng, destinationLatLng);
        // Show bottom sheet with listing information
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return SpecificListingInfoSheet(
              title: listing['displayName'],
              categories: "${listing['secondaryType']} • ${listing['tertiaryType']}",
              openingTimes: "${listing['startTime']} - ${listing['endTime']}",
              approxDistance: 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}',
              phoneNumber: listing['phone'],
              website: listing['website'],
              onGetDirections: () => getDirections(listing['id'], destinationLatLng, true),
            );
          },
        );
      },
    );

    setState(() {
      markers[markerId] = newMarker;
    });
  }

  Future<void> updateMarkersAndPolygonsForTheme() async {
    // Recreate marker bitmaps for the new theme colors
    await createAllMarkerBitmaps();

    // Update each marker’s icon to the correct color for its type
    setState(() {
      markers.updateAll((id, oldMarker) {
        final listing = listings.firstWhere(
              (l) => l['id'].toString() == id.value,
          orElse: () => {},
        );
        if (listing.isEmpty) return oldMarker;

        final type = listing['primaryType'];
        final newIcon = bitmapDescriptors[type] ?? oldMarker.icon;

        return oldMarker.copyWith(iconParam: newIcon);
      });

      // Update polygon colour to match theme
      _polygons.clear();
      _polygons.add(roadClosurePolygon());
    });
  }

  void hideAllMarkers() {
    updateMarkerVisibility(_foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds, false);
  }

  void showAllMarkers() {
    updateMarkerVisibility(_foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds, true);
  }

  void showFilteredMarkers() {
    updateMarkerVisibility(_foodMarkerIds, filterSettings['Food']!);
    updateMarkerVisibility(_stallsMarkerIds, filterSettings['Stalls']!);
    updateMarkerVisibility(_musicMarkerIds, filterSettings['Music']!);
    updateMarkerVisibility(_eventMarkerIds, filterSettings['Events']!);
    updateMarkerVisibility(_serviceMarkerIds, filterSettings['Services']!);
  }

  void showFilterMenu() {
    showModalBottomSheet(
      scrollControlDisabledMaxHeightRatio: 0.8,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      "Filter Map Pins",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    )
                  ]),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Food'),
                    title: const Text("Food"),
                    value: filterSettings["Food"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Food"] = value!;
                      });
                      final idList = _foodMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Shopping'),
                    title: const Text("Stalls"),
                    value: filterSettings["Stalls"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Stalls"] = value!;
                      });
                      final idList = _stallsMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Music'),
                    title: const Text("Music"),
                    value: filterSettings["Music"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Music"] = value!;
                      });
                      final idList = _musicMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Event'),
                    title: const Text("Events"),
                    value: filterSettings["Events"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Events"] = value!;
                      });
                      final idList = _eventMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Service'),
                    title: const Text("Services"),
                    value: filterSettings["Services"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Services"] = value!;
                      });
                      final idList = _serviceMarkerIds;
                      updateMarkerVisibility(idList, value!);
                    },
                  ),
                  Divider(color: Colors.grey[350]),
                  CheckboxListTile(
                    activeColor: Theme.of(context).colorScheme.tertiary,
                    title: const Text("Road Closures"),
                    value: filterSettings["Road Closures"],
                    onChanged: (value) {
                      setState(() {
                        filterSettings["Road Closures"] = value!;
                      });
                      updateRoadClosurePolygonVisibility(value!);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            filterSettings.forEach((key, _) {
                              filterSettings[key] = true;
                            });
                          });
                          showAllMarkers();
                        },
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Show All'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            filterSettings.forEach((key, _) {
                              filterSettings[key] = false;
                            });
                          });
                          hideAllMarkers();
                        },
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Hide All'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> getDirections(String id, LatLng destination, bool navigatorPop) async {
    // Set navigation as in progress
    _navigationInProgress = true;

    // Pop the navigator if told to
    if (navigatorPop == true) {
      Navigator.pop(context);
    }

    // Clear any existing polylines and hide the markers
    setState(() {
      _polylines.clear();
      hideAllMarkers();
    });

    // If user has location tracking enabled
    if (currentLatLng != null) {
      // Get the user's current location
      Position position = await getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      await updatePolyline(currentLatLng, destination);
      // Set the camera position once, at the beginning of the navigation
      _setMapCameraToFitPolyline(_polylines);

      // Start location updates
      await startLocationUpdates(destination);
    } else {
      Fluttertoast.showToast(
        msg: 'Location services and permissions are required to determine directions',
        gravity: ToastGravity.CENTER,
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
        fontSize: 16,
        toastLength: Toast.LENGTH_LONG,
      );
    }

    // Add destination map marker
    Map<String, dynamic> destinationListing = listings.firstWhere((element) => element['id'] == id);
    addSpecificMarker(destinationListing, false);
  }

  void cancelNavigation() {
    // Halt the location subscription
    _positionStream?.cancel();

    // Clear the polylines
    _polylines.clear();

    // Reset the distance to destination
    _distanceToDestination = null;

    // Show markers which have enabled filters
    showFilteredMarkers();

    // Reset the camera position
    _setMapCameraToFitMapMarkers();

    // Set navigation as not in progress
    _navigationInProgress = false;
    setState(() {});
  }

  @override
  void dispose() {
    // Cancel the location subscription when the page is disposed
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> startLocationUpdates(LatLng destination) async {
    // Store the destination
    _destination = destination;

    // Start listening for location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((Position position) async {
      // Update the user's current location
      currentLatLng = LatLng(position.latitude, position.longitude);

      // If a destination is set, get new directions and update the polyline
      if (_destination != null) {
        await updatePolyline(currentLatLng!, _destination!);
      }
    });
  }

  Future<void> updatePolyline(LatLng origin, LatLng destination) async {
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      String googleMapsDirectionsApiKey = "";
      String androidSigningKey = dotenv.env['SIGNING_KEY'] ?? '';
      String iosBundleId = dotenv.env['IOS_BUNDLE_ID'] ?? '';

      // Define headers based on platform
      Map<String, String> headers;
      if (Platform.isAndroid) {
        googleMapsDirectionsApiKey = dotenv.env['ANDROID_GOOGLE_MAPS_DIRECTIONS_API_KEY'] ?? '';
        headers = {
          "X-Android-Package": "com.theberridge.mill_road_winter_fair_app",
          "X-Android-Cert": androidSigningKey,
        };
      } else if (Platform.isIOS) {
        googleMapsDirectionsApiKey = dotenv.env['IOS_GOOGLE_MAPS_DIRECTIONS_API_KEY'] ?? '';
        headers = {
          "X-Ios-Bundle-Identifier": iosBundleId,
        };
      } else {
        headers = {};
      }

      if (googleMapsDirectionsApiKey.isEmpty) {
        throw Exception("Google Maps Directions API key is missing.");
      }

      // Fetch new directions from the Google Directions API
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleMapsDirectionsApiKey,
        request: PolylineRequest(
          headers: headers,
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.walking,
        ),
      );

      if (result.points.isEmpty) {
        throw Exception("No route points returned from Google Directions API.");
      }

      setState(() {
        final distanceMetres = result.totalDistanceValue ?? 0;
        final dashSpace = (distanceMetres > 0 ? distanceMetres : 500) / 50;

        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: result.points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
            color: Theme.of(context).colorScheme.tertiary,
            width: 5,
            patterns: [PatternItem.dash(dashSpace), PatternItem.gap(dashSpace)],
          ),
        );

        _distanceToDestination = convertDistanceUnits(distanceMetres, preferredDistanceUnits);
      });
    } on SocketException catch (e) {
      debugPrint("Network error while fetching route: $e");
      _handlePolylineError("Network connection issue. Please try again.");
    } on HttpException catch (e) {
      debugPrint("HTTP error while fetching route: $e");
      _handlePolylineError("Server error retrieving route data.");
    } on FormatException catch (e) {
      debugPrint("Data format error: $e");
      _handlePolylineError("Unexpected data format from directions API.");
    } on Exception catch (e, stack) {
      debugPrint("Unexpected error fetching directions: $e\n$stack");
      _handlePolylineError("Failed to get route directions.");
    }
  }

  void _handlePolylineError(String message) {
    setState(() {
      _polylines.clear();
      _distanceToDestination = null;
      hideAllMarkers();
      addAllVisibleMarkers(false);
      _setMapCameraToFitMapMarkers();
      _navigationInProgress = false;
    });
    debugPrint(message);
    // Show a snackbar with the error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredMapOrientation', preferredMapOrientation.index);
    await prefs.setInt('preferredMapStyleType', preferredMapStyleType.index);
  }

  void _setMapCameraToFitMapMarkers() {
    // Set default LatLngs bounds
    // southwest
    double markerMinLat = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).latitude : 52.199174;
    double markerMinLong = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).longitude : 0.140929;
    // northeast
    double markerMaxLat = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).latitude : 52.199174;
    double markerMaxLong = listings.first.containsKey('latLng') ? stringToLatLng(listings.first['latLng']).longitude : 0.140929;

    if (listings.isNotEmpty) {
      for (var listing in listings) {
        LatLng markerLatLng = stringToLatLng(listing['latLng']);
        if (markerLatLng.latitude < markerMinLat) markerMinLat = markerLatLng.latitude;
        if (markerLatLng.latitude > markerMaxLat) markerMaxLat = markerLatLng.latitude;
        if (markerLatLng.longitude < markerMinLong) markerMinLong = markerLatLng.longitude;
        if (markerLatLng.longitude > markerMaxLong) markerMaxLong = markerLatLng.longitude;
      }
    }

    switch (preferredMapOrientation) {
      case MapOrientation.adaptive:
        const double westUpBearing = 290;
        final double westUpPadding = mapHeight! * 0.05;
        _moveCameraToBoundsWithRotation(LatLng(markerMinLat, markerMinLong), LatLng(markerMaxLat, markerMaxLong), westUpPadding, westUpBearing);
        break;
      case MapOrientation.alwaysNorth:
        const double northUpBearing = 0;
        double northUpPadding = mapWidth! * 0.05;
        _moveCameraToBoundsWithRotation(LatLng(markerMinLat, markerMinLong), LatLng(markerMaxLat, markerMaxLong), northUpPadding, northUpBearing);
        break;
    }
  }

  void _setMapCameraToFitPolyline(Set<Polyline> polylines) {
    double polylineMinLat = polylines.first.points.first.latitude;
    double polylineMinLong = polylines.first.points.first.longitude;
    double polylineMaxLat = polylines.first.points.first.latitude;
    double polylineMaxLong = polylines.first.points.first.longitude;

    for (var polyline in polylines) {
      for (var point in polyline.points) {
        if (point.latitude < polylineMinLat) polylineMinLat = point.latitude;
        if (point.latitude > polylineMaxLat) polylineMaxLat = point.latitude;
        if (point.longitude < polylineMinLong) polylineMinLong = point.longitude;
        if (point.longitude > polylineMaxLong) polylineMaxLong = point.longitude;
      }
    }

    const double northUpBearing = 0;
    double northUpPadding = mapWidth! * 0.07;
    _moveCameraToBoundsWithRotation(LatLng(polylineMinLat, polylineMinLong), LatLng(polylineMaxLat, polylineMaxLong), northUpPadding, northUpBearing);
  }

  _moveCameraToBoundsWithRotation(LatLng southwestMin, LatLng northeastMax, double padding, double rotation) {
    double theZoom;

    if (mapWidth != null && mapHeight != null) {
      theZoom = zoomForBounds(southwestMin, northeastMax, Size(mapWidth!, mapHeight!), padding: padding);
    } else {
      theZoom = 15;
      debugPrint('No map areas size found so using default zoom of $theZoom');
    }

    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: southwestMin,
          northeast: northeastMax,
        ),
        padding, // Padding around the bounds
      ),
    );
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng((southwestMin.latitude + northeastMax.latitude) / 2, (southwestMin.longitude + northeastMax.longitude) / 2),
          zoom: theZoom,
          bearing: rotation,
        ),
      ),
    );
  }

  double zoomForBounds(
    LatLng southwestMin,
    LatLng northeastMax,
    Size mapSize, {
    double padding = 0,
  }) {
    const worldDIM = 256.0;
    const zoomMax = 21.0;

    //Default bearing
    double bearing = 290;
    if (preferredMapOrientation == MapOrientation.alwaysNorth || _navigationInProgress == true) {
      bearing = 0;
    }

    // Convert to radians for trig functions
    final bearingRad = bearing * pi / 180.0;

    // Convert LatLng to Mercator (x, y)
    Offset latLngToPoint(LatLng latLng) {
      final siny = sin(latLng.latitude * pi / 180).clamp(-0.9999, 0.9999);
      final x = (latLng.longitude + 180) / 360;
      final y = 0.5 - log((1 + siny) / (1 - siny)) / (4 * pi);
      return Offset(x, y);
    }

    final sw = latLngToPoint(southwestMin);
    final ne = latLngToPoint(northeastMax);

    // Get center
    final center = Offset((sw.dx + ne.dx) / 2, (sw.dy + ne.dy) / 2);

    // Rotate both points around center by bearing
    Offset rotatePoint(Offset point, Offset center, double angle) {
      final translated = point - center;
      final xNew = translated.dx * cos(angle) - translated.dy * sin(angle);
      final yNew = translated.dx * sin(angle) + translated.dy * cos(angle);
      return Offset(xNew, yNew) + center;
    }

    final swRot = rotatePoint(sw, center, bearingRad);
    final neRot = rotatePoint(ne, center, bearingRad);

    // Determine rotated bounds
    final minX = min(swRot.dx, neRot.dx);
    final maxX = max(swRot.dx, neRot.dx);
    final minY = min(swRot.dy, neRot.dy);
    final maxY = max(swRot.dy, neRot.dy);

    final usableWidth = mapSize.width - 2 * padding;
    final usableHeight = mapSize.height - 2 * padding;

    if (usableWidth <= 0 || usableHeight <= 0) return 0;

    final worldWidth = maxX - minX;
    final worldHeight = maxY - minY;

    final zoomX = log(usableWidth / worldDIM / worldWidth) / ln2;
    final zoomY = log(usableHeight / worldDIM / worldHeight) / ln2;

    final zoom = min(zoomX, zoomY);
    return min(zoom, zoomMax);
  }

  Future<void> refreshListings() async {
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
      setMarkerLists();
      addAllVisibleMarkers(false);
      establishLocation();
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchListings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              textAlign: TextAlign.center,
              style: TextStyle(
                backgroundColor: Theme.of(context).colorScheme.error,
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          );
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Unable to retrieve listings",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                isRefreshing
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: refreshListings,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Listings'),
                      ),
              ],
            ),
          );
        }

        switch (preferredMapOrientation) {
          case MapOrientation.adaptive:
            _mapBearing = 290;
            _compassBearing = 90;
            break;
          case MapOrientation.alwaysNorth:
            _mapBearing = 0;
            _compassBearing = 0;
            break;
        }

        switch (preferredMapStyleType) {
          case MapStyleType.normal:
            mapType = MapType.normal;
            break;
          case MapStyleType.hybrid:
            mapType = MapType.hybrid;
            break;
        }

        return Scaffold(
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  mapWidth = constraints.maxWidth;
                  mapHeight = constraints.maxHeight;
                  return GoogleMap(
                    // TODO: Possible deprecation of styles in March 2025 (See: https://www.atlist.com/blog/json-map-styles-will-stop-working-march-2025)
                    style: mapStyle,
                    mapType: mapType,
                    rotateGesturesEnabled: false,
                    compassEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller;
                      if (listings.isNotEmpty) {
                        // We should have listings by this point so set the camera to their bounds
                        _setMapCameraToFitMapMarkers();
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: const LatLng(52.199174, 0.140929),
                      zoom: 14.1,
                      bearing: _mapBearing,
                    ),
                    onCameraMove: (CameraPosition position) {
                      setState(() {
                        switch (preferredMapOrientation) {
                          case MapOrientation.adaptive:
                            _compassBearing = 90;
                            break;
                          case MapOrientation.alwaysNorth:
                            _compassBearing = 0;
                            break;
                        }
                      });
                    },
                    polygons: _polygons,
                    markers: markers.values.toSet(),
                    polylines: _polylines,
                  );
                },
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_navigationInProgress == true)
                      FloatingActionButton(
                        heroTag: 'cancelBtn',
                        shape: const CircleBorder(),
                        mini: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          cancelNavigation();
                        },
                        child: Icon(
                          Icons.cancel,
                          size: 24,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    if (_navigationInProgress == false)
                      FloatingActionButton(
                        heroTag: 'homeBtn',
                        shape: const CircleBorder(),
                        mini: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Home button resets the filters if they're all toggled off
                          if (filterSettings['Food'] == false &&
                              filterSettings['Stalls'] == false &&
                              filterSettings['Music'] == false &&
                              filterSettings['Events'] == false &&
                              filterSettings['Services'] == false) {
                            final idList = _foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds;
                            setState(() {
                              filterSettings['Food'] = true;
                              filterSettings['Stalls'] = true;
                              filterSettings['Music'] = true;
                              filterSettings['Events'] = true;
                              filterSettings['Services'] = true;
                              updateMarkerVisibility(idList, true);
                            });
                          }
                          _setMapCameraToFitMapMarkers();
                        },
                        child: Icon(
                          Icons.home,
                          size: 24,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    FloatingActionButton(
                      heroTag: 'mapTypeBtn',
                      shape: const CircleBorder(),
                      mini: true,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (mapType == MapType.normal) {
                            mapType = MapType.hybrid;
                            _layersIcon = Icons.map;
                            preferredMapStyleType = MapStyleType.hybrid;
                            _saveSettings();
                          } else {
                            mapType = MapType.normal;
                            _layersIcon = Icons.satellite_alt;
                            preferredMapStyleType = MapStyleType.normal;
                            _saveSettings();
                          }
                        });
                      },
                      child: Icon(
                        _layersIcon,
                        size: 24,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    if (_navigationInProgress == false)
                      AnimatedRotation(
                        turns: _compassBearing / 360.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: FloatingActionButton(
                          heroTag: 'mapBearingBtn',
                          shape: const CircleBorder(),
                          mini: true,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              preferredMapOrientation =
                                  (preferredMapOrientation == MapOrientation.adaptive) ? MapOrientation.alwaysNorth : MapOrientation.adaptive;
                              _saveSettings();
                            });
                            _setMapCameraToFitMapMarkers();
                          },
                          child: const Icon(Icons.assistant_navigation),
                        ),
                      ),
                    if (_navigationInProgress == false)
                      Row(
                        children: [
                          if (_navigationInProgress == false)
                            IconButton.filled(
                              onPressed: () {
                                showFilterMenu();
                                setMarkerLists();
                              },
                              icon: Icon(
                                Icons.filter_alt,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_distanceToDestination != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FloatingActionButton.extended(
                      heroTag: 'navigationBtn',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _setMapCameraToFitPolyline(_polylines);
                      },
                      icon: const Icon(Icons.directions),
                      label: Text(
                        _distanceToDestination!,
                        style: TextStyle(fontSize: 24, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
