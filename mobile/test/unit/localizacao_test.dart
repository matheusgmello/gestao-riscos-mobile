import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gestao_risco_mobile/core/localizacao.dart';

void main() {
  group('enderecoDe', () {
    test('monta rua + número + bairro', () async {
      final s = await enderecoDe(-29.7, -53.7, geocoder: (_, _) async => [
            const Placemark(
              street: 'Avenida Roraima',
              subThoroughfare: '1000',
              subLocality: 'Camobi',
              locality: 'Santa Maria',
            ),
          ]);
      expect(s, 'Avenida Roraima, 1000 — Camobi — Santa Maria');
    });

    test('cai para a cidade quando não tem rua', () async {
      final s = await enderecoDe(-29.7, -53.7, geocoder: (_, _) async => [
            const Placemark(locality: 'Santa Maria'),
          ]);
      expect(s, 'Santa Maria');
    });

    test('lista vazia => null', () async {
      expect(await enderecoDe(0, 0, geocoder: (_, _) async => []), isNull);
    });

    test('erro do geocoder => null (UI usa só as coordenadas)', () async {
      final s = await enderecoDe(0, 0, geocoder: (_, _) async => throw 'x');
      expect(s, isNull);
    });
  });
}
