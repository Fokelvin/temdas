abstract class CallbackStorage {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
  void clearUrl();
  void leaveCallback();
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
