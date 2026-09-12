import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

enum DavidOnlineFailure { offline, unavailable, timeout, rateLimited, server }

class DavidOnlineException implements Exception {
  const DavidOnlineException(this.kind, [this.message = '']);
  final DavidOnlineFailure kind;
  final String message;
}

class OnlineDavidService {
  OnlineDavidService({http.Client? client, Connectivity? connectivity})
    : _client = client ?? http.Client(),
      _connectivity = connectivity ?? Connectivity();

  static const endpoint = String.fromEnvironment('DAVID_FUNCTION_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final http.Client _client;
  final Connectivity _connectivity;

  bool get configured => endpoint.isNotEmpty;

  Future<bool> canUseOnline() async {
    if (!configured) return false;
    final connections = await _connectivity.checkConnectivity();
    return !connections.contains(ConnectivityResult.none);
  }

  Future<String> ask({
    required String question,
    required String language,
  }) async {
    if (!await canUseOnline()) {
      throw const DavidOnlineException(DavidOnlineFailure.offline);
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .post(
              Uri.parse(endpoint),
              headers: {
                'content-type': 'application/json',
                if (anonKey.isNotEmpty) 'authorization': 'Bearer $anonKey',
                if (anonKey.isNotEmpty) 'apikey': anonKey,
              },
              body: jsonEncode({'question': question, 'language': language}),
            )
            .timeout(const Duration(seconds: 18));
        if (response.statusCode == 429) {
          throw const DavidOnlineException(DavidOnlineFailure.rateLimited);
        }
        if (response.statusCode >= 500 && attempt == 0) continue;
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw DavidOnlineException(
            DavidOnlineFailure.server,
            'HTTP ${response.statusCode}',
          );
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answer = data['answer']?.toString().trim();
        if (answer == null || answer.isEmpty) {
          throw const DavidOnlineException(
            DavidOnlineFailure.server,
            'Empty response',
          );
        }
        return answer;
      } on TimeoutException {
        if (attempt == 0) continue;
        throw const DavidOnlineException(DavidOnlineFailure.timeout);
      } on DavidOnlineException {
        rethrow;
      } on http.ClientException {
        throw const DavidOnlineException(DavidOnlineFailure.unavailable);
      }
    }
    throw const DavidOnlineException(DavidOnlineFailure.unavailable);
  }
}
