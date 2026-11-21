import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:game_047_fishing_simulator/game/fish_engine.dart';
import 'package:game_047_fishing_simulator/game/rules.dart';

void main() {
  final rules = FishRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('holding lowers the hook to the finger, releasing reels it in', () {
    final s = FishSim(rules.build(planner.spec(1)).puzzle);
    for (var i = 0; i < 80; i++) {
      s.tick(const ArcadeInput(down: true, x: 500, y: 1000));
    }
    expect(s.hookY, greaterThan(900));
    for (var i = 0; i < 120; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.hookY, closeTo(kSurface, 1));
  });

  test('a hooked fish brought to the surface adds its weight', () {
    final s = FishSim(rules.build(planner.spec(1)).puzzle);
    s.carrying = 3;
    s.hookY = kSurface + 5;
    s.tick(ArcadeInput.idle);
    expect(s.caught, 1);
    expect(s.grams, 6000);
  });

  test('goal levels have a reachable weight target and a time limit', () {
    for (var n = 1; n < 300; n += 37) {
      final l = rules.build(planner.spec(n)).puzzle;
      expect(l.targetGrams, greaterThan(0));
      expect(l.limitTicks, greaterThan(0));
      final s = FishSim(l);
      expect(runBot(s, rules.bot, l.limitTicks + 60).won, isTrue, reason: 'level $n');
    }
  });

  test('calm water booster slows the fish down', () {
    final a = FishSim(rules.build(planner.spec(5)).puzzle);
    final b = FishSim(rules.build(planner.spec(5)).puzzle);
    expect(b.useBooster(), isTrue);
    a.tick(ArcadeInput.idle);
    b.tick(ArcadeInput.idle);
    expect((b.swim.first.x - a.swim.first.x).abs(), greaterThan(0));
  });
}
