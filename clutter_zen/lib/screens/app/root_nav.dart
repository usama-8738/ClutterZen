import 'package:flutter/material.dart';

import '../../widgets/app_drawer.dart';
import '../../app_firebase.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  isSelected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  label: 'History',
                  isSelected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                  showUserImage: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showUserImage = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showUserImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showUserImage) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.green.shade100 : Colors.grey.shade200,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.transparent,
                child: AppFirebase.auth.currentUser?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          AppFirebase.auth.currentUser!.photoURL!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 20,
                              color: isSelected ? Colors.green : Colors.grey,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
              ),
            ),
          ] else ...[
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
