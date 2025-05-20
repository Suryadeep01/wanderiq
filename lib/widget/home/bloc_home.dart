import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import '../../util/ad_manager.dart';

class HomeBloc {
  static const String apiKey = 'AIzaSyA-2EfILnH7QmhA9pHTUGPRAwooHGzlvxs';

  final _featuredDestinationsSubject = BehaviorSubject<List<Map<String, String>>>.seeded([]);
  final _popularDestinationsSubject = BehaviorSubject<List<Map<String, String>>>.seeded([]);
  final _searchQuerySubject = BehaviorSubject<String>.seeded('');
  final _placeDetailsSubject = BehaviorSubject<Map<String, dynamic>>.seeded({});
  final _nearbyHotelsSubject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final _itinerariesSubject = BehaviorSubject<List<Map<String, String>>>.seeded([]);
  final _adManager = AdManager();

  // Expose ad streams
  Stream<bool> get isBannerAdLoadedStream => _adManager.isBannerAdLoadedStream;
  Stream<BannerAd?> get bannerAdStream => _adManager.bannerAdStream;
  Stream<bool> get isNativeAdLoadedStream => _adManager.isNativeAdLoadedStream;
  Stream<NativeAd?> get nativeAdStream => _adManager.nativeAdStream;

  // Combine popular destinations with native ads (insert ad every 10 items)
  Stream<List<dynamic>> get filteredPopularDestinationsWithAdsStream => Rx.combineLatest3(
    _popularDestinationsSubject.stream,
    _searchQuerySubject.stream,
    _adManager.nativeAdStream,
        (List<Map<String, String>> destinations, String query, NativeAd? nativeAd) {
      List<Map<String, String>> filteredDestinations = query.isEmpty
          ? destinations
          : destinations.where((dest) => dest['name']!.toLowerCase().contains(query.toLowerCase())).toList();

      List<dynamic> combinedList = [];
      for (int i = 0; i < filteredDestinations.length; i++) {
        combinedList.add(filteredDestinations[i]);
        if (i % 10 == 9 && nativeAd != null) {
          combinedList.add({'type': 'ad', 'ad': nativeAd});
        }
      }
      return combinedList;
    },
  );

  Stream<List<Map<String, String>>> get featuredDestinationsStream => _featuredDestinationsSubject.stream;
  Stream<List<Map<String, String>>> get popularDestinationsStream => _popularDestinationsSubject.stream;
  Stream<String> get searchQueryStream => _searchQuerySubject.stream;
  Stream<List<Map<String, String>>> get filteredFeaturedDestinationsStream => Rx.combineLatest2(
    _featuredDestinationsSubject.stream,
    _searchQuerySubject.stream,
        (List<Map<String, String>> destinations, String query) {
      if (query.isEmpty) return destinations;
      return destinations.where((dest) => dest['name']!.toLowerCase().contains(query.toLowerCase())).toList();
    },
  );
  Stream<Map<String, dynamic>> get placeDetailsStream => _placeDetailsSubject.stream;
  Stream<List<Map<String, dynamic>>> get nearbyHotelsStream => _nearbyHotelsSubject.stream;
  Stream<List<Map<String, String>>> get itinerariesStream => _itinerariesSubject.stream;

  HomeBloc() {
    _adManager.loadBannerAd(
      onAdLoaded: () => print('Banner ad initialized'),
      onAdFailed: () => print('Banner ad failed to initialize'),
    );
    _adManager.loadNativeAd(
      onAdLoaded: () => print('Native ad initialized'),
      onAdFailed: () => print('Native ad failed to initialize'),
    );
    initializeFeaturedDestinations();
    initializePopularDestinations();
  }

