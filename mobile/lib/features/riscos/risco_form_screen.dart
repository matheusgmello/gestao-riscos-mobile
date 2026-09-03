import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../core/nivel_risco.dart';
import '../../data/models/pdi_model.dart';
import '../../data/models/risco_model.dart';
import '../../data/models/unidade_model.dart';
import '../../data/services/pdi_service.dart';
import '../../data/repositorios/risco_repositorio.dart';
import '../../data/services/token_service.dart';
import '../../data/services/unidade_service.dart';
import '../../widgets/estado.dart';
import '../../widgets/guarda_form.dart';
import '../../widgets/nivel_badge.dart';

class RiscoFormScreen extends StatefulWidget {
  const RiscoFormScreen({super.key, this.risco});

  final Risco? risco;

  @override
  State<RiscoFormScreen> createState() => _RiscoFormScreenState();
}

class _RiscoFormScreenState extends State<RiscoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokens = TokenService();
  late final RiscoRepositorio _repo = RiscoRepositorio(_tokens);

  bool get _edicao => widget.risco != null;

  bool _carregando = true;
  bool _salvando = false;
  bool _sujo = false;
  Object? _erroCarga;

  List<UnidadeModel> _setores = [];
  List<ObjetivoPdi> _objetivos = [];
  List<Macroprocesso> _macroprocessos = [];

  int? _setorId;
  int? _objetivoId;
  int? _macroprocessoId;
  String? _categoria;
  String? _eficacia;
  final _evento = TextEditingController();
  final _causa = TextEditingController();
  final _consequencia = TextEditingController();
  final _controles = TextEditingController();
  int _prob = 3, _impacto = 3, _probResidual = 2, _impResidual = 2;

  @override
  void initState() {
    super.initState();
    _preencherDeRisco();
    _carregar();
  }

  void _preencherDeRisco() {
    final r = widget.risco;
    if (r == null) return;
    _setorId = r.setorId;
    _objetivoId = r.objetivoId;
    _macroprocessoId = r.macroprocessoId;
    _categoria = r.categoria;
    _eficacia = r.eficaciaControle;
    _evento.text = r.evento;
    _causa.text = r.causa;
    _consequencia.text = r.consequencia;
    _controles.text = r.controlesAtuais;
    _prob = r.probabilidade;
    _impacto = r.impacto;
    _probResidual = r.probResidual;
    _impResidual = r.impResidual;
  }

  Future<void> _carregar() async {
    try {
      final usuario = await _tokens.getUsuario();
      final pdi = PdiService(_tokens);
      final todosSetores = await UnidadeService(_tokens).listar();
      final objetivos = await pdi.objetivos();
      final macros = await pdi.macroprocessos();
      if (!mounted) return;

      final meusIds = usuario?.setoresIds ?? const [];
      final setores = todosSetores
          .where((s) => meusIds.contains(s.id) || s.id == _setorId)
          .toList();

      setState(() {
        _setores = setores;
        _objetivos = objetivos;
        _macroprocessos = macros;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroCarga = e;
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _evento.dispose();
    _causa.dispose();
    _consequencia.dispose();
    _controles.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_setorId == null ||
        _objetivoId == null ||
        _macroprocessoId == null ||
        _categoria == null ||
        _eficacia == null) {
      mostrarErro(context, 'Preencha todos os campos de seleção.');
      return;
    }
    setState(() => _salvando = true);
    final payload = {
      'setor': _setorId,
      'objetivo': _objetivoId,
      'macroprocesso': _macroprocessoId,
      'categoria': _categoria,
      'evento': _evento.text.trim(),
      'causa': _causa.text.trim(),
      'consequencia': _consequencia.text.trim(),
      'controles_atuais': _controles.text.trim(),
      'eficacia_controle': _eficacia,
      'probabilidade': _prob,
      'impacto': _impacto,
      'prob_residual': _probResidual,
      'imp_residual': _impResidual,
    };
    try {
      if (_edicao) {
        await _repo.atualizarRisco(widget.risco!.uuid, payload);
      } else {
        await _repo.criarRisco(payload);
      }
      if (mounted) {
        mostrarOk(context, _edicao ? 'Risco atualizado.' : 'Risco criado.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        mostrarErro(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GuardaForm(
      sujo: _sujo && !_salvando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_edicao ? 'Editar risco' : 'Novo risco'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erroCarga != null
            ? EstadoErro(erro: _erroCarga!, onTentar: _carregar)
            : _form(),
        bottomNavigationBar: _carregando || _erroCarga != null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(_edicao ? 'Salvar' : 'Criar risco'),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      onChanged: () {
        if (!_sujo) setState(() => _sujo = true);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _setorId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Unidade *'),
            items: [
              for (final s in _setores)
                DropdownMenuItem(value: s.id, child: Text(s.rotulo)),
            ],
            validator: (v) => v == null ? 'Selecione a unidade.' : null,
            onChanged: (v) => setState(() => _setorId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _objetivoId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Objetivo PDI *'),
            items: [
              for (final o in _objetivos)
                DropdownMenuItem(
                  value: o.id,
                  child: Text(o.rotulo, overflow: TextOverflow.ellipsis),
                ),
            ],
            validator: (v) => v == null ? 'Selecione o objetivo.' : null,
            onChanged: (v) => setState(() => _objetivoId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _macroprocessoId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Macroprocesso *'),
            items: [
              for (final m in _macroprocessos)
                DropdownMenuItem(value: m.id, child: Text(m.nome)),
            ],
            validator: (v) => v == null ? 'Selecione o macroprocesso.' : null,
            onChanged: (v) => setState(() => _macroprocessoId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoria *'),
            items: [
              for (final c in Risco.categorias)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            validator: (v) => v == null ? 'Selecione a categoria.' : null,
            onChanged: (v) => setState(() => _categoria = v),
          ),
          const SizedBox(height: 20),
          _multiline(_evento, 'Evento *'),
          _multiline(_causa, 'Causa *'),
          _multiline(_consequencia, 'Consequência *'),
          _multiline(_controles, 'Controles atuais *'),
          DropdownButtonFormField<String>(
            initialValue: _eficacia,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Eficácia do controle *',
            ),
            items: [
              for (final e in Risco.eficacias)
                DropdownMenuItem(value: e, child: Text(e)),
            ],
            validator: (v) => v == null ? 'Selecione a eficácia.' : null,
            onChanged: (v) => setState(() => _eficacia = v),
          ),
          const SizedBox(height: 24),
          _blocoEscala(
            'Risco inerente',
            prob: _prob,
            impacto: _impacto,
            onProb: (v) => setState(() {
              _prob = v;
              _sujo = true;
            }),
            onImpacto: (v) => setState(() {
              _impacto = v;
              _sujo = true;
            }),
          ),
          const SizedBox(height: 16),
          _blocoEscala(
            'Risco residual',
            prob: _probResidual,
            impacto: _impResidual,
            onProb: (v) => setState(() {
              _probResidual = v;
              _sujo = true;
            }),
            onImpacto: (v) => setState(() {
              _impResidual = v;
              _sujo = true;
            }),
          ),
          if (_probResidual * _impResidual > _prob * _impacto) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'O risco residual está maior que o inerente. O residual '
                    'é o risco após os controles — normalmente deve ser menor.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _multiline(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: 3,
      minLines: 2,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          FormValidators.obrigatorio(v, label.replaceAll(' *', '')),
    ),
  );

  Widget _blocoEscala(
    String titulo, {
    required int prob,
    required int impacto,
    required ValueChanged<int> onProb,
    required ValueChanged<int> onImpacto,
  }) {
    final nivel = prob * impacto;
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
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                NivelBadge(nivel),
              ],
            ),
            _slider('Probabilidade', prob, onProb),
            _slider('Impacto', impacto, onImpacto),
            Text(
              'Faixa: ${FaixaNivel.of(nivel).rotulo}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  static const _escala = [
    'Muito baixo',
    'Baixo',
    'Médio',
    'Alto',
    'Muito alto',
  ];

  Widget _slider(String rotulo, int valor, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                rotulo,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Text(
              '$valor · ${_escala[valor - 1]}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        Slider(
          value: valor.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$valor · ${_escala[valor - 1]}',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
