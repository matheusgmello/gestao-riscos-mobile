import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/models/unidade_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/unidade_service.dart';

class UnidadeFormScreen extends StatefulWidget {
  const UnidadeFormScreen({super.key, this.unidade});

  final UnidadeModel? unidade;

  @override
  State<UnidadeFormScreen> createState() => _UnidadeFormScreenState();
}

class _UnidadeFormScreenState extends State<UnidadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _service = UnidadeService(TokenService());

  bool get _edicao => widget.unidade != null;
  bool _salvando = false;

  late final _nome = TextEditingController(text: widget.unidade?.nome ?? '');
  late final _sigla = TextEditingController(text: widget.unidade?.sigla ?? '');
  late final _siglaCentro = TextEditingController(
    text: widget.unidade?.siglaCentro ?? '',
  );
  late final _nomeCentro = TextEditingController(
    text: widget.unidade?.nomeCentro ?? '',
  );
  late final _tipo = TextEditingController(
    text: widget.unidade?.tipoUnidade ?? '',
  );

  @override
  void dispose() {
    _nome.dispose();
    _sigla.dispose();
    _siglaCentro.dispose();
    _nomeCentro.dispose();
    _tipo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    final payload = {
      'nome': _nome.text.trim(),
      'sigla': _sigla.text.trim(),
      'sigla_centro': _siglaCentro.text.trim(),
      'nome_centro': _nomeCentro.text.trim(),
      'tipo_unidade': _tipo.text.trim(),
    };
    try {
      if (_edicao) {
        await _service.editar(widget.unidade!.id, payload);
      } else {
        await _service.criar(payload);
      }
      if (mounted) {
        mostrarOk(context, _edicao ? 'Unidade atualizada.' : 'Unidade criada.');
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
      appBar: AppBar(title: Text(_edicao ? 'Editar unidade' : 'Nova unidade')),
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
            _campo(_nome, 'Nome *', obrigatorio: true),
            _campo(_sigla, 'Sigla *', obrigatorio: true),
            _campo(_siglaCentro, 'Sigla do centro'),
            _campo(_nomeCentro, 'Nome do centro'),
            _campo(_tipo, 'Tipo da unidade'),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    bool obrigatorio = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      validator: obrigatorio
          ? (v) => FormValidators.obrigatorio(v, label.replaceAll(' *', ''))
          : null,
    ),
  );
}
