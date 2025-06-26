import 'package:flutter/material.dart';

/// A reusable stat box for displaying a label and value with optional color.
class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const StatBox({
    required this.label,
    required this.value,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.08) ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.grey, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color ?? Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
