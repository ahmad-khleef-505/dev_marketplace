import 'package:dev_marketplace/models/project.dart';
import 'package:dev_marketplace/services/chat_message_filter.dart';
import 'package:dev_marketplace/services/rating_calculator.dart';
import 'package:dev_marketplace/services/smart_price_matcher_logic.dart';
import 'package:flutter_test/flutter_test.dart';

Project project(String id, double price, {String title = 'Flutter app'}) =>
    Project(
      id: id,
      developerId: 'dev',
      developerName: 'Developer',
      projectType: 'app',
      title: title,
      description: 'description',
      language: 'Dart',
      category: 'apps',
      price: price,
      demoLink: '',
      imageUrl: '',
      techStack: const ['Flutter', 'Firebase'],
      averageRating: 0,
      ratingCount: 0,
      totalRating: 0,
      isEscrow: false,
      status: 'approved',
      views: 0,
    );

void main() {
  group('ChatMessageFilter', () {
    test(
      'blocks long numbers, local mobile numbers and Syrian country code',
      () {
        expect(ChatMessageFilter.isMessageAllowed('call 1234567'), isFalse);
        expect(ChatMessageFilter.isMessageAllowed('اتصل 0912345678'), isFalse);
        expect(ChatMessageFilter.isMessageAllowed('رقمي +96312345'), isFalse);
        expect(ChatMessageFilter.isMessageAllowed('رقمي ٠٩١٢٣٤٥٦٧٨'), isFalse);
      },
    );

    test('allows ordinary conversation and prices up to six digits', () {
      expect(ChatMessageFilter.isMessageAllowed('مرحباً، شكراً لك'), isTrue);
      expect(ChatMessageFilter.isMessageAllowed('السعر 125000 دولار'), isTrue);
      expect(ChatMessageFilter.isMessageAllowed('السعر 1000000'), isFalse);
    });
  });

  group('SmartPriceMatcherLogic', () {
    test(
      'chooses the highest-priced match within the 40 percent threshold',
      () {
        final result = SmartPriceMatcherLogic.findClosestProject(
          projects: [
            project('low', 50),
            project('closest', 75),
            project('high', 110),
          ],
          budget: 100,
        );
        expect(result.status, PriceMatchStatus.found);
        expect(result.project?.id, 'closest');
      },
    );

    test('includes exact 40 percent boundary and filters by keyword', () {
      final result = SmartPriceMatcherLogic.findClosestProject(
        projects: [project('boundary', 60)],
        budget: 100,
        keyword: 'Flutter',
      );
      expect(result.status, PriceMatchStatus.found);
      expect(result.project?.id, 'boundary');
    });

    test('returns distinct empty and no-affordable-match results', () {
      expect(
        SmartPriceMatcherLogic.findClosestProject(
          projects: const [],
          budget: 100,
        ).status,
        PriceMatchStatus.noCandidates,
      );
      expect(
        SmartPriceMatcherLogic.findClosestProject(
          projects: [project('cheap', 50)],
          budget: 100,
        ).status,
        PriceMatchStatus.noAffordableMatch,
      );
    });

    test('rejects invalid budgets', () {
      expect(
        () => SmartPriceMatcherLogic.findClosestProject(
          projects: const [],
          budget: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RatingCalculator', () {
    test('calculates the updated average correctly', () {
      expect(
        RatingCalculator.nextAverage(
          totalRating: 9,
          ratingCount: 2,
          newRating: 3,
        ),
        4,
      );
    });

    test(
      'rejects ratings outside the supported range and invalid aggregates',
      () {
        expect(
          () => RatingCalculator.nextAverage(
            totalRating: 0,
            ratingCount: 0,
            newRating: 6,
          ),
          throwsArgumentError,
        );
        expect(
          () => RatingCalculator.nextAverage(
            totalRating: 1,
            ratingCount: -1,
            newRating: 4,
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
