import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class NurimAddressCard extends StatelessWidget {
  final String title;
  final String address;
  final VoidCallback? onPressed;

  const NurimAddressCard({
    super.key,
    required this.title,
    required this.address,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.isNotEmpty && address != '주소를 등록해 주세요.';

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Row: Location Pin Icon is placed on the same line as the Title
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/ic_location_20.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address Text is placed below, left-aligned with the pin icon
                  Text(
                    address,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasAddress ? AppColors.textSecondary : AppColors.placeholder,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right chevron icon
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
