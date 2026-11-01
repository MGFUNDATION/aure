import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/environment.dart';

/// Dibuja un paisaje para un entorno, o la imagen propia del usuario si existe.
class SceneView extends StatelessWidget {
  const SceneView({
    super.key,
    required this.env,
    this.customImagePath,
    this.brightness = 1.0,
    this.tint,
    this.borderRadius = 0,
    this.child,
  });

  final AureEnvironment env;
  final String? customImagePath;

  /// 0.3 (oscuro) – 1.3 (brillante). Control de "Iluminación".
  final double brightness;
  final Color? tint;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Widget base;
    final path = customImagePath;
    if (path != null && File(path).existsSync()) {
      base = Image.file(File(path), fit: BoxFit.cover);
    } else {
      base = CustomPaint(painter: _ScenePainter(env), size: Size.infinite);
    }
    final dim = (1 - brightness).clamp(-0.3, 0.7);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          base,
          if (tint != null) ColoredBox(color: tint!.withValues(alpha: 0.18)),
          if (dim > 0)
            ColoredBox(color: Colors.black.withValues(alpha: dim))
          else if (dim < 0)
            ColoredBox(color: Colors.white.withValues(alpha: -dim)),
          ?child,
        ],
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.env);
  final AureEnvironment env;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rnd = Random(env.id.hashCode);

    // Cielo
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: env.sky,
        ).createShader(Offset.zero & size),
    );

    // Estrellas
    if (env.stars) {
      final p = Paint()..color = Colors.white;
      for (var i = 0; i < 70; i++) {
        p.color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble() * 0.7);
        canvas.drawCircle(
          Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.6),
          rnd.nextDouble() * 1.4 + 0.3,
          p,
        );
      }
    }

    // Aurora boreal
    if (env.kind == SceneKind.aurora) {
      for (var i = 0; i < 3; i++) {
        final path = Path()..moveTo(0, h * (0.25 + i * 0.07));
        for (var x = 0.0; x <= w; x += w / 8) {
          path.lineTo(
            x,
            h * (0.22 + i * 0.07) + sin(x / w * pi * 2 + i) * h * 0.06,
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = h * 0.08
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
            ..color =
                (i.isEven ? const Color(0xFF3DFFB0) : const Color(0xFF9B6BFF))
                    .withValues(alpha: 0.35),
        );
      }
    }

    // Sol / luna
    final night = env.stars || env.kind == SceneKind.city;
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.22),
      h * 0.07,
      Paint()
        ..color = night ? const Color(0xFFF5F0FF) : const Color(0xFFFFF3C4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Montañas al fondo (2 capas)
    _mountains(
      canvas,
      size,
      rnd,
      h * 0.48,
      h * 0.18,
      Color.lerp(env.sky.last, env.ground, 0.45)!,
    );
    _mountains(
      canvas,
      size,
      rnd,
      h * 0.6,
      h * 0.14,
      Color.lerp(env.sky.last, env.ground, 0.75)!,
    );

    switch (env.kind) {
      case SceneKind.city:
        _city(canvas, size, rnd);
      case SceneKind.beach:
        _water(canvas, size, env.ground);
      default:
        break;
    }

    // Suelo
    final ground = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.72, w, h * 0.8)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = env.ground);

    if (env.kind == SceneKind.forest ||
        env.kind == SceneKind.cabin ||
        env.kind == SceneKind.winter ||
        env.kind == SceneKind.aurora ||
        env.kind == SceneKind.mountain) {
      final treeColor = env.kind == SceneKind.winter
          ? const Color(0xFF51677A)
          : Color.lerp(env.ground, Colors.black, 0.35)!;
      for (var i = 0; i < 14; i++) {
        final x = rnd.nextDouble() * w;
        if (env.kind == SceneKind.cabin && (x - w * 0.5).abs() < w * 0.15) {
          continue;
        }
        _tree(
          canvas,
          Offset(x, h * (0.8 + rnd.nextDouble() * 0.12)),
          h * (0.12 + rnd.nextDouble() * 0.16),
          treeColor,
        );
      }
    }
    if (env.kind == SceneKind.cabin) _cabin(canvas, size);
  }

  void _mountains(
    Canvas c,
    Size s,
    Random r,
    double base,
    double amp,
    Color col,
  ) {
    final p = Path()..moveTo(0, s.height);
    p.lineTo(0, base);
    var x = 0.0;
    while (x < s.width) {
      final step = s.width * (0.12 + r.nextDouble() * 0.15);
      p.lineTo(x + step / 2, base - amp * (0.4 + r.nextDouble() * 0.6));
      x += step;
      p.lineTo(x, base);
    }
    p.lineTo(s.width, s.height);
    p.close();
    c.drawPath(p, Paint()..color = col);
  }

  void _tree(Canvas c, Offset base, double height, Color col) {
    final w = height * 0.38;
    final p = Path()
      ..moveTo(base.dx, base.dy - height)
      ..lineTo(base.dx - w / 2, base.dy)
      ..lineTo(base.dx + w / 2, base.dy)
      ..close();
    c.drawPath(p, Paint()..color = col);
  }

  void _city(Canvas c, Size s, Random r) {
    var x = 0.0;
    while (x < s.width) {
      final bw = s.width * (0.06 + r.nextDouble() * 0.08);
      final bh = s.height * (0.2 + r.nextDouble() * 0.35);
      final rect = Rect.fromLTWH(x, s.height * 0.8 - bh, bw, bh);
      c.drawRect(rect, Paint()..color = const Color(0xFF151632));
      final win = Paint();
      for (var y = rect.top + 6; y < rect.bottom - 6; y += 9) {
        for (var wx = rect.left + 4; wx < rect.right - 4; wx += 7) {
          if (r.nextDouble() < 0.35) {
            win.color =
                (r.nextBool()
                        ? const Color(0xFFFFC46B)
                        : const Color(0xFFB57BFF))
                    .withValues(alpha: 0.8);
            c.drawRect(Rect.fromLTWH(wx, y, 3, 4), win);
          }
        }
      }
      x += bw + 2;
    }
  }

  void _water(Canvas c, Size s, Color col) {
    c.drawRect(
      Rect.fromLTWH(0, s.height * 0.6, s.width, s.height * 0.4),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [col.withValues(alpha: 0.8), col],
            ).createShader(
              Rect.fromLTWH(0, s.height * 0.6, s.width, s.height * 0.4),
            ),
    );
  }

  void _cabin(Canvas c, Size s) {
    final cx = s.width * 0.5, by = s.height * 0.82, w = s.width * 0.16;
    c.drawRect(
      Rect.fromLTWH(cx - w / 2, by - w * 0.6, w, w * 0.6),
      Paint()..color = const Color(0xFF3B2A22),
    );
    final roof = Path()
      ..moveTo(cx - w * 0.62, by - w * 0.6)
      ..lineTo(cx, by - w * 1.05)
      ..lineTo(cx + w * 0.62, by - w * 0.6)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFF241812));
    c.drawRect(
      Rect.fromLTWH(cx - w * 0.3, by - w * 0.42, w * 0.18, w * 0.16),
      Paint()
        ..color = const Color(0xFFFFB347)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.drawRect(
      Rect.fromLTWH(cx + w * 0.1, by - w * 0.42, w * 0.18, w * 0.16),
      Paint()
        ..color = const Color(0xFFFFB347)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.env.id != env.id;
}
