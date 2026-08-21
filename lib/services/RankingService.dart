// lib/services/RankingService.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-9: Smart Ranking System (Machine Learning Based)
//
// Uses a trained XGBRegressor model to predict a 
// recommendation score based on 5 input features:
// Rating , Complaint Resolution Rate, Review Volume,
// Booking Volume, Proximity.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/services/HostelScoreModel.dart';
import 'package:fyp/services/DynamicHostelScoreModel.dart';
import 'dart:math';


class RankingService {
  RankingService._();

  // ─────────────────────────────────────────────────────────────────────────
  // Main entry point: score and sort an entire list of hostels.
  // getDistance returns the distance in km from user to the hostel.
  // ─────────────────────────────────────────────────────────────────────────
  static List<HostelModel> scoreAndSort(List<HostelModel> hostels, {double Function(HostelModel)? getDistance}) {
    if (hostels.isEmpty) return hostels;

    final scored = hostels.map((h) {
      double dist = getDistance != null ? getDistance(h) : 0.0;
      final score = computeScore(h, dist);
      h.smartScore = score; // Cache it for the UI
      return _ScoredHostel(hostel: h, score: score);
    }).toList();

    // Sort descending by score
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.map((s) => s.hostel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Run inference
  // ─────────────────────────────────────────────────────────────────────────
  static double computeScore(HostelModel h, double distanceKm) {
    // 1. Prepare Features (must match Python training features)
    // "average_rating", "complaint_resolution_rate", "review_volume", "num_bookings", "proximity"
    final double fRating = h.averageRating;
    final double fResRate = h.complaintResolutionRate;
    final double fRevVol = h.totalReviews.toDouble();
    final double fBookings = h.totalBookings.toDouble();
    final double fProximity = distanceKm;

    // 2. Build input list
    List<double> input = [fRating, fResRate, fRevVol, fBookings, fProximity];

    // 3. Run Inference from generated Dart model
    try {
      double score = DynamicHostelScoreModel().predict(input);
      // The ML output score is 0-100.
      return score.clamp(0.0, 100.0);
    } catch (e) {
      return 0.0;
    }
  }
}

class _ScoredHostel {
  final HostelModel hostel;
  final double score;
  const _ScoredHostel({required this.hostel, required this.score});
}
