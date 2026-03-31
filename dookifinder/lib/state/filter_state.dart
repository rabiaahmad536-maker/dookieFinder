import 'package:flutter/material.dart';

class FilterState extends ChangeNotifier {
  //default values for filters, all false
  bool accessibility = false;
  bool genderNeutral = false;
  bool singleStall = false;
  double minRating = 0;

  //
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
}