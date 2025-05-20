import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wanderiq/widget/review/review_screen.dart';
import 'package:wanderiq/widget/search/search_screen.dart';
import 'package:wanderiq/widget/trips/trips_screen.dart';
import 'account/account_screen.dart';
import 'dashboard_bloc.dart';
import 'home/home_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardBloc = DashboardBloc();
    final pages = [
      const HomeScreen(),
      const SearchScreen(),
      const TripsScreen(),
      const ReviewScreen(),
      const AccountScreen(),
    ];

    return Theme(
      data: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange[300]!,
          secondary: Colors.orange[300]!,
        ),
        textTheme: TextTheme(
          labelMedium: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 12.sp, color: Colors.grey[400], fontWeight: FontWeight.w400),
        ),
      ),
      child: Scaffold(
        body: StreamBuilder<int>(
          stream: dashboardBloc.tabIndexStream,
          initialData: 0,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading tab', style: TextStyle(color: Colors.white)));
            }
            final currentIndex = snapshot.data ?? 0;
            return pages[currentIndex];
          },
        ),
        bottomNavigationBar: StreamBuilder<int>(
          stream: dashboardBloc.tabIndexStream,
          initialData: 0,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SizedBox.shrink(); // Hide bottom bar on error
            }
            final currentIndex = snapshot.data ?? 0;
            return BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) => dashboardBloc.selectTab(index),
              backgroundColor: Colors.black,
              selectedItemColor: Colors.orange[300],
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: Theme.of(context).textTheme.labelMedium,
              unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
              elevation: 8.0,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == 0 ? Colors.orange[300] : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.home,
                      size: 28.sp,
                      color: currentIndex == 0 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == 1 ? Colors.orange[300] : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 28.sp,
                      color: currentIndex == 1 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == 2 ? Colors.orange[300] : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.map,
                      size: 28.sp,
                      color: currentIndex == 2 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  label: 'Trips',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == 3 ? Colors.orange[300] : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.star,
                      size: 28.sp,
                      color: currentIndex == 3 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  label: 'Review',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == 4 ? Colors.orange[300] : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 28.sp,
                      color: currentIndex == 4 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  label: 'Account',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}