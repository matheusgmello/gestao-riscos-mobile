import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/models/monitoramento_model.dart';
import '../../data/repositorios/risco_repositorio.dart';
import '../../data/services/token_service.dart';

class MonitoramentoFormScreen extends StatefulWidget {
  const MonitoramentoFormScreen({
    super.key,
    required this.riscoUuid,
    this.monitoramento,
  });

  final String riscoUuid;
  final Monitoramento? monitoramento;

  @override
  State<MonitoramentoFormScreen> createState() =>
      _MonitoramentoFormScreenState();
}

class _MonitoramentoFormScreenState extends State<MonitoramentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = RiscoRepositorio(TokenService());

  bool get _edicao => widget.monitoramento != null;
  bool _salvando = false;

  final _resultados = TextEditingController();
  final _acoesFuturas = TextEditingController();
  final _analise = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = widget.monitoramento;
    if (m != null) {
      _resultados.text = m.resultados;
      _acoesFuturas.text = m.acoesFuturas;
      _analise.text = m.analiseCritica;
    }
  }

  @override
  void dispose() {
    _resultados.dispose();
    _acoesFuturas.dispose();
    _analise.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final payload = {
      'risco': widget.riscoUuid,
      'resultados': _resultados.text.trim(),
      'acoes_futuras': _acoesFuturas.text.trim(),
      'analise_critica': _analise.text.trim(),
    };
    try {
      if (_edicao) {
        await _repo.atualizarMonitoramento(widget.monitoramento!.id, payload);
      } else {
        await _repo.criarMonitoramento(payload);
      }
      if (mounted) {
        mostrarOk(
          context,
          _edicao ? 'Monitoramento atualizado.' : 'Monitoramento criado.',
        );
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
        title: Text(_edicao ? 'Editar monitoramento' : 'Novo monitoramento'),
      ),
      bottomNavigationBar: SafeArea(
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
                : Text(_edicao ? 'Salvar' : 'Criar'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _campo(_resultados, 'Resultados *'),
            _campo(_acoesFuturas, 'Ações futuras *'),
            _campo(_analise, 'Análise crítica *'),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          FormValidators.obrigatorio(v, label.replaceAll(' *', '')),
    ),
  );
}
