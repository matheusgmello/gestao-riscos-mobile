import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/exportar.dart';
import '../../data/models/risco_model.dart';
import '../../data/models/unidade_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositorios/risco_repositorio.dart';
import '../../data/services/exportacao_service.dart';
import '../../data/services/risco_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/pdi_service.dart';
import '../../data/services/unidade_service.dart';
import '../../data/sync/motor_sync.dart';
import '../../widgets/busca_selecao.dart';
import '../../widgets/categoria_chip.dart';
import '../../widgets/estado.dart';
import '../../widgets/nivel_badge.dart';
import '../../widgets/sync_status_bar.dart';
import 'risco_detalhe_screen.dart';
import 'risco_form_screen.dart';

class RiscosScreen extends StatefulWidget {
  const RiscosScreen({
    super.key,
    this.repo,
    this.exportacao,
    this.unidades,
    this.pdi,
    this.tokens,
  });

  final RiscoRepositorio? repo;
  final ExportacaoService? exportacao;
  final UnidadeService? unidades;
  final PdiService? pdi;
  final TokenService? tokens;

  @override
  State<RiscosScreen> createState() => _RiscosScreenState();
}

class _RiscosScreenState extends State<RiscosScreen> {
  late final TokenService _tokens = widget.tokens ?? TokenService();
  late final RiscoRepositorio _repo = widget.repo ?? RiscoRepositorio(_tokens);
  late final ExportacaoService _exportacao =
      widget.exportacao ?? ExportacaoService(_tokens);
  late final UnidadeService _unidadeService =
      widget.unidades ?? UnidadeService(_tokens);
  late final PdiService _pdi = widget.pdi ?? PdiService(_tokens);
  final _scroll = ScrollController();
  final _buscaCtrl = TextEditingController();
  Timer? _debounce;

  UsuarioModel? _usuario;
  List<UnidadeModel> _unidades = [];
  FiltroRisco _filtro = const FiltroRisco();

  List<Risco> _todos = [];
  List<Risco> _riscos = [];
  bool _carregando = true;
  Object? _erro;

  StreamSubscription<EstadoSync>? _syncSub;

