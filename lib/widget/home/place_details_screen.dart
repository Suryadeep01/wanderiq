import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'bloc_home.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, String> place;
  final HomeBloc homeBloc;

  const PlaceDetailsScreen({super.key, required this.place, required this.homeBloc});

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _showMapView = false;
  GoogleMapController? _mapController;
  bool _showImageOverlay = false;

  @override
  void initState() {
    super.initState();
    widget.homeBloc.fetchPlaceDetails(widget.place['place_id']!);
    widget.homeBloc.fetchNearbyHotels(widget.place['latitude']!, widget.place['longitude']!);
    widget.homeBloc.fetchItineraries(widget.place['latitude']!, widget.place['longitude']!, widget.place['name']!);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showMapView = !_showMapView;
      _showImageOverlay = false;
    });
  }

  void _toggleImageOverlay() {
    setState(() {
      _showImageOverlay = !_showImageOverlay;
    });
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
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.place['name']!, style: TextStyle(fontSize: 20.sp, color: Colors.orange[300])),
          iconTheme: IconThemeData(color: Colors.orange[300]),
          actions: [
            IconButton(
              icon: Icon(
                _showMapView ? Icons.list : Icons.map,
                color: Colors.orange[300],
                size: 24.sp,
              ),
              tooltip: _showMapView ? 'Show List' : 'Show Map',
              onPressed: _toggleView,
            ),
          ],
        ),
        body: _showMapView ? _buildMapView() : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place Images with Swipe
            StreamBuilder<Map<String, dynamic>>(
              stream: widget.homeBloc.placeDetailsStream,
              initialData: const {},
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error loading images',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final details = snapshot.data ?? {};
                final images = (details['images'] as List?)?.cast<String>() ?? [widget.place['image'] ?? ''];
                return Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    // border: Border.all(color: Colors.orange[300]!, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: PageView.builder(
                      itemCount: images.isEmpty ? 1 : images.length,
                      itemBuilder: (context, index) {
                        final imageUrl = images.isEmpty ? null : images[index];
                        return imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 200.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                            : Image.asset(
                          'assets/images/placeholder.jpg',
                          height: 200.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),

            // Place Details
            StreamBuilder<Map<String, dynamic>>(
              stream: widget.homeBloc.placeDetailsStream,
              initialData: const {},
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error loading details',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final details = snapshot.data ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details['name'] ?? widget.place['name'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      details['address'] ?? widget.place['description'] ?? 'No description available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      details['phone'] ?? 'No phone available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange[300], size: 20.sp),
                        SizedBox(width: 4.w),
                        Text(
                          details['rating']?.toString() ?? 'No rating',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24.h),

            // Nearby Hotels
            Text(
              'Nearby Hotels',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16.h),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.homeBloc.nearbyHotelsStream,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error loading hotels',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final hotels = snapshot.data ?? [];
                if (hotels.isEmpty) {
                  return Text(
                    'No hotels found nearby',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12.w),
                        leading: hotel['image'] != null && hotel['image']!.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: CachedNetworkImage(
                            imageUrl: hotel['image']!,
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 24.r,
                              backgroundColor: Colors.orange[300],
                              child: Text(
                                hotel['name']?.substring(0, 1) ?? '',
                                style: TextStyle(fontSize: 18.sp, color: Colors.black),
                              ),
                            ),
                          ),
                        )
                            : CircleAvatar(
                          radius: 24.r,
                          backgroundColor: Colors.orange[300],
                          child: Text(
                            hotel['name']?.substring(0, 1) ?? '',
                            style: TextStyle(fontSize: 18.sp, color: Colors.black),
                          ),
                        ),
                        title: Text(
                          hotel['name'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        subtitle: Text(
                          hotel['address'] ?? 'No address',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.orange[300], size: 16.sp),
                            SizedBox(width: 4.w),
                            Text(
                              hotel['rating']?.toString() ?? 'N/A',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 24.h),

            // Itineraries
            Text(
              'Suggested Itineraries',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16.h),
            StreamBuilder<List<Map<String, String>>>(
              stream: widget.homeBloc.itinerariesStream,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Error loading itineraries',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final itineraries = snapshot.data ?? [];
                if (itineraries.isEmpty) {
                  return Text(
                    'No itineraries available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: itineraries.map((itinerary) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.h),
                      child: ExpansionTile(
                        title: Text(
                          itinerary['day'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              itinerary['activity'] ?? 'No activity',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.homeBloc.placeDetailsStream,
      initialData: const {},
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading map',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final details = snapshot.data ?? {};
        final latitude = double.tryParse(details['latitude'] ?? widget.place['latitude'] ?? '0') ?? 0;
        final longitude = double.tryParse(details['longitude'] ?? widget.place['longitude'] ?? '0') ?? 0;
        final placeName = details['name'] ?? widget.place['name'] ?? 'Unknown';
        final images = (details['images'] as List?)?.cast<String>() ?? [];

        if (latitude == 0 && longitude == 0) {
          return Center(
            child: Text(
              'Location data not available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(widget.place['place_id']!),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(
                    title: placeName,
                    onTap: _toggleImageOverlay,
                  ),
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.setMapStyle('''
                  [
                    {
                      "elementType": "geometry",
                      "stylers": [{"color": "#212121"}]
                    },
                    {
                      "elementType": "labels.text.fill",
                      "stylers": [{"color": "#757575"}]
                    },
                    {
                      "elementType": "labels.text.stroke",
                      "stylers": [{"color": "#212121"}]
                    },
                    {
                      "featureType": "administrative",
                      "elementType": "geometry",
                      "stylers": [{"color": "#757575"}]
                    },
                    {
                      "featureType": "road",
                      "elementType": "geometry.fill",
                      "stylers": [{"color": "#2c2c2c"}]
                    },
                    {
                      "featureType": "water",
                      "elementType": "geometry",
                      "stylers": [{"color": "#000000"}]
                    }
                  ]
                ''');
              },
            ),
            if (_showImageOverlay && images.isNotEmpty)
              Positioned(
                bottom: 16.h,
                left: 16.w,
                right: 16.w,
                child: Container(
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12.r),
                    // border: Border.all(color: Colors.orange[300]!, width: 2),
                  ),
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}