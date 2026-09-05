import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/app_feedback.dart';
import '../../core/exportar.dart';
import '../../core/role.dart';
import '../../data/models/historico_model.dart';
import '../../data/models/monitoramento_model.dart';
import '../../data/models/plano_acao_model.dart';
import '../../data/models/risco_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositorios/risco_repositorio.dart';
import '../../data/services/exportacao_service.dart';
import '../../data/services/token_service.dart';
import '../../widgets/categoria_chip.dart';
import '../../widgets/estado.dart';
import '../../widgets/nivel_badge.dart';
import '../monitoramentos/monitoramento_form_screen.dart';
import '../planos_acao/plano_acao_form_screen.dart';
import 'risco_form_screen.dart';

/// Cor de texto/ícone sobre a AppBar (branco no tema claro, onSurface no
/// escuro) — usada nas abas para não fixar branco.
Color _corAppBar(BuildContext context) =>
    Theme.of(context).appBarTheme.foregroundColor ??
    Theme.of(context).colorScheme.onSurface;

class RiscoDetalheScreen extends StatefulWidget {
  const RiscoDetalheScreen({
    super.key,
    required this.uuid,
    this.repo,
    this.exportacao,
    this.tokens,
  });

  final String uuid;
  final RiscoRepositorio? repo;
  final ExportacaoService? exportacao;
  final TokenService? tokens;

  @override
  State<RiscoDetalheScreen> createState() => _RiscoDetalheScreenState();
}

class _RiscoDetalheScreenState extends State<RiscoDetalheScreen> {
  late final TokenService _tokens = widget.tokens ?? TokenService();
  late final RiscoRepositorio _repo = widget.repo ?? RiscoRepositorio(_tokens);
  late final ExportacaoService _exportacao =
      widget.exportacao ?? ExportacaoService(_tokens);

  UsuarioModel? _usuario;
  Risco? _risco;
  List<PlanoAcao> _acoes = [];
  List<Monitoramento> _monitoramentos = [];
  List<HistoricoEntrada> _historico = [];

  bool _carregando = true;
  Object? _erro;
  bool _mudou = false;

  /// Chave real após a carga (a tela pode ter sido aberta com a temporária).
  String get _uuid => _risco?.uuid ?? widget.uuid;

