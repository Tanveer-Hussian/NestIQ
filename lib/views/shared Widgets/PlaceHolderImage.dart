// ── Fallback image when no photo is available ──────────────────────────────
import 'package:flutter/material.dart';
import 'package:fyp/utils/AppColors.dart';

class PlaceholderImage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.divider,
      child: const Center(
        child: Icon(Icons.home_work_outlined,
            size: 48, color: AppColors.textSecondary),
      ),
    );
  }
}
