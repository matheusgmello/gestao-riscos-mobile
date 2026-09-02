import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_error.dart';
import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/services/recuperacao_service.dart';
import '../../data/services/token_service.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

enum _Etapa { email, codigo, novaSenha }

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _service = RecuperacaoService(TokenService());

  _Etapa _etapa = _Etapa.email;
  bool _carregando = false;

  final _email = TextEditingController();
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();

  Timer? _timer;
  int _segundos = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _codigo.dispose();
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  void _iniciarContador() {
    _timer?.cancel();
    setState(() => _segundos = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundos <= 1) {
        t.cancel();
        setState(() => _segundos = 0);
      } else {
        setState(() => _segundos--);
      }
    });
  }

  Future<void> _rodar(Future<void> Function() acao) async {
    setState(() => _carregando = true);
    try {
      await acao();
    } on ApiError catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    final erro =
        FormValidators.email(_email.text) ??
        FormValidators.obrigatorio(_email.text, 'E-mail');
    if (erro != null) {
      mostrarErro(context, erro);
      return;
    }
    await _rodar(() async {
      await _service.enviarCodigo(_email.text.trim());
      if (!mounted) return;
      setState(() => _etapa = _Etapa.codigo);
      _iniciarContador();
    });
  }

  Future<void> _validar() async {
    if (_codigo.text.trim().length != 6) {
      mostrarErro(context, 'O código tem 6 dígitos.');
      return;
    }
    await _rodar(() async {
      await _service.validarCodigo(_email.text.trim(), _codigo.text.trim());
      if (!mounted) return;
      setState(() => _etapa = _Etapa.novaSenha);
    });
  }

  Future<void> _redefinir() async {
    final erroSenha = FormValidators.senha(_senha.text);
    if (erroSenha != null) {
      mostrarErro(context, erroSenha);
      return;
    }
    if (_senha.text != _confirma.text) {
      mostrarErro(context, 'As senhas não coincidem.');
      return;
    }
    await _rodar(() async {
      await _service.redefinir(
        email: _email.text.trim(),
        codigo: _codigo.text.trim(),
        novaSenha: _senha.text,
        confirmacaoSenha: _confirma.text,
      );
      if (!mounted) return;
      mostrarOk(context, 'Senha redefinida. Faça login.');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _passos(),
              const SizedBox(height: 24),
              ..._campos(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregando ? null : _acaoEtapa,
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_rotuloBotao()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback get _acaoEtapa => switch (_etapa) {
    _Etapa.email => _enviar,
    _Etapa.codigo => _validar,
    _Etapa.novaSenha => _redefinir,
  };

  String _rotuloBotao() => switch (_etapa) {
    _Etapa.email => 'Enviar código',
    _Etapa.codigo => 'Validar código',
    _Etapa.novaSenha => 'Redefinir senha',
  };

  Widget _passos() {
    final i = _Etapa.values.indexOf(_etapa);
    const rotulos = ['E-mail', 'Código', 'Nova senha'];
    return Row(
      children: [
        for (var p = 0; p < 3; p++) ...[
          if (p > 0)
            Expanded(
              child: Container(
                height: 2,
                color: p <= i
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: p <= i
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                child: Text(
                  '${p + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 4),
              Text(rotulos[p], style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _campos() {
    switch (_etapa) {
      case _Etapa.email:
        return [
          const Text('Informe o e-mail cadastrado. Enviaremos um código.'),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
        ];
      case _Etapa.codigo:
        return [
          Text('Código enviado para ${_email.text.trim()}.'),
          const SizedBox(height: 12),
          TextField(
            controller: _codigo,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _segundos > 0
                ? Text(
                    'Expira em ${_segundos}s',
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                : TextButton(
                    onPressed: _carregando ? null : _enviar,
                    child: const Text('Reenviar código'),
                  ),
          ),
        ];
      case _Etapa.novaSenha:
        return [
          const Text('Defina a nova senha (mínimo 8 caracteres).'),
          const SizedBox(height: 12),
          TextField(
            controller: _senha,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirma,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
          ),
        ];
    }
  }
}
