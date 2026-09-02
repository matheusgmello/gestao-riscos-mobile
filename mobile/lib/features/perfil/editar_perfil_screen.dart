import 'package:flutter/material.dart';

import '../../core/api_error.dart';
import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/usuario_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key, required this.usuario});

  final UsuarioModel usuario;

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = UsuarioService(TokenService());

  late final _email = TextEditingController(text: widget.usuario.email ?? '');
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirma = TextEditingController();

  bool _trocarSenha = false;
  bool _salvando = false;

  @override
  void dispose() {
    _email.dispose();
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_trocarSenha && _novaSenha.text != _confirma.text) {
      mostrarErro(context, 'As senhas não coincidem.');
      return;
    }
    setState(() => _salvando = true);
    try {
      await _service.atualizarPerfil(
        email: _email.text.trim(),
        senhaAtual: _trocarSenha ? _senhaAtual.text : null,
        novaSenha: _trocarSenha ? _novaSenha.text : null,
        confirmacaoSenha: _trocarSenha ? _confirma.text : null,
      );
      if (mounted) {
        mostrarOk(context, 'Perfil atualizado.');
        Navigator.pop(context, true);
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        mostrarErro(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
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
                : const Text('Salvar'),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: FormValidators.email,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Trocar senha'),
              value: _trocarSenha,
              onChanged: (v) => setState(() => _trocarSenha = v),
            ),
            if (_trocarSenha) ...[
              TextFormField(
                controller: _senhaAtual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) => _trocarSenha
                    ? FormValidators.obrigatorio(v, 'Senha atual')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _novaSenha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) => _trocarSenha ? FormValidators.senha(v) : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirma,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
                validator: (v) => _trocarSenha
                    ? FormValidators.obrigatorio(v, 'Confirmação')
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
