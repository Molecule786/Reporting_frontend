import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Sidebar extends StatefulWidget {
  final String currentRoute;

  const Sidebar({super.key, required this.currentRoute});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String userRole = 'employee';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final result = await ApiService.getCurrentUser();
    if (mounted && result['success']) {
      setState(() {
        userRole = result['data']['role'] ?? 'employee';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 200,
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: 200,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, color: Colors.blue, size: 28),
                SizedBox(width: 8),
                Text(
                  'WorkFlow Pro',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'MAIN MENU',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          
          // Dashboard - Show for both
          _buildMenuItem(
            context,
            icon: Icons.dashboard_outlined,
            label: userRole == 'admin' ? 'Overview' : 'My Dashboard',
            route: userRole == 'admin' ? '/admin' : '/dashboard',
          ),
          
          // Submit Report - Show only for employees
          if (userRole != 'admin')
            _buildMenuItem(
              context,
              icon: Icons.add_circle_outline,
              label: 'Submit Report',
              route: '/submit-report',
            ),
          
          // Detailed Reports - Show for both
          _buildMenuItem(
            context,
            icon: Icons.description_outlined,
            label: 'Detailed Reports',
            route: '/detailed-report',
          ),
          
          // Analytics - Show for both
          _buildMenuItem(
            context,
            icon: Icons.analytics_outlined,
            label: 'Analytics & Export',
            route: '/analytics',
          ),
          
          // Leave Management - Show only for admin
          if (userRole == 'admin')
            _buildMenuItem(
              context,
              icon: Icons.event_available_outlined,
              label: 'Leave Management',
              route: '/admin-leaves',
            ),
          
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ApiService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String label, required String route}) {
    final isActive = widget.currentRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.black54, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (route != widget.currentRoute) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
