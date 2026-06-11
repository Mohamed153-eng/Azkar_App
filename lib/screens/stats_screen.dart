// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/azkar_provider.dart';
import '../utils/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AzkarProvider>().refreshStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AzkarProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: RefreshIndicator(
        onRefresh: prov.refreshStats,
        color: AppTheme.accent,
        backgroundColor: AppTheme.surface,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── KPI cards ─────────────────────────────────
            Row(children: [
              Expanded(child: _KpiCard(
                emoji: '🔥',
                value: '${prov.streak}',
                label: 'يوم متتالي',
                color: AppTheme.morningColor,
              )),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(
                emoji: '✅',
                value: '${prov.totalCompletions}',
                label: 'مرة إتمام',
                color: AppTheme.success,
              )),
            ]),

            const SizedBox(height: 24),

            // ── Weekly heatmap (last 30 days) ──────────────
            Text('آخر ٣٠ يوم',
                textAlign: TextAlign.right,
                style: GoogleFonts.tajawal(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _HeatmapGrid(stats: prov.last30Stats),

            const SizedBox(height: 24),

            // ── Legend ────────────────────────────────────
            _Legend(),

            const SizedBox(height: 24),

            // ── Weekly breakdown ──────────────────────────
            Text('هذا الأسبوع',
                textAlign: TextAlign.right,
                style: GoogleFonts.tajawal(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _WeekRow(stats: prov.last30Stats),

            const SizedBox(height: 32),

            // ── Motivational quote ────────────────────────
            _MotivationCard(streak: prov.streak),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _KpiCard({required this.emoji, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.tajawal(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: GoogleFonts.tajawal(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      );
}

class _HeatmapGrid extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const _HeatmapGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    // Build a map for quick lookup
    final Map<String, Map<String, dynamic>> map = {
      for (final s in stats) s['stat_date'] as String: s,
    };

    final today = DateTime.now();
    final days = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        final key =
            '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        final s = map[key];
        final m = s?['morning_done'] == 1;
        final e = s?['evening_done'] == 1;
        final sl = s?['sleep_done'] == 1;
        final total = (m ? 1 : 0) + (e ? 1 : 0) + (sl ? 1 : 0);
        final allDone = total == 3;
        final isToday = key == map.keys.lastOrNull ||
            d.day == today.day &&
                d.month == today.month &&
                d.year == today.year;

        final color = allDone
            ? AppTheme.success
            : total == 2
                ? AppTheme.primaryLight
                : total == 1
                    ? AppTheme.primary.withOpacity(0.5)
                    : AppTheme.surfaceLight;

        return Tooltip(
          message: '${d.day}/${d.month}\nص:${m ? '✓' : '✗'} م:${e ? '✓' : '✗'} ن:${sl ? '✓' : '✗'}',
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: AppTheme.accent, width: 2)
                  : null,
            ),
            child: allDone
                ? const Icon(Icons.check_rounded, size: 16, color: AppTheme.bg)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (AppTheme.surfaceLight, 'لا شيء'),
      (AppTheme.primary.withOpacity(0.5), '١ جلسة'),
      (AppTheme.primaryLight, '٢ جلسة'),
      (AppTheme.success, 'مكتمل'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: items.reversed.map((item) => Row(children: [
        const SizedBox(width: 12),
        Text(item.$2,
            style: GoogleFonts.tajawal(
                fontSize: 11, color: AppTheme.textHint)),
        const SizedBox(width: 4),
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: item.$1,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ])).toList(),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  const _WeekRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> map = {
      for (final s in stats) s['stat_date'] as String: s,
    };
    final today = DateTime.now();
    final weekDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return Row(
      children: List.generate(7, (i) {
        final d = today.subtract(Duration(days: today.weekday % 7 - i));
        final key =
            '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        final s = map[key];
        final allDone =
            s?['morning_done'] == 1 && s?['evening_done'] == 1 && s?['sleep_done'] == 1;
        final isToday = d.day == today.day &&
            d.month == today.month &&
            d.year == today.year;

        return Expanded(
          child: Column(children: [
            Text(weekDays[d.weekday % 7],
                style: GoogleFonts.tajawal(
                    fontSize: 10, color: AppTheme.textHint)),
            const SizedBox(height: 6),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: allDone
                    ? AppTheme.success
                    : isToday
                        ? AppTheme.primaryLight.withOpacity(0.4)
                        : AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: AppTheme.accent, width: 2)
                    : null,
              ),
              child: Center(
                child: allDone
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: AppTheme.bg)
                    : Text('${d.day}',
                        style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: isToday
                                ? AppTheme.textPrimary
                                : AppTheme.textHint)),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final int streak;
  const _MotivationCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final quotes = [
      ('وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا', 'الأحزاب: ٣٥'),
      ('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'الرعد: ٢٨'),
      ('فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ', 'البقرة: ١٥٢'),
    ];
    final q = quotes[streak % quotes.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.3),
            AppTheme.primaryDark.withOpacity(0.5),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(q.$1,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
                fontSize: 20,
                height: 2.0,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(q.$2,
            style: GoogleFonts.tajawal(
                fontSize: 12,
                color: AppTheme.accent,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
