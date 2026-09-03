import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';
import 'gestor_form_screen.dart';

class GestoresScreen extends StatefulWidget {
  const GestoresScreen({super.key});

  @override
  State<GestoresScreen> createState() => _GestoresScreenState();
}

class _GestoresScreenState extends State<GestoresScreen> {
  late final UsuarioService _service = UsuarioService(TokenService());
  final _scroll = ScrollController();
  final _buscaCtrl = TextEditingController();
  Timer? _debounce;

  final List<UsuarioModel> _gestores = [];
  int _page = 1;
  bool _temMais = false;
  bool _carregando = true;
  bool _carregandoMais = false;
  Object? _erro;
  String? _busca;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _mais();
      }
    });
    _recarregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = await _service.listarGestores(page: 1, busca: _busca);
      if (!mounted) return;
      setState(() {
        _gestores
          ..clear()
          ..addAll(p.results);
        _page = 1;
        _temMais = p.hasNext;
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

  Future<void> _mais() async {
    if (_carregandoMais || !_temMais) return;
    setState(() => _carregandoMais = true);
    try {
      final p = await _service.listarGestores(page: _page + 1, busca: _busca);
      if (!mounted) return;
      setState(() {
        _gestores.addAll(p.results);
        _page++;
        _temMais = p.hasNext;
        _carregandoMais = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  void _aoBuscar(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      setState(() => _busca = v);
      _recarregar();
    });
  }

  Future<void> _novo() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const GestorFormScreen()));
    if (ok == true) _recarregar();
  }

  Future<void> _editar(UsuarioModel g) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GestorFormScreen(gestor: g)),
    );
    if (ok == true) _recarregar();
  }

  Future<void> _alternar(UsuarioModel g) async {
    final ativar = !g.ativo;
    if (!await confirmar(
      context,
      titulo: ativar ? 'Reativar gestor' : 'Desativar gestor',
      mensagem: '${g.nome} será ${ativar ? "reativado" : "desativado"}.',
      confirmar: ativar ? 'Reativar' : 'Desativar',
      destrutivo: !ativar,
    )) {
      return;
    }
    try {
      if (ativar) {
        await _service.reativarGestor(g.uuid);
      } else {
        await _service.desativarGestor(g.uuid);
      }
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestores')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.add),
        label: const Text('Novo gestor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: _aoBuscar,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, SIAPE ou e-mail',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _lista() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(child: Text('$_erro'));
    }
    if (_gestores.isEmpty) {
      return const Center(child: Text('Nenhum gestor.'));
    }
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 88),
        itemCount: _gestores.length + (_temMais ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _gestores.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final g = _gestores[i];
          return ListTile(
            title: Text(g.nome),
            subtitle: Text(
              'SIAPE ${g.siape} · ${g.isSuperuser ? "admin" : g.cargo}'
              '${g.ativo ? "" : " · inativo"}',
            ),
            leading: CircleAvatar(
              backgroundColor: g.ativo
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                g.ativo ? Icons.person : Icons.person_off,
                color: g.ativo
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? _editar(g) : _alternar(g),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(
                  value: 'alternar',
                  child: Text(g.ativo ? 'Desativar' : 'Reativar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
