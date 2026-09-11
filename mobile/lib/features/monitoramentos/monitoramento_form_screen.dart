import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_feedback.dart';
import '../../core/foto_evidencia.dart';
import '../../core/form_validators.dart';
import '../../data/models/monitoramento_model.dart';
import '../../data/repositorios/risco_repositorio.dart';
import '../../data/services/token_service.dart';
import '../../widgets/guarda_form.dart';

class MonitoramentoFormScreen extends StatefulWidget {
  const MonitoramentoFormScreen({
    super.key,
    required this.riscoUuid,
    this.monitoramento,
    this.repo,
    this.capturarFoto,
  });

  final String riscoUuid;
  final Monitoramento? monitoramento;
  final RiscoRepositorio? repo;

  /// Injetável em teste — captura/seleção da foto, devolve o caminho local.
  final Future<String?> Function(ImageSource)? capturarFoto;

  @override
  State<MonitoramentoFormScreen> createState() =>
      _MonitoramentoFormScreenState();
}

class _MonitoramentoFormScreenState extends State<MonitoramentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = widget.repo ?? RiscoRepositorio(TokenService());

  bool get _edicao => widget.monitoramento != null;
  bool _salvando = false;
  bool _sujo = false;
  bool _capturandoFoto = false;

  /// Caminho da nova foto tirada nesta edição (ainda não enviada).
  String? _fotoPath;

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
      _fotoPath = m.fotoLocalPath;
    }
  }

  @override
  void dispose() {
    _resultados.dispose();
    _acoesFuturas.dispose();
    _analise.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    setState(() => _capturandoFoto = true);
    try {
      final capturar = widget.capturarFoto ??
          (ImageSource o) => tirarFotoEvidencia(origem: o);
      final caminho = await capturar(origem);
      if (!mounted) return;
      setState(() {
        if (caminho != null) {
          _fotoPath = caminho;
          _sujo = true;
        }
        _capturandoFoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturandoFoto = false);
      mostrarErro(context, e);
    }
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
        await _repo.atualizarMonitoramento(
          widget.monitoramento!.id,
          payload,
          fotoLocalPath: _fotoPath,
        );
      } else {
        await _repo.criarMonitoramento(payload, fotoLocalPath: _fotoPath);
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
    return GuardaForm(
      sujo: _sujo && !_salvando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_edicao ? 'Editar monitoramento' : 'Novo monitoramento'),
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
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_sujo) setState(() => _sujo = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _campo(_resultados, 'Resultados *'),
              _campo(_acoesFuturas, 'Ações futuras *'),
              _campo(_analise, 'Análise crítica *'),
              _blocoFoto(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blocoFoto() {
    final servidor = widget.monitoramento?.foto;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidência (foto)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_fotoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_fotoPath!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (servidor != null && servidor.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  servidor,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _capturandoFoto
                      ? null
                      : () => _escolherFoto(ImageSource.camera),
                  icon: _capturandoFoto
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _fotoPath != null || (servidor?.isNotEmpty ?? false)
                        ? 'Trocar foto'
                        : 'Tirar foto',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _capturandoFoto
                      ? null
                      : () => _escolherFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Escolher da galeria'),
                ),
                if (_fotoPath != null)
                  TextButton(
                    onPressed: _capturandoFoto
                        ? null
                        : () => setState(() {
                            _fotoPath = null;
                            _sujo = true;
                          }),
                    child: const Text('Remover'),
                  ),
              ],
            ),
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
