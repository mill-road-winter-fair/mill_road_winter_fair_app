import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Us")),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
            "Mill Road Winter Fair is an annual event ..."), // Add event details here
      ),
    );
  }
}