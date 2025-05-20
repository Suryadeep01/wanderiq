import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchBloc {
  static const String apiKey = 'AIzaSyA-2EfILnH7QmhA9pHTUGPRAwooHGzlvxs';
  static const int maxRecentSearches = 5;

  // Streams
  final _searchQuerySubject = BehaviorSubject<String>.seeded('');
  final _searchResultsSubject = BehaviorSubject<List<Map<String, String>>>.seeded([]);
  final _recentSearchesSubject = BehaviorSubject<List<String>>.seeded([]);
  final _nearbyPlacesSubject = BehaviorSubject<List<Map<String, String>>>.seeded([]);
  final _filterSubject = BehaviorSubject<String>.seeded('all');
  final _mapMarkersSubject = BehaviorSubject<Set<Marker>>.seeded({});
  final _isNearbyActiveSubject = BehaviorSubject<bool>.seeded(false);

  // Getters for streams
  Stream<String> get searchQueryStream => _searchQuerySubject.stream;
  Stream<List<Map<String, String>>> get searchResultsStream => _searchResultsSubject.stream;
  Stream<List<String>> get recentSearchesStream => _recentSearchesSubject.stream;
  Stream<List<Map<String, String>>> get nearbyPlacesStream => _nearbyPlacesSubject.stream;
  Stream<String> get filterStream => _filterSubject.stream;
  Stream<Set<Marker>> get mapMarkersStream => _mapMarkersSubject.stream;
  Stream<bool> get isNearbyActiveStream => _isNearbyActiveSubject.stream;

  SearchBloc() {
    // Load recent searches on initialization
    _loadRecentSearches();
  }

  // Fetch place photo URL
  Future<String> fetchPlacePhoto(String? photoReference) async {
    if (photoReference == null || photoReference.isEmpty) return '';
    final url = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=$photoReference&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.request!.url.toString();
      }
      print('Photo API error: ${response.statusCode}');
      return '';
    } catch (e) {
      print('Error fetching photo: $e');
      return '';
    }
  }

  // Search places using Text Search API
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      if (!_searchResultsSubject.isClosed) {
        _searchResultsSubject.add([]);
      }
      return;
    }

    final url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final places = data['results'] as List;
          final results = <Map<String, String>>[];
          for (var place in places) {
            final photoReference = place['photos'] != null && (place['photos'] as List).isNotEmpty
                ? place['photos'][0]['photo_reference']
                : null;
            final photoUrl = await fetchPlacePhoto(photoReference);
            results.add({
              'name': place['name'] ?? 'Unknown',
              'description': place['formatted_address'] ?? 'No description available',
              'image': photoUrl,
              'place_id': place['place_id'] ?? '',
              'latitude': place['geometry']?['location']?['lat']?.toString() ?? '0',
              'longitude': place['geometry']?['location']?['lng']?.toString() ?? '0',
            });
          }
          if (!_searchResultsSubject.isClosed) {
            _searchResultsSubject.add(results);
          }
          // Save to recent searches
          await _saveRecentSearch(query);
        } else {
          print('Places API error: ${data['status']}');
          if (!_searchResultsSubject.isClosed) {
            _searchResultsSubject.add([]);
          }
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        if (!_searchResultsSubject.isClosed) {
          _searchResultsSubject.add([]);
        }
      }
    } catch (e) {
      print('Error searching places: $e');
      if (!_searchResultsSubject.isClosed) {
        _searchResultsSubject.add([]);
      }
    }
  }

  // Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    if (!_recentSearchesSubject.isClosed) {
      _recentSearchesSubject.add(searches);
    }
  }

  // Save a search query to recent searches
  Future<void> _saveRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    if (!searches.contains(query)) {
      searches.insert(0, query);
      if (searches.length > maxRecentSearches) {
        searches.removeLast();
      }
      await prefs.setStringList('recent_searches', searches);
      if (!_recentSearchesSubject.isClosed) {
        _recentSearchesSubject.add(searches);
      }
    }
  }

  // Get current location
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Fetch nearby places based on filter
  Future<void> fetchNearbyPlaces({String filter = 'all'}) async {
    final position = await _getCurrentLocation();
    if (position == null) {
      if (!_nearbyPlacesSubject.isClosed) {
        _nearbyPlacesSubject.add([]);
      }
      if (!_mapMarkersSubject.isClosed) {
        _mapMarkersSubject.add({});
      }
      return;
    }

    String type;
    switch (filter) {
      case 'hotel':
        type = 'lodging';
        break;
      case 'restaurant':
        type = 'restaurant';
        break;
      case 'attraction':
        type = 'tourist_attraction';
        break;
      default:
        type = ''; // No type filter for 'all'
    }

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=10000${type.isNotEmpty ? '&type=$type' : ''}&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final places = data['results'] as List;
          final results = <Map<String, String>>[];
          final markers = <Marker>{};
          for (var place in places) {
            final photoReference = place['photos'] != null && (place['photos'] as List).isNotEmpty
                ? place['photos'][0]['photo_reference']
                : null;
            final photoUrl = await fetchPlacePhoto(photoReference);
            final placeData = {
              'name': place['name'] ?? 'Unknown',
              'description': place['vicinity'] ?? 'No address available',
              'image': photoUrl,
              'place_id': place['place_id'] ?? '',
              'latitude': place['geometry']?['location']?['lat']?.toString() ?? '0',
              'longitude': place['geometry']?['location']?['lng']?.toString() ?? '0',
            };
            // results.add(placeData);
            markers.add(
              Marker(
                markerId: MarkerId(place['place_id'] ?? place['name'] ?? 'unknown'),
                position: LatLng(
                  place['geometry']['location']['lat'] ?? 0,
                  place['geometry']['location']['lng'] ?? 0,
                ),
                infoWindow: InfoWindow(title: place['name'] ?? 'Unknown'),
                // onTap: () {
                //   // Emulate navigation by emitting the place data
                //   if (!_searchResultsSubject.isClosed) {
                //     _searchResultsSubject.add([placeData]);
                //   }
                // },
              ),
            );
          }
          if (!_nearbyPlacesSubject.isClosed) {
            _nearbyPlacesSubject.add(results);
          }
          if (!_mapMarkersSubject.isClosed) {
            _mapMarkersSubject.add(markers);
          }
        } else {
          print('Nearby API error: ${data['status']}');
          if (!_nearbyPlacesSubject.isClosed) {
            _nearbyPlacesSubject.add([]);
          }
          if (!_mapMarkersSubject.isClosed) {
            _mapMarkersSubject.add({});
          }
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        if (!_nearbyPlacesSubject.isClosed) {
          _nearbyPlacesSubject.add([]);
        }
        if (!_mapMarkersSubject.isClosed) {
          _mapMarkersSubject.add({});
        }
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      if (!_nearbyPlacesSubject.isClosed) {
        _nearbyPlacesSubject.add([]);
      }
      if (!_mapMarkersSubject.isClosed) {
        _mapMarkersSubject.add({});
      }
    }
  }

  // Update search query
  void updateSearchQuery(String query) {
    if (!_searchQuerySubject.isClosed) {
      _searchQuerySubject.add(query);
    }
    searchPlaces(query);
    // Deactivate nearby when searching
    if (!_isNearbyActiveSubject.isClosed) {
      _isNearbyActiveSubject.add(false);
    }
  }

  // Toggle nearby mode
  void toggleNearby() async {
    final isActive = !_isNearbyActiveSubject.value;
    if (!_isNearbyActiveSubject.isClosed) {
      _isNearbyActiveSubject.add(isActive);
    }
    if (isActive) {
      await fetchNearbyPlaces(filter: _filterSubject.value);
    } else {
      if (!_nearbyPlacesSubject.isClosed) {
        _nearbyPlacesSubject.add([]);
      }
      if (!_mapMarkersSubject.isClosed) {
        _mapMarkersSubject.add({});
      }
    }
  }

  // Update filter
  void updateFilter(String filter) {
    if (!_filterSubject.isClosed) {
      _filterSubject.add(filter);
    }
    if (_isNearbyActiveSubject.value) {
      fetchNearbyPlaces(filter: filter);
    }
  }

  // Dispose streams
  void dispose() {
    _searchQuerySubject.close();
    _searchResultsSubject.close();
    _recentSearchesSubject.close();
    _nearbyPlacesSubject.close();
    _filterSubject.close();
    _mapMarkersSubject.close();
    _isNearbyActiveSubject.close();
  }
}