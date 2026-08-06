import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom Vedic and Astrological Icons rendered with high precision vector graphics
class VedicIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  final Color color;
  final bool showGlow;

  const VedicIcon({
    super.key,
    required this.iconKey,
    this.size = 32,
    required this.color,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VedicIconPainter(
          iconKey: iconKey,
          color: color,
          showGlow: showGlow,
        ),
      ),
    );
  }
}

class _VedicIconPainter extends CustomPainter {
  final String iconKey;
  final Color color;
  final bool showGlow;

  _VedicIconPainter({
    required this.iconKey,
    required this.color,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.055)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    switch (iconKey) {
      case 'horoscope':
      case 'kundli':
        _drawKundliChart(canvas, size, paint, fillPaint);
        break;
      case 'panchanga':
      case 'muhurta':
        _drawSwastikVedic(canvas, size, paint);
        break;
      case 'gochara':
      case 'planet':
        _drawPlanetOrbit(canvas, size, paint, fillPaint);
        break;
      case 'matching':
        _drawMatchingHearts(canvas, size, paint, fillPaint);
        break;
      case 'calendar_panchanga':
        _drawPanchangCalendar(canvas, size, paint, fillPaint);
        break;
      case 'ephemeris':
        _drawEphemerisStar(canvas, size, paint, fillPaint);
        break;
      case 'gochara_year':
        _drawYearlyGochara(canvas, size, paint, fillPaint);
        break;
      case 'ayanamsa':
        _drawAyanamsaGeometry(canvas, size, paint, fillPaint);
        break;
      case 'widget':
        _drawWidgetGrid(canvas, size, paint, fillPaint);
        break;
      case 'settings':
        _drawSettingsSliders(canvas, size, paint);
        break;
      case 'places':
        _drawLocationPin(canvas, size, paint, fillPaint);
        break;
      case 'about':
        _drawAboutInfo(canvas, size, paint, fillPaint);
        break;
      case 'rate':
        _drawRateStars(canvas, size, paint, fillPaint);
        break;
      case 'share':
        _drawShareNodes(canvas, size, paint);
        break;
      case 'subscribe':
        _drawSubscribeCoin(canvas, size, paint, fillPaint);
        break;
      default:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.4, paint);
    }
  }

  void _drawKundliChart(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final rect = Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.8, size.height * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

    // Kundli inner diagonals
    final p1 = Offset(rect.left, rect.top);
    final p2 = Offset(rect.right, rect.bottom);
    final p3 = Offset(rect.right, rect.top);
    final p4 = Offset(rect.left, rect.bottom);
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p3, p4, paint);

    // Kundli inner diamond
    final midTop = Offset(rect.center.dx, rect.top);
    final midRight = Offset(rect.right, rect.center.dy);
    final midBottom = Offset(rect.center.dx, rect.bottom);
    final midLeft = Offset(rect.left, rect.center.dy);

    final path = Path()
      ..moveTo(midTop.dx, midTop.dy)
      ..lineTo(midRight.dx, midRight.dy)
      ..lineTo(midBottom.dx, midBottom.dy)
      ..lineTo(midLeft.dx, midLeft.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawSwastikVedic(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.width * 0.36;

    // Cross
    canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), paint);
    canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), paint);

    // Hooks
    canvas.drawLine(Offset(cx - arm, cy), Offset(cx - arm, cy - arm * 0.5), paint);
    canvas.drawLine(Offset(cx + arm, cy), Offset(cx + arm, cy + arm * 0.5), paint);
    canvas.drawLine(Offset(cx, cy - arm), Offset(cx + arm * 0.5, cy - arm), paint);
    canvas.drawLine(Offset(cx, cy + arm), Offset(cx - arm * 0.5, cy + arm), paint);

    // 4 Auspicious dots
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    final dotR = size.width * 0.035;
    final d = arm * 0.45;
    canvas.drawCircle(Offset(cx - d, cy - d), dotR, dotPaint);
    canvas.drawCircle(Offset(cx + d, cy - d), dotR, dotPaint);
    canvas.drawCircle(Offset(cx - d, cy + d), dotR, dotPaint);
    canvas.drawCircle(Offset(cx + d, cy + d), dotR, dotPaint);
  }

  void _drawPlanetOrbit(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.26;

    // Planet body
    canvas.drawCircle(Offset(cx, cy), r, fillPaint);
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Orbit Ring (tilted ellipse)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-math.pi / 5.5);
    final ringRect = Rect.fromCenter(center: Offset.zero, width: size.width * 0.9, height: size.height * 0.32);
    canvas.drawOval(ringRect, paint);
    canvas.restore();
  }

  void _drawMatchingHearts(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;

    // Main Heart
    final path = Path();
    path.moveTo(w * 0.5, h * 0.82);
    path.cubicTo(w * 0.15, h * 0.55, w * 0.1, h * 0.3, w * 0.32, h * 0.22);
    path.cubicTo(w * 0.44, h * 0.18, w * 0.5, h * 0.32, w * 0.5, h * 0.32);
    path.cubicTo(w * 0.5, h * 0.32, w * 0.56, h * 0.18, w * 0.68, h * 0.22);
    path.cubicTo(w * 0.9, h * 0.3, w * 0.85, h * 0.55, w * 0.5, h * 0.82);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Tiny satellite heart at top right
    final miniHeart = Path();
    final mx = w * 0.76;
    final my = h * 0.2;
    final ms = 0.28;
    miniHeart.moveTo(mx, my + 10 * ms);
    miniHeart.cubicTo(mx - 8 * ms, my + 4 * ms, mx - 8 * ms, my - 4 * ms, mx - 2 * ms, my - 6 * ms);
    miniHeart.cubicTo(mx, my - 6 * ms, mx, my - 2 * ms, mx, my - 2 * ms);
    miniHeart.cubicTo(mx, my - 2 * ms, mx, my - 6 * ms, mx + 2 * ms, my - 6 * ms);
    miniHeart.cubicTo(mx + 8 * ms, my - 4 * ms, mx + 8 * ms, my + 4 * ms, mx, my + 10 * ms);
    final fillSolid = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawPath(miniHeart, fillSolid);
  }

  void _drawPanchangCalendar(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(w * 0.16, h * 0.2, w * 0.68, h * 0.68);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);

    // Top rings
    canvas.drawLine(Offset(w * 0.32, h * 0.12), Offset(w * 0.32, h * 0.24), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.24), paint);
    canvas.drawLine(Offset(w * 0.68, h * 0.12), Offset(w * 0.68, h * 0.24), paint);

    // Grid dots / Om sign inside calendar
    final dotPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawCircle(Offset(w * 0.32 + c * w * 0.18, h * 0.42 + r * h * 0.18), w * 0.035, dotPaint);
      }
    }
  }

  void _drawEphemerisStar(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final outerR = size.width * 0.36;
    final innerR = size.width * 0.16;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? outerR : innerR;
      final angle = (i * math.pi / 5) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Ephemeris bars inside
    canvas.drawLine(Offset(size.width * 0.38, size.height * 0.42), Offset(size.width * 0.62, size.height * 0.42), paint);
    canvas.drawLine(Offset(size.width * 0.42, size.height * 0.52), Offset(size.width * 0.58, size.height * 0.52), paint);
  }

  void _drawYearlyGochara(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    _drawPlanetOrbit(canvas, size, paint, fillPaint);
    // Add planetary ring dots
    final dotPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.36), size.width * 0.04, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.64), size.width * 0.04, dotPaint);
  }

  void _drawAyanamsaGeometry(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;

    // Angled constellation polygon
    final path = Path()
      ..moveTo(w * 0.28, h * 0.75)
      ..lineTo(w * 0.42, h * 0.25)
      ..lineTo(w * 0.78, h * 0.28)
      ..lineTo(w * 0.65, h * 0.78)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Nodes
    final dotPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.28, h * 0.75), w * 0.05, dotPaint);
    canvas.drawCircle(Offset(w * 0.42, h * 0.25), w * 0.05, dotPaint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.28), w * 0.05, dotPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.78), w * 0.05, dotPaint);

    // Plus/minus symbols for Ayanamsa precession offset
    canvas.drawLine(Offset(w * 0.12, h * 0.35), Offset(w * 0.22, h * 0.35), paint);
    canvas.drawLine(Offset(w * 0.82, h * 0.65), Offset(w * 0.92, h * 0.65), paint);
    canvas.drawLine(Offset(w * 0.87, h * 0.60), Offset(w * 0.87, h * 0.70), paint);
  }

  void _drawWidgetGrid(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;
    final s = w * 0.3;

    // 4 tiles with top-right rotated
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.12, s, s), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.58, s, s), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, h * 0.58, s, s), const Radius.circular(4)), paint);

    // Rotated top-right diamond tile
    canvas.save();
    canvas.translate(w * 0.73, h * 0.27);
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 0.9, height: s * 0.9), const Radius.circular(4)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 0.9, height: s * 0.9), const Radius.circular(4)), paint);
    canvas.restore();
  }

  void _drawSettingsSliders(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    for (int i = 0; i < 3; i++) {
      final y = h * (0.28 + i * 0.22);
      canvas.drawLine(Offset(w * 0.15, y), Offset(w * 0.85, y), paint);
      final knobX = (i == 0) ? w * 0.32 : (i == 1) ? w * 0.68 : w * 0.5;
      final knobPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(knobX, y), w * 0.07, knobPaint);
    }
  }

  void _drawLocationPin(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final r = size.width * 0.26;

    final path = Path();
    path.moveTo(cx, size.height * 0.82);
    path.cubicTo(cx - r * 1.3, cy + r * 0.6, cx - r, cy - r, cx, cy - r);
    path.cubicTo(cx + r, cy - r, cx + r * 1.3, cy + r * 0.6, cx, size.height * 0.82);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Center Plus
    canvas.drawLine(Offset(cx - r * 0.4, cy - r * 0.1), Offset(cx + r * 0.4, cy - r * 0.1), paint);
    canvas.drawLine(Offset(cx, cy - r * 0.5), Offset(cx, cy + r * 0.3), paint);

    // Shadow ground oval
    final groundRect = Rect.fromCenter(center: Offset(cx, size.height * 0.88), width: size.width * 0.6, height: size.height * 0.1);
    canvas.drawOval(groundRect, paint);
  }

  void _drawAboutInfo(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    canvas.drawCircle(Offset(cx, cy), r, fillPaint);
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // 'i' dot and bar
    final dotPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - r * 0.38), size.width * 0.05, dotPaint);
    canvas.drawLine(Offset(cx, cy - r * 0.1), Offset(cx, cy + r * 0.48), paint);
    canvas.drawLine(Offset(cx - size.width * 0.08, cy - r * 0.1), Offset(cx, cy - r * 0.1), paint);
  }

  void _drawRateStars(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final outerR = size.width * 0.32;
    final innerR = size.width * 0.14;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = (i % 2 == 0) ? outerR : innerR;
      final angle = (i * math.pi / 5) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Two smaller side stars
    final dotPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.72), size.width * 0.04, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.72), size.width * 0.04, dotPaint);
  }

  void _drawShareNodes(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.35;

    // Segmented circular arc
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, 0.2, 1.6, false, paint);
    canvas.drawArc(rect, 2.3, 1.6, false, paint);
    canvas.drawArc(rect, 4.4, 1.6, false, paint);

    final dotPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + r * math.cos(0.2), cy + r * math.sin(0.2)), size.width * 0.05, dotPaint);
    canvas.drawCircle(Offset(cx + r * math.cos(2.3), cy + r * math.sin(2.3)), size.width * 0.05, dotPaint);
    canvas.drawCircle(Offset(cx + r * math.cos(4.4), cy + r * math.sin(4.4)), size.width * 0.05, dotPaint);
  }

  void _drawSubscribeCoin(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;

    // Hand reaching for coin
    final path = Path();
    path.moveTo(w * 0.85, h * 0.45);
    path.lineTo(w * 0.65, h * 0.25);
    path.lineTo(w * 0.38, h * 0.42);
    path.lineTo(w * 0.25, h * 0.58);
    path.lineTo(w * 0.42, h * 0.68);
    path.lineTo(w * 0.65, h * 0.52);

    canvas.drawPath(path, paint);

    // Coin
    final coinRect = Rect.fromCenter(center: Offset(w * 0.28, h * 0.72), width: w * 0.24, height: h * 0.24);
    canvas.drawOval(coinRect, fillPaint);
    canvas.drawOval(coinRect, paint);
  }

  @override
  bool shouldRepaint(covariant _VedicIconPainter oldDelegate) {
    return oldDelegate.iconKey != iconKey ||
        oldDelegate.color != color ||
        oldDelegate.showGlow != showGlow;
  }
}
