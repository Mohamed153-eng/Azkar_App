// lib/screens/add_dhikr_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dhikr_model.dart';
import '../providers/azkar_provider.dart';
import '../utils/app_theme.dart';

class AddDhikrScreen extends StatefulWidget {
  final String initialCategory;
  const AddDhikrScreen({super.key, required this.initialCategory});

  @override
  State<AddDhikrScreen> createState() => _AddDhikrScreenState();
}

class _AddDhikrScreenState extends State<AddDhikrScreen> {
  late String _category;
  final _textCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _virtueCtrl = TextEditingController();
  final _countCtrl = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _sourceCtrl.dispose();
    _virtueCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_textCtrl.text.trim().isEmpty) {
      _snack('الرجاء إدخال نص الذكر');
      return;
    }
    setState(() => _saving = true);
    final count = int.tryParse(_countCtrl.text) ?? 1;
    await context.read<AzkarProvider>().addCustomDhikr(
          text: _textCtrl.text.trim(),
          category: _category,
          source:
              _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
          virtue:
              _virtueCtrl.text.trim().isEmpty ? null : _virtueCtrl.text.trim(),
          repeatCount: count.clamp(1, 9999),
        );
    if (mounted) Navigator.pop(context, _category);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.tajawal()),
      backgroundColor: AppTheme.primaryLight,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('إضافة ذكر'),
        backgroundColor: AppTheme.bg,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _label('الفئة'),
          const SizedBox(height: 8),
          _CategoryPicker(
            selected: _category,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 20),
          _label('نص الذكر *'),
          const SizedBox(height: 8),
          _field(_textCtrl,
              maxLines: 6, hint: 'اكتب نص الذكر أو الدعاء هنا...'),
          const SizedBox(height: 16),
          _label('المصدر (اختياري)'),
          const SizedBox(height: 8),
          _field(_sourceCtrl, hint: 'مثال: البخاري، سورة البقرة...'),
          const SizedBox(height: 16),
          _label('فضل الذكر (اختياري)'),
          const SizedBox(height: 8),
          _field(_virtueCtrl,
              maxLines: 3, hint: 'اكتب ثواب أو فضل قراءة هذا الذكر...'),
          const SizedBox(height: 16),
          _label('عدد التكرار'),
          const SizedBox(height: 8),
          _field(_countCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.textPrimary))
                : Text('حفظ الذكر',
                    style: GoogleFonts.tajawal(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        textAlign: TextAlign.right,
        style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary),
      );

  Widget _field(TextEditingController ctrl,
      {int maxLines = 1,
      String? hint,
      TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.tajawal(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cats = [
      (DhikrCategory.morning, 'الصباح', '🌅'),
      (DhikrCategory.evening, 'المساء', '🌆'),
      (DhikrCategory.sleep, 'النوم', '🌙'),
      (DhikrCategory.custom, 'مخصصة', '✨'),
    ];
    return Row(
      children: cats.reversed.map((c) {
        final isSelected = c.$1 == selected;
        final color = AppTheme.categoryColor(c.$1);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? color.withOpacity(0.2) : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? color.withOpacity(0.6) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.$3, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(c.$2,
                    style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isSelected ? color : AppTheme.textHint,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.normal)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
