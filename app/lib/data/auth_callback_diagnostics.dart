import 'dart:convert';

// Temporary callback diagnostics. Remove this file and its call sites after
// recovery has been diagnosed. Never accept arbitrary messages or field maps.
enum CallbackDiagnosticStage { page, parameters, exchange, restore, session }

enum CallbackDiagnosticReason {
  pageStarted,
  pageResult,
  pageSessionExpired,
  processorReentered,
  clientUnavailable,
  parametersInvalid,
  parametersDuplicate,
  parametersConflicting,
  parametersAmbiguous,
  payloadAbsent,
  parameterEmpty,
  requestedFlowUnknown,
  exchangeStarted,
  pkceExchangeFailed,
  pkceVerifierMissing,
  pkceVerifierRejected,
  pkceFlowStateMissing,
  callbackReuseOrExpiryReported,
  sessionAbsentAfterExchange,
  sessionUserEmpty,
  sessionUserMismatch,
  flowsMismatch,
  returnedFlowUnknown,
  callbackAccepted,
  authExceptionInvalid,
  authExceptionExpired,
  operationUnavailable,
  callbackStateMissing,
  callbackStateIncomplete,
  callbackStateTooOld,
  callbackStateMalformed,
  sessionAbsent,
  sessionUserUnverified,
  sessionVerified,
  callbackRestored,
}

const callbackDiagnostics = CallbackDiagnostics();

class CallbackDiagnostics {
  const CallbackDiagnostics([this._output = _writeToConsole]);

  final void Function(String) _output;

  // The schema deliberately accepts only fixed enums and booleans. No URL,
  // exception, parameter value, identity, session, or credential can be passed.
  void emit(
    CallbackDiagnosticStage stage,
    CallbackDiagnosticReason reason, {
    bool? hasCode,
    bool? hasTokenHash,
    bool? hasAccessToken,
    bool? hasProviderError,
    bool? hasSession,
    bool? hasCurrentSession,
    bool? hasUser,
    bool? userMatches,
    bool? hasRequestedFlow,
    bool? hasReturnedFlow,
    bool? afterRefresh,
    bool? expired,
    bool? invalid,
    bool? accepted,
    bool? unavailable,
  }) {
    try {
      final fields = <String, Object>{
        'stage': stage.name,
        'reason': reason.name,
        'hasCode': ?hasCode,
        'hasTokenHash': ?hasTokenHash,
        'hasAccessToken': ?hasAccessToken,
        'hasProviderError': ?hasProviderError,
        'hasSession': ?hasSession,
        'hasCurrentSession': ?hasCurrentSession,
        'hasUser': ?hasUser,
        'userMatches': ?userMatches,
        'hasRequestedFlow': ?hasRequestedFlow,
        'hasReturnedFlow': ?hasReturnedFlow,
        'afterRefresh': ?afterRefresh,
        'expired': ?expired,
        'invalid': ?invalid,
        'accepted': ?accepted,
        'unavailable': ?unavailable,
      };
      _output('TEMDAS_AUTH_DIAG ${jsonEncode(fields)}');
    } catch (_) {
      // Diagnostics must never change authentication behavior.
    }
  }
}

void _writeToConsole(String message) {
  // Intentionally enabled in release Web builds; not gated by kDebugMode.
  // ignore: avoid_print
  print(message);
}
