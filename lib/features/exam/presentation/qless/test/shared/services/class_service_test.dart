import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qless/shared/services/class_service.dart';

// A simple fake http.Client that returns pre-configured responses.
class FakeHttpClient extends http.BaseClient {
  FakeHttpClient({required this.response});

  final http.Response response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

void main() {
  const baseUrl = 'https://api.qles.app';

  group('HttpClassService.fetchStudentClasses', () {
    test('returns a list of ClassModel on 200 response', () async {
      final body = jsonEncode([
        {
          'id': 'c1',
          'name': 'Math 101',
          'subject': 'Mathematics',
          'teacher_name': 'Mr. Smith',
          'completed_assignments': 3,
          'total_assignments': 10,
        },
        {
          'id': 'c2',
          'name': 'Physics 101',
          'subject': 'Physics',
          'teacher_name': 'Ms. Jones',
          'completed_assignments': 5,
          'total_assignments': 8,
        },
      ]);

      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response(body, 200),
        ),
      );

      final classes = await service.fetchStudentClasses('student-1');

      expect(classes.length, 2);
      expect(classes[0].id, 'c1');
      expect(classes[0].name, 'Math 101');
      expect(classes[0].subject, 'Mathematics');
      expect(classes[0].teacherName, 'Mr. Smith');
      expect(classes[0].completedAssignments, 3);
      expect(classes[0].totalAssignments, 10);
      expect(classes[1].id, 'c2');
    });

    test('throws ClassServiceException on non-2xx response', () async {
      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response(
            jsonEncode({'message': 'Unauthorized'}),
            401,
            reasonPhrase: 'Unauthorized',
          ),
        ),
      );

      expect(
        () => service.fetchStudentClasses('student-1'),
        throwsA(
          isA<ClassServiceException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('401')),
        ),
      );
    });
  });

  group('HttpClassService.fetchClassRoster', () {
    test('returns a list of StudentModel on 200 response', () async {
      final body = jsonEncode([
        {
          'id': 's1',
          'name': 'Alice',
          'email': 'alice@example.com',
          'is_verified': true,
        },
        {
          'id': 's2',
          'name': 'Bob',
          'email': 'bob@example.com',
          'is_verified': false,
        },
      ]);

      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response(body, 200),
        ),
      );

      final students = await service.fetchClassRoster('class-1');

      expect(students.length, 2);
      expect(students[0].id, 's1');
      expect(students[0].name, 'Alice');
      expect(students[0].email, 'alice@example.com');
      expect(students[0].isVerified, true);
      expect(students[1].id, 's2');
      expect(students[1].isVerified, false);
    });

    test('throws ClassServiceException on non-2xx response', () async {
      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response(
            jsonEncode({'message': 'Not Found'}),
            404,
            reasonPhrase: 'Not Found',
          ),
        ),
      );

      expect(
        () => service.fetchClassRoster('class-1'),
        throwsA(
          isA<ClassServiceException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('404')),
        ),
      );
    });
  });

  group('HttpClassService.verifyStudent', () {
    test('completes without error on 200 response', () async {
      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response('{}', 200),
        ),
      );

      await expectLater(service.verifyStudent('student-1'), completes);
    });

    test('throws ClassServiceException on non-2xx response', () async {
      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response(
            jsonEncode({'message': 'Internal Server Error'}),
            500,
            reasonPhrase: 'Internal Server Error',
          ),
        ),
      );

      expect(
        () => service.verifyStudent('student-1'),
        throwsA(
          isA<ClassServiceException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('500')),
        ),
      );
    });
  });

  group('HttpClassService.removeStudent', () {
    test('completes without error on 200 response', () async {
      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response('{}', 200),
        ),
      );

      await expectLater(
        service.removeStudent('class-1', 'student-1'),
        completes,
      );
    });

    test('throws ClassServiceException on non-2xx response', () async {
      final service = HttpClassService(
        baseUrl: baseUrl,
        client: FakeHttpClient(
          response: http.Response(
            jsonEncode({'message': 'Forbidden'}),
            403,
            reasonPhrase: 'Forbidden',
          ),
        ),
      );

      expect(
        () => service.removeStudent('class-1', 'student-1'),
        throwsA(
          isA<ClassServiceException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('403')),
        ),
      );
    });
  });
}
