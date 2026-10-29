import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dev_marketplace/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockUserCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockUserDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockUserSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockAuthUser extends Mock implements User {}

void main() {
  late MockFirestore firestore;
  late MockUserCollection users;
  late MockUserDocument user;
  late MockUserSnapshot snapshot;
  late UserRepository repository;

  setUp(() {
    firestore = MockFirestore();
    users = MockUserCollection();
    user = MockUserDocument();
    snapshot = MockUserSnapshot();
    repository = UserRepository(firestore: firestore);

    when(() => firestore.collection('users')).thenReturn(users);
    when(() => users.doc('user-1')).thenReturn(user);
  });

  test(
    'loads the profile using server-and-cache and returns its data',
    () async {
      when(
        () => user.get(const GetOptions(source: Source.serverAndCache)),
      ).thenAnswer((_) async => snapshot);
      when(
        () => snapshot.data(),
      ).thenReturn({'name': 'Ada', 'role': 'developer'});

      final profile = await repository.getUserProfile('user-1');

      expect(profile, {'name': 'Ada', 'role': 'developer'});
      verify(
        () => user.get(const GetOptions(source: Source.serverAndCache)),
      ).called(1);
    },
  );

  test('returns null when the user profile document is empty', () async {
    when(
      () => user.get(const GetOptions(source: Source.serverAndCache)),
    ).thenAnswer((_) async => snapshot);
    when(() => snapshot.data()).thenReturn(null);

    expect(await repository.getUserProfile('user-1'), isNull);
  });

  test('propagates Firestore errors instead of hiding them', () async {
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    when(
      () => user.get(const GetOptions(source: Source.serverAndCache)),
    ).thenThrow(error);

    await expectLater(
      repository.getUserProfile('user-1'),
      throwsA(same(error)),
    );
  });

  test(
    'creates a missing account document with safe client defaults',
    () async {
      final authUser = MockAuthUser();
      when(() => authUser.uid).thenReturn('user-1');
      when(() => authUser.email).thenReturn('client@example.com');
      when(() => authUser.displayName).thenReturn('New Client');
      when(
        () => user.get(const GetOptions(source: Source.serverAndCache)),
      ).thenAnswer((_) async => snapshot);
      when(() => snapshot.exists).thenReturn(false);
      when(() => user.set(any())).thenAnswer((_) async {});

      await repository.ensureUserProfile(authUser);

      final captured = verify(() => user.set(captureAny())).captured.single;
      expect(captured, containsPair('uid', 'user-1'));
      expect(captured, containsPair('email', 'client@example.com'));
      expect(captured, containsPair('userType', 'client'));
      expect(captured, containsPair('role', 'client'));
      expect(captured, containsPair('name', 'New Client'));
      expect(captured, contains('createdAt'));
    },
  );

  test('does not replace an existing account document', () async {
    final authUser = MockAuthUser();
    when(() => authUser.uid).thenReturn('user-1');
    when(() => authUser.email).thenReturn('client@example.com');
    when(
      () => user.get(const GetOptions(source: Source.serverAndCache)),
    ).thenAnswer((_) async => snapshot);
    when(() => snapshot.exists).thenReturn(true);

    await repository.ensureUserProfile(authUser);

    verifyNever(() => user.set(any()));
  });
}
