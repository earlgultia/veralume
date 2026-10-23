import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veralume/data/services/online_sam_sam_service.dart';

void main() {
  const supabaseUrl = 'https://sample-project.supabase.co/';
  const publishableKey = 'sb_publishable_test-key';

  test(
    'calls the Supabase function with history and parses its answer',
    () async {
      late http.Request capturedRequest;
      final service = OnlineSamSamService(
        supabaseUrl: supabaseUrl,
        supabasePublishableKey: publishableKey,
        connectivity: _FakeConnectivity(),
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({'answer': 'Hello! Let’s explore that together.'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final answer = await service.ask(
        question: 'Can you explain this?',
        language: 'English',
        conversation: [
          {'role': 'user', 'content': 'Tell me about Psalm 23'},
          {'role': 'assistant', 'content': 'It describes God as our shepherd.'},
        ],
      );

      expect(answer, 'Hello! Let’s explore that together.');
      expect(
        capturedRequest.url.toString(),
        'https://sample-project.supabase.co/functions/v1/david',
      );
      expect(capturedRequest.headers['authorization'], isNull);
      expect(capturedRequest.headers['apikey'], publishableKey);
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['question'], 'Can you explain this?');
      expect(body['language'], 'English');
      expect(body['conversation'], [
        {'role': 'user', 'content': 'Tell me about Psalm 23'},
        {'role': 'assistant', 'content': 'It describes God as our shepherd.'},
      ]);
      service.dispose();
    },
  );

  test('does not send requests without Supabase configuration', () async {
    var requestCount = 0;
    final service = OnlineSamSamService(
      supabaseUrl: '',
      supabasePublishableKey: '',
      connectivity: _FakeConnectivity(),
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    expect(service.configured, isFalse);
    expect(await service.canUseOnline(), isFalse);
    await expectLater(
      service.ask(question: 'Hello', language: 'English'),
      throwsA(
        isA<SamSamOnlineException>().having(
          (error) => error.kind,
          'kind',
          SamSamOnlineFailure.unconfigured,
        ),
      ),
    );
    expect(requestCount, 0);
    service.dispose();
  });

  test('reports Supabase rate limits explicitly', () async {
    final service = OnlineSamSamService(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
      connectivity: _FakeConnectivity(),
      client: MockClient((_) async => http.Response('{}', 429)),
    );

    await expectLater(
      service.ask(question: 'Hello', language: 'English'),
      throwsA(
        isA<SamSamOnlineException>().having(
          (error) => error.kind,
          'kind',
          SamSamOnlineFailure.rateLimited,
        ),
      ),
    );
    service.dispose();
  });

  test(
    'attempts the function even if connectivity reports no network',
    () async {
      var requestCount = 0;
      final service = OnlineSamSamService(
        supabaseUrl: supabaseUrl,
        supabasePublishableKey: publishableKey,
        connectivity: _FakeConnectivity(result: ConnectivityResult.none),
        client: MockClient((_) async {
          requestCount++;
          return http.Response.bytes(
            utf8.encode(jsonEncode({'answer': 'I’m here to help.'})),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      expect(await service.canUseOnline(), isFalse);
      expect(
        await service.ask(question: 'Can you help?', language: 'English'),
        'I’m here to help.',
      );
      expect(requestCount, 1);
      service.dispose();
    },
  );

  test('reports invalid Supabase authorization clearly', () async {
    final service = OnlineSamSamService(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
      connectivity: _FakeConnectivity(),
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    await expectLater(
      service.ask(question: 'Hello', language: 'English'),
      throwsA(
        isA<SamSamOnlineException>().having(
          (error) => error.kind,
          'kind',
          SamSamOnlineFailure.invalidConfiguration,
        ),
      ),
    );
    service.dispose();
  });

  test('explains provider failures returned by the Edge Function', () async {
    final service = OnlineSamSamService(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
      connectivity: _FakeConnectivity(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'The server OpenRouter key was rejected.',
            'code': 'provider_key_invalid',
          }),
          502,
        ),
      ),
    );

    await expectLater(
      service.ask(question: 'Hello', language: 'English'),
      throwsA(
        isA<SamSamOnlineException>()
            .having(
              (error) => error.kind,
              'kind',
              SamSamOnlineFailure.providerKeyInvalid,
            )
            .having(
              (error) => error.message,
              'message',
              'The server OpenRouter key was rejected.',
            ),
      ),
    );
    service.dispose();
  });

  test('reports when all free provider models are unavailable', () async {
    final service = OnlineSamSamService(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
      connectivity: _FakeConnectivity(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': 'All configured free OpenRouter models failed.',
            'code': 'free_models_unavailable',
          }),
          502,
        ),
      ),
    );

    await expectLater(
      service.ask(question: 'Hello', language: 'English'),
      throwsA(
        isA<SamSamOnlineException>().having(
          (error) => error.kind,
          'kind',
          SamSamOnlineFailure.modelsUnavailable,
        ),
      ),
    );
    service.dispose();
  });

  test('removes markdown asterisks and converts asterisk bullets', () async {
    final service = OnlineSamSamService(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
      connectivity: _FakeConnectivity(),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'answer': '**A clear answer**\n\n* First step\n* Second step',
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    expect(
      await service.ask(question: 'What should I do?', language: 'English'),
      'A clear answer\n\n• First step\n• Second step',
    );
    service.dispose();
  });
}

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity({this.result = ConnectivityResult.wifi});
  final ConnectivityResult result;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [result];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
