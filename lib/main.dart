import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mill Road Winter Fair',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List listings = [];

  @override
  void initState() {
    super.initState();
    fetchListings();
  }

  fetchListings() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/listings'));
    if (response.statusCode == 200) {
      setState(() {
        listings = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mill Road Winter Fair')),
      body: ListView.builder(
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return ListTile(
            title: Text(listing['displayName']),
            subtitle: Text(listing['tertiaryType'] +
                ' (' +
                listing['startTime'] +
                ' - ' +
                listing['endTime'] +
                ')'),
            trailing: IconButton(
              onPressed: () => _launchUrl(listing['plusCode']),
              icon: const Icon(Icons.directions),
            ),
          );
        },
      ),
    );
  }
}

_launchUrl(String plusCode) async {
  String encodedPlusCode = Uri.encodeComponent(plusCode);
  final url = 'https://www.google.com/maps/dir/?api=1&destination=$encodedPlusCode&travelmode=walking';
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
