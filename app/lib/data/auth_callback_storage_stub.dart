abstract class CallbackStorage {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
  void clearUrl();
  void leaveCallback();
}

/// Used by Web history.replaceState; never retains query or token fragments.
Uri sanitizedAuthEntryUri(Uri uri) {
  final fragmentPath = Uri.tryParse(uri.fragment)?.path;
  final fragment =
      const {'/auth/callback', '/auth/confirm'}.contains(fragmentPath)
      ? fragmentPath!
      : '';
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    fragment: fragment.isEmpty ? null : fragment,
  );
}

final CallbackStorage browserCallbackStorage = _NoopCallbackStorage();

class _NoopCallbackStorage implements CallbackStorage {
  @override
  String? read(String key) => null;

  @override
  void write(String key, String value) {}

  @override
  void remove(String key) {}

  @override
  void clearUrl() {}

  @override
  void leaveCallback() {}
}
