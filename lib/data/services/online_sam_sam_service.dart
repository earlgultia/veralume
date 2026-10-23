import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

enum SamSamOnlineFailure {
  offline,
  unconfigured,
  unavailable,
  timeout,
  rateLimited,
  invalidConfiguration,
  providerKeyInvalid,
  providerCredits,
  modelsUnavailable,
  providerUnavailable,
  server,
}

class SamSamOnlineException implements Exception {
  const SamSamOnlineException(this.kind, [this.message = '']);

  final SamSamOnlineFailure kind;
  final String message;
}

class OnlineSamSamService {
  OnlineSamSamService({
    http.Client? client,
    Connectivity? connectivity,
    String? supabaseUrl,
    String? supabasePublishableKey,
  }) : _client = client ?? http.Client(),
       _connectivity = connectivity ?? Connectivity(),
       _supabaseUrl = supabaseUrl ?? configuredSupabaseUrl,
       _supabasePublishableKey =
           supabasePublishableKey ?? configuredSupabasePublishableKey,
       _ownsClient = client == null;

  static const functionName = 'david';
  static const configuredSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const configuredSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  final http.Client _client;
  final Connectivity _connectivity;
  final String _supabaseUrl;
  final String _supabasePublishableKey;
  final bool _ownsClient;

  bool get configured =>
      _supabaseUrl.trim().isNotEmpty &&
      _supabasePublishableKey.trim().isNotEmpty;

  Uri get _endpoint => Uri.parse(
    '${_supabaseUrl.replaceFirst(RegExp(r'/+$'), '')}/functions/v1/$functionName',
  );

  Future<bool> hasNetworkConnection() async {
    final connections = await _connectivity.checkConnectivity();
    return !connections.contains(ConnectivityResult.none);
  }

  Future<bool> canUseOnline() async {
    if (!configured) return false;
    return hasNetworkConnection();
  }

  Future<String> ask({
    required String question,
    required String language,
    List<Map<String, String>> conversation = const [],
  }) async {
    if (!configured) {
      throw const SamSamOnlineException(SamSamOnlineFailure.unconfigured);
    }
    final history = <Map<String, String>>[
      for (final turn in conversation)
        if ((turn['role'] == 'user' || turn['role'] == 'assistant') &&
            (turn['content']?.trim().isNotEmpty ?? false))
          {
            'role': turn['role']!,
            'content': turn['content']!.length <= 1200
                ? turn['content']!
                : turn['content']!.substring(0, 1200),
          },
    ];

    try {
      final response = await _client
          .post(
            _endpoint,
            headers: {
              'apikey': _supabasePublishableKey.trim(),
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'question': question,
              'language': language,
              'conversation': history,
            }),
          )
          .timeout(const Duration(seconds: 35));

      final providerCode = _providerErrorCode(response.body);
      if (response.statusCode == 429 ||
          providerCode == 'provider_rate_limited') {
        throw const SamSamOnlineException(SamSamOnlineFailure.rateLimited);
      }
      if (providerCode == 'provider_key_missing' ||
          providerCode == 'provider_key_invalid') {
        throw SamSamOnlineException(
          SamSamOnlineFailure.providerKeyInvalid,
          _providerErrorMessage(response.body),
        );
      }
      if (providerCode == 'provider_billing') {
        throw SamSamOnlineException(
          SamSamOnlineFailure.providerCredits,
          _providerErrorMessage(response.body),
        );
      }
      if (providerCode == 'free_models_unavailable') {
        throw SamSamOnlineException(
          SamSamOnlineFailure.modelsUnavailable,
          _providerErrorMessage(response.body),
        );
      }
      if (providerCode == 'provider_unavailable') {
        throw SamSamOnlineException(
          SamSamOnlineFailure.providerUnavailable,
          _providerErrorMessage(response.body),
        );
      }
      if (response.statusCode == 503) {
        throw const SamSamOnlineException(SamSamOnlineFailure.unconfigured);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const SamSamOnlineException(
          SamSamOnlineFailure.invalidConfiguration,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SamSamOnlineException(
          SamSamOnlineFailure.server,
          'HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const SamSamOnlineException(
          SamSamOnlineFailure.server,
          'Invalid response format',
        );
      }
      final answer = data['answer'];
      if (answer is! String || answer.trim().isEmpty) {
        throw const SamSamOnlineException(
          SamSamOnlineFailure.server,
          'Empty response',
        );
      }
      return _removeAsteriskFormatting(answer.trim());
    } on TimeoutException {
      throw const SamSamOnlineException(SamSamOnlineFailure.timeout);
    } on SamSamOnlineException {
      rethrow;
    } on http.ClientException {
      throw const SamSamOnlineException(SamSamOnlineFailure.unavailable);
    } on FormatException {
      throw const SamSamOnlineException(
        SamSamOnlineFailure.server,
        'Invalid JSON response',
      );
    }
  }

  String? _providerErrorCode(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map<String, dynamic> && data['code'] is String
          ? data['code'] as String
          : null;
    } on FormatException {
      return null;
    }
  }

  String _providerErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      return data is Map<String, dynamic> && data['error'] is String
          ? data['error'] as String
          : '';
    } on FormatException {
      return '';
    }
  }

  String _removeAsteriskFormatting(String text) => text
      .replaceAllMapped(
        RegExp(r'(^|\n)[ \t]*\*[ \t]+', multiLine: true),
        (match) => '${match[1]}• ',
      )
      .replaceAll('*', '');

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
