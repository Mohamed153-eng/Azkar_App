// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dhikr_model.dart';
import '../providers/azkar_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dhikr_card.dart';
import 'add_dhikr_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late TabController _tabCtrl;

  final _categories = [
    DhikrCategory.morning,
    DhikrCategory.evening,
    DhikrCategory.sleep,
    DhikrCategory.custom,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<AzkarProvider>().loadCategory(_categories[_tabCtrl.index]);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AzkarProvider>().init();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AzkarPage(tabCtrl: _tabCtrl, categories: _categories),
      const StatsScreen(),
      const SettingsScreen()
    ];

    return Scaffold(
      body: pages[_navIndex],
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.auto_stories_rounded,
                label: 'الأذكار',
                selected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'الإحصائيات',
                selected: _navIndex == 1,
                onTap: () => setState(() => _navIndex = 1),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                selected: _navIndex == 2,
                onTap: () => setState(() => _navIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textHint;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.tajawal(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ─── Azkar page ──────────────────────────────────────────────────────────────
class _AzkarPage extends StatelessWidget {
  final TabController tabCtrl;
  final List<String> categories;

  const _AzkarPage({required this.tabCtrl, required this.categories});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AzkarProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context, prov),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: tabCtrl,
              children: categories.map((_) => _AzkarList(prov: prov)).toList(),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.bg,
        onPressed: () async {
          final addedCategory = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => AddDhikrScreen(
                initialCategory: prov.activeCategory,
              ),
            ),
          );
          if (addedCategory == null || !context.mounted) return;

          final tabIndex = categories.indexOf(addedCategory);
          if (tabIndex != -1) {
            tabCtrl.animateTo(tabIndex);
          }
          await context.read<AzkarProvider>().loadCategory(addedCategory);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, AzkarProvider prov) {
    final catColor = AppTheme.categoryColor(prov.activeCategory);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Text('🔥', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('${prov.streak} يوم',
                      style: GoogleFonts.tajawal(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ]),
              ),
            ]),
            Text('أذكار اليوم',
                style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${prov.totalCompletions} ✓',
                  style: GoogleFonts.tajawal(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${prov.completedCount} / ${prov.totalCount} ذكر',
                style: GoogleFonts.tajawal(
                    color: AppTheme.textSecondary, fontSize: 12)),
            Text('${(prov.completionPercent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.tajawal(
                    color: catColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: prov.completionPercent,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(catColor),
              minHeight: 6,
            ),
          ),
        ]),
        if (prov.sessionComplete)
          _SessionDoneBanner(
              category: prov.activeCategory, onReset: prov.resetSession),
      ]),
    );
  }

  Widget _buildTabBar(BuildContext ctx) {
    final labels = {
      DhikrCategory.morning: ('الصباح', '🌅'),
      DhikrCategory.evening: ('المساء', '🌆'),
      DhikrCategory.sleep: ('النوم', '🌙'),
      DhikrCategory.custom: ('مخصصة', '✨'),
    };
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: tabCtrl,
        dividerHeight: 0,
        indicator: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryLight.withOpacity(0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        tabs: categories.map((cat) {
          final l = labels[cat]!;
          return Tab(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.$2, style: const TextStyle(fontSize: 16)),
              Text(l.$1,
                  style: GoogleFonts.tajawal(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          );
        }).toList(),
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textHint,
      ),
    );
  }
}

class _AzkarList extends StatelessWidget {
  final AzkarProvider prov;
  const _AzkarList({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (prov.azkar.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_circle_outline_rounded,
              size: 56, color: AppTheme.textHint),
          const SizedBox(height: 12),
          Text('لا توجد أذكار بعد',
              style:
                  GoogleFonts.tajawal(color: AppTheme.textHint, fontSize: 16)),
          const SizedBox(height: 8),
          Text('اضغط + لإضافة ذكر مخصص',
              style:
                  GoogleFonts.tajawal(color: AppTheme.textHint, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: prov.azkar.length,
      itemBuilder: (_, i) {
        final d = prov.azkar[i];
        return DhikrCard(
          key: ValueKey(d.id),
          dhikr: d,
          progress: prov.progress[d.id],
        );
      },
    );
  }
}

// ─── Session Done Banner ─────────────────────────────────────────────────────
class _SessionDoneBanner extends StatelessWidget {
  final String category;
  final VoidCallback onReset;
  const _SessionDoneBanner({required this.category, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(category);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(children: [
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: Text('إعادة',
              style: GoogleFonts.tajawal(
                  color: color.withOpacity(0.7), fontSize: 12)),
        ),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('ما شاء الله! أتممت أذكارك 🎉',
              textAlign: TextAlign.right,
              style: GoogleFonts.tajawal(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          Text('جعلها الله في ميزان حسناتك',
              textAlign: TextAlign.right,
              style: GoogleFonts.tajawal(
                  fontSize: 11, color: color.withOpacity(0.7))),
        ]),
        const SizedBox(width: 8),
        Icon(Icons.check_circle_rounded, color: color, size: 28),
      ]),
    );
  }
}
