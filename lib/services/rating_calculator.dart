class RatingCalculator {
  const RatingCalculator._();

  static double nextAverage({
    required double totalRating,
    required int ratingCount,
    required int newRating,
  }) {
    if (!totalRating.isFinite || totalRating < 0) {
      throw ArgumentError.value(totalRating, 'totalRating');
    }
    if (ratingCount < 0) {
      throw ArgumentError.value(ratingCount, 'ratingCount');
    }
    if (newRating < 1 || newRating > 5) {
      throw ArgumentError.value(newRating, 'newRating');
    }

    return (totalRating + newRating) / (ratingCount + 1);
  }
}
