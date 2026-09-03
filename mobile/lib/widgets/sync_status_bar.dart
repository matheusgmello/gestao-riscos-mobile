import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/sync/conectividade.dart';
import '../data/sync/motor_sync.dart';

/// Faixa fina que mostra o estado da sincronização offline:
/// offline, sincronizando, N alterações pendentes ou conflitos descartados.
class SyncStatusBar extends StatefulWidget {
  const SyncStatusBar({super.key});

  @override
  State<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends State<SyncStatusBar> {
  bool _online = Conectividade.instance.online;
  EstadoSync _estado = EstadoSync.ocioso;
  ResumoSync _resumo = const ResumoSync();

  @override
  void initState() {
    super.initState();
    Conectividade.instance.mudancas.listen((v) {
      if (mounted) setState(() => _online = v);
    });
    MotorSync.instance.estado.listen((e) {
      if (mounted) setState(() => _estado = e);
    });
    MotorSync.instance.resumo.listen((r) {
      if (mounted) setState(() => _resumo = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ({IconData icone, String texto, Color cor})? info = _info(
      Theme.of(context).colorScheme,
    );
    if (info == null) return const SizedBox.shrink();
    return Material(
      color: info.cor.withValues(alpha: 0.12),
      child: InkWell(
        onTap: _online ? MotorSync.instance.sincronizar : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              if (_estado == EstadoSync.sincronizando)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(info.icone, size: 16, color: info.cor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.texto,
                  style: TextStyle(color: info.cor, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icone, String texto, Color cor})? _info(ColorScheme cores) {
    if (!_online) {
      final p = _resumo.pendentes;
      return (
        icone: Icons.cloud_off,
        texto: p > 0
            ? 'Offline · $p ${p == 1 ? "alteração" : "alterações"} aguardando envio'
            : 'Offline · mostrando dados salvos',
        cor: cores.onSurfaceVariant,
      );
    }
    if (_estado == EstadoSync.sincronizando) {
      return (
        icone: Icons.sync,
        texto: 'Sincronizando...',
        cor: cores.primary,
      );
    }
    if (_resumo.conflitos > 0) {
      return (
        icone: Icons.merge_type,
        texto:
            '${_resumo.conflitos} ${_resumo.conflitos == 1 ? "alteração local foi descartada" : "alterações locais foram descartadas"} por conflito',
        cor: AppColors.nivelAlto,
      );
    }
    if (_resumo.pendentes > 0) {
      return (
        icone: Icons.cloud_upload_outlined,
        texto:
            '${_resumo.pendentes} ${_resumo.pendentes == 1 ? "alteração pendente" : "alterações pendentes"} · toque para enviar',
        cor: cores.primary,
      );
    }
    return null;
  }
}
