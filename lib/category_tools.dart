import 'package:flutter/cupertino.dart';

// Some things in the app (mainly the map markers & filters) are currently dependent on the category of a listing. This file contains helper functions to determine the category of a listing based on its attributes.

int countCategories(Map<String, dynamic> listing) {
  // Start with a count of 0
  int count = 0;

  if (listing['food'] == 'TRUE') {
    count++;
  }
  if (listing['shopping'] == 'TRUE') {
    count++;
  }
  if (listing['charityCommunityInfo'] == 'TRUE') {
    count++;
  }
  if (listing['performance'] == 'TRUE') {
    count++;
  }
  if (listing['visitExperience'] == 'TRUE') {
    count++;
  }
  if (listing['service'] == 'TRUE') {
    count++;
  }

  if (count == 0) {
    debugPrint("No categories found for listing: ${listing['name']}");
  }

  return count;
}

String getCategory(Map<String, dynamic> listing) {
  final catCount = countCategories(listing);

  if (catCount > 1) {
    return 'Mixed';
  } else {
    if (listing['food'] == 'TRUE') {
      return 'Food';
    }
    if (listing['food'] == 'TRUE' && listing['groupParent'] == 'TRUE') {
      return 'Group-Food';
    }
    if (listing['shopping'] == 'TRUE') {
      return 'Shopping';
    }
    if (listing['shopping'] == 'TRUE' && listing['groupParent'] == 'TRUE') {
      return 'Group-Shopping';
    }
    if (listing['charityCommunityInfo'] == 'TRUE') {
      return 'Charity/Community/Info';
    }
    if (listing['charityCommunityInfo'] == 'TRUE' && listing['groupParent'] == 'TRUE') {
      return 'Group-Charity/Community/Info';
    }
    if (listing['performance'] == 'TRUE') {
      return 'Performance';
    }
    if (listing['performance'] == 'TRUE' && listing['groupParent'] == 'TRUE') {
      return 'Group-Performance';
    }
    if (listing['visitExperience'] == 'TRUE') {
      return 'Visit/Experience';
    }
    if (listing['visitExperience'] == 'TRUE' && listing['groupParent'] == 'TRUE') {
      return 'Group-Visit/Experience';
    }
    if (listing['service'] == 'TRUE') {
      return 'Service';
    }
    if (listing['service'] == 'TRUE' && listing['groupParent'] == 'TRUE') {
      return 'Group-Service';
    }
  }

  return 'No Category';
}

bool isGroupSingleCategory(String groupID, List<Map<String, dynamic>> listings) {
  // Get all listings with the same groupID
  final groupListings = listings.where((listing) => listing['groupID'] == groupID).toList();

  // If there are no listings in the group, return false
  if (groupListings.isEmpty) {
    return false;
  }

  // Get the category of the first listing in the group
  final firstCategory = getCategory(groupListings.first);

  // Check if all listings in the group have the same category
  for (final listing in groupListings) {
    if (getCategory(listing) != firstCategory) {
      return false;
    }
  }

  return true;
}
