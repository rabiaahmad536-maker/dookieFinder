import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/filter_state.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({super.key});

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  //preset filters
  bool _accessibility = false;
  bool _genderNeutral = false;
  bool _singleStall = false;
  double _minRating = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final filters = context.read<FilterState>();
    _accessibility = filters.accessibility;
    _genderNeutral = filters.genderNeutral;
    _singleStall = filters.singleStall;
    _minRating = filters.minRating;
  }

  @override
  Widget build(BuildContext context) {
    final filters = context.read<FilterState>();
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),

            //filter options
            SwitchListTile(
              title: const Text('Accessibility'),
              subtitle: const Text('Wheelchair accessible'),
              value: _accessibility,
              onChanged: (val) => setState(() => _accessibility = val),
            ),
            SwitchListTile(
              title: const Text('Gender Neutral'),
              value: _genderNeutral,
              onChanged: (val) => setState(() => _genderNeutral = val),
            ),
            SwitchListTile(
              title: const Text('Single Stall'),
              value: _singleStall,
              onChanged: (val) => setState(() => _singleStall = val),
            ),

            const Divider(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Minimum Rating', style: TextStyle(fontSize: 16)),
            ),
            Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 5,
              label: '${_minRating.toInt()} stars',
              onChanged: (val) => setState(() => _minRating = val),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _accessibility = false;
                      _genderNeutral = false;
                      _singleStall = false;
                      _minRating = 0;
                    });
                    filters.clear();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    filters.update(
                    accessibility: _accessibility,
                    genderNeutral: _genderNeutral,
                    singleStall: _singleStall,
                    minRating: _minRating,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}