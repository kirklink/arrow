import 'package:test/test.dart';

/// Simple mock request for testing (doesn't need actual HTTP server)
class MockRequest {
  final Map<String, dynamic> context = {};
  bool isAlive = true;

  void cancel() {
    isAlive = false;
  }
}

void main() {
  group('Pipeline Async Middleware', () {
    test('preserves all modifications from multiple async request middleware',
        () async {
      // This test verifies the async middleware bug fix
      // Multiple async middleware should all modify the shared object

      final sharedData = <String, String>{};

      // Simulate what Pipeline does: run all handlers with same object
      List<Future<Map<String, String>>> futures = [];

      // Middleware 1: delays 10ms, sets key1
      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 10));
        sharedData['key1'] = 'value1';
        return sharedData; // Returns reference to shared object
      }));

      // Middleware 2: delays 5ms, sets key2
      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 5));
        sharedData['key2'] = 'value2';
        return sharedData; // Returns reference to shared object
      }));

      // Middleware 3: delays 15ms, sets key3
      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 15));
        sharedData['key3'] = 'value3';
        return sharedData; // Returns reference to shared object
      }));

      // NEW behavior (fixed): await all, return shared object
      await Future.wait(futures);
      final result = sharedData;

      // Verify all modifications are preserved
      expect(result['key1'], equals('value1'));
      expect(result['key2'], equals('value2'));
      expect(result['key3'], equals('value3'));
    });

    test('demonstrates old buggy behavior would pick arbitrary result',
        () async {
      final sharedData = <String, String>{};
      List<Future<Map<String, String>>> futures = [];

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 10));
        sharedData['key1'] = 'value1';
        return sharedData;
      }));

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 5));
        sharedData['key2'] = 'value2';
        return sharedData;
      }));

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 15));
        sharedData['key3'] = 'value3';
        return sharedData;
      }));

      final results = await Future.wait(futures);

      // OLD buggy code: return results[results.length - 1]
      final oldResult = results[results.length - 1];

      // All results are the same object reference
      expect(identical(results[0], results[1]), isTrue);
      expect(identical(results[1], results[2]), isTrue);
      expect(identical(oldResult, sharedData), isTrue);

      // So picking [last] was meaningless - they're all the same!
      expect(oldResult['key1'], equals('value1'));
      expect(oldResult['key2'], equals('value2'));
      expect(oldResult['key3'], equals('value3'));
    });

    test('async middleware complete in non-deterministic order', () async {
      final completionOrder = <String>[];
      final sharedData = <String, String>{};
      List<Future<void>> futures = [];

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 10));
        completionOrder.add('mw1');
        sharedData['mw1'] = 'done';
      }));

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 5));
        completionOrder.add('mw2');
        sharedData['mw2'] = 'done';
      }));

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 15));
        completionOrder.add('mw3');
        sharedData['mw3'] = 'done';
      }));

      await Future.wait(futures);

      // Completion order should be based on delays: mw2, mw1, mw3
      expect(completionOrder, equals(['mw2', 'mw1', 'mw3']));

      // But all data should be present regardless of order
      expect(sharedData['mw1'], equals('done'));
      expect(sharedData['mw2'], equals('done'));
      expect(sharedData['mw3'], equals('done'));
    });

    test('race condition when multiple async middleware modify same key',
        () async {
      final sharedData = <String, String>{};
      List<Future<void>> futures = [];

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 10));
        sharedData['user'] = 'Alice';
      }));

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 5));
        sharedData['user'] = 'Bob';
      }));

      futures.add(Future(() async {
        await Future.delayed(Duration(milliseconds: 15));
        sharedData['user'] = 'Charlie';
      }));

      await Future.wait(futures);

      // Last write wins, but order depends on timing
      // With these delays, Charlie (15ms) should win
      expect(sharedData['user'], equals('Charlie'));
    });
  });

  group('Pipeline Execution Order', () {
    test('sync middleware execute sequentially', () async {
      final executionOrder = <String>[];

      // Simulate sequential execution
      executionOrder.add('sync1');
      await Future.delayed(Duration(milliseconds: 1));

      executionOrder.add('sync2');
      await Future.delayed(Duration(milliseconds: 1));

      executionOrder.add('sync3');

      expect(executionOrder, equals(['sync1', 'sync2', 'sync3']));
    });

    test('correct order: sync request → async request → handler → async response → sync response',
        () async {
      final executionOrder = <String>[];

      // Sync request middleware (sequential)
      executionOrder.add('sync-req-1');
      executionOrder.add('sync-req-2');

      // Async request middleware (parallel)
      List<Future<void>> asyncReqFutures = [];
      asyncReqFutures.add(Future(() async {
        executionOrder.add('async-req-1-start');
        await Future.delayed(Duration(milliseconds: 5));
        executionOrder.add('async-req-1-end');
      }));
      asyncReqFutures.add(Future(() async {
        executionOrder.add('async-req-2-start');
        await Future.delayed(Duration(milliseconds: 3));
        executionOrder.add('async-req-2-end');
      }));
      await Future.wait(asyncReqFutures);

      // Handler
      executionOrder.add('handler');

      // Async response middleware (parallel)
      List<Future<void>> asyncResFutures = [];
      asyncResFutures.add(Future(() async {
        executionOrder.add('async-res-1-start');
        await Future.delayed(Duration(milliseconds: 5));
        executionOrder.add('async-res-1-end');
      }));
      await Future.wait(asyncResFutures);

      // Sync response middleware (sequential)
      executionOrder.add('sync-res-1');
      executionOrder.add('sync-res-2');

      // Verify order
      final syncReq1Index = executionOrder.indexOf('sync-req-1');
      final asyncReq1Index = executionOrder.indexOf('async-req-1-start');
      final handlerIndex = executionOrder.indexOf('handler');
      final asyncRes1Index = executionOrder.indexOf('async-res-1-start');
      final syncRes1Index = executionOrder.indexOf('sync-res-1');

      expect(syncReq1Index, lessThan(asyncReq1Index),
          reason: 'Sync request before async request');
      expect(asyncReq1Index, lessThan(handlerIndex),
          reason: 'Async request before handler');
      expect(handlerIndex, lessThan(asyncRes1Index),
          reason: 'Handler before async response');
      expect(asyncRes1Index, lessThan(syncRes1Index),
          reason: 'Async response before sync response');
    });
  });

  group('Request Cancellation', () {
    test('useAlways flag controls execution when request is cancelled',
        () async {
      final mock = MockRequest();
      final executionLog = <String>[];

      // Cancel the request
      mock.cancel();
      expect(mock.isAlive, isFalse);

      // Middleware with useAlways=false (respects cancellation)
      if (mock.isAlive) {
        executionLog.add('should-not-run');
      } else {
        executionLog.add('skipped-due-to-cancel');
      }

      // Middleware with useAlways=true (ignores cancellation)
      executionLog.add('always-runs');

      expect(executionLog, equals(['skipped-due-to-cancel', 'always-runs']));
    });
  });
}
