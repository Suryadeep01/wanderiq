import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../home/bloc_home.dart';
import '../home/place_details_screen.dart';
import 'bloc_search.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late SearchBloc searchBloc;
  final _mapController = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    searchBloc = SearchBloc();
  }

  @override
  void dispose() {
    searchBloc.dispose();
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
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[800],
          selectedColor: Colors.orange[300],
          labelStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Search', style: TextStyle(fontSize: 20.sp, color: Colors.orange[300])),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: StreamBuilder<String>(
                stream: searchBloc.searchQueryStream,
                initialData: '',
                builder: (context, snapshot) {
                  return TextField(
                    decoration: InputDecoration(
                      hintText: 'Search destinations...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    ),
                    style: TextStyle(color: Colors.white),
                    onChanged: searchBloc.updateSearchQuery,
                  );
                },
              ),
            ),
            // Recent Searches and Nearby Toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      StreamBuilder<bool>(
                        stream: searchBloc.isNearbyActiveStream,
                        initialData: false,
                        builder: (context, snapshot) {
                          return TextButton(
                            onPressed: searchBloc.toggleNearby,
                            child: Text(
                              snapshot.data! ? 'Hide Nearby' : 'Show Nearby',
                              style: TextStyle(color: Colors.orange[300], fontSize: 14.sp),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  StreamBuilder<List<String>>(
                    stream: searchBloc.recentSearchesStream,
                    initialData: const [],
                    builder: (context, snapshot) {
                      final searches = snapshot.data ?? [];
                      if (searches.isEmpty) {
                        return Text(
                          'No recent searches',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      }
                      return SizedBox(
                        height: 40.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: searches.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: ActionChip(
                                label: Text(searches[index]),
                                onPressed: () {
                                  searchBloc.updateSearchQuery(searches[index]);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Nearby Map and Places
            Expanded(
              child: StreamBuilder<bool>(
                stream: searchBloc.isNearbyActiveStream,
                initialData: false,
                builder: (context, nearbySnapshot) {
                  if (!nearbySnapshot.data!) {
                    // Show search results when nearby is not active
                    return StreamBuilder<List<Map<String, String>>>(
                      stream: searchBloc.searchResultsStream,
                      initialData: const [],
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final places = snapshot.data ?? [];
                        if (places.isEmpty) {
                          return Center(
                            child: Text(
                              'No results found',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return _buildPlaceCard(context, place);
                          },
                        );
                      },
                    );
                  }
                  // Show map and filtered places when nearby is active
                  return Column(
                    children: [
                      // Map (Top Half)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: StreamBuilder<Set<Marker>>(
                          stream: searchBloc.mapMarkersStream,
                          initialData: const {},
                          builder: (context, snapshot) {
                            return GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(0, 0),
                                zoom: 12,
                              ),
                              markers: snapshot.data ?? {},
                              // onMapCreated: (controller) async {
                              //   _mapController.complete(controller);
                              //   final position = await searchBloc._getCurrentLocation();
                              //   if (position != null) {
                              //     controller.animateCamera(
                              //       CameraUpdate.newCameraPosition(
                              //         CameraPosition(
                              //           target: LatLng(position.latitude, position.longitude),
                              //           zoom: 12,
                              //         ),
                              //       ),
                              //     );
                              //   }
                              // },
                            );
                          },
                        ),
                      ),
                      // Filters
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        child: StreamBuilder<String>(
                          stream: searchBloc.filterStream,
                          initialData: 'all',
                          builder: (context, snapshot) {
                            final currentFilter = snapshot.data ?? 'all';
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildFilterButton(context, 'All', 'all', currentFilter),
                                _buildFilterButton(context, 'Hotels', 'hotel', currentFilter),
                                _buildFilterButton(context, 'Restaurants', 'restaurant', currentFilter),
                                _buildFilterButton(context, 'Attractions', 'attraction', currentFilter),
                              ],
                            );
                          },
                        ),
                      ),
                      // Nearby Places List (Bottom Half)
                      Expanded(
                        child: StreamBuilder<List<Map<String, String>>>(
                          stream: searchBloc.nearbyPlacesStream,
                          initialData: const [],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final places = snapshot.data ?? [];
                            if (places.isEmpty) {
                              return Center(
                                child: Text(
                                  'No nearby places found',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: places.length,
                              itemBuilder: (context, index) {
                                final place = places[index];
                                return _buildPlaceCard(context, place);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, Map<String, String> place) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(
                  place: place,
                  homeBloc: HomeBloc(), // Assuming HomeBloc handles details
                ),
              ),
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
                child: SizedBox(
                  width: 100.w,
                  height: 100.h,
                  child: place['image'] != null && place['image']!.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: place['image']!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[700],
                      child: const Center(child: Icon(Icons.error, color: Colors.white)),
                    ),
                  )
                      : Container(
                    color: Colors.grey[700],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name']!,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        place['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, String label, String filter, String currentFilter) {
    final isSelected = filter == currentFilter;
    return GestureDetector(
      onTap: () {
        searchBloc.updateFilter(filter);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[300] : Colors.grey[800],
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}