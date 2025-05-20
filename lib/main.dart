import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Add this import
import 'package:wanderiq/widget/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'Wanderiq',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          canvasColor: Colors.black54,
        ),
        home: const DashboardPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}