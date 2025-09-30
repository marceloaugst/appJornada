import 'package:flutter/cupertino.dart';

class JourneyButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isLoading;

  const JourneyButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.1)
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : CupertinoColors.separator,
            width: isActive ? 2 : 0.5,
          ),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            if (isActive)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const CupertinoActivityIndicator()
                  : Icon(
                      icon,
                      size: 32,
                      color: isActive ? color : color.withValues(alpha: 0.8),
                    ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? color : CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