  @override
  void initState() {
    super.initState();
    _iniciar();
    _syncSub = MotorSync.instance.estado.listen((e) {
      if (e == EstadoSync.ocioso && mounted) _recarregar();
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _debounce?.cancel();
    _scroll.dispose();
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    _usuario = await _tokens.getUsuario();
    _carregarUnidades();
    await _recarregar();
    // atualiza em segundo plano ao abrir; o listener de estado recarrega a
    // lista quando o pull termina.
    unawaited(MotorSync.instance.sincronizar());
  }

  Future<void> _carregarUnidades() async {
    try {
      final u = await _unidadeService.listar();
      if (mounted) setState(() => _unidades = u);
      // aquece o cache dos selects do formulário (para funcionar offline)
      unawaited(_pdi.objetivos());
      unawaited(_pdi.macroprocessos());
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
      final todos = await _repo.listar();
      if (!mounted) return;
      setState(() {
        _todos = todos;
        _riscos = _filtro.aplicar(todos);
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

  Future<void> _sincronizar() async {
    await MotorSync.instance.sincronizar();
    await _recarregar();
  }

  void _reaplicarFiltro() => setState(() => _riscos = _filtro.aplicar(_todos));

  void _aoBuscar(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _filtro = _filtro.copyWith(busca: v));
      _reaplicarFiltro();
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
      _reaplicarFiltro();
    }
  }

  Future<void> _novoRisco() async {
    final criado = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => const RiscoFormScreen()));
    if (criado == true) _recarregar();
  }

  Future<void> _abrirRisco(Risco r) async {
    final mudou = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => RiscoDetalheScreen(uuid: r.uuid)),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Exportar',
            onSelected: (v) => exportarECompartilhar(
              context,
              () => v == 'excel'
                  ? _exportacao.listaExcel(_filtro)
                  : _exportacao.relatorioPdf(_filtro),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'excel',
                child: Text('Planilha (Excel) da lista'),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Text('Relatório gerencial (PDF)'),
              ),
            ],
          ),
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
          const SyncStatusBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: (v) {
                setState(() {});
                _aoBuscar(v);
              },
              decoration: InputDecoration(
                hintText: 'Buscar evento, causa, responsável...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _buscaCtrl.clear();
                          setState(() {});
                          _aoBuscar('');
                        },
                      ),
              ),
            ),
          ),
          _chipsFiltro(),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

  Widget _chipsFiltro() {
    final f = _filtro;
    final chips = <Widget>[];
    if (f.setorId != null) {
      final achadas = _unidades.where((u) => u.id == f.setorId);
      final nome = achadas.isEmpty ? '${f.setorId}' : achadas.first.rotulo;
      chips.add(
        _chip('Unidade: $nome', () {
          setState(() => _filtro = f.copyWith(limparSetor: true));
          _reaplicarFiltro();
        }),
      );
    }
    if (f.categoria != null) {
      chips.add(
        _chip('Categoria: ${f.categoria}', () {
          setState(() => _filtro = f.copyWith(limparCategoria: true));
          _reaplicarFiltro();
        }),
      );
    }
    if (f.incluirInativos) {
      chips.add(
        _chip('Inclui inativos', () {
          setState(() => _filtro = f.copyWith(incluirInativos: false));
          _reaplicarFiltro();
        }),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _chip(String texto, VoidCallback onRemover) => InputChip(
    label: Text(texto),
    onDeleted: onRemover,
    visualDensity: VisualDensity.compact,
  );

  Widget _corpo() {
    if (_carregando) {
      return const SkeletonLista();
    }
    if (_erro != null) {
      return EstadoErro(erro: _erro!, onTentar: _recarregar);
    }
    if (_riscos.isEmpty) {
      return EstadoVazio(
        icone: Icons.inbox_outlined,
        titulo: 'Nenhum risco',
        detalhe: _filtro.temFiltroAtivo
            ? 'Nenhum resultado para os filtros atuais.'
            : 'Ainda não há riscos cadastrados.',
        acao: (!_filtro.temFiltroAtivo && (_usuario?.setores.isNotEmpty ?? false))
            ? FilledButton.icon(
                onPressed: _novoRisco,
                icon: const Icon(Icons.add),
                label: const Text('Criar o primeiro risco'),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _sincronizar,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
        itemCount: _riscos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) =>
            _RiscoCard(risco: _riscos[i], onTap: () => _abrirRisco(_riscos[i])),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (risco.pendenteSync) ...[
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
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
              const SizedBox(height: 4),
              Text(
                risco.evento,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CategoriaChip(risco.categoria),
                  const SizedBox(width: 8),
                  if (risco.possuiPlanoAcao)
                    Icon(
                      Icons.task_alt,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  if (risco.possuiMonitoramento) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.monitor_heart_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'inerente ${risco.nivelRisco} → residual ${risco.nivelResidual}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  UnidadeModel? _unidadeSelecionada() {
    for (final u in widget.unidades) {
      if (u.id == _f.setorId) return u;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            BuscaSelecao<UnidadeModel>(
              label: 'Unidade',
              rotuloVazio: 'Todas',
              itens: widget.unidades,
              rotulo: (u) => u.rotulo,
              selecionado: _unidadeSelecionada(),
              onChanged: (u) => setState(
                () => _f = u == null
                    ? _f.copyWith(limparSetor: true)
                    : _f.copyWith(setorId: u.id),
              ),
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
              onChanged: (v) => setState(
                () => _f = v == null
                    ? _f.copyWith(limparCategoria: true)
                    : _f.copyWith(categoria: v),
              ),
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
              onChanged: (v) => setState(() => _f = _f.copyWith(ordenacao: v)),
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
                      ),
                    ),
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
