import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../data/models/risco_model.dart';
import '../../data/models/unidade_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/risco_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/unidade_service.dart';
import '../../widgets/nivel_badge.dart';
import 'risco_detalhe_screen.dart';
import 'risco_form_screen.dart';

class RiscosScreen extends StatefulWidget {
  const RiscosScreen({super.key});

  @override
  State<RiscosScreen> createState() => _RiscosScreenState();
}

class _RiscosScreenState extends State<RiscosScreen> {
  final _tokens = TokenService();
  late final RiscoService _service = RiscoService(_tokens);
  final _scroll = ScrollController();
  final _buscaCtrl = TextEditingController();
  Timer? _debounce;

  UsuarioModel? _usuario;
  List<UnidadeModel> _unidades = [];
  FiltroRisco _filtro = const FiltroRisco();

  final List<Risco> _riscos = [];
  int _page = 1;
  bool _temMais = false;
  bool _carregando = true;
  bool _carregandoMais = false;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_aoRolar);
    _iniciar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    _usuario = await _tokens.getUsuario();
    _carregarUnidades();
    await _recarregar();
  }

  Future<void> _carregarUnidades() async {
    try {
      final u = await UnidadeService(_tokens).listar();
      if (mounted) setState(() => _unidades = u);
    } catch (_) {
      // filtro por unidade fica indisponível, mas a lista funciona
    }
  }

  Future<void> _recarregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pagina = await _service.listar(page: 1, filtro: _filtro);
      if (!mounted) return;
      setState(() {
        _riscos
          ..clear()
          ..addAll(pagina.results);
        _page = 1;
        _temMais = pagina.hasNext;
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

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_temMais) return;
    setState(() => _carregandoMais = true);
    try {
      final pagina =
          await _service.listar(page: _page + 1, filtro: _filtro);
      if (!mounted) return;
      setState(() {
        _riscos.addAll(pagina.results);
        _page++;
        _temMais = pagina.hasNext;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
      mostrarErro(context, e);
    }
  }

  void _aoRolar() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _carregarMais();
    }
  }

  void _aoBuscar(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      setState(() => _filtro = _filtro.copyWith(busca: v));
      _recarregar();
    });
  }

  Future<void> _abrirFiltros() async {
    final novo = await showModalBottomSheet<FiltroRisco>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltroSheet(
        filtro: _filtro,
        unidades: _unidades,
        podeVerInativos: _usuario?.isSuperuser ?? false,
      ),
    );
    if (novo != null) {
      setState(() => _filtro = novo);
      _recarregar();
    }
  }

  Future<void> _novoRisco() async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RiscoFormScreen()),
    );
    if (criado == true) _recarregar();
  }

  Future<void> _abrirRisco(Risco r) async {
    final mudou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RiscoDetalheScreen(uuid: r.uuid),
      ),
    );
    if (mudou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final podeCriar = (_usuario?.setores.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riscos'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filtro.temFiltroAtivo,
              child: const Icon(Icons.tune),
            ),
            onPressed: _abrirFiltros,
            tooltip: 'Filtros',
          ),
        ],
      ),
      floatingActionButton: podeCriar
          ? FloatingActionButton.extended(
              onPressed: _novoRisco,
              icon: const Icon(Icons.add),
              label: const Text('Novo risco'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: _aoBuscar,
              decoration: InputDecoration(
                hintText: 'Buscar evento, causa, responsável...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _buscaCtrl.clear();
                          _aoBuscar('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return _Estado(
        icone: Icons.cloud_off,
        titulo: 'Não foi possível carregar',
        detalhe: '$_erro',
        acao: FilledButton(
          onPressed: _recarregar,
          child: const Text('Tentar de novo'),
        ),
      );
    }
    if (_riscos.isEmpty) {
      return _Estado(
        icone: Icons.inbox_outlined,
        titulo: 'Nenhum risco',
        detalhe: _filtro.temFiltroAtivo
            ? 'Nenhum resultado para os filtros atuais.'
            : 'Ainda não há riscos cadastrados.',
      );
    }
    return RefreshIndicator(
      onRefresh: _recarregar,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: _riscos.length + (_temMais ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i >= _riscos.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _RiscoCard(
            risco: _riscos[i],
            onTap: () => _abrirRisco(_riscos[i]),
          );
        },
      ),
    );
  }
}

class _RiscoCard extends StatelessWidget {
  const _RiscoCard({required this.risco, required this.onTap});

  final Risco risco;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      risco.setorRotulo,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  NivelBadge(risco.nivelResidual),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                risco.evento,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Chip(risco.categoria),
                  const SizedBox(width: 8),
                  if (risco.possuiPlanoAcao)
                    const Icon(Icons.task_alt,
                        size: 16, color: AppColors.textMuted),
                  if (risco.possuiMonitoramento) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.monitor_heart_outlined,
                        size: 16, color: AppColors.textMuted),
                  ],
                  const Spacer(),
                  Text('Inerente ${risco.nivelRisco}',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({
    required this.icone,
    required this.titulo,
    required this.detalhe,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String detalhe;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(icone, size: 56, color: AppColors.grey400),
        const SizedBox(height: 12),
        Text(titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(detalhe, textAlign: TextAlign.center),
        ),
        if (acao != null) ...[
          const SizedBox(height: 16),
          Center(child: acao!),
        ],
      ],
    );
  }
}

class _FiltroSheet extends StatefulWidget {
  const _FiltroSheet({
    required this.filtro,
    required this.unidades,
    required this.podeVerInativos,
  });

  final FiltroRisco filtro;
  final List<UnidadeModel> unidades;
  final bool podeVerInativos;

  @override
  State<_FiltroSheet> createState() => _FiltroSheetState();
}

class _FiltroSheetState extends State<_FiltroSheet> {
  late FiltroRisco _f = widget.filtro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _f.setorId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Unidade'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final u in widget.unidades)
                  DropdownMenuItem(value: u.id, child: Text(u.rotulo)),
              ],
              onChanged: (v) => setState(() => _f = v == null
                  ? _f.copyWith(limparSetor: true)
                  : _f.copyWith(setorId: v)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _f.categoria,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final c in Risco.categorias)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _f = v == null
                  ? _f.copyWith(limparCategoria: true)
                  : _f.copyWith(categoria: v)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<OrdenacaoRisco>(
              initialValue: _f.ordenacao,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items: [
                for (final o in OrdenacaoRisco.values)
                  DropdownMenuItem(value: o, child: Text(o.rotulo)),
              ],
              onChanged: (v) =>
                  setState(() => _f = _f.copyWith(ordenacao: v)),
            ),
            if (widget.podeVerInativos) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Incluir inativos'),
                value: _f.incluirInativos,
                onChanged: (v) =>
                    setState(() => _f = _f.copyWith(incluirInativos: v)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(
                        context,
                        FiltroRisco(
                          busca: widget.filtro.busca,
                          ordenacao: OrdenacaoRisco.recentes,
                        )),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _f),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
