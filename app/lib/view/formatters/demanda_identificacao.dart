import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

String formatarIdentificacaoDemanda(backend.Demanda demanda) {
  final id = demanda.id;
  return id == null ? demanda.titulo : '$id - ${demanda.titulo}';
}
