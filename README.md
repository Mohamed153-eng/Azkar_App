# 🕌 أذكار اليوم – Flutter App

تطبيق Flutter كامل لأذكار الصباح والمساء والنوم، مستوحى من موقع **alazkar.today**، مع قاعدة بيانات SQLite محلية وإمكانية الاستيراد والتصدير.

---

## ✨ المميزات

| الميزة | التفاصيل |
|--------|---------|
| 📖 الأذكار الأصلية | أذكار الصباح والمساء والنوم من حصن المسلم |
| 🔢 عداد تفاعلي | اضغط على البطاقة لتسجيل كل تكرار |
| ↩️ تراجع | إمكانية التراجع عن أي ذكر مكتمل |
| ✅ تتبع الجلسات | تتبع إتمام كل جلسة (صباح / مساء / نوم) |
| 🔥 Streak | عد الأيام المتتالية التي أتممت فيها الأذكار |
| 📊 إحصائيات | خريطة حرارية لآخر 30 يوم + عرض أسبوعي |
| ➕ أذكار مخصصة | إضافة وتعديل وحذف أذكار شخصية |
| 📤 تصدير | حفظ قاعدة البيانات كملف JSON |
| 📥 استيراد | استعادة النسخة الاحتياطية من ملف JSON |
| 🌙 تصميم داكن | واجهة داكنة مريحة للعين بألوان إسلامية |
| 🇸🇦 عربي كامل | RTL كامل، خطوط Amiri + Tajawal |

---

## 🏗️ هيكل المشروع

```
lib/
├── main.dart                    ← نقطة البداية
├── models/
│   └── dhikr_model.dart         ← Dhikr, DhikrProgress, DayStats
├── database/
│   └── database_helper.dart     ← SQLite CRUD + seed data + export/import
├── providers/
│   └── azkar_provider.dart      ← State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart         ← الشاشة الرئيسية + التبويبات
│   ├── add_dhikr_screen.dart    ← إضافة ذكر مخصص
│   ├── stats_screen.dart        ← الإحصائيات والخريطة الحرارية
│   └── settings_screen.dart     ← استيراد / تصدير + معلومات
├── widgets/
│   └── dhikr_card.dart          ← بطاقة الذكر التفاعلية
└── utils/
    └── app_theme.dart           ← الألوان والخطوط والتصميم
```

---

## 🗄️ قاعدة البيانات (SQLite)

### الجداول

```sql
-- الأذكار
CREATE TABLE dhikr (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  category     TEXT,    -- morning / evening / sleep / custom
  text         TEXT,
  source       TEXT,    -- المصدر (البخاري، مسلم...)
  virtue       TEXT,    -- فضل الذكر
  repeat_count INTEGER,
  is_custom    INTEGER, -- 0 = أصلي، 1 = مخصص
  sort_order   INTEGER
);

-- تقدم اليوم
CREATE TABLE dhikr_progress (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  dhikr_id      INTEGER,
  session_date  TEXT,   -- yyyy-MM-dd
  session_type  TEXT,   -- morning / evening / sleep / custom
  current_count INTEGER,
  is_completed  INTEGER
);

-- إحصائيات يومية
CREATE TABLE stats (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  stat_date    TEXT UNIQUE,
  morning_done INTEGER,
  evening_done INTEGER,
  sleep_done   INTEGER
);
```

---

## 🚀 تشغيل المشروع

### المتطلبات
- Flutter SDK ≥ 3.10
- Dart ≥ 3.0

### الخطوات

```bash
# 1. تثبيت الحزم
flutter pub get

# 2. تشغيل التطبيق
flutter run

# 3. بناء APK
flutter build apk --release
```

---

## 📦 الحزم المستخدمة

| الحزمة | الغرض |
|--------|-------|
| `sqflite` | قاعدة البيانات SQLite |
| `provider` | إدارة الحالة |
| `google_fonts` | خطوط Amiri + Tajawal |
| `file_picker` | اختيار ملف JSON للاستيراد |
| `share_plus` | مشاركة ملف التصدير |
| `path_provider` | مسار تخزين الملفات |
| `flutter_localizations` | دعم RTL العربي |

---

## 📱 الشاشات

### 1. الشاشة الرئيسية
- تبويبات: الصباح / المساء / النوم / مخصصة
- شريط تقدم الجلسة الحالية
- بطاقات الأذكار مع عداد التكرار
- لافتة الإتمام عند الانتهاء

### 2. بطاقة الذكر
- نص الذكر بخط Amiri
- المصدر والفضل (قابل للطي)
- عداد يظهر المتبقي من التكرارات
- زر التراجع والنسخ والتعديل (للمخصص)

### 3. الإحصائيات
- 🔥 عداد الأيام المتتالية
- ✅ إجمالي مرات الإتمام
- خريطة حرارية لآخر 30 يوم
- عرض أسبوعي دائري
- آية قرآنية متغيرة

### 4. الإعدادات
- تصدير قاعدة البيانات (JSON + Share)
- استيراد قاعدة البيانات

---

## 🎨 نظام الألوان

| اللون | الكود | الاستخدام |
|------|-------|----------|
| أخضر داكن | `#0D1F1A` | خلفية الشاشة |
| ذهبي دافئ | `#D4A852` | لهجة Accent |
| برتقالي شروق | `#E8A020` | أذكار الصباح |
| بنفسجي أزرق | `#6A7FDB` | أذكار المساء |
| أزرق ليلي | `#4A7FAA` | أذكار النوم |
| أخضر ناعم | `#70B87E` | أذكار مخصصة |

---

## 🔄 صيغة ملف التصدير (JSON)

```json
{
  "version": 1,
  "exported_at": "2025-01-01T10:00:00.000Z",
  "dhikr": [...],
  "stats": [...],
  "progress": [...]
}
```

---

بارك الله فيك وجعل هذا العمل في ميزان حسناتك 🤲
