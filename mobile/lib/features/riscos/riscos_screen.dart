import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
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
import '../../widgets/nivel_badge.dart';
import '../../widgets/sync_status_bar.dart';
import 'risco_detalhe_screen.dart';
import 'risco_form_screen.dart';

class RiscosScreen extends StatefulWidget {
  const RiscosScreen({super.key});

  @override
  State<RiscosScreen> createState() => _RiscosScreenState();
}

class _RiscosScreenState extends State<RiscosScreen> {
  final _tokens = TokenService();
  late final RiscoRepositorio _repo = RiscoRepositorio(_tokens);
  late final ExportacaoService _exportacao = ExportacaoService(_tokens);
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
      final u = await UnidadeService(_tokens).listar();
      if (mounted) setState(() => _unidades = u);
      // aquece o cache dos selects do formulário (para funcionar offline)
      final pdi = PdiService(_tokens);
      unawaited(pdi.objetivos());
      unawaited(pdi.macroprocessos());
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
            icon: const Icon(Icons.ios_share),
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
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 14,
                      color: AppColors.primary,
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
                  _Chip(risco.categoria),
                  const SizedBox(width: 8),
                  if (risco.possuiPlanoAcao)
                    const Icon(
                      Icons.task_alt,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  if (risco.possuiMonitoramento) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.monitor_heart_outlined,
                      size: 16,
                      color: AppColors.textMuted,
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
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
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
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(detalhe, textAlign: TextAlign.center),
        ),
        if (acao != null) ...[const SizedBox(height: 16), Center(child: acao!)],
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