  Future<String> fetchPlacePhoto(String? photoReference) async {
    if (photoReference == null || photoReference.isEmpty) {
      return '';
    }
    final url = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$photoReference&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.request!.url.toString();
      }
      print('Photo API returned status: ${response.statusCode}');
      return '';
    } catch (e) {
      print('Error fetching photo: $e');
      return '';
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      initializeFeaturedDestinations();
      initializePopularDestinations();
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final places = data['results'] as List;
          final newDestinations = <Map<String, String>>[];
          for (var place in places) {
            final photoReference = place['photos'] != null && (place['photos'] as List).isNotEmpty
                ? place['photos'][0]['photo_reference']
                : null;
            final photoUrl = await fetchPlacePhoto(photoReference);
            newDestinations.add({
              'name': place['name'] ?? 'Unknown',
              'description': place['formatted_address'] ?? 'No description available',
              'image': photoUrl,
              'place_id': place['place_id'] ?? '',
              'latitude': place['geometry']?['location']?['lat']?.toString() ?? '0',
              'longitude': place['geometry']?['location']?['lng']?.toString() ?? '0',
            });
          }
          _featuredDestinationsSubject.add(newDestinations.take(5).toList());
          _popularDestinationsSubject.add(newDestinations);
        } else {
          print('Places API error: ${data['status']}');
          _featuredDestinationsSubject.add([]);
          _popularDestinationsSubject.add([]);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _featuredDestinationsSubject.add([]);
        _popularDestinationsSubject.add([]);
      }
    } catch (e) {
      print('Error searching places: $e');
      _featuredDestinationsSubject.add([]);
      _popularDestinationsSubject.add([]);
    }
  }

  Future<void> initializeFeaturedDestinations() async {
    const cities = ['Paris', 'New York', 'Tokyo', 'London'];
    final updated = <Map<String, String>>[];
    for (var city in cities) {
      final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$city&key=$apiKey';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            final place = data['results'][0];
            final photoReference = place['photos'] != null && (place['photos'] as List).isNotEmpty
                ? place['photos'][0]['photo_reference']
                : null;
            final photoUrl = await fetchPlacePhoto(photoReference);
            updated.add({
              'name': place['name'] ?? city,
              'image': photoUrl,
              'place_id': place['place_id'] ?? '',
              'latitude': place['geometry']?['location']?['lat']?.toString() ?? '0',
              'longitude': place['geometry']?['location']?['lng']?.toString() ?? '0',
              'description': place['formatted_address'] ?? 'No description available',
            });
          } else {
            print('Featured destinations API error for $city: ${data['status']}');
          }
        } else {
          print('HTTP error for $city: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching $city: $e');
      }
    }
    _featuredDestinationsSubject.add(updated);
  }

  Future<void> initializePopularDestinations() async {
    const query = 'top tourist destinations';
    final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final places = data['results'] as List;
          final updated = <Map<String, String>>[];
          for (var place in places) {
            final photoReference = place['photos'] != null && (place['photos'] as List).isNotEmpty
                ? place['photos'][0]['photo_reference']
                : null;
            final photoUrl = await fetchPlacePhoto(photoReference);
            updated.add({
              'name': place['name'] ?? 'Unknown',
              'description': place['formatted_address'] ?? 'No description available',
              'image': photoUrl,
              'place_id': place['place_id'] ?? '',
              'latitude': place['geometry']?['location']?['lat']?.toString() ?? '0',
              'longitude': place['geometry']?['location']?['lng']?.toString() ?? '0',
            });
          }
          _popularDestinationsSubject.add(updated);
        } else {
          print('Popular destinations API error: ${data['status']}');
          _popularDestinationsSubject.add([]);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _popularDestinationsSubject.add([]);
      }
    } catch (e) {
      print('Error fetching popular destinations: $e');
      _popularDestinationsSubject.add([]);
    }
  }

  Future<void> fetchPlaceDetails(String placeId) async {
    if (placeId.isEmpty) {
      _placeDetailsSubject.add({});
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number,rating,reviews,photos,geometry&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final photos = result['photos'] != null
              ? (result['photos'] as List).map((photo) => photo['photo_reference']).toList()
              : [];
          final photoUrls = <String>[];
          for (var ref in photos.take(5)) {
            final url = await fetchPlacePhoto(ref);
            if (url.isNotEmpty) photoUrls.add(url);
          }
          final details = {
            'name': result['name'] ?? 'Unknown',
            'address': result['formatted_address'] ?? 'No address available',
            'phone': result['formatted_phone_number'] ?? 'No phone available',
            'rating': result['rating']?.toString() ?? 'No rating',
            'reviews': result['reviews'] ?? [],
            'images': photoUrls,
            'latitude': result['geometry']?['location']?['lat']?.toString() ?? '0',
            'longitude': result['geometry']?['location']?['lng']?.toString() ?? '0',
          };
          _placeDetailsSubject.add(details);
        } else {
          print('Place Details API error: ${data['status']}');
          _placeDetailsSubject.add({});
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _placeDetailsSubject.add({});
      }
    } catch (e) {
      print('Error fetching place details: $e');
      _placeDetailsSubject.add({});
    }
  }

  Future<void> fetchNearbyHotels(String latitude, String longitude) async {
    if (latitude.isEmpty || longitude.isEmpty || latitude == '0' || longitude == '0') {
      _nearbyHotelsSubject.add([]);
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=5000&type=lodging&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final hotels = data['results'] as List;
          final hotelList = <Map<String, dynamic>>[];
          for (var hotel in hotels) {
            final photoReference = hotel['photos'] != null && (hotel['photos'] as List).isNotEmpty
                ? hotel['photos'][0]['photo_reference']
                : null;
            final photoUrl = await fetchPlacePhoto(photoReference);
            hotelList.add({
              'name': hotel['name'] ?? 'Unknown Hotel',
              'address': hotel['vicinity'] ?? 'No address available',
              'rating': hotel['rating']?.toString() ?? 'No rating',
              'image': photoUrl,
            });
          }
          _nearbyHotelsSubject.add(hotelList);
        } else {
          print('Nearby Search API error: ${data['status']}');
          _nearbyHotelsSubject.add([]);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _nearbyHotelsSubject.add([]);
      }
    } catch (e) {
      print('Error fetching nearby hotels: $e');
      _nearbyHotelsSubject.add([]);
    }
  }

  Future<void> fetchItineraries(String latitude, String longitude, String placeName) async {
    if (latitude.isEmpty || longitude.isEmpty || latitude == '0' || longitude == '0') {
      _itinerariesSubject.add([
        {'day': 'Day 1', 'activity': 'Explore the main attractions in $placeName'},
      ]);
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=10000&type=tourist_attraction&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final attractions = data['results'] as List;
          final itineraries = <Map<String, String>>[];
          for (int i = 0; i < 3 && i < attractions.length; i++) {
            final attraction = attractions[i];
            itineraries.add({
              'day': 'Day ${i + 1}',
              'activity': 'Visit ${attraction['name'] ?? 'a local attraction'} and explore nearby areas',
            });
          }
          if (itineraries.isEmpty) {
            itineraries.add({
              'day': 'Day 1',
              'activity': 'Explore the main attractions in $placeName',
            });
          }
          _itinerariesSubject.add(itineraries);
        } else {
          print('Attractions API error: ${data['status']}');
          _itinerariesSubject.add([
            {'day': 'Day 1', 'activity': 'Explore the main attractions in $placeName'},
          ]);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _itinerariesSubject.add([
          {'day': 'Day 1', 'activity': 'Explore the main attractions in $placeName'},
        ]);
      }
    } catch (e) {
      print('Error fetching attractions: $e');
      _itinerariesSubject.add([
        {'day': 'Day 1', 'activity': 'Explore the main attractions in $placeName'},
      ]);
    }
  }

  void refreshCachedData() {
    if (_featuredDestinationsSubject.hasValue) {
      _featuredDestinationsSubject.add(_featuredDestinationsSubject.value);
    }
    if (_popularDestinationsSubject.hasValue) {
      _popularDestinationsSubject.add(_popularDestinationsSubject.value);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuerySubject.add(query);
    searchPlaces(query);
  }

  void dispose() {
    _featuredDestinationsSubject.close();
    _popularDestinationsSubject.close();
    _searchQuerySubject.close();
    _placeDetailsSubject.close();
    _nearbyHotelsSubject.close();
    _itinerariesSubject.close();
    _adManager.dispose();
  }
}