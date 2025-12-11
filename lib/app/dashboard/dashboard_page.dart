import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../profile/employee_profile_page.dart';

class EmployeeDashboardPage extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final String mobile;
  final String? city;
  final String? state;
  final String? profileImage;

  const EmployeeDashboardPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.mobile,
    this.city,
    this.state,
    this.profileImage,
  });

  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xff4f46e5);

    final screens = [
      _dashboardUI(primary),
      EmployeeProfilePage(
        id: widget.employeeId,
        name: widget.employeeName,
        mobile: widget.mobile,
        city: widget.city,
        state: widget.state,
        profileImage: widget.profileImage,
      ),
    ];

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafc),
        // keep an empty appbar presence (no visible toolbar)
        appBar: AppBar(backgroundColor: primary, elevation: 0, toolbarHeight: 0),
        body: screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: primary,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _dashboardUI(Color primary) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
            decoration: BoxDecoration(color: primary, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Welcome 👋", style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.employeeName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 150, crossAxisSpacing: 18, mainAxisSpacing: 18),
              children: [
                _menuCard(icon: Icons.timer_outlined, title: "Attendance", color: primary),
                _menuCard(icon: Icons.assignment_outlined, title: "Tasks", color: Colors.teal),
                _menuCard(icon: Icons.calendar_month_outlined, title: "Leave Request", color: Colors.orange),
                _menuCard(icon: Icons.bar_chart_outlined, title: "Reports", color: Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _menuCard({required IconData icon, required String title, required Color color}) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 5))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
