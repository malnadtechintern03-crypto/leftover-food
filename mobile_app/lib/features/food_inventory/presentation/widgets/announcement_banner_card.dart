import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/services/admin_sync_service.dart';

/// Dismissible announcement card displaying live broadcasts from the Admin Console
class AnnouncementBannerCard extends StatefulWidget {
  const AnnouncementBannerCard({super.key});

  @override
  State<AnnouncementBannerCard> createState() => _AnnouncementBannerCardState();
}

class _AnnouncementBannerCardState extends State<AnnouncementBannerCard> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _loadAnnouncements();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final items = await AdminSyncService.fetchAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isDismissed || _announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = _announcements.first;
    final title = item['title']?.toString() ?? 'Pantry Announcement';
    final message = item['message']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
              : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.35 : 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.25 : 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: ColorPalette.freshEmerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isDismissed = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? ColorPalette.darkTextSecondary : const Color(0xFF047857),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
