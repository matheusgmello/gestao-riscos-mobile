import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/nivel_risco.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/unidade_model.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/token_service.dart';
import '../../data/services/unidade_service.dart';
import '../../widgets/busca_selecao.dart';
import '../../widgets/matriz_risco.dart';
import '../../widgets/nivel_badge.dart';
import '../../widgets/sync_status_bar.dart';
import '../riscos/risco_detalhe_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _tokens = TokenService();
  late final DashboardService _service = DashboardService(_tokens);

  List<UnidadeModel> _unidades = [];
  FiltroDashboard _filtro = const FiltroDashboard();

  Dashboard? _dados;
  bool _carregando = true;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    _carregarUnidades();
    await _carregar();
  }

  Future<void> _carregarUnidades() async {
    try {
      final u = await UnidadeService(_tokens).listar();
      if (mounted) setState(() => _unidades = u);
    } catch (_) {
      // filtro por unidade indisponível
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final d = await _service.carregar(_filtro);
      if (!mounted) return;
      setState(() {
        _dados = d;
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

  Future<void> _abrirFiltros() async {
    final novo = await showModalBottomSheet<FiltroDashboard>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltroSheet(filtro: _filtro, unidades: _unidades),
    );
    if (novo != null) {
      setState(() => _filtro = novo);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _filtro.ativo,
              child: const Icon(Icons.tune),
            ),
            onPressed: _abrirFiltros,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [const SyncStatusBar(), Expanded(child: _corpo())],
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null || _dados == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
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
    final d = _dados!;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          _kpis(d),
          const SizedBox(height: 16),
          _secao('Riscos por nível'),
          _PorNivel(nivel: d.riscosPorNivel),
          const SizedBox(height: 16),
          _secao('Distribuição por categoria'),
          _CategoriaChart(dados: d.distribuicaoCategorias),
          const SizedBox(height: 16),
          _secao('Matriz de risco residual'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: MatrizRisco(celulas: d.matrizResidual),
            ),
          ),
          const SizedBox(height: 16),
          _secao('Unidades com maior exposição'),
          _RankingUnidades(itens: d.unidadesMaiorExposicao),
          const SizedBox(height: 16),
          _secao('Riscos prioritários'),
          for (final p in d.riscosPrioritarios)
            _PrioritarioCard(
              prioritario: p,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => RiscoDetalheScreen(uuid: p.risco.uuid),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _secao(String titulo) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _kpis(Dashboard d) {
    final primaria = Theme.of(context).colorScheme.primary;
    final itens = [
      ('Total de riscos', '${d.totalPlanos}', primaria),
      ('Críticos', '${d.riscosCriticos}', AppColors.nivelAlto),
      (
        'Cobertura monit.',
        '${d.coberturaMonitoramento.toStringAsFixed(0)}%',
        primaria,
      ),
      (
        'Taxa de mitigação',
        '${d.taxaMitigacao.toStringAsFixed(0)}%',
        AppColors.nivelBaixo,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.1,
      children: [
        for (final (rotulo, valor, cor) in itens)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    valor,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: cor, fontWeight: FontWeight.bold),
                  ),
                  Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PorNivel extends StatelessWidget {
  const _PorNivel({required this.nivel});
  final RiscosPorNivel nivel;

  @override
  Widget build(BuildContext context) {
    final segs = [
      (FaixaNivel.extremo, nivel.extremo),
      (FaixaNivel.alto, nivel.alto),
      (FaixaNivel.moderado, nivel.moderado),
      (FaixaNivel.baixo, nivel.baixo),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Row(
                children: [
                  for (final (faixa, qtd) in segs)
                    if (qtd > 0)
                      Expanded(
                        flex: qtd,
                        child: Container(height: 14, color: faixa.cor),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final (faixa, qtd) in segs)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: faixa.cor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${faixa.rotulo}: $qtd',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaChart extends StatelessWidget {
  const _CategoriaChart({required this.dados});
  final List<CategoriaContagem> dados;

  @override
  Widget build(BuildContext context) {
    if (dados.every((d) => d.quantidade == 0)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Sem dados.')),
        ),
      );
    }
    final maxV = dados
        .map((d) => d.quantidade)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxV + 1),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 2,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${rod.toY.toInt()}',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= dados.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dados[i].nome,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < dados.length; i++)
                  BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: const [0],
                    barRods: [
                      BarChartRodData(
                        toY: dados[i].quantidade.toDouble(),
                        color: Theme.of(context).colorScheme.primary,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingUnidades extends StatelessWidget {
  const _RankingUnidades({required this.itens});
  final List<UnidadeExposicao> itens;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Sem dados.')),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < itens.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                itens[i].nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${itens[i].quantidadeRiscos} riscos · ${itens[i].criticos} críticos',
              ),
              trailing: Text(
                '${itens[i].pontos} pts',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
        ],
      ),
    );
  }
}

class _PrioritarioCard extends StatelessWidget {
  const _PrioritarioCard({required this.prioritario, required this.onTap});
  final RiscoPrioritario prioritario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = prioritario.risco;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                      r.setorRotulo,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  NivelBadge(r.nivelResidual),
                ],
              ),
              const SizedBox(height: 6),
              Text(r.evento, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (prioritario.responsavel != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${prioritario.tipoResposta ?? ''} · ${prioritario.responsavel} · ${prioritario.statusTratamento ?? ''}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroSheet extends StatefulWidget {
  const _FiltroSheet({required this.filtro, required this.unidades});
  final FiltroDashboard filtro;
  final List<UnidadeModel> unidades;

  @override
  State<_FiltroSheet> createState() => _FiltroSheetState();
}

class _FiltroSheetState extends State<_FiltroSheet> {
  late FiltroDashboard _f = widget.filtro;

  UnidadeModel? _unidade() {
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
            selecionado: _unidade(),
            onChanged: (u) => setState(
              () => _f = u == null
                  ? _f.copyWith(limparSetor: true)
                  : _f.copyWith(setorId: u.id),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const FiltroDashboard()),
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
    );
  }
}
