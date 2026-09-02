import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/models/plano_acao_model.dart';
import '../../data/repositorios/risco_repositorio.dart';
import '../../data/services/token_service.dart';

class PlanoAcaoFormScreen extends StatefulWidget {
  const PlanoAcaoFormScreen({super.key, required this.riscoUuid, this.acao});

  final String riscoUuid;
  final PlanoAcao? acao;

  @override
  State<PlanoAcaoFormScreen> createState() => _PlanoAcaoFormScreenState();
}

class _PlanoAcaoFormScreenState extends State<PlanoAcaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = RiscoRepositorio(TokenService());
  static final _fmt = DateFormat('yyyy-MM-dd');

  bool get _edicao => widget.acao != null;
  bool _salvando = false;

  String? _tipoResposta;
  String? _status;
  final _descricao = TextEditingController();
  final _responsavel = TextEditingController();
  final _parceiros = TextEditingController();
  final _observacoes = TextEditingController();
  DateTime? _inicio;
  DateTime? _fim;
  double _progresso = 0;

  @override
  void initState() {
    super.initState();
    final a = widget.acao;
    if (a != null) {
      _tipoResposta = a.tipoResposta;
      _status = a.status;
      _descricao.text = a.descricaoAcao;
      _responsavel.text = a.responsavel;
      _parceiros.text = a.parceiros;
      _observacoes.text = a.observacoes;
      _inicio = DateTime.tryParse(a.dataInicio);
      _fim = DateTime.tryParse(a.dataFim);
      _progresso = a.progresso.toDouble();
    }
  }

  @override
  void dispose() {
    _descricao.dispose();
    _responsavel.dispose();
    _parceiros.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _escolherData({required bool inicio}) async {
    final base = (inicio ? _inicio : _fim) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) {
      setState(() => inicio ? _inicio = d : _fim = d);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoResposta == null || _status == null) {
      mostrarErro(context, 'Selecione tipo de resposta e status.');
      return;
    }
    if (_inicio == null || _fim == null) {
      mostrarErro(context, 'Informe as datas de início e fim.');
      return;
    }
    if (_fim!.isBefore(_inicio!)) {
      mostrarErro(context, 'A data de fim é anterior à de início.');
      return;
    }
    setState(() => _salvando = true);
    final payload = {
      'risco': widget.riscoUuid,
      'tipo_resposta': _tipoResposta,
      'descricao_acao': _descricao.text.trim(),
      'responsavel': _responsavel.text.trim(),
      'parceiros': _parceiros.text.trim(),
      'data_inicio': _fmt.format(_inicio!),
      'data_fim': _fmt.format(_fim!),
      'status': _status,
      'progresso': _progresso.round(),
      'observacoes': _observacoes.text.trim(),
    };
    try {
      if (_edicao) {
        await _repo.atualizarAcao(widget.acao!.id, payload);
      } else {
        await _repo.criarAcao(payload);
      }
      if (mounted) {
        mostrarOk(context, _edicao ? 'Ação atualizada.' : 'Ação criada.');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_edicao ? 'Editar plano de ação' : 'Novo plano de ação'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_edicao ? 'Salvar' : 'Criar'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tipoResposta,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de resposta *',
              ),
              items: [
                for (final t in PlanoAcao.tiposResposta)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              validator: (v) => v == null ? 'Selecione.' : null,
              onChanged: (v) => setState(() => _tipoResposta = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição da ação *',
              ),
              validator: (v) => FormValidators.obrigatorio(v, 'Descrição'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _responsavel,
              decoration: const InputDecoration(labelText: 'Responsável *'),
              validator: (v) => FormValidators.obrigatorio(v, 'Responsável'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parceiros,
              decoration: const InputDecoration(labelText: 'Parceiros'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _campoData(
                    'Início *',
                    _inicio,
                    () => _escolherData(inicio: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campoData(
                    'Fim *',
                    _fim,
                    () => _escolherData(inicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status *'),
              items: [
                for (final s in PlanoAcao.statuses)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              validator: (v) => v == null ? 'Selecione.' : null,
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Progresso: ${_progresso.round()}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Slider(
              value: _progresso,
              max: 100,
              divisions: 20,
              label: '${_progresso.round()}%',
              onChanged: (v) => setState(() => _progresso = v),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _observacoes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoData(String rotulo, DateTime? valor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: rotulo),
        child: Text(
          valor == null ? 'Selecionar' : DateFormat('dd/MM/yyyy').format(valor),
        ),
      ),
    );
  }
}
