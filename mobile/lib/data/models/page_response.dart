/// Paginação do DRF.
///
/// `PageNumberPagination` padrão devolve `{count, next, previous, results}`.
/// As listas administrativas customizadas (`/gestores/`, `/setores/admin/`)
/// devolvem `{count, page, total_pages, results}` — use [PageResponse.fromDrfAdmin].
class PageResponse<T> {
  const PageResponse({
    required this.results,
    required this.count,
    this.next,
    this.previous,
    this.page = 1,
    this.totalPages = 1,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;
  final int page;
  final int totalPages;

  bool get hasNext => next != null || page < totalPages;

  static List<T> _parseResults<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }

  factory PageResponse.fromDrf(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PageResponse<T>(
      results: _parseResults(json['results'], fromJson),
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }

  factory PageResponse.fromDrfAdmin(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final totalPages = (json['total_pages'] as num?)?.toInt() ?? 1;
    return PageResponse<T>(
      results: _parseResults(json['results'], fromJson),
      count: (json['count'] as num?)?.toInt() ?? 0,
      page: page,
      totalPages: totalPages,
    );
  }
}
