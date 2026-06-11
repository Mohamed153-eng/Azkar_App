// lib/models/dhikr_model.dart

class DhikrCategory {
  static const String morning = 'morning';
  static const String evening = 'evening';
  static const String sleep = 'sleep';
  static const String custom = 'custom';

  static String getArabicName(String cat) {
    switch (cat) {
      case morning: return 'أذكار الصباح';
      case evening: return 'أذكار المساء';
      case sleep:   return 'أذكار النوم';
      case custom:  return 'أذكار مخصصة';
      default:      return cat;
    }
  }
}

class Dhikr {
  final int? id;
  final String category;
  final String text;
  final String? source;
  final String? virtue;
  final int repeatCount;
  final bool isCustom;
  final int sortOrder;

  const Dhikr({
    this.id,
    required this.category,
    required this.text,
    this.source,
    this.virtue,
    this.repeatCount = 1,
    this.isCustom = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'category':     category,
    'text':         text,
    'source':       source,
    'virtue':       virtue,
    'repeat_count': repeatCount,
    'is_custom':    isCustom ? 1 : 0,
    'sort_order':   sortOrder,
  };

  factory Dhikr.fromMap(Map<String, dynamic> m) => Dhikr(
    id:          m['id'] as int?,
    category:    m['category'] as String,
    text:        m['text'] as String,
    source:      m['source'] as String?,
    virtue:      m['virtue'] as String?,
    repeatCount: m['repeat_count'] as int? ?? 1,
    isCustom:    (m['is_custom'] as int? ?? 0) == 1,
    sortOrder:   m['sort_order'] as int? ?? 0,
  );

  Dhikr copyWith({
    int? id, String? category, String? text,
    String? source, String? virtue,
    int? repeatCount, bool? isCustom, int? sortOrder,
  }) => Dhikr(
    id:          id ?? this.id,
    category:    category ?? this.category,
    text:        text ?? this.text,
    source:      source ?? this.source,
    virtue:      virtue ?? this.virtue,
    repeatCount: repeatCount ?? this.repeatCount,
    isCustom:    isCustom ?? this.isCustom,
    sortOrder:   sortOrder ?? this.sortOrder,
  );
}

class DhikrProgress {
  final int? id;
  final int dhikrId;
  final String sessionDate; // yyyy-MM-dd
  final String sessionType; // morning / evening / sleep / custom
  final int currentCount;
  final bool isCompleted;

  const DhikrProgress({
    this.id,
    required this.dhikrId,
    required this.sessionDate,
    required this.sessionType,
    this.currentCount = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'dhikr_id':     dhikrId,
    'session_date': sessionDate,
    'session_type': sessionType,
    'current_count': currentCount,
    'is_completed': isCompleted ? 1 : 0,
  };

  factory DhikrProgress.fromMap(Map<String, dynamic> m) => DhikrProgress(
    id:           m['id'] as int?,
    dhikrId:      m['dhikr_id'] as int,
    sessionDate:  m['session_date'] as String,
    sessionType:  m['session_type'] as String,
    currentCount: m['current_count'] as int? ?? 0,
    isCompleted:  (m['is_completed'] as int? ?? 0) == 1,
  );

  DhikrProgress copyWith({
    int? id, int? dhikrId, String? sessionDate,
    String? sessionType, int? currentCount, bool? isCompleted,
  }) => DhikrProgress(
    id:           id ?? this.id,
    dhikrId:      dhikrId ?? this.dhikrId,
    sessionDate:  sessionDate ?? this.sessionDate,
    sessionType:  sessionType ?? this.sessionType,
    currentCount: currentCount ?? this.currentCount,
    isCompleted:  isCompleted ?? this.isCompleted,
  );
}

class DayStats {
  final String date;
  final bool morningDone;
  final bool eveningDone;
  final bool sleepDone;

  const DayStats({
    required this.date,
    this.morningDone = false,
    this.eveningDone = false,
    this.sleepDone = false,
  });

  bool get allDone => morningDone && eveningDone && sleepDone;
}
