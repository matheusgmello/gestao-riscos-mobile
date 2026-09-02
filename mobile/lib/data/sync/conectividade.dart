import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de conexão do dispositivo. `online` é otimista: qualquer interface
/// ativa (wifi/mobile/ethernet) conta como online.
class Conectividade {
  Conectividade._() {
    Connectivity().onConnectivityChanged.listen(_atualizar);
    Connectivity().checkConnectivity().then(_atualizar);
  }
  static final Conectividade instance = Conectividade._();

  bool _online = true;
  bool get online => _online;

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
