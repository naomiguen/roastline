import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Header maroon dengan sudut bawah membulat + logo lingkaran,
/// sesuai desain login / register / forgot-password.
class AuthHeader extends StatelessWidget {
  final double height;
  const AuthHeader({super.key, this.height = 250});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'RoastLine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Deadline nge-roast kamu!',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
