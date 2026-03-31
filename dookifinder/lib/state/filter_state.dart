import 'package:flutter/material.dart';
import '../data/washroom_data.dart';

class FilterState extends ChangeNotifier {
  //default values for filters, all false
  bool accessibility = false;
  bool genderNeutral = false;
  bool singleStall = false;
  double minRating = 0;

  void update({
    bool? accessibility,
    bool? genderNeutral,
    bool? singleStall,
    double? minRating,
  }) {
    if (accessibility != null) this.accessibility = accessibility;
    if (genderNeutral != null) this.genderNeutral = genderNeutral;
    if (singleStall != null) this.singleStall = singleStall;
    if (minRating != null) this.minRating = minRating;
    notifyListeners(); // triggers map to re-filter markers
  }

  void clear() {
    accessibility = false;
    genderNeutral = false;
    singleStall = false;
    minRating = 0;
    notifyListeners();
  }

  //activates bathrooms that have matching filters. Runs through all locations (loc), if 
  //the loc retuns false it is not displayed
  List<WashroomLocation> applyFilters(List<WashroomLocation> locations) {
    return locations.where((loc) {
      //if accessibility filter is on but location isn't accessible, return false
      if (accessibility && !loc.isAccessible) return false;
      if (genderNeutral && !loc.isGenderNeutral) return false;
      if (singleStall && !loc.isSingleStall) return false;
      //if the washroom is below the stated rating, return false
      if (loc.rating < minRating) return false;
      return true;
    }).toList();
  }
}