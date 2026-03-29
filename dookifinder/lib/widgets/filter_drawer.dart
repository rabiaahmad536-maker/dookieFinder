import 'package:flutter/material.dart';
import 'package:dookifinder/screens/login_page.dart';
import '../state/filter_state.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dookifinder/screens/profile_page.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({super.key});

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  double _minRating = 0;

  @override
  Widget build(BuildContext context) {
    //looks for any update to the filters and applies them 
    final filters = context.watch<FilterState>(); 

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
              value: filters.accessibility,
              //on any change, calls update function that reloads the map, and displays the new filter setting.
              //val is the new value of the switch
             onChanged: (val) => filters.update(accessibility: val),
            ),

            SwitchListTile(
              title: const Text('Gender Neutral'),
              value: filters.genderNeutral,
              onChanged: (val) => filters.update(genderNeutral: val),
            ),

            SwitchListTile(
              title: const Text('Single Stall'),
              value: filters.singleStall,
              onChanged: (val) => filters.update(singleStall: val),
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

            const Spacer(),

            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => user != null
                                ? const ProfilePage()
                                : const LoginPage(),
                          ),
                        );
                      },
                      icon: Icon(user != null ? Icons.person : Icons.login),
                      label: Text(user != null ? 'Profile' : 'Login'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}