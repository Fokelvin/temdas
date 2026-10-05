import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'supabase_auth_service.dart';

class AuthEndpoint extends Endpoint {
  Future<AuthMe> me(Session session) async {
    final authenticated = await requireAal2Usuario(session);
    return AuthMe(usuarioId: authenticated.usuario.id!, aal: authenticated.aal);
  }
}
