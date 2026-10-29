import '../models/project.dart';

enum PriceMatchStatus { found, noCandidates, noAffordableMatch }

class SmartPriceMatchResult {
  const SmartPriceMatchResult({required this.status, this.project});

  final PriceMatchStatus status;
  final Project? project;
}

class SmartPriceMatcherLogic {
  const SmartPriceMatcherLogic._();

  static const maximumBudgetDifferenceRatio = 0.4;

  static SmartPriceMatchResult findClosestProject({
    required List<Project> projects,
    required double budget,
    String keyword = '',
  }) {
    if (!budget.isFinite || budget <= 0) {
      throw ArgumentError.value(
        budget,
        'budget',
        'Must be finite and positive',
      );
    }

    final normalizedKeyword = keyword.trim().toLowerCase();
    final candidates = projects
        .where((project) {
          if (normalizedKeyword.isEmpty) return true;
          return project.title.toLowerCase().contains(normalizedKeyword) ||
              project.description.toLowerCase().contains(normalizedKeyword) ||
              project.techStack
                  .join(' ')
                  .toLowerCase()
                  .contains(normalizedKeyword);
        })
        .where((project) => project.price.isFinite && project.price >= 0)
        .toList();

    if (candidates.isEmpty) {
      return const SmartPriceMatchResult(status: PriceMatchStatus.noCandidates);
    }

    final matches =
        candidates.where((project) {
          if (project.price > budget) return false;
          final differenceRatio = (budget - project.price) / budget;
          return differenceRatio <= maximumBudgetDifferenceRatio;
        }).toList()..sort((first, second) {
          final priceOrder = second.price.compareTo(first.price);
          return priceOrder != 0 ? priceOrder : first.id.compareTo(second.id);
        });

    if (matches.isEmpty) {
      return const SmartPriceMatchResult(
        status: PriceMatchStatus.noAffordableMatch,
      );
    }
    return SmartPriceMatchResult(
      status: PriceMatchStatus.found,
      project: matches.first,
    );
  }
}
