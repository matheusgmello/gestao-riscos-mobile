import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../data/models/unidade_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/equipe_service.dart';
import '../../data/services/token_service.dart';
import '../../data/sync/conectividade.dart';
import '../../widgets/estado.dart';
import '../../widgets/sync_status_bar.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key, this.service, this.tokens});

  final EquipeService? service;
  final TokenService? tokens;

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  late final TokenService _tokens = widget.tokens ?? TokenService();
  late final EquipeService _service = widget.service ?? EquipeService(_tokens);

  List<UnidadeModel> _setores = [];
  UnidadeModel? _setor;
  List<UsuarioModel> _membros = [];
  bool _carregando = true;
  Object? _erro;

  bool _online = Conectividade.instance.online;
  StreamSubscription<bool>? _conSub;

  @override
  void initState() {
    super.initState();
    _iniciar();
    _conSub = Conectividade.instance.mudancas.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    _conSub?.cancel();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final u = await _tokens.getUsuario();
    setState(() {
      _setores = u?.setores ?? [];
      _setor = _setores.isNotEmpty ? _setores.first : null;
    });
    await _carregarMembros();
  }

  Future<void> _carregarMembros() async {
    if (_setor == null) {
      setState(() => _carregando = false);
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final m = await _service.membros(_setor!.id);
      if (!mounted) return;
      setState(() {
        _membros = m;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e;
        _carregando = false;
      });
    }
  }

  Future<void> _adicionar() async {
    final setor = _setor;
    if (setor == null) return;
    final siape = await _pedirSiape();
    if (siape == null || siape.isEmpty) return;
    try {
      await _service.adicionar(setor.id, siape);
      if (!mounted) return;
      mostrarOk(context, 'Membro adicionado.');
      _carregarMembros();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<String?> _pedirSiape() async {
    final ctrl = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Adicionar membro'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'SIAPE'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isEmpty || int.tryParse(v) == null) return;
                Navigator.pop(context, v);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _remover(UsuarioModel m) async {
    final setor = _setor;
    if (setor == null) return;
    if (!await confirmar(
      context,
      titulo: 'Remover membro',
      mensagem: '${m.nome} sai da equipe de ${setor.rotulo}.',
      confirmar: 'Remover',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _service.remover(setor.id, m.id);
      if (!mounted) return;
      mostrarOk(context, 'Membro removido.');
      _carregarMembros();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipe')),
      floatingActionButton: (_setor == null || !_online)
          ? null
          : FloatingActionButton.extended(
              onPressed: _adicionar,
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar'),
            ),
      body: Column(
        children: [const SyncStatusBar(), Expanded(child: _corpo())],
      ),
    );
  }

  Widget _corpo() {
    if (_setores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Você não está vinculado a nenhuma unidade.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        if (_setores.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<int>(
              initialValue: _setor?.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Unidade'),
              items: [
                for (final s in _setores)
                  DropdownMenuItem(value: s.id, child: Text(s.rotulo)),
              ],
              onChanged: (v) {
                setState(() => _setor = _setores.firstWhere((s) => s.id == v));
                _carregarMembros();
              },
            ),
          ),
        Expanded(child: _lista()),
      ],
    );
  }

  Widget _lista() {
    if (_carregando) {
      return const SkeletonLista(altura: 68);
    }
    if (_erro != null) {
      return EstadoErro(erro: _erro!, onTentar: _carregarMembros);
    }
    if (_membros.isEmpty) {
      return const EstadoVazio(
        icone: Icons.groups_outlined,
        titulo: 'Nenhum membro',
        detalhe: 'Esta unidade ainda não tem gestores vinculados.',
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarMembros,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        itemCount: _membros.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = _membros[i];
          return ListTile(
            title: Text(m.nome),
            subtitle: Text(
              'SIAPE ${m.siape} · ${m.isSuperuser ? "admin" : m.cargo}',
            ),
            trailing: _online
                ? IconButton(
                    icon: const Icon(Icons.person_remove_outlined),
                    tooltip: 'Remover',
                    onPressed: () => _remover(m),
                  )
                : null,
          );
        },
      ),
    );
  }
}
