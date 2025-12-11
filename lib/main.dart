import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login/login_page.dart';
import 'login/otp_verification_page.dart';
import 'app/dashboard/dashboard_page.dart';
import 'app/profile/employee_profile_page.dart';
import 'app/profile/edit_profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  // load stored data (safe defaults)
  final storedData = {
    "id": prefs.getInt("employeeId") ?? 0,
    "name": prefs.getString("employeeName") ?? "Employee",
    "mobile": prefs.getString("employeeMobile") ?? "",
    "city": prefs.getString("employeeCity") ?? "",
    "state": prefs.getString("employeeState") ?? "",
    "profile": prefs.getString("employeeProfile") ?? "",
  };

  runApp(MyApp(isLoggedIn: isLoggedIn, storedData: storedData));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final Map<String, dynamic> storedData;

  const MyApp({super.key, required this.isLoggedIn, required this.storedData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee App',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? "/dashboard" : "/login",
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/login":
            return MaterialPageRoute(builder: (_) => const EmployeeLoginPage());

          case "/otp":
            final phone = settings.arguments as String?;
            if (phone == null) {
              return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text("Phone missing"))));
            }
            return MaterialPageRoute(builder: (_) => OtpVerificationPage(phoneNumber: phone));

          case "/dashboard":
            final data = (settings.arguments as Map<String, dynamic>?) ?? storedData;
            return MaterialPageRoute(
              builder: (_) => EmployeeDashboardPage(
                employeeId: (data["id"] is int) ? data["id"] : int.tryParse("${data["id"]}") ?? 0,
                employeeName: (data["name"] ?? "").toString(),
                mobile: (data["mobile"] ?? "").toString(),
                city: (data["city"] ?? "").toString(),
                state: (data["state"] ?? "").toString(),
                profileImage: (data["profile"] ?? "").toString(),
              ),
            );

          case "/profile":
            final data = (settings.arguments as Map<String, dynamic>?) ?? storedData;
            return MaterialPageRoute(
              builder: (_) => EmployeeProfilePage(
                id: (data["id"] is int) ? data["id"] : int.tryParse("${data["id"]}") ?? 0,
                name: (data["name"] ?? "").toString(),
                mobile: (data["mobile"] ?? "").toString(),
                city: (data["city"] ?? "").toString(),
                state: (data["state"] ?? "").toString(),
                profileImage: (data["profile"] ?? "").toString(),
              ),
            );

          case "/edit_profile":
            final data = settings.arguments as Map<String, dynamic>?;
            if (data == null) return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text("Missing data"))));
            return MaterialPageRoute(
              builder: (_) => EditProfilePage(
                id: (data["id"] is int) ? data["id"] : int.tryParse("${data["id"]}") ?? 0,
                name: (data["name"] ?? "").toString(),
                mobile: (data["mobile"] ?? "").toString(),
                city: (data["city"] ?? "").toString(),
                state: (data["state"] ?? "").toString(),
                profileImage: (data["profile"] ?? "").toString(),
              ),
            );
        }

        return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text("Unknown route: ${settings.name}"))));
      },
    );
  }
}
