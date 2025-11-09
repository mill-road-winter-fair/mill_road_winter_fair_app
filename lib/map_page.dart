import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mill_road_winter_fair_app/as_the_crow_flies.dart';
import 'package:mill_road_winter_fair_app/convert_distance_units.dart';
import 'package:mill_road_winter_fair_app/get_current_location.dart';
import 'package:mill_road_winter_fair_app/listings.dart';
import 'package:mill_road_winter_fair_app/listings_info_sheets.dart';
import 'package:mill_road_winter_fair_app/listings_may_change_reminder.dart';
import 'package:mill_road_winter_fair_app/main.dart';
import 'package:mill_road_winter_fair_app/settings_page.dart';
import 'package:mill_road_winter_fair_app/string_to_latlng.dart';
import 'package:mill_road_winter_fair_app/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Define a GlobalKey for MapPageState:
final GlobalKey<MapPageState> mapPageKey = GlobalKey<MapPageState>();

// Indicator for a simple map marker
const String aSimpleMarkerId = 'SIMPLE';

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
  final Set<Polyline> polylines = {}; // For displaying the route polyline
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
  final ScrollController _roadClosuresDialogScrollController = ScrollController();
  // Declare default filters
  final Map<String, bool> filterSettings = {
    'Food': true,
    'Stalls': true,
    'Music': true,
    'Events': true,
    'Services': true,
    'Road Closures': true,
  };
  late List<bool> detailsVisibilityList; // for modal bottom sheet group listings

  @override
  void initState() {
    debugPrint('MapPageState initState() called');
    _polylinePoints = PolylinePoints();
    _fetchListings = fetchExistingListings(http.Client());
    setMarkerLists();
    addAllVisibleMarkers();
    establishLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _polygons.add(roadClosurePolygon());
      ListingUpdateNotifier.maybeShowNotice(context);
    });
    super.initState();
  }

  Polygon roadClosurePolygon() {
    final List<LatLng> roadClosurePolygonPoints = [];
    roadClosurePolygonPoints.add(const LatLng(52.20235281420999, 0.1310619082596975));
    roadClosurePolygonPoints.add(const LatLng(52.20231516801594, 0.1311597848998902));
    roadClosurePolygonPoints.add(const LatLng(52.20234751634417, 0.1312922180728582));
    roadClosurePolygonPoints.add(const LatLng(52.20233631517088, 0.1314355240724652));
    roadClosurePolygonPoints.add(const LatLng(52.20200908093806, 0.1322005128635384));
    roadClosurePolygonPoints.add(const LatLng(52.20197859926515, 0.1322488316534076));
    roadClosurePolygonPoints.add(const LatLng(52.2019422735798, 0.1322292934474145));
    roadClosurePolygonPoints.add(const LatLng(52.2012105622847, 0.1316364880114951));
    roadClosurePolygonPoints.add(const LatLng(52.20117278129067, 0.1317673350512383));
    roadClosurePolygonPoints.add(const LatLng(52.20190848239522, 0.1323816884898998));
    roadClosurePolygonPoints.add(const LatLng(52.20191780047099, 0.1324033494486065));
    roadClosurePolygonPoints.add(const LatLng(52.20191206154605, 0.1324377833024948));
    roadClosurePolygonPoints.add(const LatLng(52.20180722003214, 0.1326842889403568));
    roadClosurePolygonPoints.add(const LatLng(52.20154108514724, 0.1333489959015899));
    roadClosurePolygonPoints.add(const LatLng(52.20124796928181, 0.1340602671079827));
    roadClosurePolygonPoints.add(const LatLng(52.2009753675207, 0.1347188867023652));
    roadClosurePolygonPoints.add(const LatLng(52.20078759974723, 0.1351815253610478));
    roadClosurePolygonPoints.add(const LatLng(52.20060350929509, 0.1356303405175474));
    roadClosurePolygonPoints.add(const LatLng(52.20033257981164, 0.1363163764622999));
    roadClosurePolygonPoints.add(const LatLng(52.20016584154403, 0.1367620437365646));
    roadClosurePolygonPoints.add(const LatLng(52.20014486316023, 0.1367911433027813));
    roadClosurePolygonPoints.add(const LatLng(52.2001218686615, 0.1367779005334402));
    roadClosurePolygonPoints.add(const LatLng(52.19998306812768, 0.1366803857699761));
    roadClosurePolygonPoints.add(const LatLng(52.19995058464553, 0.136812478115258));
    roadClosurePolygonPoints.add(const LatLng(52.20007112413746, 0.1368946557236161));
    roadClosurePolygonPoints.add(const LatLng(52.20008936448654, 0.1369210598442261));
    roadClosurePolygonPoints.add(const LatLng(52.20007929576207, 0.1369620891686041));
    roadClosurePolygonPoints.add(const LatLng(52.20000944413438, 0.1371278011066357));
    roadClosurePolygonPoints.add(const LatLng(52.19960936113254, 0.1381715386581228));
    roadClosurePolygonPoints.add(const LatLng(52.1995865061542, 0.1381953576575357));
    roadClosurePolygonPoints.add(const LatLng(52.19955963533969, 0.1381996076168601));
    roadClosurePolygonPoints.add(const LatLng(52.19938594800258, 0.1380926323613463));
    roadClosurePolygonPoints.add(const LatLng(52.19934316751451, 0.1382500101117978));
    roadClosurePolygonPoints.add(const LatLng(52.1995022352211, 0.1383479669667653));
    roadClosurePolygonPoints.add(const LatLng(52.19951582917572, 0.1383766977703216));
    roadClosurePolygonPoints.add(const LatLng(52.1995114294751, 0.1384144685687305));
    roadClosurePolygonPoints.add(const LatLng(52.19939091995906, 0.1386707785667762));
    roadClosurePolygonPoints.add(const LatLng(52.19917741656872, 0.1392624799447906));
    roadClosurePolygonPoints.add(const LatLng(52.19916631280751, 0.1392828751651831));
    roadClosurePolygonPoints.add(const LatLng(52.1991446428936, 0.1392756075048496));
    roadClosurePolygonPoints.add(const LatLng(52.1989175486481, 0.1391726819940953));
    roadClosurePolygonPoints.add(const LatLng(52.19889771872434, 0.1392709721100016));
    roadClosurePolygonPoints.add(const LatLng(52.19911453244046, 0.1393715381498972));
    roadClosurePolygonPoints.add(const LatLng(52.19913034133225, 0.1393917519890997));
    roadClosurePolygonPoints.add(const LatLng(52.19913119844188, 0.1394384318111475));
    roadClosurePolygonPoints.add(const LatLng(52.19905709832486, 0.1396793349892134));
    roadClosurePolygonPoints.add(const LatLng(52.19888886920802, 0.1401470573250951));
    roadClosurePolygonPoints.add(const LatLng(52.19872575446356, 0.1406882487196137));
    roadClosurePolygonPoints.add(const LatLng(52.19857919460625, 0.1412221159165639));
    roadClosurePolygonPoints.add(const LatLng(52.19830401464963, 0.1420795096207583));
    roadClosurePolygonPoints.add(const LatLng(52.19805523258207, 0.1428446992033949));
    roadClosurePolygonPoints.add(const LatLng(52.19796058547896, 0.1431700690124305));
    roadClosurePolygonPoints.add(const LatLng(52.19777043831322, 0.1439182506974968));
    roadClosurePolygonPoints.add(const LatLng(52.19773906069497, 0.1440271555659201));
    roadClosurePolygonPoints.add(const LatLng(52.19760690963302, 0.1446079456685312));
    roadClosurePolygonPoints.add(const LatLng(52.19752098068638, 0.1450090212216604));
    roadClosurePolygonPoints.add(const LatLng(52.19728430868131, 0.1458929568071077));
    roadClosurePolygonPoints.add(const LatLng(52.19718620331415, 0.1462664966187099));
    roadClosurePolygonPoints.add(const LatLng(52.19715943539327, 0.1464441477274536));
    roadClosurePolygonPoints.add(const LatLng(52.19713596405279, 0.1469755713590337));
    roadClosurePolygonPoints.add(const LatLng(52.19712231441085, 0.148011136800752));
    roadClosurePolygonPoints.add(const LatLng(52.19710307516238, 0.148069413077816));
    roadClosurePolygonPoints.add(const LatLng(52.19707444705853, 0.1481099103727335));
    roadClosurePolygonPoints.add(const LatLng(52.19704767600419, 0.1481444468743121));
    roadClosurePolygonPoints.add(const LatLng(52.19721043817059, 0.1481847622388588));
    roadClosurePolygonPoints.add(const LatLng(52.19722302277, 0.1474140266218704));
    roadClosurePolygonPoints.add(const LatLng(52.19722565195199, 0.146889669990915));
    roadClosurePolygonPoints.add(const LatLng(52.19726897902555, 0.1464747706739122));
    roadClosurePolygonPoints.add(const LatLng(52.19733900493154, 0.1461190078434771));
    roadClosurePolygonPoints.add(const LatLng(52.19739118450674, 0.1458830211390794));
    roadClosurePolygonPoints.add(const LatLng(52.19755813717495, 0.1452606860195216));
    roadClosurePolygonPoints.add(const LatLng(52.19757901364062, 0.1452168759986305));
    roadClosurePolygonPoints.add(const LatLng(52.19761552409477, 0.1451996552309986));
    roadClosurePolygonPoints.add(const LatLng(52.19797077273405, 0.1454282307815458));
    roadClosurePolygonPoints.add(const LatLng(52.19800074143257, 0.1453174537048341));
    roadClosurePolygonPoints.add(const LatLng(52.19764604071845, 0.1450942683488377));
    roadClosurePolygonPoints.add(const LatLng(52.19762791445593, 0.1450806419496486));
    roadClosurePolygonPoints.add(const LatLng(52.19762480908257, 0.1450539383381266));
    roadClosurePolygonPoints.add(const LatLng(52.19770791836908, 0.14475061805028));
    roadClosurePolygonPoints.add(const LatLng(52.19783188969217, 0.1442675574167662));
    roadClosurePolygonPoints.add(const LatLng(52.19794279870698, 0.1438312258765273));
    roadClosurePolygonPoints.add(const LatLng(52.19803501146946, 0.1434695710127309));
    roadClosurePolygonPoints.add(const LatLng(52.19808263193191, 0.1432575640823996));
    roadClosurePolygonPoints.add(const LatLng(52.19810430566206, 0.1432082446911287));
    roadClosurePolygonPoints.add(const LatLng(52.19814007266301, 0.143197469994214));
    roadClosurePolygonPoints.add(const LatLng(52.19823619993755, 0.1432444901333763));
    roadClosurePolygonPoints.add(const LatLng(52.19826647248333, 0.143117556460064));
    roadClosurePolygonPoints.add(const LatLng(52.19817736904658, 0.143079741532075));
    roadClosurePolygonPoints.add(const LatLng(52.19814857116783, 0.1430312397977263));
    roadClosurePolygonPoints.add(const LatLng(52.19813774401835, 0.1429826127655653));
    roadClosurePolygonPoints.add(const LatLng(52.1981395496733, 0.1429257420584218));
    roadClosurePolygonPoints.add(const LatLng(52.19838239595334, 0.1421511196770431));
    roadClosurePolygonPoints.add(const LatLng(52.19866819899372, 0.1412727505878197));
    roadClosurePolygonPoints.add(const LatLng(52.1988946308355, 0.140430858937366));
    roadClosurePolygonPoints.add(const LatLng(52.19898785139731, 0.1401239799499643));
    roadClosurePolygonPoints.add(const LatLng(52.1990949156823, 0.1398575281699244));
    roadClosurePolygonPoints.add(const LatLng(52.19916224790448, 0.1398825903315903));
    roadClosurePolygonPoints.add(const LatLng(52.19960636796143, 0.1400957500436917));
    roadClosurePolygonPoints.add(const LatLng(52.19963166053221, 0.1399841997340023));
    roadClosurePolygonPoints.add(const LatLng(52.19920869096963, 0.1397790582244829));
    roadClosurePolygonPoints.add(const LatLng(52.19918395215315, 0.1397595337506052));
    roadClosurePolygonPoints.add(const LatLng(52.19917858268948, 0.1397261437714437));
    roadClosurePolygonPoints.add(const LatLng(52.19925561252868, 0.1393610777706944));
    roadClosurePolygonPoints.add(const LatLng(52.19938272725695, 0.1390182457566169));
    roadClosurePolygonPoints.add(const LatLng(52.19957938929511, 0.1385117709767414));
    roadClosurePolygonPoints.add(const LatLng(52.19959849381066, 0.1384832104027955));
    roadClosurePolygonPoints.add(const LatLng(52.1996205426845, 0.138488654837039));
    roadClosurePolygonPoints.add(const LatLng(52.19988950470529, 0.1386132646940519));
    roadClosurePolygonPoints.add(const LatLng(52.19991965694164, 0.1384589372589007));
    roadClosurePolygonPoints.add(const LatLng(52.1997044021644, 0.1383681140327409));
    roadClosurePolygonPoints.add(const LatLng(52.19968147601194, 0.1383525488609494));
    roadClosurePolygonPoints.add(const LatLng(52.19968791077611, 0.1382998401510327));
    roadClosurePolygonPoints.add(const LatLng(52.19976017735745, 0.1380852582527425));
    roadClosurePolygonPoints.add(const LatLng(52.19994474305631, 0.1376361571871065));
    roadClosurePolygonPoints.add(const LatLng(52.20024124768548, 0.1368691189440052));
    roadClosurePolygonPoints.add(const LatLng(52.20044131744081, 0.1363590732360365));
    roadClosurePolygonPoints.add(const LatLng(52.20047559338849, 0.1362605493615976));
    roadClosurePolygonPoints.add(const LatLng(52.20060058749072, 0.1359530811674525));
    roadClosurePolygonPoints.add(const LatLng(52.20078215089771, 0.135500576050156));
    roadClosurePolygonPoints.add(const LatLng(52.20106039161641, 0.1348202822524414));
    roadClosurePolygonPoints.add(const LatLng(52.20119370680953, 0.1344925343925496));
    roadClosurePolygonPoints.add(const LatLng(52.20136533156352, 0.1340803487453357));
    roadClosurePolygonPoints.add(const LatLng(52.20147425034508, 0.1338054699789071));
    roadClosurePolygonPoints.add(const LatLng(52.20170022686337, 0.1332403201753118));
    roadClosurePolygonPoints.add(const LatLng(52.20185494572683, 0.1328594526718563));
    roadClosurePolygonPoints.add(const LatLng(52.2020821221406, 0.1323470401379923));
    roadClosurePolygonPoints.add(const LatLng(52.20217853160823, 0.1322296546103541));
    roadClosurePolygonPoints.add(const LatLng(52.20226261801045, 0.1320472213527735));
    roadClosurePolygonPoints.add(const LatLng(52.20229087498912, 0.1319118627783045));
    roadClosurePolygonPoints.add(const LatLng(52.2024125802474, 0.1316399501782883));
    roadClosurePolygonPoints.add(const LatLng(52.20246156812499, 0.1315758165697245));
    roadClosurePolygonPoints.add(const LatLng(52.20253475854415, 0.1315288299783668));
    roadClosurePolygonPoints.add(const LatLng(52.20259725355452, 0.1315025919232182));
    roadClosurePolygonPoints.add(const LatLng(52.2026438385976, 0.1313751782097183));
    roadClosurePolygonPoints.add(const LatLng(52.20235281420999, 0.1310619082596975));

    return Polygon(
        polygonId: const PolygonId('roadClosure'),
        points: roadClosurePolygonPoints,
        strokeWidth: 3,
        strokeColor: Theme.of(context).colorScheme.tertiary,
        fillColor: Theme.of(context).colorScheme.tertiary.withAlpha(50));
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

  Widget roadClosuresDialog() {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.clamp(300.0, 500.0);
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Scrollbar(
                controller: _roadClosuresDialogScrollController,
                thumbVisibility: Platform.isIOS ? false : true, // iOS has its own scrollbar style
                thickness: 4,
                radius: const Radius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SingleChildScrollView(
                    controller: _roadClosuresDialogScrollController,
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Road closures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 10),
                        const Text(
                            style: TextStyle(height: 1.25),
                            'Whilst Mill Road (between East Road and Coleridge Road), Mortimer Road, Headly Street and the tops of Tenison Road, St Barnabas Road, Devonshire Road, Gwydir Street, Cavendish Road and Catharine Street where they join Mill Road will be closed to traffic (including cyclists and scooters) between 9am and 5.30pm on the day, there will be some vehicle movement.'),
                        const SizedBox(height: 10),
                        const Text('Pedestrians should exercise particular care before the road is fully closed.',
                            style: TextStyle(fontWeight: FontWeight.bold, height: 1.25)),
                        const SizedBox(height: 10),
                        const Text('Re-opening will occur gradually, so drivers and pedestrians should take extreme care.',
                            style: TextStyle(fontWeight: FontWeight.bold, height: 1.25)),
                        const SizedBox(height: 10),
                        const Text(
                            style: TextStyle(height: 1.25),
                            'Pedestrians will be required to make way for emergency and other vehicles within the closure area, from time to time.'),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                  style: TextStyle(height: 1.25),
                                  text:
                                      'If your property/business is in the area affected by the road closure, please read the Road Closure Notice distributed separately or available at '),
                              TextSpan(
                                  text: 'www.millroadwinterfair.org',
                                  style: const TextStyle(decoration: TextDecoration.underline, height: 1.25),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      HapticFeedback.lightImpact();
                                      launchUrl(Uri.parse('http://www.millroadwinterfair.org/wp-content/uploads/2025/11/Road-Closure-Notice.pdf'));
                                    }),
                              const TextSpan(style: TextStyle(height: 1.25), text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentGeometry.bottomRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    filterSettings["Road Closures"] = false;
                                  });
                                  updateRoadClosurePolygonVisibility(false);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Hide road closures',
                                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Close',
                                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void updateMarkerVisibility(List<MarkerId> idList, bool visibleState) {
    debugPrint('updateMarkerVisibility called');
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
    debugPrint('setMarkerLists called');
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
      } else if (listing['primaryType'].startsWith("Service") || listing['primaryType'] == "Group-Service") {
        _serviceMarkerIds.add(MarkerId(listing['id'].toString()));
      }
    }
  }

  void addAllVisibleMarkers() async {
    debugPrint('addAllVisibleMarkers called');

    // Create all marker bitmaps first, but only if not onTest
    if (onTest == false) {
      await createAllMarkerBitmaps();
    }

    // Ensure the markers list is empty
    markers.clear();

    for (var listing in listings) {
      if (listing['visibleOnMap'] == 'TRUE') {
        // Add Group markers
        if (listing['primaryType'].startsWith('Group-')) {
          addGroupMarker(listing);
        }
        // Add Specific markers
        if (!listing['primaryType'].startsWith('Group-')) {
          addSpecificMarker(listing);
        }
      }
    }
  }

  Future<bool> createAllMarkerBitmaps() async {
    debugPrint('createAllMarkerBitmaps called');
    for (var listingType
        in 'Food, Shopping, Music, Event, Service, Service-FirstAid, Service-Information, Service-Toilet, Group-Food, Group-Shopping, Group-Music, Group-Event, Group-Service'
            .split(', ')) {
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

  void addGroupMarker(listing) async {
    // debugPrint('addGroupMarker called for marker ID: ${listing['id']}');
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;

    if (onTest == false) {
      customMarker = bitmapDescriptors[listing['primaryType']]!;
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        // Update the current location, do not await as this causes issues with using the context across async gaps
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
          scrollControlDisabledMaxHeightRatio: 0.8,
          useSafeArea: true,
          builder: (BuildContext context) {
            double screenHeight = MediaQuery.of(context).size.height;
            // Estimate the height of a SpecificListingInfoSheet in pixels
            double estimatedItemHeight = 135;
            // Estimate the total height of the bottom sheet
            double estimatedSheetHeight = relatedListings.length * estimatedItemHeight;
            // Set the minimum size of the modalBottomSheet based on either the estimatedSheetHeight or 2/3 of the screen, whichever is lower
            double minFraction = min((estimatedSheetHeight / screenHeight), 0.66);
            // Set the maximum size of the modalBottomSheet based on either the estimatedSheetHeight or the whole screen, whichever is lower
            double maxFraction = min((estimatedSheetHeight / screenHeight), 0.9);
            detailsVisibilityList = List<bool>.filled(relatedListings.length, false);

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                void toggleDetailsRow(int index) {
                  HapticFeedback.lightImpact();
                  setModalState(() {
                    detailsVisibilityList[index] = !detailsVisibilityList[index];
                  });
                }

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
                          separatorBuilder: (BuildContext context, int index) => Divider(color: Theme.of(context).colorScheme.surfaceDim),
                          itemCount: relatedListings.length,
                          itemBuilder: (context, index) {
                            final rel = relatedListings[index];

                            // Calculate distance if current location is known
                            var distanceMessage = 'Distance unknown';
                            if (currentLatLng != null) {
                              int approximateDistanceMetres = asTheCrowFlies(
                                currentLatLng!,
                                stringToLatLng(rel['latLng']),
                              );
                              distanceMessage = 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}';
                            }

                            if (rel['primaryType'].startsWith("Group")) {
                              return GroupListingInfoSheet(
                                title: rel['displayName'],
                                categories: "${rel['tertiaryType']}",
                                startTime: "${listing['startTime']}",
                                endTime: "${listing['endTime']}",
                                approxDistance: distanceMessage,
                              );
                            } else {
                              return SpecificListingInfoSheet(
                                title: rel['displayName'],
                                location: '',
                                subtitle: "${rel['tertiaryType']}\n${rel['startTime']}—${rel['endTime']}",
                                startTime: '',
                                endTime: '',
                                approxDistance: '',
                                phoneNumber: (rel['phone'] != null) ? rel['phone'] : '',
                                website: (rel['website'] != null) ? rel['website'] : '',
                                email: (rel['email'] != null) ? rel['email'] : '',
                                description: (rel['description'] != null) ? rel['description'] : '',
                                detailsVisible: detailsVisibilityList[index],
                                onDetailsTapped: () => toggleDetailsRow(index),
                                onGetDirections: () => getDirections(rel['id'], stringToLatLng(rel['latLng']), true),
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
      },
    );

    setState(() {
      markers[markerId] = newMarker;
    });
  }

  void addSpecificMarker(listing) async {
    debugPrint('addSpecificMarker called for marker ID: ${listing['id']}');
    LatLng destinationLatLng = stringToLatLng(listing['latLng']);
    MarkerId markerId = MarkerId(listing['id'].toString());
    Color color = getCategoryColor(selectedThemeKey, listing['primaryType']);
    late BitmapDescriptor customMarker;
    if (onTest == false) {
      customMarker = bitmapDescriptors[listing['primaryType']]!;
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
      onTap: () {
        HapticFeedback.lightImpact();
        // Update the current location, do not await as this causes issues with using the context across async gaps
        establishLocation();

        // Calculate distance if current location is known
        var distanceMessage = 'Distance unknown';
        if (currentLatLng != null) {
          int approximateDistanceMetres = asTheCrowFlies(
            currentLatLng!,
            stringToLatLng(listing['latLng']),
          );
          distanceMessage = 'approx. ${convertDistanceUnits(approximateDistanceMetres, preferredDistanceUnits)}';
        }

        // Show bottom sheet with listing information
        showModalBottomSheet(
          context: context,
          showDragHandle: false,
          enableDrag: false,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
          isScrollControlled: true,
          useSafeArea: true,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.33,
                  minChildSize: 0.33,
                  maxChildSize: 0.66,
                  builder: (context, specificSheetModalScrollController) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: Scrollbar(
                        controller: specificSheetModalScrollController,
                        thumbVisibility: false,
                        thickness: 4,
                        radius: const Radius.circular(8),
                        child: ListView(
                          controller: specificSheetModalScrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            SpecificListingInfoSheet(
                              title: listing['displayName'],
                              location: listing['secondaryType'],
                              subtitle: listing['tertiaryType'],
                              startTime: "${listing['startTime']}",
                              endTime: "${listing['endTime']}",
                              approxDistance: distanceMessage,
                              phoneNumber: (listing['phone'] != null) ? listing['phone'] : '',
                              website: (listing['website'] != null) ? listing['website'] : '',
                              email: (listing['email'] != null) ? listing['email'] : '',
                              description: (listing['description'] != null) ? listing['description'] : '',
                              detailsVisible: true,
                              onGetDirections: () => getDirections(listing['id'], destinationLatLng, true),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  void addSimpleMarker(primaryType, destinationLatLng) async {
    debugPrint('addSimpleMarker called for primary type: $primaryType');
    const MarkerId markerId = MarkerId(aSimpleMarkerId);
    Color color = getCategoryColor(selectedThemeKey, primaryType);
    late BitmapDescriptor customMarker;
    if (onTest == false) {
      customMarker = bitmapDescriptors[primaryType]!;
    } else {
      double hue = HSVColor.fromColor(color).hue;
      customMarker = BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    Marker newMarker = Marker(
      markerId: markerId,
      position: destinationLatLng,
      icon: customMarker,
      visible: true,
    );

    setState(() {
      markers[markerId] = newMarker;
    });
  }

  Future<void> updateMarkersAndPolygonsForTheme() async {
    debugPrint('updateMarkersAndPolygonsForTheme called');
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

      // Update polygon colour to match theme, if filtered-in
      if (filterSettings["Road Closures"] == true) {
        _polygons.clear();
        _polygons.add(roadClosurePolygon());
      }
    });
  }

  void hideAllMarkers() {
    debugPrint('hideAllMarkers called');
    updateMarkerVisibility(_foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds, false);
  }

  void showAllMarkers() {
    debugPrint('showAllMarkers called');
    updateMarkerVisibility(_foodMarkerIds + _stallsMarkerIds + _musicMarkerIds + _eventMarkerIds + _serviceMarkerIds, true);
  }

  void showFilteredMarkers() {
    debugPrint('showFilteredMarkers called');
    updateMarkerVisibility(_foodMarkerIds, filterSettings['Food']!);
    updateMarkerVisibility(_stallsMarkerIds, filterSettings['Stalls']!);
    updateMarkerVisibility(_musicMarkerIds, filterSettings['Music']!);
    updateMarkerVisibility(_eventMarkerIds, filterSettings['Events']!);
    updateMarkerVisibility(_serviceMarkerIds, filterSettings['Services']!);
  }

  void showFilterMenu() {
    debugPrint('showFilterMenu called');
    showModalBottomSheet(
      scrollControlDisabledMaxHeightRatio: 0.8,
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
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
                      "Filter map layers",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    )
                  ]),
                  CheckboxListTile(
                    activeColor: getCategoryColor(selectedThemeKey, 'Food'),
                    title: const Text("Food"),
                    value: filterSettings["Food"],
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
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
                      HapticFeedback.selectionClick();
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
                      HapticFeedback.selectionClick();
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
                      HapticFeedback.selectionClick();
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
                      HapticFeedback.selectionClick();
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
                    title: const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text("Shade road closures")),
                    value: filterSettings["Road Closures"],
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        filterSettings["Road Closures"] = value!;
                      });
                      updateRoadClosurePolygonVisibility(value!);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    filterSettings.forEach((key, _) {
                                      filterSettings[key] = true;
                                    });
                                  });
                                  showAllMarkers();
                                  updateRoadClosurePolygonVisibility(true);
                                },
                                icon: const Icon(Icons.filter_alt),
                                label: const Text('Show all'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    filterSettings.forEach((key, _) {
                                      filterSettings[key] = false;
                                    });
                                  });
                                  hideAllMarkers();
                                  updateRoadClosurePolygonVisibility(false);
                                },
                                icon: const Icon(Icons.filter_alt_off),
                                label: const Text('Hide all'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Done'),
                              ),
                            ],
                          ),
                        ),
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
    // Cancelling of any previous navigation
    // Halt the location subscription
    _positionStream?.cancel();
    // Clear the polylines
    polylines.clear();
    // Clear the polygons
    _polygons.clear();
    hideAllMarkers();
    // Remove any simple marker shown
    markers.removeWhere((key, marker) => marker.markerId.value == aSimpleMarkerId);
    // Reset the distance to destination
    _distanceToDestination = null;
    // Set navigation as not in progress
    _navigationInProgress = false;
    setState(() {});

    debugPrint('getDirections called for listing ID: $id');
    // Set navigation as in progress
    _navigationInProgress = true;

    if (navigatorPop == true) {
      Navigator.pop(context);
      // The navigator is only popped when called from the map page, so if this is true set the previousIndex to 0
      previousIndex = 0;
    }

    // If user has location tracking enabled
    if (currentLatLng != null) {
      // Get the user's current location
      Position position = await getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      await updatePolyline(currentLatLng, destination);
      // Set the camera position once, at the beginning of the navigation
      _setMapCameraToFitPolyline(polylines);
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

    // SIMPLE ids come from non-listing source e.g. Key Events table on About The Fair
    const int aSimpleMarkerIdLen = aSimpleMarkerId.length;
    if (id.length > aSimpleMarkerIdLen && id.substring(0, aSimpleMarkerIdLen) == aSimpleMarkerId) {
      if (id.length > (aSimpleMarkerIdLen + 1)) {
        addSimpleMarker(id.substring(aSimpleMarkerIdLen + 1), destination);
      } else {
        debugPrint('Adding Event type simple marker as category was not specified: $id');
        addSimpleMarker('Event', destination);
      }
    } else {
      // Add destination map marker
      Map<String, dynamic> destinationListing = listings.firstWhere((element) => element['id'] == id);
      addSpecificMarker(destinationListing);
    }
  }

  void cancelNavigation() {
    debugPrint('cancelNavigation called');
    // Halt the location subscription
    _positionStream?.cancel();

    // Clear the polylines
    polylines.clear();

    // Re-add the polygons
    if (filterSettings["Road Closures"] == true) {
      _polygons.add(roadClosurePolygon());
    }

    // Reset the distance to destination
    _distanceToDestination = null;

    // Remove any simple marker shown
    markers.removeWhere((key, marker) => marker.markerId.value == aSimpleMarkerId);

    // Show markers which have enabled filters
    showFilteredMarkers();

    // Set navigation as not in progress
    _navigationInProgress = false;

    // Reset the camera position
    _setMapCameraToFitMapMarkers();

    // If we came from a page other than the map page, go back to that page
    if (previousIndex != 0) {
      homePageKey.currentState?.setCurrentIndex(previousIndex);
    }

    setState(() {});
  }

  @override
  void dispose() {
    debugPrint('MapPageState dispose() called');
    // Cancel the location subscription when the page is disposed
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> startLocationUpdates(LatLng destination) async {
    debugPrint('startLocationUpdates called');
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
    debugPrint('updatePolyline called');
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
        // empirical formula, since dashes don't space as if measured in pixels as per google's docs
        final dashSpace = pow((distanceMetres > 0 ? distanceMetres : 500), 0.9) / 27;

        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: result.points.map((point) => LatLng(point.latitude, point.longitude)).toList(),
            color: Theme.of(context).colorScheme.tertiary,
            width: 5,
            patterns: [PatternItem.dash(dashSpace), PatternItem.gap(dashSpace * 0.75)],
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
      polylines.clear();
      _distanceToDestination = null;
      hideAllMarkers();
      addAllVisibleMarkers();
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
    debugPrint('_saveSettings called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferredMapOrientation', preferredMapOrientation.index);
    await prefs.setInt('preferredMapStyleType', preferredMapStyleType.index);
  }

  void _setMapCameraToFitMapMarkers() {
    debugPrint('_setMapCameraToFitMapMarkers called');
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
    debugPrint('_setMapCameraToFitPolyline called');
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
    debugPrint('_moveCameraToBoundsWithRotation called');
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
    debugPrint('zoomForBounds called');
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
    debugPrint('refreshListings called');
    setState(() {
      isRefreshing = true;
    });

    try {
      listings = await fetchListings(http.Client());
      setMarkerLists();
      addAllVisibleMarkers();
      establishLocation();
    } finally {
      setState(() {
        isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MapPageState build() called');
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
                        label: const Text('Refresh listings'),
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
                      polylines: polylines);
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
                          shadows: [
                            Shadow(
                              color: Theme.of(context).shadowColor,
                              offset: const Offset(1, 3),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    if (_navigationInProgress == false)
                      FloatingActionButton(
                        heroTag: 'homeBtn',
                        shape: const CircleBorder(),
                        elevation: 3,
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
                      elevation: 3,
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
                          elevation: 3,
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
                            FloatingActionButton(
                              heroTag: 'filterBtn',
                              shape: const CircleBorder(),
                              elevation: 3,
                              mini: true,
                              onPressed: () {
                                showFilterMenu();
                                setMarkerLists();
                              },
                              child: const Icon(Icons.filter_alt),
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
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          iconSize: 30,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          visualDensity: const VisualDensity(horizontal: 2, vertical: 0),
                          padding: const EdgeInsets.all(0),
                          elevation: 3,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _setMapCameraToFitPolyline(polylines);
                      },
                      icon: Icon(Icons.directions, color: Theme.of(context).colorScheme.onPrimary),
                      label: Text(
                        _distanceToDestination!,
                        style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              if (filterSettings['Road Closures'] == true && _navigationInProgress == false)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5.0, bottom: 6.0),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return roadClosuresDialog();
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: selectedThemeKey == 'colourBlindFriendly'
                                      ? const Color.fromRGBO(224, 129, 87, 255)
                                      : Theme.of(context).colorScheme.tertiary.withAlpha(50),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.tertiary,
                                    width: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Road closures',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
