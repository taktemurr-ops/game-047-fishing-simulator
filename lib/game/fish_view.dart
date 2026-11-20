import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/arcade_stage.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/arcade.dart';
import 'fish_engine.dart';

void paintFish(Canvas c, ArcadeSim sim, ArcadePalette p, double t, bool tr) {
  final s = sim as FishSim;
  final night = s.level.night;
  final sky = const Rect.fromLTWH(0, 0, kWorldW, kSurface);
  c.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? [const Color(0xFF03045E), const Color(0xFF023E8A)] : [const Color(0xFF8ECAE6), const Color(0xFFCAF0F8)],
        ).createShader(sky));
  c.drawCircle(const Offset(820, 170), 60, Paint()..color = night ? const Color(0xFFF1FAEE) : const Color(0xFFFFD166));
  final water = const Rect.fromLTWH(0, kSurface, kWorldW, kWorldH - kSurface);
  c.drawRect(
      water,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? [const Color(0xFF023E8A), const Color(0xFF03045E)] : [const Color(0xFF00B4D8), const Color(0xFF023E8A)],
        ).createShader(water));
  // waves
  final wave = Path()..moveTo(0, kSurface);
  for (var x = 0.0; x <= kWorldW; x += 20) {
    wave.lineTo(x, kSurface + math.sin(x / 60 + (p.reducedMotion ? 0 : t * 2)) * 6);
  }
  c.drawPath(wave, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..color = Colors.white54);
  // sea floor
  final floor = Path()..moveTo(0, kWorldH);
  for (var x = 0.0; x <= kWorldW; x += 25) {
    floor.lineTo(x, kBottom + 30 + math.sin(x / 90) * 20);
  }
  floor
    ..lineTo(kWorldW, kWorldH)
    ..close();
  c.drawPath(floor, Paint()..color = const Color(0xFFDDB892));
  for (var i = 0; i < 7; i++) {
    final x = 70 + i * 140.0;
    final sway = p.reducedMotion ? 0.0 : math.sin(t * 1.5 + i) * 12;
    c.drawLine(Offset(x, kBottom + 40), Offset(x + sway, kBottom - 90), Paint()
      ..color = const Color(0xFF2D6A4F)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round);
  }
  // swimmers
  for (final o in s.swim) {
    c.save();
    c.translate(o.x, o.y);
    if (o.vx < 0) c.scale(-1, 1);
    if (o.kind < 5) {
      final f = fishKinds[o.kind];
      final r = f.size;
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.1), Paint()..color = Color(f.color));
      c.drawPath(
          Path()
            ..moveTo(-r * 0.9, 0)
            ..lineTo(-r * 1.6, -r * 0.6)
            ..lineTo(-r * 1.6, r * 0.6)
            ..close(),
          Paint()..color = Color(f.color));
      c.drawCircle(Offset(r * 0.55, -r * 0.15), r * 0.16, Paint()..color = Colors.white);
      c.drawCircle(Offset(r * 0.6, -r * 0.15), r * 0.08, Paint()..color = Colors.black);
      if (o.kind == 4) {
        c.drawCircle(Offset.zero, r * 1.4, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0x88FFD60A));
      }
    } else if (o.kind == kShark) {
      c.drawPath(
          Path()
            ..moveTo(90, 0)
            ..quadraticBezierTo(20, -45, -70, -10)
            ..lineTo(-110, -40)
            ..lineTo(-100, 0)
            ..lineTo(-110, 40)
            ..lineTo(-70, 10)
            ..quadraticBezierTo(20, 40, 90, 0)
            ..close(),
          Paint()..color = const Color(0xFF6C757D));
      c.drawPath(
          Path()
            ..moveTo(0, -30)
            ..lineTo(20, -70)
            ..lineTo(35, -25)
            ..close(),
          Paint()..color = const Color(0xFF495057));
      c.drawCircle(const Offset(55, -8), 5, Paint()..color = Colors.black);
    } else if (o.kind == kJelly) {
      c.drawArc(const Rect.fromLTWH(-34, -30, 68, 60), math.pi, math.pi, true, Paint()..color = const Color(0xBBF72585));
      for (var k = 0; k < 4; k++) {
        final x = -24 + k * 16.0;
        c.drawLine(Offset(x, 0), Offset(x + math.sin(t * 3 + k) * 6, 40), Paint()
          ..color = const Color(0x99F72585)
          ..strokeWidth = 4);
      }
    } else {
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -30, 30, 50), const Radius.circular(6)), Paint()..color = const Color(0xFF5C4033));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-24, 8, 52, 18), const Radius.circular(6)), Paint()..color = const Color(0xFF5C4033));
    }
    c.restore();
  }
  // boat, line and hook
  c.drawLine(Offset(s.boatX + 40, kBoatY - 40), Offset(s.hookX, s.hookY), Paint()
    ..color = Colors.white70
    ..strokeWidth = 3);
  c.drawPath(
      Path()
        ..moveTo(s.boatX - 110, kBoatY)
        ..lineTo(s.boatX + 110, kBoatY)
        ..lineTo(s.boatX + 80, kBoatY + 50)
        ..lineTo(s.boatX - 80, kBoatY + 50)
        ..close(),
      Paint()..color = const Color(0xFFE76F51));
  c.drawRect(Rect.fromLTWH(s.boatX - 40, kBoatY - 50, 50, 50), Paint()..color = Colors.white);
  c.drawCircle(Offset(s.boatX - 15, kBoatY - 75), 22, Paint()..color = const Color(0xFFFFD6A5));
  c.drawLine(Offset(s.boatX - 5, kBoatY - 60), Offset(s.boatX + 40, kBoatY - 40), Paint()
    ..color = const Color(0xFF6F4E37)
    ..strokeWidth = 6);
  c.drawCircle(Offset(s.hookX, s.hookY), 10, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..color = const Color(0xFFADB5BD));
  if (s.carrying >= 0) {
    c.save();
    c.translate(s.hookX, s.hookY + 30);
    c.rotate(math.pi / 2);
    if (s.carrying < 5) {
      final f = fishKinds[s.carrying];
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: f.size * 2, height: f.size * 1.1), Paint()..color = Color(f.color));
    } else {
      c.drawRect(const Rect.fromLTWH(-20, -20, 40, 40), Paint()..color = const Color(0xFF5C4033));
    }
    c.restore();
  }
  if (s.shield > 0) {
    c.drawCircle(Offset(s.hookX, s.hookY), 60, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xAA8ECAE6));
  }
  if (night) {
    c.drawRect(const Rect.fromLTWH(0, kSurface, kWorldW, kWorldH - kSurface), Paint()..color = const Color(0x66000814));
    c.drawCircle(Offset(s.hookX, s.hookY), 160, Paint()..color = const Color(0x22FFF3B0));
  }
  // HUD
  c.drawRect(const Rect.fromLTWH(0, 0, kWorldW, 120), Paint()..color = Colors.black38);
  paintText(c, s.goalText, const Offset(220, 60), 42, Colors.white);
  paintText(c, '🐟 ${s.caught}', const Offset(560, 60), 42, const Color(0xFFFFD60A));
  if (s.level.limitTicks > 0) paintText(c, '⏱ ${s.secondsLeft}', const Offset(850, 60), 42, Colors.white);
  for (var i = 0; i < s.lives.clamp(0, 5); i++) {
    c.drawCircle(Offset(40 + i * 36.0, 150), 13, Paint()..color = const Color(0xFFEF476F));
  }
  paintText(c, tr ? 'Basılı tut: oltayı indir · Bırak: çek' : 'Hold: lower the hook · Release: reel in', const Offset(500, 1560), 30, Colors.white70);
}

Sfx? fishSound(ArcadeSim sim) => switch ((sim as FishSim).lastEvent) {
      1 => Sfx.tap,
      2 => Sfx.coin,
      3 => Sfx.error,
      4 => Sfx.lose,
      5 => Sfx.place,
      _ => null,
    };
