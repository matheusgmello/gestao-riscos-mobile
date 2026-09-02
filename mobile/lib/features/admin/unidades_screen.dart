import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../data/models/unidade_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/unidade_service.dart';
import 'unidade_form_screen.dart';

class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  late final UnidadeService _service = UnidadeService(TokenService());
  final _scroll = ScrollController();
  final _buscaCtrl = TextEditingController();
  Timer? _debounce;

  final List<UnidadeModel> _unidades = [];
  List<String> _centros = [];
  List<String> _tipos = [];
  String? _busca;
  String? _centro;
  String? _tipo;

  int _page = 1;
  bool _temMais = false;
  bool _carregando = true;
  bool _carregandoMais = false;
  Object? _erro;

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
      final r = await _service.listarAdmin(
        page: 1,
        busca: _busca,
        centro: _centro,
        tipo: _tipo,
      );
      if (!mounted) return;
      setState(() {
        _unidades
          ..clear()
          ..addAll(r.pagina.results);
        _centros = r.centros;
        _tipos = r.tipos;
        _page = 1;
        _temMais = r.pagina.hasNext;
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
      final r = await _service.listarAdmin(
        page: _page + 1,
        busca: _busca,
        centro: _centro,
        tipo: _tipo,
      );
      if (!mounted) return;
      setState(() {
        _unidades.addAll(r.pagina.results);
        _page++;
        _temMais = r.pagina.hasNext;
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

  Future<void> _form([UnidadeModel? u]) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UnidadeFormScreen(unidade: u)),
    );
    if (ok == true) _recarregar();
  }

  Future<void> _alternar(UnidadeModel u) async {
    if (!await confirmar(
      context,
      titulo: u.ativo ? 'Desativar unidade' : 'Reativar unidade',
      mensagem: '${u.rotulo} será ${u.ativo ? "desativada" : "reativada"}.',
      confirmar: u.ativo ? 'Desativar' : 'Reativar',
      destrutivo: u.ativo,
    )) {
      return;
    }
    try {
      await _service.alternarAtivo(u.id);
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unidades')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _form,
        icon: const Icon(Icons.add),
        label: const Text('Nova unidade'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: _aoBuscar,
              decoration: const InputDecoration(
                hintText: 'Buscar unidade',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _filtroChip(
                  'Centro',
                  _centro,
                  _centros,
                  (v) => setState(() {
                    _centro = v;
                    _recarregar();
                  }),
                ),
                const SizedBox(width: 8),
                _filtroChip(
                  'Tipo',
                  _tipo,
                  _tipos,
                  (v) => setState(() {
                    _tipo = v;
                    _recarregar();
                  }),
                ),
              ],
            ),
          ),
          Expanded(child: _lista()),
        ],
      ),
    );
  }

  Widget _filtroChip(
    String rotulo,
    String? valor,
    List<String> opcoes,
    ValueChanged<String?> onSelect,
  ) {
    return PopupMenuButton<String?>(
      onSelected: onSelect,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Todos')),
        for (final o in opcoes) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Chip(
        label: Text(valor ?? rotulo),
        avatar: const Icon(Icons.arrow_drop_down, size: 18),
        backgroundColor: valor != null ? AppColors.primarySurface : null,
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
    if (_unidades.isEmpty) {
      return const Center(child: Text('Nenhuma unidade.'));
    }
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 88),
        itemCount: _unidades.length + (_temMais ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _unidades.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final u = _unidades[i];
          return ListTile(
            title: Text(u.nome),
            subtitle: Text(
              '${u.siglaCentro} · ${u.tipoUnidade}${u.ativo ? "" : " · inativa"}',
            ),
            onTap: () => _form(u),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? _form(u) : _alternar(u),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(
                  value: 'alternar',
                  child: Text(u.ativo ? 'Desativar' : 'Reativar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
