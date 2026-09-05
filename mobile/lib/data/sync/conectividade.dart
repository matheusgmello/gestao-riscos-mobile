import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de conexão do dispositivo. `online` é otimista: qualquer interface
/// ativa (wifi/mobile/ethernet) conta como online.
class Conectividade {
  Conectividade._({bool escutarPlataforma = true}) {
    if (escutarPlataforma) {
      Connectivity().onConnectivityChanged.listen(_atualizar);
      Connectivity().checkConnectivity().then(_atualizar);
    }
  }
  static Conectividade instance = Conectividade._();

  /// Substitui o singleton por um que não fala com a plataforma (testes).
  static void definirParaTeste({bool online = true}) {
    instance = Conectividade._(escutarPlataforma: false).._online = online;
  }

  bool _online = true;
  bool get online => _online;

  /// Simula uma mudança de conexão nos testes.
  void emitirParaTeste({required bool online}) => _atualizar(
    online ? [ConnectivityResult.wifi] : [ConnectivityResult.none],
  );

  final _controller = StreamController<bool>.broadcast();

  /// Emite `true` quando a conexão volta (offline -> online).
  Stream<bool> get aoVoltar => _controller.stream.where((online) => online);

  Stream<bool> get mudancas => _controller.stream;

  void _atualizar(List<ConnectivityResult> resultados) {
    final agora = resultados.any((r) => r != ConnectivityResult.none);
    if (agora != _online) {
      _online = agora;
      _controller.add(agora);
    }
  }
}
