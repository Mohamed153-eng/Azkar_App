// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:azkar_app/models/dhikr_model.dart';

void main() {
  test('Dhikr maps to and from SQLite rows', () {
    const dhikr = Dhikr(
      category: DhikrCategory.morning,
      text: 'سبحان الله',
      source: 'اختبار',
      virtue: 'ذكر',
      repeatCount: 3,
      isCustom: true,
      sortOrder: 7,
    );

    final restored = Dhikr.fromMap(dhikr.toMap());

    expect(restored.category, DhikrCategory.morning);
    expect(restored.text, 'سبحان الله');
    expect(restored.repeatCount, 3);
    expect(restored.isCustom, isTrue);
    expect(restored.sortOrder, 7);
  });
}
