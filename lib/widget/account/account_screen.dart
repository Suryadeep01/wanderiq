import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'bloc_account.dart';




class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeBloc = AccountBloc();

    return Scaffold(
      appBar: AppBar(
        title: Text('Wanderiq', style: TextStyle(fontSize: 20.sp, color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              StreamBuilder<String>(
                stream: homeBloc.searchQueryStream,
                initialData: '',
                builder: (context, snapshot) {
                  return TextField(
                    decoration: InputDecoration(
                      hintText: 'Search destinations...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: homeBloc.updateSearchQuery,
                  );
                },
              ),
              SizedBox(height: 24.h),

              // Featured Destinations Carousel
              Text(
                'Featured Destinations',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16.h),
              StreamBuilder<List<Map<String, String>>>(
                stream: homeBloc.featuredDestinationsStream,
                initialData: const [],
                builder: (context, snapshot) {
                  final destinations = snapshot.data ?? [];
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
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.symmetric(horizontal: 5.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.asset(
                                    'assets/images/${destination['image']}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/placeholder.jpg',
                                        fit: BoxFit.cover,
                                      );
                                    },
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
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => homeBloc.addFeaturedDestination('New City', 'newcity.jpg'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                ),
                child: Text(
                  'Add Featured Destination',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
              SizedBox(height: 24.h),

              // Popular Places
              Text(
                'Popular Places',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16.h),
              StreamBuilder<List<Map<String, String>>>(
                stream: homeBloc.filteredPopularPlacesStream,
                initialData: const [],
                builder: (context, snapshot) {
                  final places = snapshot.data ?? [];
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12.w),
                          leading: CircleAvatar(
                            radius: 24.r,
                            backgroundColor: Colors.blueAccent.shade100,
                            child: Text(
                              places[index]['name']!.substring(0, 1),
                              style: TextStyle(fontSize: 18.sp, color: Colors.white),
                            ),
                          ),
                          title: Text(
                            places[index]['name']!,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            places[index]['description']!,
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to place details
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => homeBloc.addPopularPlace('New Place', 'Exciting destination'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                ),
                child: Text(
                  'Add Popular Place',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}