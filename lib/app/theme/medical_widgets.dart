import 'package:flutter/material.dart';
import '../theme.dart';

/// Widget helper untuk menampilkan status BPM dengan warna yang sesuai
class BpmStatusIndicator extends StatelessWidget {
  final int bpm;
  final double? size;
  final bool showLabel;

  const BpmStatusIndicator({
    required this.bpm,
    this.size = 16,
    this.showLabel = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final status = _getBpmStatus(bpm);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            status.icon,
            size: size! * 0.6,
            color: AppColors.medicalWhite,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            status.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  BpmStatus _getBpmStatus(int bpm) {
    if (bpm < 100) {
      return BpmStatus(
        color: AppColors.bpmCritical,
        label: 'Kritis Rendah',
        icon: Icons.warning,
      );
    } else if (bpm < 120) {
      return BpmStatus(
        color: AppColors.bpmLow,
        label: 'Rendah',
        icon: Icons.trending_down,
      );
    } else if (bpm <= 160) {
      return BpmStatus(
        color: AppColors.bpmNormal,
        label: 'Normal',
        icon: Icons.check_circle,
      );
    } else if (bpm <= 180) {
      return BpmStatus(
        color: AppColors.bpmHigh,
        label: 'Tinggi',
        icon: Icons.trending_up,
      );
    } else {
      return BpmStatus(
        color: AppColors.bpmCritical,
        label: 'Kritis Tinggi',
        icon: Icons.warning,
      );
    }
  }
}

class BpmStatus {
  final Color color;
  final String label;
  final IconData icon;

  BpmStatus({required this.color, required this.label, required this.icon});
}

/// Widget untuk menampilkan card medical dengan style konsisten
class MedicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool isElevated;

  const MedicalCard({
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.isElevated = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: isElevated ? [AppColors.softShadow] : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

/// Widget untuk header section dengan style medical
class MedicalSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const MedicalSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
