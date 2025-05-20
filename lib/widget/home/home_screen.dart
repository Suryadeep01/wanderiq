import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'bloc_home.dart';
import 'place_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeBloc homeBloc;

  @override
  void initState() {
    super.initState();
    homeBloc = HomeBloc();
    homeBloc.initializeFeaturedDestinations();
    homeBloc.initializePopularDestinations();
  }

  @override
  void dispose() {
    homeBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange[300]!,
          secondary: Colors.orange[300]!,
        ),
        textTheme: TextTheme(
          headlineMedium: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14.sp, color: Colors.grey[300]),
          labelLarge: TextStyle(fontSize: 16.sp, color: Colors.orange[300]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[300],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Where to?', style: TextStyle(fontSize: 20.sp, color: Colors.orange[300])),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                color: Colors.orange[300],
                size: 24.sp,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notifications not implemented yet')),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Ad
                StreamBuilder<bool>(
                  stream: homeBloc.isBannerAdLoadedStream,
                  initialData: false,
                  builder: (context, isAdLoadedSnapshot) {
                    if (isAdLoadedSnapshot.data == true) {
                      return StreamBuilder<BannerAd?>(
                        stream: homeBloc.bannerAdStream,
                        initialData: null,
                        builder: (context, bannerAdSnapshot) {
                          final bannerAd = bannerAdSnapshot.data;
                          if (bannerAd != null) {
                            return Container(
                              alignment: Alignment.center,
                              width: bannerAd.size.width.toDouble(),
                              height: bannerAd.size.height.toDouble(),
                              child: AdWidget(ad: bannerAd),
                            );
                          }
                          return SizedBox(
                            height: AdSize.banner.height.toDouble(),
                            child: Center(child: Text('Banner ad failed to load', style: Theme.of(context).textTheme.bodyMedium)),
                          );
                        },
                      );
                    }
                    return SizedBox(
                      height: AdSize.banner.height.toDouble(),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Search Bar
                StreamBuilder<String>(
                  stream: homeBloc.searchQueryStream,
                  initialData: '',
                  builder: (context, snapshot) {
                    return TextField(
                      decoration: InputDecoration(
                        hintText: 'Search destinations...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: homeBloc.updateSearchQuery,
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Featured Destinations Carousel
                Text(
                  'Featured Destinations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                StreamBuilder<List<Map<String, String>>>(
                  stream: homeBloc.filteredFeaturedDestinationsStream,
                  initialData: const [],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 200.h,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final destinations = snapshot.data ?? [];
                    if (destinations.isEmpty) {
                      return SizedBox(
                        height: 200.h,
                        child: Center(
                          child: Text(
                            'No destinations found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return CarouselSlider(
                      options: CarouselOptions(
                        height: 200.h,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 0.8,
                      ),
                      items: destinations.map((destination) {
                        return Builder(
                          builder: (BuildContext context) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailsScreen(
                                      place: destination,
                                      homeBloc: homeBloc,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.symmetric(horizontal: 5.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: destination['image']!.isNotEmpty && destination['image']!.startsWith('http')
                                          ? CachedNetworkImage(
                                        imageUrl: destination['image']!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => Image.asset(
                                          'assets/images/placeholder.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                          : Image.asset(
                                        'assets/images/placeholder.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Padding(
                                        padding: EdgeInsets.all(8.w),
                                        child: Text(
                                          destination['name']!,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 10.0,
                                                color: Colors.black54,
                                                offset: Offset(2.0, 2.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // NearBy Destinations with Native Ads
                Text(
                  'NearBy Destinations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                StreamBuilder<List<dynamic>>(
                  stream: homeBloc.filteredPopularDestinationsWithAdsStream,
                  initialData: const [],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 260.h,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return SizedBox(
                        height: 260.h,
                        child: Center(
                          child: Text(
                            'No destinations found',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 260.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (item is Map<String, String>) {
                            // Destination item
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailsScreen(
                                      place: item,
                                      homeBloc: homeBloc,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 160.w,
                                margin: EdgeInsets.only(right: 16.w),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                                        child: Container(
                                          height: 160.h,
                                          width: double.infinity,
                                          child: item['image'] != null && item['image']!.isNotEmpty
                                              ? CachedNetworkImage(
                                            imageUrl: item['image']!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                            errorWidget: (context, url, error) => Image.asset(
                                              'assets/images/placeholder.jpg',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                              : Image.asset(
                                            'assets/images/placeholder.jpg',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 20.h,
                                              child: Text(
                                                item['name']!,
                                                style: Theme.of(context).textTheme.labelLarge,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Container(
                                              height: 32.h,
                                              child: Text(
                                                item['description'] ?? 'No description',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (item is Map<String, dynamic> && item['type'] == 'ad') {
                            // Native ad item
                            return Container(
                              width: 160.w,
                              margin: EdgeInsets.only(right: 16.w),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: AdWidget(ad: item['ad'] as NativeAd),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Hotel Booking Card
                Text(
                  'Book Your Stay',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    height: 100.h,
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Find the Best Hotels',
                                style: Theme.of(context).textTheme.labelLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Book your stay at top hotels nearby',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hotel booking not implemented yet')),
                            );
                          },
                          child: Text(
                            'Book Now',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Flight Booking Card
                Text(
                  'Book Your Flight',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    height: 100.h,
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Find the Best Flights',
                                style: Theme.of(context).textTheme.labelLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Book your Ticket to Fly',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Flights booking not implemented yet')),
                            );
                          },
                          child: Text(
                            'Book Now',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}