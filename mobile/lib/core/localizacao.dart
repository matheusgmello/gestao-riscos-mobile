import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Coordenada capturada pelo GPS do aparelho.
typedef Coordenada = ({double latitude, double longitude});

/// Pede permissão (se preciso) e lê a posição atual. Lança [String] com
/// mensagem pronta para exibir quando o GPS está desligado ou a permissão
/// foi negada.
Future<Coordenada> capturarLocalizacao({
  Future<bool> Function()? servicoHabilitado,
  Future<LocationPermission> Function()? checarPermissao,
  Future<LocationPermission> Function()? pedirPermissao,
  Future<Position> Function()? posicaoAtual,
}) async {
  final habilitado =
      servicoHabilitado ?? Geolocator.isLocationServiceEnabled;
  final checar = checarPermissao ?? Geolocator.checkPermission;
  final pedir = pedirPermissao ?? Geolocator.requestPermission;
  final posicao = posicaoAtual ??
      () => Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            ),
          );

  if (!await habilitado()) {
    throw 'Ative o GPS do celular para registrar a localização.';
  }

  var permissao = await checar();
  if (permissao == LocationPermission.denied) {
    permissao = await pedir();
  }
  if (permissao == LocationPermission.denied ||
      permissao == LocationPermission.deniedForever) {
    throw 'Permissão de localização negada.';
  }

  final p = await posicao();
  return (latitude: p.latitude, longitude: p.longitude);
}

/// Abre a localização no app de mapas do sistema (URI `geo:`). Sem SDK, sem key.
Future<void> abrirNoMapa(double latitude, double longitude) async {
  final uri = Uri.parse(
    'geo:$latitude,$longitude?q=$latitude,$longitude(Risco)',
  );
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Nenhum app de mapas encontrado.';
  }
}
