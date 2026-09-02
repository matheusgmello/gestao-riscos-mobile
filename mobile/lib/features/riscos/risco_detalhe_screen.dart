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
import '../../data/services/exportacao_service.dart';
import '../../data/services/monitoramento_service.dart';
import '../../data/services/plano_acao_service.dart';
import '../../data/services/risco_service.dart';
import '../../data/services/token_service.dart';
import '../../widgets/nivel_badge.dart';
import '../monitoramentos/monitoramento_form_screen.dart';
import '../planos_acao/plano_acao_form_screen.dart';
import 'risco_form_screen.dart';

class RiscoDetalheScreen extends StatefulWidget {
  const RiscoDetalheScreen({super.key, required this.uuid});

  final String uuid;

  @override
  State<RiscoDetalheScreen> createState() => _RiscoDetalheScreenState();
}

class _RiscoDetalheScreenState extends State<RiscoDetalheScreen> {
  final _tokens = TokenService();
  late final RiscoService _riscos = RiscoService(_tokens);
  late final PlanoAcaoService _acoesSvc = PlanoAcaoService(_tokens);
  late final MonitoramentoService _monSvc = MonitoramentoService(_tokens);
  late final ExportacaoService _exportacao = ExportacaoService(_tokens);

  UsuarioModel? _usuario;
  Risco? _risco;
  List<PlanoAcao> _acoes = [];
  List<Monitoramento> _monitoramentos = [];
  List<HistoricoEntrada> _historico = [];

  bool _carregando = true;
  Object? _erro;
  bool _mudou = false;

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
      final risco = await _riscos.obter(widget.uuid);
      final acoes = await _acoesSvc.listarPorRisco(widget.uuid);
      final mons = await _monSvc.listarPorRisco(widget.uuid);
      final hist = await _riscos.historico(widget.uuid);
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
      await _riscos.duplicar(widget.uuid);
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
      await _riscos.desativar(widget.uuid);
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
        builder: (_) => PlanoAcaoFormScreen(riscoUuid: widget.uuid),
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
        builder: (_) => PlanoAcaoFormScreen(riscoUuid: widget.uuid, acao: a),
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
      await _acoesSvc.desativar(a.id);
      _mudou = true;
      _carregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _novoMonitoramento() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => MonitoramentoFormScreen(riscoUuid: widget.uuid),
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
            MonitoramentoFormScreen(riscoUuid: widget.uuid, monitoramento: m),
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
      await _monSvc.desativar(m.id);
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
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Exportar',
                  onSelected: (v) => exportarECompartilhar(
                    context,
                    () => v == 'excel'
                        ? _exportacao.riscoExcel(widget.uuid)
                        : _exportacao.riscoPdf(widget.uuid),
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
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_erro', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _carregar,
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                risco.categoria,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NivelResumo(risco: risco),
        const SizedBox(height: 16),
        _campo(context, 'Evento', risco.evento),
        _campo(context, 'Causa', risco.causa),
        _campo(context, 'Consequência', risco.consequencia),
        _campo(context, 'Controles atuais', risco.controlesAtuais),
        _campo(context, 'Eficácia do controle', risco.eficaciaControle),
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
      ],
    );
  }

  Widget _campo(BuildContext context, String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
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
            const Icon(Icons.arrow_forward, color: AppColors.textMuted),
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
          Center(child: Text(vazio))
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
    Color cor = AppColors.grey400;
    if (s.contains('conclu')) cor = AppColors.nivelBaixo;
    if (s.contains('andamento')) cor = AppColors.primary;
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
