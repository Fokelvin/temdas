import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../formatters/demanda_identificacao.dart';

class DemandaBuscaGlobal extends StatefulWidget {
  const DemandaBuscaGlobal({super.key, required this.buscar});

  final Future<List<backend.Demanda>> Function(String) buscar;

  @override
  State<DemandaBuscaGlobal> createState() => _DemandaBuscaGlobalState();
}

class _DemandaBuscaGlobalState extends State<DemandaBuscaGlobal> {
  final _consulta = TextEditingController();
  Future<List<backend.Demanda>>? _resultado;

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  void _buscar() {
    final consulta = _consulta.text.trim();
    final resultado = consulta.isEmpty ? null : widget.buscar(consulta);
    setState(() {
      _resultado = resultado;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buscar em Demandas e Backlog'),
    content: SizedBox(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _consulta,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            decoration: InputDecoration(
              labelText: 'ID ou título',
              suffixIcon: IconButton(
                tooltip: 'Buscar',
                onPressed: _buscar,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          if (_resultado != null)
            Flexible(
              child: FutureBuilder<List<backend.Demanda>>(
                future: _resultado,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Não foi possível buscar. Tente novamente.',
                    );
                  }
                  final demandas = snapshot.data ?? const [];
                  if (demandas.isEmpty) {
                    return const Text('Nenhuma demanda encontrada.');
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final demanda in demandas)
                        ListTile(
                          title: Text(formatarIdentificacaoDemanda(demanda)),
                          subtitle: Text(
                            demanda.localizacao ==
                                    backend.DemandaLocalizacao.backlog
                                ? 'Backlog'
                                : 'Demandas',
                          ),
                          onTap: () => Navigator.pop(context, demanda),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
    ],
  );
}
