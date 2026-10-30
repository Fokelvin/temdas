import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_provisioning.dart';
import '../data/supabase_session.dart';
import '../view/demandas_page.dart';
import '../view/home_page.dart';
import 'auth_gate.dart';

/// A public front door; sessions still pass every existing AuthGate check.
class PublicHomeEntry extends StatelessWidget {
  const PublicHomeEntry({
    super.key,
    this.session,
    this.provisioning,
    this.authenticatedChild,
  });

  final SupabaseSession? session;
  final AuthProvisioning? provisioning;
  final Widget? authenticatedChild;

  @override
  Widget build(BuildContext context) {
    final effectiveSession = session ?? supabaseSession;
    return StreamBuilder<AuthState>(
      stream: effectiveSession?.authChanges,
      builder: (context, _) {
        if (effectiveSession?.currentSession == null) return const HomePage();
        return AuthGate(
          session: effectiveSession,
          provisioning: provisioning,
          child: authenticatedChild ?? const DemandasPage(),
        );
      },
    );
  }
}
