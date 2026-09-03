import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/form_validators.dart';
import '../../data/models/pdi_model.dart';
import '../../data/services/pdi_service.dart';
import '../../data/services/token_service.dart';
import '../../widgets/estado.dart';

class PdiScreen extends StatelessWidget {
  const PdiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estrutura PDI'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Desafios'),
              Tab(text: 'Objetivos'),
              Tab(text: 'Macroproc.'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_AbaDesafios(), _AbaObjetivos(), _AbaMacroprocessos()],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------

class _AbaDesafios extends StatefulWidget {
  const _AbaDesafios();

  @override
  State<_AbaDesafios> createState() => _AbaDesafiosState();
}

class _AbaDesafiosState extends State<_AbaDesafios> {
  final _service = PdiService(TokenService());
  late Future<List<DesafioPdi>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.desafios();
  }

  void _recarregar() => setState(() => _future = _service.desafios());

  Future<void> _editar([DesafioPdi? d]) async {
    final numero = TextEditingController(text: d?.numero.toString() ?? '');
    final descricao = TextEditingController(text: d?.descricao ?? '');
    final ok = await _dialogForm(
      context,
      titulo: d == null ? 'Novo desafio' : 'Editar desafio',
      campos: [
        _CampoDialog(numero, 'Número', numero: true),
        _CampoDialog(descricao, 'Descrição'),
      ],
    );
    if (ok != true) return;
    final payload = {
      'numero': int.tryParse(numero.text.trim()) ?? 0,
      'descricao': descricao.text.trim(),
    };
    try {
      if (d == null) {
        await _service.criar('desafios', payload);
      } else {
        await _service.atualizar('desafios', d.id, payload);
      }
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _remover(DesafioPdi d) async {
    if (!await confirmar(
      context,
      titulo: 'Remover desafio',
      mensagem: '"${d.descricao}" será removido.',
      confirmar: 'Remover',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _service.remover('desafios', d.id);
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ListaPdi<DesafioPdi>(
      future: _future,
      onNovo: () => _editar(),
      titulo: (d) => d.rotulo,
      onEditar: _editar,
      onRemover: _remover,
      onRefresh: _recarregar,
    );
  }
}

// --------------------------------------------------------------------------

class _AbaMacroprocessos extends StatefulWidget {
  const _AbaMacroprocessos();

  @override
  State<_AbaMacroprocessos> createState() => _AbaMacroprocessosState();
}

class _AbaMacroprocessosState extends State<_AbaMacroprocessos> {
  final _service = PdiService(TokenService());
  late Future<List<Macroprocesso>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.macroprocessos();
  }

  void _recarregar() => setState(() => _future = _service.macroprocessos());

  Future<void> _editar([Macroprocesso? m]) async {
    final nome = TextEditingController(text: m?.nome ?? '');
    final ok = await _dialogForm(
      context,
      titulo: m == null ? 'Novo macroprocesso' : 'Editar macroprocesso',
      campos: [_CampoDialog(nome, 'Nome')],
    );
    if (ok != true) return;
    try {
      if (m == null) {
        await _service.criar('macroprocessos', {'nome': nome.text.trim()});
      } else {
        await _service.atualizar('macroprocessos', m.id, {
          'nome': nome.text.trim(),
        });
      }
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _remover(Macroprocesso m) async {
    if (!await confirmar(
      context,
      titulo: 'Remover macroprocesso',
      mensagem: '"${m.nome}" será removido.',
      confirmar: 'Remover',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _service.remover('macroprocessos', m.id);
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ListaPdi<Macroprocesso>(
      future: _future,
      onNovo: () => _editar(),
      titulo: (m) => m.nome,
      onEditar: _editar,
      onRemover: _remover,
      onRefresh: _recarregar,
    );
  }
}

// --------------------------------------------------------------------------

class _AbaObjetivos extends StatefulWidget {
  const _AbaObjetivos();

  @override
  State<_AbaObjetivos> createState() => _AbaObjetivosState();
}

class _AbaObjetivosState extends State<_AbaObjetivos> {
  final _service = PdiService(TokenService());
  late Future<List<ObjetivoPdi>> _future;
  List<DesafioPdi> _desafios = [];

  @override
  void initState() {
    super.initState();
    _future = _service.objetivos();
    _service.desafios().then((d) {
      if (mounted) setState(() => _desafios = d);
    });
  }

  void _recarregar() => setState(() => _future = _service.objetivos());

  Future<void> _editar([ObjetivoPdi? o]) async {
    final codigo = TextEditingController(text: o?.codigo ?? '');
    final descricao = TextEditingController(text: o?.descricao ?? '');
    int? desafioId = o?.desafioId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(o == null ? 'Novo objetivo' : 'Editar objetivo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codigo,
                  decoration: const InputDecoration(labelText: 'Código'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descricao,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: desafioId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Desafio'),
                  items: [
                    for (final d in _desafios)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(d.rotulo, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => desafioId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || desafioId == null) return;
    final payload = {
      'codigo': codigo.text.trim(),
      'descricao': descricao.text.trim(),
      'desafio': desafioId,
    };
    try {
      if (o == null) {
        await _service.criar('objetivos', payload);
      } else {
        await _service.atualizar('objetivos', o.id, payload);
      }
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  Future<void> _remover(ObjetivoPdi o) async {
    if (!await confirmar(
      context,
      titulo: 'Remover objetivo',
      mensagem: '"${o.codigo}" será removido.',
      confirmar: 'Remover',
      destrutivo: true,
    )) {
      return;
    }
    try {
      await _service.remover('objetivos', o.id);
      _recarregar();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ListaPdi<ObjetivoPdi>(
      future: _future,
      onNovo: () => _editar(),
      titulo: (o) => o.rotulo,
      onEditar: _editar,
      onRemover: _remover,
      onRefresh: _recarregar,
    );
  }
}

// --------------------------------------------------------------------------

class _ListaPdi<T> extends StatelessWidget {
  const _ListaPdi({
    required this.future,
    required this.onNovo,
    required this.titulo,
    required this.onEditar,
    required this.onRemover,
    required this.onRefresh,
  });

  final Future<List<T>> future;
  final VoidCallback onNovo;
  final String Function(T) titulo;
  final void Function(T) onEditar;
  final void Function(T) onRemover;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: onNovo,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<T>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SkeletonLista(altura: 56);
          }
          if (snap.hasError) {
            return EstadoErro(erro: snap.error!, onTentar: onRefresh);
          }
          final itens = snap.data ?? [];
          if (itens.isEmpty) {
            return const EstadoVazio(
              icone: Icons.list_alt_outlined,
              titulo: 'Nada cadastrado',
              detalhe: 'Use o botão + para adicionar o primeiro item.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 88),
            itemCount: itens.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => ListTile(
              title: Text(titulo(itens[i])),
              onTap: () => onEditar(itens[i]),
              trailing: PopupMenuButton<String>(
                onSelected: (v) =>
                    v == 'editar' ? onEditar(itens[i]) : onRemover(itens[i]),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'remover', child: Text('Remover')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CampoDialog {
  _CampoDialog(this.controller, this.label, {this.numero = false});
  final TextEditingController controller;
  final String label;
  final bool numero;
}

Future<bool?> _dialogForm(
  BuildContext context, {
  required String titulo,
  required List<_CampoDialog> campos,
}) {
  final formKey = GlobalKey<FormState>();
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in campos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: c.controller,
                  keyboardType: c.numero ? TextInputType.number : null,
                  decoration: InputDecoration(labelText: c.label),
                  validator: (v) => FormValidators.obrigatorio(v, c.label),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}
