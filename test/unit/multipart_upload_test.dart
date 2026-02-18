import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:arrow/src/request.dart';
import 'package:arrow/src/uploaded_file.dart';
import 'package:arrow/src/multipart_form_data.dart';
import 'package:arrow/src/middlewares/read_multipart_content.dart';

import '../test_helpers.dart';

void main() {
  tearDownAll(() async {
    await cleanupAllMockRequests();
  });

  group('UploadedFile', () {
    test('stores fields correctly', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final file = UploadedFile(
        fieldName: 'avatar',
        filename: 'photo.jpg',
        contentType: 'image/jpeg',
        bytes: bytes,
      );
      expect(file.fieldName, equals('avatar'));
      expect(file.filename, equals('photo.jpg'));
      expect(file.contentType, equals('image/jpeg'));
      expect(file.bytes, equals([1, 2, 3, 4, 5]));
    });

    test('size getter returns bytes.length', () {
      final file = UploadedFile(
        fieldName: 'f',
        filename: 'f.txt',
        contentType: 'text/plain',
        bytes: Uint8List.fromList([10, 20, 30]),
      );
      expect(file.size, equals(3));
    });

    test('toString returns useful description', () {
      final file = UploadedFile(
        fieldName: 'doc',
        filename: 'readme.md',
        contentType: 'text/markdown',
        bytes: Uint8List.fromList([1, 2]),
      );
      expect(file.toString(), contains('doc'));
      expect(file.toString(), contains('readme.md'));
      expect(file.toString(), contains('2 bytes'));
    });
  });

  group('MultipartFormData', () {
    test('field() returns text field value', () {
      final form = MultipartFormData(
          fields: {'name': 'Alice', 'age': '30'}, files: []);
      expect(form.field('name'), equals('Alice'));
      expect(form.field('age'), equals('30'));
    });

    test('field() returns null for missing field', () {
      final form = MultipartFormData(fields: {}, files: []);
      expect(form.field('missing'), isNull);
    });

    test('file() returns first file matching field name', () {
      final f1 = UploadedFile(
          fieldName: 'avatar',
          filename: 'a.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List(0));
      final f2 = UploadedFile(
          fieldName: 'avatar',
          filename: 'b.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List(0));
      final form = MultipartFormData(fields: {}, files: [f1, f2]);
      expect(form.file('avatar')?.filename, equals('a.jpg'));
    });

    test('file() returns null for missing field name', () {
      final form = MultipartFormData(fields: {}, files: []);
      expect(form.file('avatar'), isNull);
    });

    test('filesFor() returns all files for a field name', () {
      final f1 = UploadedFile(
          fieldName: 'photos',
          filename: 'a.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List(0));
      final f2 = UploadedFile(
          fieldName: 'photos',
          filename: 'b.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List(0));
      final f3 = UploadedFile(
          fieldName: 'other',
          filename: 'c.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List(0));
      final form = MultipartFormData(fields: {}, files: [f1, f2, f3]);
      expect(form.filesFor('photos'), hasLength(2));
      expect(form.filesFor('other'), hasLength(1));
    });

    test('filesFor() returns empty list for missing field name', () {
      final form = MultipartFormData(fields: {}, files: []);
      expect(form.filesFor('photos'), isEmpty);
    });

    test('of(req) returns null when middleware not run', () async {
      final httpReq = await createMockHttpRequest();
      final req = Request(httpReq);
      expect(MultipartFormData.of(req), isNull);
      await cleanupMockRequest(httpReq);
    });
  });

  group('readMultipartContent() middleware', () {
    group('content type handling', () {
      test('passes through non-multipart requests unchanged', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockHttpRequest(
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: '{"key":"value"}',
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        expect(result.isAlive, isTrue);
        expect(MultipartFormData.of(result), isNull);
        await cleanupMockRequest(httpReq);
      });

      test('passes through GET requests unchanged', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockHttpRequest(method: 'GET');
        final req = Request(httpReq);
        final result = await middleware(req);
        expect(result.isAlive, isTrue);
        expect(MultipartFormData.of(result), isNull);
        await cleanupMockRequest(httpReq);
      });
    });

    group('text fields', () {
      test('parses single text field', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockMultipartRequest(
          fields: {'name': 'Alice'},
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result);
        expect(form, isNotNull);
        expect(form!.field('name'), equals('Alice'));
        expect(form.files, isEmpty);
        await cleanupMockRequest(httpReq);
      });

      test('parses multiple text fields', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockMultipartRequest(
          fields: {'name': 'Alice', 'email': 'alice@example.com', 'age': '30'},
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result)!;
        expect(form.field('name'), equals('Alice'));
        expect(form.field('email'), equals('alice@example.com'));
        expect(form.field('age'), equals('30'));
        await cleanupMockRequest(httpReq);
      });

      test('handles empty field value', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockMultipartRequest(
          fields: {'empty': ''},
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result)!;
        expect(form.field('empty'), equals(''));
        await cleanupMockRequest(httpReq);
      });
    });

    group('file uploads', () {
      test('parses single file upload', () async {
        final middleware = readMultipartContent();
        final fileBytes = [72, 101, 108, 108, 111]; // "Hello"
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile('doc', 'hello.txt', 'text/plain', fileBytes)
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result)!;
        expect(form.files, hasLength(1));
        expect(form.file('doc')!.filename, equals('hello.txt'));
        expect(form.file('doc')!.contentType, equals('text/plain'));
        expect(form.file('doc')!.bytes, equals(fileBytes));
        expect(form.file('doc')!.size, equals(5));
        await cleanupMockRequest(httpReq);
      });

      test('parses multiple file uploads', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile('file1', 'a.txt', 'text/plain', [65]),
            MockMultipartFile('file2', 'b.txt', 'text/plain', [66]),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result)!;
        expect(form.files, hasLength(2));
        expect(form.file('file1')!.filename, equals('a.txt'));
        expect(form.file('file2')!.filename, equals('b.txt'));
        await cleanupMockRequest(httpReq);
      });
    });

    group('mixed fields and files', () {
      test('parses text fields and files together', () async {
        final middleware = readMultipartContent();
        final httpReq = await createMockMultipartRequest(
          fields: {'description': 'My photo', 'tags': 'nature'},
          files: [
            MockMultipartFile(
                'photo', 'sunset.jpg', 'image/jpeg', [0xFF, 0xD8, 0xFF])
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result)!;
        expect(form.field('description'), equals('My photo'));
        expect(form.field('tags'), equals('nature'));
        expect(form.files, hasLength(1));
        expect(form.file('photo')!.filename, equals('sunset.jpg'));
        expect(form.file('photo')!.bytes, equals([0xFF, 0xD8, 0xFF]));
        await cleanupMockRequest(httpReq);
      });
    });

    group('validation - file size', () {
      test('rejects file exceeding maxFileSize', () async {
        final middleware = readMultipartContent(MultipartConfig(
          maxFileSize: 5, // 5 bytes max
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile(
                'big', 'big.bin', 'application/octet-stream',
                List.filled(10, 0x41)), // 10 bytes > 5
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        expect(result.isAlive, isFalse); // badRequest was called
        expect(MultipartFormData.of(result), isNull);
        await cleanupMockRequest(httpReq);
      });

      test('allows file at maxFileSize limit', () async {
        final middleware = readMultipartContent(MultipartConfig(
          maxFileSize: 5,
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile(
                'ok', 'ok.bin', 'application/octet-stream',
                List.filled(5, 0x41)), // exactly 5 bytes
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result);
        expect(form, isNotNull);
        expect(form!.file('ok')!.size, equals(5));
        await cleanupMockRequest(httpReq);
      });

      test('rejects when total size exceeds maxTotalSize', () async {
        final middleware = readMultipartContent(MultipartConfig(
          maxFileSize: 10,
          maxTotalSize: 8,
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile(
                'a', 'a.bin', 'application/octet-stream', List.filled(5, 0x41)),
            MockMultipartFile(
                'b', 'b.bin', 'application/octet-stream', List.filled(5, 0x42)),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        expect(result.isAlive, isFalse);
        await cleanupMockRequest(httpReq);
      });
    });

    group('validation - file count', () {
      test('rejects when file count exceeds maxFiles', () async {
        final middleware = readMultipartContent(MultipartConfig(
          maxFiles: 1,
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile('a', 'a.txt', 'text/plain', [65]),
            MockMultipartFile('b', 'b.txt', 'text/plain', [66]),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        expect(result.isAlive, isFalse);
        await cleanupMockRequest(httpReq);
      });

      test('allows exactly maxFiles files', () async {
        final middleware = readMultipartContent(MultipartConfig(
          maxFiles: 2,
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile('a', 'a.txt', 'text/plain', [65]),
            MockMultipartFile('b', 'b.txt', 'text/plain', [66]),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result);
        expect(form, isNotNull);
        expect(form!.files, hasLength(2));
        await cleanupMockRequest(httpReq);
      });
    });

    group('validation - MIME types', () {
      test('rejects file with disallowed MIME type', () async {
        final middleware = readMultipartContent(MultipartConfig(
          allowedMimeTypes: ['image/jpeg', 'image/png'],
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile('doc', 'evil.exe',
                'application/x-msdownload', [0x4D, 0x5A]),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        expect(result.isAlive, isFalse);
        await cleanupMockRequest(httpReq);
      });

      test('allows file with allowed MIME type', () async {
        final middleware = readMultipartContent(MultipartConfig(
          allowedMimeTypes: ['image/jpeg', 'image/png'],
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile(
                'photo', 'pic.jpg', 'image/jpeg', [0xFF, 0xD8]),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result);
        expect(form, isNotNull);
        expect(form!.files, hasLength(1));
        await cleanupMockRequest(httpReq);
      });

      test('allows any type when allowedMimeTypes is empty', () async {
        final middleware = readMultipartContent(MultipartConfig(
          allowedMimeTypes: [],
        ));
        final httpReq = await createMockMultipartRequest(
          files: [
            MockMultipartFile('doc', 'data.xyz',
                'application/x-custom', [1, 2, 3]),
          ],
        );
        final req = Request(httpReq);
        final result = await middleware(req);
        final form = MultipartFormData.of(result);
        expect(form, isNotNull);
        expect(form!.files, hasLength(1));
        await cleanupMockRequest(httpReq);
      });
    });

    group('MultipartConfig', () {
      test('has sensible defaults', () {
        final config = MultipartConfig();
        expect(config.maxFileSize, equals(10 * 1024 * 1024));
        expect(config.maxTotalSize, equals(50 * 1024 * 1024));
        expect(config.maxFiles, equals(10));
        expect(config.allowedMimeTypes, isEmpty);
      });

      test('accepts custom values', () {
        final config = MultipartConfig(
          maxFileSize: 1024,
          maxTotalSize: 4096,
          maxFiles: 3,
          allowedMimeTypes: ['image/png'],
        );
        expect(config.maxFileSize, equals(1024));
        expect(config.maxTotalSize, equals(4096));
        expect(config.maxFiles, equals(3));
        expect(config.allowedMimeTypes, equals(['image/png']));
      });
    });
  });
}
