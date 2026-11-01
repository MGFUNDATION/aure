import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

/// Estadísticas de escucha y bienestar, guardadas solo en el dispositivo.
class StatsStore extends ChangeNotifier {
  StatsStore(this._prefs) {
    final raw = _prefs.getString('stats');
    if (raw != null) _data = jsonDecode(raw) as Map<String, dynamic>;
  }

  final SharedPreferences _prefs;
  Map<String, dynamic> _data = {};
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, dynamic> _bucket(String key) =>
      (_data[key] ??= <String, dynamic>{}) as Map<String, dynamic>;

  List<dynamic> _list(String key) =>
      (_data[key] ??= <dynamic>[]) as List<dynamic>;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _inc(String bucket, String key, num by) {
    final b = _bucket(bucket);
    b[key] = ((b[key] as num?) ?? 0) + by;
  }

  void recordPlay(Track t) {
    _inc('plays', '${t.id}', 1);
    _list('history').insert(0, {
      'id': t.id,
      'title': t.title,
      'artist': t.displayArtist,
      'at': DateTime.now().toIso8601String(),
    });
    final h = _list('history');
    if (h.length > 200) h.removeRange(200, h.length);
    _persist(force: true);
  }

  void addListening(Track t, int seconds, {String? envId}) {
    _inc('daily', dayKey(DateTime.now()), seconds);
    _inc('trackSecs', '${t.id}', seconds);
    _inc('artistSecs', t.displayArtist, seconds);
    if (t.genre != null && t.genre!.isNotEmpty) {
      _inc('genreSecs', t.genre!, seconds);
    }
    if (envId != null) _inc('envSecs', envId, seconds);
    _inc('hourSecs', '${DateTime.now().hour}', seconds);
    _persist();
  }

  void addFocusSession(int minutes) {
    _inc('focusDaily', dayKey(DateTime.now()), minutes);
    _inc('focusCount', dayKey(DateTime.now()), 1);
    _inc('counters', 'focusSessions', 1);
    _persist(force: true);
  }

  void logMood(String mood) {
    _list(
      'moods',
    ).insert(0, {'mood': mood, 'at': DateTime.now().toIso8601String()});
    _persist(force: true);
  }

  void _persist({bool force = false}) {
    notifyListeners();
    final now = DateTime.now();
    if (force || now.difference(_lastSave).inSeconds > 30) {
      _lastSave = now;
      _prefs.setString('stats', jsonEncode(_data));
    }
  }

  // ---------- Lecturas ----------

  /// Minutos escuchados por día en los últimos [days] días (más antiguo primero).
  List<MapEntry<DateTime, double>> lastDays(
    int days, {
    String bucket = 'daily',
  }) {
    final b = _bucket(bucket);
    final today = DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(today.year, today.month, today.day - (days - 1 - i));
      final v = ((b[dayKey(d)] as num?) ?? 0).toDouble();
      return MapEntry(d, bucket == 'daily' ? v / 60 : v);
    });
  }

  double minutesInRange(int days, {int offsetDays = 0}) {
    final b = _bucket('daily');
    final today = DateTime.now();
    var total = 0.0;
    for (var i = offsetDays; i < offsetDays + days; i++) {
      final d = DateTime(today.year, today.month, today.day - i);
      total += ((b[dayKey(d)] as num?) ?? 0).toDouble();
    }
    return total / 60;
  }

  double dayValue(String bucket, DateTime d) =>
      ((_bucket(bucket)[dayKey(d)] as num?) ?? 0).toDouble();

  /// Valores lunes→domingo de una semana (0 = esta, 1 = la pasada…).
  List<double> week(String bucket, {int weeksAgo = 0}) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1) - 7 * weeksAgo,
    );
    return List.generate(
      7,
      (i) =>
          dayValue(bucket, DateTime(monday.year, monday.month, monday.day + i)),
    );
  }

  /// Suma de un contador diario en [days] días, empezando hace [offsetDays].
  double sumRange(String bucket, int days, {int offsetDays = 0}) {
    final b = _bucket(bucket);
    final today = DateTime.now();
    var total = 0.0;
    for (var i = offsetDays; i < offsetDays + days; i++) {
      final d = DateTime(today.year, today.month, today.day - i);
      total += ((b[dayKey(d)] as num?) ?? 0).toDouble();
    }
    return total;
  }

  double get totalMinutes =>
      _bucket('daily').values.fold<double>(0, (a, b) => a + (b as num)) / 60;

  int get totalPlays =>
      _bucket('plays').values.fold<int>(0, (a, b) => a + (b as num).toInt());

  int get focusSessions =>
      ((_bucket('counters')['focusSessions'] as num?) ?? 0).toInt();

  List<MapEntry<String, double>> top(String bucket, {int n = 5}) {
    final e =
        _bucket(bucket).entries
            .map((e) => MapEntry(e.key, (e.value as num).toDouble()))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return e.take(n).toList();
  }

  List<Map<String, dynamic>> get history =>
      _list('history').cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get moods =>
      _list('moods').cast<Map<String, dynamic>>();

  /// Hora del día en que más escuchas (0-23), o null.
  int? get peakHour {
    final t = top('hourSecs', n: 1);
    return t.isEmpty ? null : int.parse(t.first.key);
  }
}
