import 'package:flutter/material.dart';

/// Campo de seleção única com busca — para listas grandes (ex.: 1300+ unidades)
/// onde um Dropdown seria inutilizável.
class BuscaSelecao<T> extends StatelessWidget {
  const BuscaSelecao({
    super.key,
    required this.label,
    required this.itens,
    required this.rotulo,
    required this.selecionado,
    required this.onChanged,
    this.rotuloVazio = 'Todos',
    this.permiteVazio = true,
  });

  final String label;
  final List<T> itens;
  final String Function(T) rotulo;
  final T? selecionado;
  final ValueChanged<T?> onChanged;
  final String rotuloVazio;
  final bool permiteVazio;

  Future<void> _abrir(BuildContext context) async {
    final r = await showModalBottomSheet<_Resultado<T>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SheetBusca<T>(
        titulo: label,
        itens: itens,
        rotulo: rotulo,
        rotuloVazio: rotuloVazio,
        permiteVazio: permiteVazio,
      ),
    );
    if (r != null) onChanged(r.valor);
  }

  @override
  Widget build(BuildContext context) {
    final texto = selecionado != null ? rotulo(selecionado as T) : rotuloVazio;
    return InkWell(
      onTap: () => _abrir(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(texto, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );
  }
}

class _Resultado<T> {
  const _Resultado(this.valor);
  final T? valor;
}

class _SheetBusca<T> extends StatefulWidget {
  const _SheetBusca({
    required this.titulo,
    required this.itens,
    required this.rotulo,
    required this.rotuloVazio,
    required this.permiteVazio,
  });

  final String titulo;
  final List<T> itens;
  final String Function(T) rotulo;
  final String rotuloVazio;
  final bool permiteVazio;

  @override
  State<_SheetBusca<T>> createState() => _SheetBuscaState<T>();
}

class _SheetBuscaState<T> extends State<_SheetBusca<T>> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final termo = _busca.trim().toLowerCase();
    final filtrados = termo.isEmpty
        ? widget.itens
        : widget.itens
              .where((i) => widget.rotulo(i).toLowerCase().contains(termo))
              .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar ${widget.titulo.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (widget.permiteVazio && termo.isEmpty)
                    ListTile(
                      title: Text(widget.rotuloVazio),
                      onTap: () => Navigator.pop(context, _Resultado<T>(null)),
                    ),
                  for (final i in filtrados)
                    ListTile(
                      title: Text(widget.rotulo(i)),
                      onTap: () => Navigator.pop(context, _Resultado<T>(i)),
                    ),
                  if (filtrados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Nenhum resultado.')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
