sealed class HomeEvent {
  const HomeEvent();
}

class SearchRequested extends HomeEvent {
  const SearchRequested(this.query);
  final String query;
}
