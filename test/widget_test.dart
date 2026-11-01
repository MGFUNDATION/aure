import 'package:aure/services/lyrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea letras LRC sincronizadas', () {
    final l = LyricsService.parse(
      '[ar:Artista]\n[00:12.50]Primera línea\n[00:05.00]Intro\n[01:02.3]Final',
      source: 'test',
    );
    expect(l.synced, isTrue);
    expect(l.lines.map((e) => e.text), ['Intro', 'Primera línea', 'Final']);
    expect(l.lines[1].time, const Duration(seconds: 12, milliseconds: 500));
    expect(l.lines[2].time, const Duration(minutes: 1, seconds: 2, milliseconds: 300));
  });

  test('letras sin tiempos', () {
    final l = LyricsService.parse('Hola\nMundo', source: 'test');
    expect(l.synced, isFalse);
    expect(l.lines.length, 2);
  });
}
