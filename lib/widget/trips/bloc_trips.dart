import 'package:rxdart/rxdart.dart';

class TripsBloc {
  // Stream for featured destinations (carousel)
  final _featuredDestinationsSubject = BehaviorSubject<List<Map<String, String>>>.seeded([
    {'name': 'Paris', 'image': 'paris.jpg'},
    {'name': 'Tokyo', 'image': 'tokyo.jpg'},
    {'name': 'New York', 'image': 'newyork.jpg'},
  ]);

  // Stream for popular places
  final _popularPlacesSubject = BehaviorSubject<List<Map<String, String>>>.seeded([
    {'name': 'London', 'description': 'Historic city with iconic landmarks'},
    {'name': 'Sydney', 'description': 'Vibrant city with stunning beaches'},
    {'name': 'Rome', 'description': 'Ancient ruins and rich culture'},
  ]);

  // Stream for search query
  final _searchQuerySubject = BehaviorSubject<String>.seeded('');

  // Getters for streams
  Stream<List<Map<String, String>>> get featuredDestinationsStream => _featuredDestinationsSubject.stream;
  Stream<List<Map<String, String>>> get popularPlacesStream => _popularPlacesSubject.stream;
  Stream<String> get searchQueryStream => _searchQuerySubject.stream;

  // Combined stream for filtered popular places
  Stream<List<Map<String, String>>> get filteredPopularPlacesStream => Rx.combineLatest2(
    _popularPlacesSubject.stream,
    _searchQuerySubject.stream,
        (List<Map<String, String>> places, String query) {
      if (query.isEmpty) return places;
      return places
          .where((place) =>
          place['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    },
  );

  // Methods to update state
  void addFeaturedDestination(String name, String image) {
    final current = _featuredDestinationsSubject.value;
    _featuredDestinationsSubject.add([...current, {'name': name, 'image': image}]);
  }

  void addPopularPlace(String name, String description) {
    final current = _popularPlacesSubject.value;
    _popularPlacesSubject.add([...current, {'name': name, 'description': description}]);
  }

  void updateSearchQuery(String query) {
    _searchQuerySubject.add(query);
  }

  void dispose() {
    _featuredDestinationsSubject.close();
    _popularPlacesSubject.close();
    _searchQuerySubject.close();
  }
}