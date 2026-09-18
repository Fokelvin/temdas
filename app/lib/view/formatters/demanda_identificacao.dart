import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

String formatarIdentificacaoDemanda(backend.Demanda demanda) {
  return formatarIdentificacaoDemandaPorId(
    id: demanda.id,
    titulo: demanda.titulo,
  );
}

String formatarIdentificacaoDemandaPorId({
  required int? id,
  required String titulo,
}) {
  return id == null ? titulo : '$id - $titulo';
}
