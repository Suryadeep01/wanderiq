import 'package:rxdart/rxdart.dart';

class DashboardBloc {
  final _tabIndexSubject = BehaviorSubject<int>.seeded(0);

  Stream<int> get tabIndexStream => _tabIndexSubject.stream;

  void selectTab(int index) {
    _tabIndexSubject.add(index);
  }

  void dispose() {
    _tabIndexSubject.close();
  }
}