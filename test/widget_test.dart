import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dev_marketplace/models/favorite_project.dart';
import 'package:dev_marketplace/providers/auth_provider.dart';
import 'package:dev_marketplace/providers/favorites_provider.dart';
import 'package:dev_marketplace/repositories/auth_repository.dart';
import 'package:dev_marketplace/repositories/favorite_repository.dart';
import 'package:dev_marketplace/repositories/user_repository.dart';
import 'package:dev_marketplace/screens/auth_screen.dart';
import 'package:dev_marketplace/screens/profile_screen.dart';
import 'package:dev_marketplace/widgets/EmptyStateWidget.dart';
import 'package:dev_marketplace/widgets/project_card.dart';
import 'package:dev_marketplace/widgets/shimmer_card.dart';
import 'package:dev_marketplace/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockUser extends Mock implements User {}

class FakeFavoriteProject extends Fake implements FavoriteProject {}

class MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpRequest();
}

class MockHttpRequest extends Mock implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => MockHttpResponse();
}

class MockHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  static final _pixel = Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    8,
    215,
    99,
    248,
    207,
    192,
    240,
    31,
    0,
    5,
    0,
    1,
    255,
    137,
    153,
    61,
    29,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]);

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _pixel.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_pixel).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerFallbackValue(FakeFavoriteProject());

  testWidgets(
    'Auth screen disables submit until email and password are valid',
    (tester) async {
      final repository = MockAuthRepository();
      when(
        () => repository.authStateChanges,
      ).thenAnswer((_) => const Stream.empty());
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AuthProvider(repository: repository),
            child: const MaterialApp(home: AuthScreen()),
          ),
        );

        final signIn = find.widgetWithText(ElevatedButton, 'دخول').first;
        expect(tester.widget<ElevatedButton>(signIn).onPressed, isNull);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'not-an-email',
        );
        await tester.enterText(find.byType(TextFormField).at(1), '123456');
        await tester.pump();
        expect(tester.widget<ElevatedButton>(signIn).onPressed, isNull);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'user@example.com',
        );
        await tester.pump();
        expect(tester.widget<ElevatedButton>(signIn).onPressed, isNotNull);
      }, createHttpClient: (_) => MockHttpClient());
    },
  );

  testWidgets('ShimmerCard renders its skeleton while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ShimmerCard())),
    );

    expect(find.byType(ShimmerCard), findsOneWidget);
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('ShimmerCard fits in a narrow mobile grid cell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 140, child: ShimmerCard()),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('EmptyStateWidget renders text and invokes its action', (
    tester,
  ) async {
    var actionCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            lottiePath: 'missing-animation.json',
            title: 'No projects',
            subtitle: 'Try again later',
            actionLabel: 'Browse',
            onActionPressed: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('No projects'), findsOneWidget);
    expect(find.text('Try again later'), findsOneWidget);
    await tester.tap(find.text('Browse'));
    expect(actionCalled, isTrue);
  });

  testWidgets(
    'favorite icon updates after favorite stream emits the saved item',
    (tester) async {
      final authRepository = MockAuthRepository();
      final authEvents = StreamController<User?>.broadcast();
      when(
        () => authRepository.authStateChanges,
      ).thenAnswer((_) => authEvents.stream);
      final authProvider = AuthProvider(repository: authRepository);

      final user = MockUser();
      when(() => user.uid).thenReturn('buyer-1');
      final favoriteRepository = MockFavoriteRepository();
      final favoriteEvents =
          StreamController<List<FavoriteProject>>.broadcast();
      when(
        () => favoriteRepository.watchFavorites('buyer-1'),
      ).thenAnswer((_) => favoriteEvents.stream);

      final favorite = FavoriteProject(
        projectId: 'project-1',
        title: 'Starter project',
        developerUid: 'developer-1',
        developerName: 'Developer',
        price: 25,
        imageUrl: '',
        projectType: 'app',
        techStack: const ['Flutter'],
        averageRating: 0,
        ratingCount: 0,
        description: 'Project description',
        demoLink: '',
        isEscrow: false,
        views: 0,
      );
      when(
        () =>
            favoriteRepository.setFavorite('buyer-1', any(), isFavorite: true),
      ).thenAnswer((_) async => favoriteEvents.add([favorite]));

      final favoritesProvider = FavoritesProvider(
        repository: favoriteRepository,
        authProvider: authProvider,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(
              value: favoritesProvider,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProjectCard(
                title: 'Starter project',
                developerName: 'Developer',
                developerUid: 'developer-1',
                projectId: 'project-1',
                projectType: 'app',
                price: 25,
                techStack: ['Flutter'],
                rating: 0,
                imageUrl: '',
                description: 'Project description',
              ),
            ),
          ),
        ),
      );
      authEvents.add(user);
      await tester.pump();
      favoriteEvents.add(const []);
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('أضف إلى المفضلة'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      favoritesProvider.dispose();
      authProvider.dispose();
      await authEvents.close();
      await favoriteEvents.close();
    },
  );

  testWidgets('profile keeps logout available when account loading fails', (
    tester,
  ) async {
    final authRepository = MockAuthRepository();
    final authEvents = StreamController<User?>.broadcast();
    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => authEvents.stream);
    when(() => authRepository.signOut()).thenAnswer((_) async {});
    final authProvider = AuthProvider(repository: authRepository);

    final user = MockUser();
    when(() => user.uid).thenReturn('buyer-1');
    final userRepository = MockUserRepository();
    when(
      () => userRepository.ensureUserProfile(user),
    ).thenThrow(StateError('Firestore unavailable'));
    final userProvider = UserProvider(
      repository: userRepository,
      authProvider: authProvider,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    authEvents.add(user);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('تعذر تحميل بيانات الحساب'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);

    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pump();
    verify(() => authRepository.signOut()).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    userProvider.dispose();
    authProvider.dispose();
    await authEvents.close();
  });
}
