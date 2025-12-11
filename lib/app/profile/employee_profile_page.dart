// lib/app/profile/employee_profile_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';

class EmployeeProfilePage extends StatefulWidget {
  final int id;
  final String name;
  final String mobile;
  final String? city;
  final String? state;
  final String? profileImage;

  const EmployeeProfilePage({
    super.key,
    required this.id,
    required this.name,
    required this.mobile,
    this.city,
    this.state,
    this.profileImage,
  });

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _fixImageUrl(String? img) {
    if (img == null || img.trim().isEmpty) return "";
    var s = img.replaceAll("\\", "/");
    if (s.startsWith("http://") || s.startsWith("https://")) return s;
    if (s.startsWith("/")) s = s.substring(1);
    return "${ApiConstants.fileURL}/$s";
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _fixImageUrl(widget.profileImage);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        body: Column(
          children: [
            SizedBox(
              height: 290,
              child: Stack(
                children: [
                  Container(
                    height: 230,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff4f46e5), Color(0xff6a5af9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // animated translucent wave overlay
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (_, __) {
                      return ClipPath(
                        clipper: _WaveClipper(_waveController.value),
                        child: Container(
                          height: 260,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(.18),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Title
                  const Positioned(
                    top: 44,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Hero profile pic
                  Positioned(
                    bottom: 34,
                    left: 0,
                    right: 0,
                    child: Hero(
                      tag: 'profile_pic',
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // edit button
                  Positioned(
                    right: 18,
                    bottom: 86,
                    child: Material(
                      color: Colors.white,
                      elevation: 5,
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: _navigateToEdit,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.edit, color: Colors.deepPurple),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: Colors.white,
              child: const TabBar(
                indicatorColor: Color(0xff4f46e5),
                labelColor: Color(0xff4f46e5),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
                  Tab(icon: Icon(Icons.info_outline), text: 'Details'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(children: [_overviewTab(), _detailsTab()]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '+91 ${widget.mobile}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _detailsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _infoCard('City', widget.city ?? 'Not provided', Icons.location_city),
        const SizedBox(height: 14),
        _infoCard('State', widget.state ?? 'Not provided', Icons.map_rounded),
        const SizedBox(height: 28),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _confirmLogout,
          child: const Text(
            'Logout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff4f46e5), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$title\n$value',
              style: const TextStyle(fontSize: 15, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.pushNamed(
      context,
      '/edit_profile',
      arguments: {
        'id': widget.id,
        'name': widget.name,
        'mobile': widget.mobile,
        'city': widget.city,
        'state': widget.state,
        'profile': widget.profileImage,
      },
    );

    if (result is Map<String, dynamic>) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'employeeName',
        (result['name'] ?? widget.name).toString(),
      );
      await prefs.setString(
        'employeeCity',
        (result['city'] ?? widget.city ?? '').toString(),
      );
      await prefs.setString(
        'employeeState',
        (result['state'] ?? widget.state ?? '').toString(),
      );
      await prefs.setString(
        'employeeProfile',
        (result['profile'] ?? widget.profileImage ?? '').toString(),
      );

      if (!mounted) return;

      // Replace profile screen with updated data
      Navigator.pushReplacementNamed(
        context,
        '/profile',
        arguments: {
          'id': widget.id,
          'name': (result['name'] ?? widget.name).toString(),
          'mobile': widget.mobile,
          'city': (result['city'] ?? widget.city ?? '').toString(),
          'state': (result['state'] ?? widget.state ?? '').toString(),
          'profile': (result['profile'] ?? widget.profileImage ?? '')
              .toString(),
        },
      );
    }
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double v;
  _WaveClipper(this.v);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    final waveHeight = 30 * v;
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 60 + waveHeight,
      size.width * 0.5,
      size.height - 40 - waveHeight,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 80 + waveHeight,
      size.width,
      size.height - 20 - waveHeight,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => true;
}