  bool get _podeEscrever =>
      _risco != null &&
      podeEscreverNoSetor(_risco!.setorId, _usuario?.setoresIds ?? const []);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      _usuario ??= await _tokens.getUsuario();
      final risco = await _repo.obter(widget.uuid);
      if (risco == null) throw Exception('Risco não encontrado no cache.');
      // pode ter sido aberto com a chave temporária; usa o uuid resolvido
      final uuid = risco.uuid;
      final acoes = await _repo.acoes(uuid);
      final mons = await _repo.monitoramentos(uuid);
      final hist = await _repo.historico(uuid);
      if (!mounted) return;
      setState(() {
        _risco = risco;
        _acoes = acoes;
        _monitoramentos = mons;
        _historico = hist;
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

  Future<void> _editar() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => RiscoFormScreen(risco: _risco)),
    );
    if (ok == true) {
      _mudou = true;
      _carregar();
    }
  }

  Future<void> _duplicar() async {
    if (!await confirmar(
      context,
      titulo: 'Duplicar risco',
      mensagem: 'Cria uma cópia deste risco com os planos de ação.',
      confirmar: 'Duplicar',
    )) {
      return;
    }
    try {
      await _repo.duplicar(_uuid);
      _mudou = true;
      if (mounted) {
        mostrarOk(context, 'Risco duplicado.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _excluir() async {
    if (!await confirmar(
      context,
      titulo: 'Excluir risco',
      mensagem:
          'O risco e seus planos de ação e monitoramentos serão desativados.',
      confirmar: 'Excluir',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _repo.desativarRisco(_uuid);
      if (mounted) {
        mostrarOk(context, 'Risco excluído.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _novaAcao() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanoAcaoFormScreen(riscoUuid: _uuid),
      ),
    );
    if (ok == true) {
      _mudou = true;
      _carregar();
    }
  }

  Future<void> _editarAcao(PlanoAcao a) async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlanoAcaoFormScreen(riscoUuid: _uuid, acao: a),
      ),
    );
    if (ok == true) {
      _mudou = true;
      _carregar();
    }
  }

  Future<void> _excluirAcao(PlanoAcao a) async {
    if (!await confirmar(
      context,
      titulo: 'Excluir plano de ação',
      mensagem: 'Esta ação será desativada.',
      confirmar: 'Excluir',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _repo.desativarAcao(a.id);
      _mudou = true;
      _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _novoMonitoramento() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => MonitoramentoFormScreen(riscoUuid: _uuid),
      ),
    );
    if (ok == true) {
      _mudou = true;
      _carregar();
    }
  }

  Future<void> _editarMonitoramento(Monitoramento m) async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            MonitoramentoFormScreen(riscoUuid: _uuid, monitoramento: m),
      ),
    );
    if (ok == true) {
      _mudou = true;
      _carregar();
    }
  }

  Future<void> _excluirMonitoramento(Monitoramento m) async {
    if (!await confirmar(
      context,
      titulo: 'Excluir monitoramento',
      mensagem: 'Este registro será desativado.',
      confirmar: 'Excluir',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _repo.desativarMonitoramento(m.id);
      _mudou = true;
      _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _mudou);
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Risco'),
            actions: [
              if (_risco != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Exportar',
                  onSelected: (v) => exportarECompartilhar(
                    context,
                    () => v == 'excel'
                        ? _exportacao.riscoExcel(_uuid)
                        : _exportacao.riscoPdf(_uuid),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'excel', child: Text('Excel')),
                    PopupMenuItem(value: 'pdf', child: Text('PDF')),
                  ],
                ),
              if (_podeEscrever && _risco != null)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'editar') _editar();
                    if (v == 'duplicar') _duplicar();
                    if (v == 'excluir') _excluir();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'duplicar', child: Text('Duplicar')),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                ),
            ],
            bottom: TabBar(
              labelColor: _corAppBar(context),
              unselectedLabelColor: _corAppBar(context).withValues(alpha: 0.7),
              indicatorColor: _corAppBar(context),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Dados'),
                Tab(text: 'Ações'),
                Tab(text: 'Monitor.'),
                Tab(text: 'Histórico'),
              ],
            ),
          ),
          body: _corpo(),
        ),
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null || _risco == null) {
      return EstadoErro(
        erro: _erro ?? 'Risco não encontrado.',
        onTentar: _carregar,
      );
    }
    return TabBarView(
      children: [
        _AbaDados(risco: _risco!),
        _AbaLista(
          vazio: 'Nenhum plano de ação.',
          podeEscrever: _podeEscrever,
          onNovo: _novaAcao,
          rotuloNovo: 'Novo plano de ação',
          itens: [
            for (final a in _acoes)
              _AcaoCard(
                acao: a,
                podeEscrever: _podeEscrever,
                onEditar: () => _editarAcao(a),
                onExcluir: () => _excluirAcao(a),
              ),
          ],
        ),
        _AbaLista(
          vazio: 'Nenhum monitoramento.',
          podeEscrever: _podeEscrever,
          onNovo: _novoMonitoramento,
          rotuloNovo: 'Novo monitoramento',
          itens: [
            for (final m in _monitoramentos)
              _MonitoramentoCard(
                monitoramento: m,
                podeEscrever: _podeEscrever,
                onEditar: () => _editarMonitoramento(m),
                onExcluir: () => _excluirMonitoramento(m),
              ),
          ],
        ),
        _AbaHistorico(entradas: _historico),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _AbaDados extends StatelessWidget {
  const _AbaDados({required this.risco});
  final Risco risco;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                risco.setorRotulo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            CategoriaChip(risco.categoria),
          ],
        ),
        const SizedBox(height: 16),
        _NivelResumo(risco: risco),
        const SizedBox(height: 16),
        _secao(context, 'Descrição do risco', [
          _campo(context, 'Evento', risco.evento),
          _campo(context, 'Causa', risco.causa),
          _campo(context, 'Consequência', risco.consequencia),
        ]),
        const SizedBox(height: 12),
        _secao(context, 'Controle', [
          _campo(context, 'Controles atuais', risco.controlesAtuais),
          _campo(context, 'Eficácia do controle', risco.eficaciaControle),
        ]),
        const SizedBox(height: 12),
        _secao(context, 'Vínculos', [
          if (risco.objetivo != null)
            _campo(context, 'Objetivo PDI', risco.objetivo!.rotulo),
          if (risco.macroprocesso != null)
            _campo(context, 'Macroprocesso', risco.macroprocesso!.nome),
          if (risco.periodoInicio != null)
            _campo(
              context,
              'Período de ação',
              '${risco.periodoInicio} a ${risco.periodoFim ?? '—'}',
            ),
        ]),
      ],
    );
  }

  Widget _secao(BuildContext context, String titulo, List<Widget> campos) {
    if (campos.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            ...campos,
          ],
        ),
      ),
    );
  }

  Widget _campo(BuildContext context, String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          valor.isEmpty ? '—' : valor,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

class _NivelResumo extends StatelessWidget {
  const _NivelResumo({required this.risco});
  final Risco risco;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _coluna(
              context,
              'Inerente',
              risco.probabilidade,
              risco.impacto,
              risco.nivelRisco,
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            _coluna(
              context,
              'Residual',
              risco.probResidual,
              risco.impResidual,
              risco.nivelResidual,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coluna(BuildContext context, String rotulo, int p, int i, int n) {
    return Expanded(
      child: Column(
        children: [
          Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          NivelBadge(n),
          const SizedBox(height: 4),
          Text(
            'prob $p × impacto $i',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _AbaLista extends StatelessWidget {
  const _AbaLista({
    required this.itens,
    required this.vazio,
    required this.podeEscrever,
    required this.onNovo,
    required this.rotuloNovo,
  });

  final List<Widget> itens;
  final String vazio;
  final bool podeEscrever;
  final VoidCallback onNovo;
  final String rotuloNovo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (itens.isEmpty)
          EstadoVazio(icone: Icons.inbox_outlined, titulo: vazio)
        else
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              for (final w in itens) ...[w, const SizedBox(height: 8)],
            ],
          ),
        if (podeEscrever)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: onNovo,
              icon: const Icon(Icons.add),
              label: Text(rotuloNovo),
            ),
          ),
      ],
    );
  }
}

class _AcaoCard extends StatelessWidget {
  const _AcaoCard({
    required this.acao,
    required this.podeEscrever,
    required this.onEditar,
    required this.onExcluir,
  });

  final PlanoAcao acao;
  final bool podeEscrever;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    acao.tipoResposta,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _StatusChip(acao.status),
                if (podeEscrever)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (v) => v == 'editar' ? onEditar() : onExcluir(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(acao.descricaoAcao),
            const SizedBox(height: 8),
            Text(
              'Responsável: ${acao.responsavel}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              '${acao.dataInicio} a ${acao.dataFim}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (acao.progresso.clamp(0, 100)) / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${acao.progresso}%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color cor = Theme.of(context).colorScheme.outline;
    if (s.contains('conclu')) cor = AppColors.nivelBaixo;
    if (s.contains('andamento')) cor = Theme.of(context).colorScheme.primary;
    if (s.contains('atras')) cor = AppColors.nivelExtremo;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MonitoramentoCard extends StatelessWidget {
  const _MonitoramentoCard({
    required this.monitoramento,
    required this.podeEscrever,
    required this.onEditar,
    required this.onExcluir,
  });

  final Monitoramento monitoramento;
  final bool podeEscrever;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    monitoramento.dataVerificacao.isEmpty
                        ? 'Monitoramento'
                        : 'Verificado em ${monitoramento.dataVerificacao}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (podeEscrever)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (v) => v == 'editar' ? onEditar() : onExcluir(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _linha(context, 'Resultados', monitoramento.resultados),
            _linha(context, 'Ações futuras', monitoramento.acoesFuturas),
            _linha(context, 'Análise crítica', monitoramento.analiseCritica),
          ],
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, String r, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(r, style: Theme.of(context).textTheme.labelMedium),
        Text(v.isEmpty ? '—' : v),
      ],
    ),
  );
}

class _AbaHistorico extends StatelessWidget {
  const _AbaHistorico({required this.entradas});
  final List<HistoricoEntrada> entradas;

  @override
  Widget build(BuildContext context) {
    if (entradas.isEmpty) {
      return const Center(child: Text('Sem histórico.'));
    }
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entradas.length,
      separatorBuilder: (_, _) => const Divider(height: 20),
      itemBuilder: (context, i) {
        final e = entradas[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.descricao, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 2),
            Text(
              '${e.usuarioNome} · ${e.dataHora != null ? fmt.format(e.dataHora!.toLocal()) : ''}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      },
    );
  }
}
