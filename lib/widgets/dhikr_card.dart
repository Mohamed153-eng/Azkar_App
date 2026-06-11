// lib/widgets/dhikr_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dhikr_model.dart';
import '../providers/azkar_provider.dart';
import '../utils/app_theme.dart';

class DhikrCard extends StatefulWidget {
  final Dhikr dhikr;
  final DhikrProgress? progress;

  const DhikrCard({super.key, required this.dhikr, this.progress});

  @override
  State<DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<DhikrCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scaleAnim;
  bool _showVirtue = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onTap(AzkarProvider prov) async {
    if (widget.progress?.isCompleted == true) return;
    HapticFeedback.lightImpact();
    await _pulse.forward();
    await _pulse.reverse();
    await prov.increment(widget.dhikr);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AzkarProvider>();
    final p = widget.progress;
    final dhikr = widget.dhikr;
    final current = p?.currentCount ?? 0;
    final total = dhikr.repeatCount;
    final done = p?.isCompleted ?? false;
    final catColor = AppTheme.categoryColor(dhikr.category);
    final remaining = (total - current).clamp(0, total);
    final percent = total == 0 ? 0.0 : current / total;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (ctx, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              done ? AppTheme.primaryDark.withOpacity(0.9) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? catColor.withOpacity(0.6) : AppTheme.divider,
            width: done ? 1.5 : 1,
          ),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: catColor.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Progress bar ──────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: LinearProgressIndicator(
                value: percent.toDouble(),
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation(catColor),
                minHeight: 3,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Arabic text ───────────────────────────
                  Text(
                    dhikr.text,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      height: 2.0,
                      color: done
                          ? AppTheme.textPrimary.withOpacity(0.75)
                          : AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Source row ────────────────────────────
                  if (dhikr.source != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          dhikr.source!,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: catColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.menu_book_rounded,
                            size: 13, color: catColor.withOpacity(0.8)),
                      ],
                    ),

                  // ── Virtue (expandable) ───────────────────
                  if (dhikr.virtue != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() => _showVirtue = !_showVirtue),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedRotation(
                            turns: _showVirtue ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.expand_more_rounded,
                                size: 16, color: AppTheme.textHint),
                          ),
                          const SizedBox(width: 4),
                          Text('الفضل',
                              style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  color: AppTheme.textHint,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: _showVirtue
                          ? Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: catColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                dhikr.virtue!,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.tajawal(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.7,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Bottom row: counter + actions ─────────
                  Row(
                    children: [
                      // Undo
                      if (current > 0)
                        _SmallAction(
                          icon: Icons.undo_rounded,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            prov.undo(dhikr);
                          },
                        ),

                      // Copy
                      _SmallAction(
                        icon: Icons.copy_rounded,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: dhikr.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم النسخ',
                                  style: GoogleFonts.tajawal()),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppTheme.primaryLight,
                            ),
                          );
                        },
                      ),

                      _SmallAction(
                        icon: Icons.edit_rounded,
                        onTap: () => _showEditDialog(context, prov),
                      ),

                      const Spacer(),

                      // Counter chip / Done badge
                      if (done)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            prov.undo(dhikr);
                          },
                          child: _DoneBadge(color: catColor),
                        )
                      else
                        GestureDetector(
                          onTap: () => _onTap(prov),
                          child: _CounterChip(
                            current: current,
                            total: total,
                            remaining: remaining,
                            color: catColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext ctx, AzkarProvider prov) {
    final textCtrl = TextEditingController(text: widget.dhikr.text);
    final sourceCtrl = TextEditingController(text: widget.dhikr.source ?? '');
    final virtueCtrl = TextEditingController(text: widget.dhikr.virtue ?? '');
    final countCtrl =
        TextEditingController(text: widget.dhikr.repeatCount.toString());

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditSheet(
        textCtrl: textCtrl,
        sourceCtrl: sourceCtrl,
        virtueCtrl: virtueCtrl,
        countCtrl: countCtrl,
        onSave: () async {
          final count = int.tryParse(countCtrl.text) ?? 1;
          await prov.updateCustomDhikr(Dhikr(
            id: widget.dhikr.id,
            category: widget.dhikr.category,
            text: textCtrl.text.trim(),
            source:
                sourceCtrl.text.trim().isEmpty ? null : sourceCtrl.text.trim(),
            virtue:
                virtueCtrl.text.trim().isEmpty ? null : virtueCtrl.text.trim(),
            repeatCount: count.clamp(1, 9999),
            isCustom: widget.dhikr.isCustom,
            sortOrder: widget.dhikr.sortOrder,
          ));
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onDelete: () async {
          await prov.deleteDhikr(widget.dhikr.id!);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─── Small action button ──────────────────────────────────────────────────────
class _SmallAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppTheme.textHint),
        ),
      );
}

// ─── Counter chip ─────────────────────────────────────────────────────────────
class _CounterChip extends StatelessWidget {
  final int current, total, remaining;
  final Color color;
  const _CounterChip({
    required this.current,
    required this.total,
    required this.remaining,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$remaining',
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('متبقي',
                    style: GoogleFonts.tajawal(
                        fontSize: 10, color: color.withOpacity(0.7))),
                Text('من $total',
                    style: GoogleFonts.tajawal(
                        fontSize: 10, color: color.withOpacity(0.5))),
              ],
            ),
          ],
        ),
      );
}

// ─── Done badge ───────────────────────────────────────────────────────────────
class _DoneBadge extends StatelessWidget {
  final Color color;
  const _DoneBadge({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: color),
            const SizedBox(width: 6),
            Text('تمّ',
                style: GoogleFonts.tajawal(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

// ─── Edit sheet ───────────────────────────────────────────────────────────────
class _EditSheet extends StatelessWidget {
  final TextEditingController textCtrl, sourceCtrl, virtueCtrl, countCtrl;
  final VoidCallback onSave, onDelete;

  const _EditSheet({
    required this.textCtrl,
    required this.sourceCtrl,
    required this.virtueCtrl,
    required this.countCtrl,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24),
      child: SingleChildScrollView(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('تعديل الذكر',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          _field('نص الذكر', textCtrl, maxLines: 5),
          const SizedBox(height: 12),
          _field('المصدر (اختياري)', sourceCtrl),
          const SizedBox(height: 12),
          _field('الفضل (اختياري)', virtueCtrl, maxLines: 3),
          const SizedBox(height: 12),
          _field('عدد التكرار', countCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: Text('حذف',
                    style: GoogleFonts.tajawal(color: Colors.redAccent)),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.textPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text('حفظ',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.tajawal(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.tajawal(color: AppTheme.textHint),
      ),
    );
  }
}
