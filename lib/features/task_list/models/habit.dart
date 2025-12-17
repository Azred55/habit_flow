import 'package:hive_ce/hive.dart';

class Habit extends HiveObject {
  Habit({
    required this.title,
    this.lastCompletionDate,
    this.streakCount = 0,
  });

  static const boxName = 'habits';

  String title;
  DateTime? lastCompletionDate;
  int streakCount;

  bool get isCompletedToday {
    if (lastCompletionDate == null) {
      return false;
    }
    return _isSameDay(lastCompletionDate!, DateTime.now());
  }

  int get currentStreak {
    if (lastCompletionDate == null) {
      return 0;
    }
    final today = _normalizeDate(DateTime.now());
    final last = _normalizeDate(lastCompletionDate!);
    final difference = today.difference(last).inDays;
    if (difference > 1) {
      return 0;
    }
    return streakCount;
  }

  void markCompletedToday() {
    final today = _normalizeDate(DateTime.now());
    final last = lastCompletionDate != null ? _normalizeDate(lastCompletionDate!) : null;
    final streakBase = currentStreak;

    if (last != null && _isSameDay(last, today.subtract(const Duration(days: 1)))) {
      streakCount = streakBase + 1;
    } else if (last != null && _isSameDay(last, today)) {
      // Already completed today; nothing to do.
      return;
    } else {
      streakCount = 1;
    }

    lastCompletionDate = today;
  }

  void resetCompletion() {
    lastCompletionDate = null;
    streakCount = 0;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final title = fields[0] as String;
    final rawCompletion = fields[1];
    final rawStreak = fields[2];

    DateTime? lastCompletion;
    if (rawCompletion is DateTime) {
      lastCompletion = rawCompletion;
    } else if (rawCompletion is bool && rawCompletion) {
      lastCompletion = Habit._normalizeDate(DateTime.now());
    }

    final streak = rawStreak is int ? rawStreak : (lastCompletion != null ? 1 : 0);

    return Habit(
      title: title,
      lastCompletionDate: lastCompletion,
      streakCount: streak,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.lastCompletionDate)
      ..writeByte(2)
      ..write(obj.streakCount);
  }
}
