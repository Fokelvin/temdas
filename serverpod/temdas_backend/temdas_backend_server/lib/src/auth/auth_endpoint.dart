import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'provisioning_service.dart';
import 'supabase_auth_service.dart';

class AuthEndpoint extends Endpoint {
  AuthEndpoint({
    SupabaseAuthService? authService,
    ProvisioningService? provisioningService,
  }) : _authService = authService,
       _provisioningService =
           provisioningService ?? ProvisioningService.production();

  final SupabaseAuthService? _authService;
  final ProvisioningService _provisioningService;

  /// Onboarding accepts AAL1/AAL2 before an internal Usuario exists.
  Future<AuthMe> provisionar(Session session) async {
    final claims = await requireValidSupabaseClaims(
      session,
      authService: _authService,
    );
    final usuario = await _provisioningService.provisionar(session, claims.sub);
    return AuthMe(
      usuarioId: usuario.id!,
      aal: claims.aal,
      isAdmin: usuario.isAdmin,
    );
  }

  Future<AuthMe> me(Session session) async {
    final authenticated = await requireAal2Usuario(
      session,
      authService: _authService,
    );
    return AuthMe(
      usuarioId: authenticated.usuario.id!,
      aal: authenticated.aal,
      isAdmin: authenticated.usuario.isAdmin,
    );
  }
}
