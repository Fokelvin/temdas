import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart';

/// Reads the current session on every call, including after refresh/logout.
class SupabaseSession implements ClientAuthKeyProvider {
  final SupabaseClient client;

  SupabaseSession(this.client);

  Session? get currentSession => client.auth.currentSession;
  String? get accessToken => currentSession?.accessToken;
  Stream<AuthState> get authChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => client.auth.signOut();

  @override
  Future<String?> get authHeaderValue async {
    final session = currentSession;
    if (session == null) return null;
    // Supabase also refreshes automatically. Cover calls after app resume.
    if (session.isExpired) await client.auth.refreshSession();
    final token = accessToken;
    return token == null ? null : 'Bearer $token';
  }
}

SupabaseSession? supabaseSession;

Future<void> initializeSupabaseSession() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty && key.isEmpty) return;
  if (url.isEmpty || key.isEmpty) {
    throw StateError('Configure SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.');
  }
  if (!key.startsWith('sb_publishable_')) {
    throw StateError('Use a Supabase publishable key in Flutter.');
  }
  await Supabase.initialize(
    url: url,
    publishableKey: key,
    // The callback route consumes the URL and reports errors itself.
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
  );
  supabaseSession = SupabaseSession(Supabase.instance.client);
}
