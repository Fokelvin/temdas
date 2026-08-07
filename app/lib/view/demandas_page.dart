import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../view_model/demandas_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/demanda_card.dart';

class DemandasPage extends StatefulWidget {
  const DemandasPage({super.key});

  @override
  State<DemandasPage> createState() => _DemandasPageState();
}

class _DemandasPageState extends State<DemandasPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoController = TextEditingController(text: '1');
  final _viewModel = DemandasViewModel();

  backend.Prioridade _prioridade = backend.Prioridade.media;

  @override
  void initState() {
    super.initState();
    _viewModel.carregarDemandas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _criarDemanda() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final descricao = _descricaoController.text.trim();

    final criada = await _viewModel.criarDemanda(
      titulo: _tituloController.text.trim(),
      tempoEstimadoHoras: double.parse(
        _tempoController.text.replaceAll(',', '.'),
      ),
      descricao: descricao.isEmpty ? null : descricao,
      prioridade: _prioridade,
    );

    if (criada) {
      await _viewModel.carregarDemandas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final demanda = _viewModel.demandaCriada;

        return PageScaffold(
          title: 'Demandas',
          route: AppRoutes.demandas,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Criar demanda',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _tituloController,
                              decoration: const InputDecoration(
                                labelText: 'Título',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o título.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descricaoController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<backend.Prioridade>(
                              initialValue: _prioridade,
                              decoration: const InputDecoration(
                                labelText: 'Prioridade',
                              ),
                              items: backend.Prioridade.values
                                  .map(
                                    (prioridade) => DropdownMenuItem(
                                      value: prioridade,
                                      child: Text(
                                        switch (prioridade) {
                                          backend.Prioridade.baixa => 'Baixa',
                                          backend.Prioridade.media => 'Média',
                                          backend.Prioridade.alta => 'Alta',
                                          backend.Prioridade.urgente => 'Urgente',
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _prioridade = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tempoController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Tempo estimado (horas)',
                              ),
                              validator: (value) {
                                final horas = double.tryParse(
                                  (value ?? '').replaceAll(',', '.'),
                                );

                                if (horas == null || horas <= 0) {
                                  return 'Informe um tempo válido.';
                                }

                                if ((horas * 2).roundToDouble() != horas * 2) {
                                  return 'Use intervalos de 0,5 hora.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed:
                                  _viewModel.enviando ? null : _criarDemanda,
                              child: Text(
                                _viewModel.enviando
                                    ? 'Enviando...'
                                    : 'Criar demanda',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_viewModel.erro != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _viewModel.erro!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Demandas salvas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (_viewModel.carregando)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_viewModel.demandas.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Nenhuma demanda cadastrada.'),
                      ),
                    )
                  else
                    ..._viewModel.demandas.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DemandaCard(demanda: item),
                      ),
                    ),
                  if (demanda != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demanda retornada pelo backend',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text('ID: ${demanda.id}'),
                            Text('Título: ${demanda.titulo}'),
                            Text('Status: ${demanda.status.name}'),
                            Text('Prioridade: ${demanda.prioridade.name}'),
                            Text(
                              'Tempo estimado: '
                              '${demanda.tempoEstimadoMinutos} minutos',
                            ),
                            Text(
                              'Tempo executado: '
                              '${demanda.tempoExecutadoMinutos} minutos',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
