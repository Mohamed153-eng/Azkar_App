// lib/screens/settings_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/azkar_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AzkarProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'قاعدة البيانات'),
          const SizedBox(height: 12),

          // Export JSON
          _SettingsTile(
            icon: Icons.upload_rounded,
            iconColor: AppTheme.success,
            title: 'تصدير قاعدة البيانات',
            subtitle: 'حفظ نسخة احتياطية JSON',
            onTap: () => _export(context, prov),
          ),

          // Import JSON
          _SettingsTile(
            icon: Icons.download_rounded,
            iconColor: AppTheme.accent,
            title: 'استيراد قاعدة البيانات',
            subtitle: 'استعادة من ملف JSON',
            onTap: () => _import(context, prov),
          ),

          const SizedBox(height: 24),
          _SectionHeader(title: 'معلومات'),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.textHint,
            title: 'عن التطبيق',
            subtitle: 'أذكار اليوم – الإصدار 1.0.0',
            onTap: () => _showAbout(context),
          ),

          const SizedBox(height: 32),

          // App info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(children: [
              Text('اللهم اجعلنا من الذاكرين لك كثيراً',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: AppTheme.accent,
                      height: 1.8)),
              const SizedBox(height: 8),
              Text('بياناتك محفوظة محلياً على جهازك فقط',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.tajawal(
                      fontSize: 12, color: AppTheme.textHint)),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, AzkarProvider prov) async {
    try {
      _showLoading(context, 'جاري التصدير...');
      final path = await prov.exportToFile();
      if (context.mounted) Navigator.pop(context);

      final result = await Share.shareXFiles(
        [XFile(path)],
        subject: 'نسخة احتياطية – أذكار اليوم',
      );

      if (context.mounted && result.status == ShareResultStatus.success) {
        _snack(context, 'تم التصدير بنجاح ✓', AppTheme.success);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'خطأ في التصدير: $e', Colors.redAccent);
      }
    }
  }

  Future<void> _import(BuildContext context, AzkarProvider prov) async {
    // Confirm first
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('استيراد قاعدة البيانات',
            style: GoogleFonts.tajawal(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
            'سيتم استبدال الأذكار المخصصة والإحصائيات الحالية بالبيانات المستوردة. هل أنت متأكد؟',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.tajawal(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: GoogleFonts.tajawal(color: AppTheme.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary),
            child: Text('استيراد',
                style: GoogleFonts.tajawal(color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      if (!context.mounted) return;
      _showLoading(context, 'جاري الاستيراد...');
      final content = await File(result.files.single.path!).readAsString();
      await prov.importFromJson(content);

      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'تم الاستيراد بنجاح ✓', AppTheme.success);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'خطأ في الاستيراد: $e', Colors.redAccent);
      }
    }
  }

  void _showLoading(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            const SizedBox(width: 16),
            Text(msg,
                style: GoogleFonts.tajawal(color: AppTheme.textPrimary)),
          ]),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'أذكار اليوم',
      applicationVersion: '1.0.0',
      applicationLegalese: 'بياناتك محفوظة محلياً على جهازك',
    );
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.tajawal()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
                letterSpacing: 0.5)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(children: [
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textHint),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(title,
                  style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.tajawal(
                      fontSize: 12, color: AppTheme.textHint)),
            ]),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ]),
        ),
      );
}
