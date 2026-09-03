import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/models/unidade_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/unidade_service.dart';
import '../../data/services/usuario_service.dart';
import '../../widgets/busca_selecao.dart';
import '../../widgets/guarda_form.dart';

class GestorFormScreen extends StatefulWidget {
  const GestorFormScreen({super.key, this.gestor});

  final UsuarioModel? gestor;

  @override
  State<GestorFormScreen> createState() => _GestorFormScreenState();
}

class _GestorFormScreenState extends State<GestorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokens = TokenService();
  late final _service = UsuarioService(_tokens);

  bool get _edicao => widget.gestor != null;
  bool _carregando = true;
  bool _salvando = false;
  bool _sujo = false;

  List<UnidadeModel> _unidades = [];
  final _siape = TextEditingController();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String _cargo = 'gestor';
  final List<int> _setoresIds = [];

  @override
  void initState() {
    super.initState();
    final g = widget.gestor;
    if (g != null) {
      _siape.text = g.siape;
      _nome.text = g.nome;
      _email.text = g.email ?? '';
      _cargo = g.cargo;
      _setoresIds.addAll(g.setoresIds);
    }
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final u = await UnidadeService(_tokens).listar();
      if (mounted) {
        setState(() {
          _unidades = u;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        mostrarErro(context, e);
        setState(() => _carregando = false);
      }
    }
  }

  @override
  void dispose() {
    _siape.dispose();
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  String _rotuloUnidade(int id) {
    for (final u in _unidades) {
      if (u.id == id) return u.rotulo;
    }
    return 'Unidade $id';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      if (_edicao) {
        await _service.editarGestor(
          widget.gestor!.uuid,
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          cargo: _cargo,
          setoresIds: _setoresIds,
        );
      } else {
        await _service.registrar(
          siape: _siape.text.trim(),
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          senha: _senha.text,
          setoresIds: _setoresIds,
          cargo: _cargo,
        );
      }
      if (mounted) {
        mostrarOk(context, _edicao ? 'Gestor atualizado.' : 'Gestor criado.');
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
        title: Text(_edicao ? 'Editar gestor' : 'Novo gestor'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: () => Navigator.maybePop(context),
        ),
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
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              onChanged: () {
                if (!_sujo) setState(() => _sujo = true);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _siape,
                    enabled: !_edicao,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SIAPE *'),
                    validator: (v) => FormValidators.obrigatorio(v, 'SIAPE'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nome,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    validator: (v) => FormValidators.obrigatorio(v, 'Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail *'),
                    validator: (v) =>
                        FormValidators.obrigatorio(v, 'E-mail') ??
                        FormValidators.email(v),
                  ),
                  if (!_edicao) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senha,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha *'),
                      validator: FormValidators.senha,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _cargo,
                    decoration: const InputDecoration(labelText: 'Cargo'),
                    items: const [
                      DropdownMenuItem(value: 'gestor', child: Text('Gestor')),
                      DropdownMenuItem(
                        value: 'gestor_adm',
                        child: Text('Gestor Administrador'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _cargo = v ?? 'gestor'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unidades vinculadas',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final id in _setoresIds)
                    Chip(
                      label: Text(_rotuloUnidade(id)),
                      onDeleted: () => setState(() {
                        _setoresIds.remove(id);
                        _sujo = true;
                      }),
                    ),
                  const SizedBox(height: 8),
                  BuscaSelecao<UnidadeModel>(
                    label: 'Adicionar unidade',
                    rotuloVazio: 'Selecionar',
                    permiteVazio: false,
                    itens: _unidades
                        .where((u) => !_setoresIds.contains(u.id))
                        .toList(),
                    rotulo: (u) => u.rotulo,
                    selecionado: null,
                    onChanged: (u) {
                      if (u != null) {
                        setState(() {
                          _setoresIds.add(u.id);
                          _sujo = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
