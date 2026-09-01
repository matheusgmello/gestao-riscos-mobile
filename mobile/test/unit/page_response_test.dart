import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_risco_mobile/data/models/page_response.dart';

class _Item {
  _Item(this.id);
  final int id;
  static _Item fromJson(Map<String, dynamic> j) => _Item((j['id'] as num).toInt());
}

void main() {
  test('fromDrf lê count/next/results', () {
    final page = PageResponse.fromDrf({
      'count': 12,
      'next': 'http://x/?page=2',
      'previous': null,
      'results': [
        {'id': 1},
        {'id': 2},
      ],
    }, _Item.fromJson);

    expect(page.count, 12);
    expect(page.results.map((e) => e.id), [1, 2]);
    expect(page.hasNext, isTrue);
  });

  test('fromDrf sem next não tem próxima página', () {
    final page = PageResponse.fromDrf(
      {'count': 2, 'next': null, 'results': []},
      _Item.fromJson,
    );
    expect(page.hasNext, isFalse);
  });

  test('fromDrfAdmin usa page/total_pages', () {
    final page = PageResponse.fromDrfAdmin({
      'count': 40,
      'page': 1,
      'total_pages': 2,
      'results': [
        {'id': 9},
      ],
    }, _Item.fromJson);

    expect(page.page, 1);
    expect(page.totalPages, 2);
    expect(page.hasNext, isTrue);
    expect(page.results.single.id, 9);
  });
}
