import 'package:serverpod/serverpod.dart';

import '../auth/supabase_auth_service.dart';
import '../generated/protocol.dart';
import 'convite_service.dart';

class ConviteEndpoint extends Endpoint {
  ConviteEndpoint({ConviteService? service})
    : _service = service ?? ConviteService.production();

  final ConviteService _service;

  Future<String> consultar(Session session, String email) async {
    await _requireAdmin(session);
    return _service.consultar(session, email);
  }

  Future<String> convidar(Session session, String email) async {
    final admin = await _requireAdmin(session);
    return _service.enviar(session, admin.usuario.id!, email, reenviar: false);
  }

  Future<String> reenviar(Session session, String email) async {
    final admin = await _requireAdmin(session);
    return _service.enviar(session, admin.usuario.id!, email, reenviar: true);
  }

  Future<AuthenticatedUsuario> _requireAdmin(Session session) async {
    final usuario = await requireAal2Usuario(session);
    if (!usuario.usuario.isAdmin) {
      throw AuthException(codigo: 'adminRequired');
    }
    return usuario;
  }
}
