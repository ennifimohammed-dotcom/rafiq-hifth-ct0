import 'package:flutter/material.dart';

import '../../domain/entities/enums.dart';

Color ratingColor(SessionRating rating) {
  switch (rating) {
    case SessionRating.excellent:
      return const Color(0xFF1B7A4A);
    case SessionRating.good:
      return const Color(0xFF2E7DB8);
    case SessionRating.weak:
      return const Color(0xFFC0392B);
  }
}

class RatingChip extends StatelessWidget {
  final SessionRating rating;

  const RatingChip({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final color = ratingColor(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rating.labelAr,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
