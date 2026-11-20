import 'dart:math' as math;

import '../core/arcade.dart';
import '../core/level_plan.dart';
import '../core/rng.dart';

/// Fishing engine: hold the finger where the hook should go (the boat
/// follows sideways, the hook sinks to the finger's depth); release to reel
/// in. Hook a fish, bring it to the surface, avoid jellyfish and sharks.

const double kSurface = 420;
const double kBottom = 1480;
const double kBoatY = 360;

class FishKind {
  final String tr, en;
  final double weight; // kg
  final double speed;
  final double size;
  final int color;
  final double minDepth, maxDepth; // 0..1 of the water column
  const FishKind(this.tr, this.en, this.weight, this.speed, this.size, this.color, this.minDepth, this.maxDepth);
}

const fishKinds = [
  FishKind('Hamsi', 'Anchovy', 0.4, 2.2, 28, 0xFF90E0EF, 0.0, 0.35),
  FishKind('Çipura', 'Sea bream', 1.2, 2.0, 40, 0xFFE9C46A, 0.15, 0.55),
  FishKind('Levrek', 'Sea bass', 2.5, 2.6, 50, 0xFF8D99AE, 0.3, 0.75),
  FishKind('Orkinos', 'Tuna', 6.0, 3.4, 70, 0xFF457B9D, 0.55, 1.0),
  FishKind('Altın balık', 'Golden fish', 4.0, 3.8, 36, 0xFFFFD60A, 0.2, 0.9),
];

const int kJelly = 10, kShark = 11, kBoot = 12;

class Swimmer {
  final int kind; // 0..4 fish, 10 jelly, 11 shark, 12 boot
  double x, y, vx;
  bool alive = true;
  final double phase;
  Swimmer(this.kind, this.x, this.y, this.vx, this.phase);
  Swimmer clone() => Swimmer(kind, x, y, vx, phase)..alive = alive;
  bool get isFish => kind < 5;
  double get size => isFish ? fishKinds[kind].size : (kind == kShark ? 80 : (kind == kJelly ? 34 : 30));
}

class FishLevel {
  final ArcadeMeta meta;
  final int targetGrams; // 0 = endless
  final int limitTicks; // goal modes
  final bool sharks, jelly, current, junk, night;
  final double spawnEvery;
  const FishLevel(this.meta, this.targetGrams, this.limitTicks, this.sharks, this.jelly, this.current, this.junk, this.night, this.spawnEvery);
  FishLevel withTarget(int t) => FishLevel(meta, t, limitTicks, sharks, jelly, current, junk, night, spawnEvery);
}

FishLevel generateFishLevel(LevelSpec s) {
  final m = ArcadeMeta.of(s);
  final d = s.difficulty;
  var l = FishLevel(
    m,
    m.goal ? 1 : 0,
    m.goal ? (60 + d * 6) * 60 : 0,
    s.has('sharks') || d >= 6,
    s.has('jelly') || d >= 3,
    s.has('current'),
    s.has('junk'),
    s.has('night'),
    math.max(26.0, 60 - d * 3.0),
  );
  if (m.goal) {
    final p = FishSim(l.withTarget(1 << 30))..probe = true;
    runBot(p, fishBot, l.limitTicks + 10);
    l = l.withTarget(math.max(400, (p.grams * (0.5 + 0.035 * d)).floor()));
  }
  return l;
}

class FishSim extends ArcadeSim {
  final FishLevel level;
  double boatX = 500;
  double hookX = 500, hookY = kSurface;
  int carrying = -1; // kind of hooked fish
  List<Swimmer> swim = [];
  int nextSpawn = 0;
  int spawnIndex = 0;
  int grams = 0, caught = 0, golden = 0, lost = 0;
  int calm = 0; // booster: fish slow down
  int lastEvent = 0; // 1 bite, 2 caught, 3 lost fish, 4 line cut, 5 junk
  bool probe = false;

  FishSim(this.level) : super(level.meta) {
    // a few fish from the start
    for (var i = 0; i < 6; i++) {
      _spawn();
    }
  }

  FishSim._(this.level, FishSim o) : super(o.meta) {
    boatX = o.boatX;
    hookX = o.hookX;
    hookY = o.hookY;
    carrying = o.carrying;
    swim = [for (final s in o.swim) s.clone()];
    nextSpawn = o.nextSpawn;
    spawnIndex = o.spawnIndex;
    grams = o.grams;
    caught = o.caught;
    golden = o.golden;
    lost = o.lost;
    calm = o.calm;
    probe = o.probe;
    ticks = o.ticks;
    score = o.score;
    lives = o.lives;
    revives = o.revives;
    shield = o.shield;
    slow = o.slow;
  }

  FishSim copy() => FishSim._(level, this);

  void _spawn() {
    final k = spawnIndex++;
    final rr = SeededRandom(mixSeed([meta.seed, k, 4747]));
    final d = meta.difficulty;
    final w = [
      6,
      5,
      4,
      2 + d ~/ 3,
      1,
      level.jelly ? 2 + d ~/ 3 : 0,
      level.sharks && k % 3 == 0 ? 2 : 0,
      level.junk ? 2 : 0,
    ];
    final pick = rr.weighted(w);
    final kind = pick < 5 ? pick : (pick == 5 ? kJelly : (pick == 6 ? kShark : kBoot));
    double depth;
    double speed;
    if (kind < 5) {
      final f = fishKinds[kind];
      depth = f.minDepth + rr.nextDouble() * (f.maxDepth - f.minDepth);
      speed = f.speed * (0.8 + rr.nextDouble() * 0.4) * (level.current ? 1.3 : 1) * (1 + d * 0.03);
    } else if (kind == kShark) {
      depth = 0.35 + rr.nextDouble() * 0.6;
      speed = 3.2 + d * 0.15;
    } else if (kind == kJelly) {
      depth = 0.1 + rr.nextDouble() * 0.85;
      speed = 0.8;
    } else {
      depth = 0.6 + rr.nextDouble() * 0.4;
      speed = 1.0;
    }
    final fromLeft = rr.chance(0.5);
    final y = kSurface + 60 + depth * (kBottom - kSurface - 120);
    swim.add(Swimmer(kind, fromLeft ? -60 : 1060, y, fromLeft ? speed : -speed, rr.nextDouble() * 6.28));
  }

  bool get timeOver => level.limitTicks > 0 && ticks >= level.limitTicks;

  int get secondsLeft => level.limitTicks == 0 ? 0 : math.max(0, (level.limitTicks - ticks) ~/ 60);

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    if (ticks >= nextSpawn) {
      _spawn();
      final rr = SeededRandom(mixSeed([meta.seed, spawnIndex, 99]));
      nextSpawn = ticks + (level.spawnEvery * (0.6 + rr.nextDouble() * 0.8)).round();
    }
    if (calm > 0) calm--;
    // controls
    final heavy = carrying >= 0 ? (carrying < 5 ? fishKinds[carrying].weight : 0.5) : 0.0;
    var tx = boatX;
    var down = false;
    double ty = kSurface;
    if (input.down && input.x >= 0) {
      tx = input.x;
      ty = clampD(input.y, kSurface, kBottom - 30);
      down = true;
    }
    if (input.dirX != 0) tx = boatX + input.dirX * 200;
    if (input.dirY > 0) {
      down = true;
      ty = kBottom;
    }
    boatX = clampD(moveToward(boatX, tx, 7), 60, 940);
    hookX = moveToward(hookX, boatX, 9);
    if (down && carrying < 0) {
      hookY = moveToward(hookY, ty, 9);
    } else {
      hookY = moveToward(hookY, kSurface, carrying >= 0 ? 10 - math.min(6.0, heavy) : 14);
    }
    // swimmers
    final f = calm > 0 ? 0.35 : 1.0;
    for (final s in swim) {
      s.x += s.vx * f;
      if (s.kind == kJelly) s.y += math.sin(ticks / 40 + s.phase) * 0.8;
      if (s.kind < 5) s.y += math.sin(ticks / 30 + s.phase) * 0.6;
      if (s.x < -120 || s.x > 1120) s.alive = false;
    }
    // interactions
    for (final s in swim) {
      if (!s.alive) continue;
      final dx = s.x - hookX, dy = s.y - hookY;
      final dist = math.sqrt(dx * dx + dy * dy);
      final r = s.size * 0.7 + 14;
      if (s.kind == kShark) {
        // a shark cuts the line anywhere along it
        final onLine = (s.x - hookX).abs() < s.size * 0.6 && s.y > kSurface && s.y < hookY + 20;
        if (onLine && shield == 0 && !meta.zen) {
          s.alive = false;
          if (carrying >= 0) lost++;
          carrying = -1;
          hookY = kSurface;
          lastEvent = 4;
          hit();
        }
        continue;
      }
      if (dist > r) continue;
      if (s.kind == kJelly) {
        if (carrying >= 0) {
          carrying = -1;
          lost++;
          lastEvent = 3;
        }
        continue;
      }
      if (carrying < 0) {
        s.alive = false;
        carrying = s.kind;
        lastEvent = s.kind == kBoot ? 5 : 1;
      }
    }
    swim.removeWhere((s) => !s.alive);
    // landed?
    if (carrying >= 0 && hookY <= kSurface + 1) {
      if (carrying < 5) {
        final g = (fishKinds[carrying].weight * 1000).round();
        grams += g;
        caught++;
        if (carrying == 4) golden++;
        score += g ~/ 10;
        lastEvent = 2;
      }
      carrying = -1;
    }
    if (meta.goal && !probe) {
      if (grams >= level.targetGrams) {
        win();
      } else if (timeOver) {
        shield = 0;
        lives = 1;
        hit();
      }
    } else if (probe && timeOver) {
      win();
    }
  }

  @override
  void hit() {
    if (meta.zen) return;
    super.hit();
  }

  @override
  void revive() {
    super.revive();
    if (timeOver) {
      // continue: 20 more seconds on the clock
      ticks = level.limitTicks - 20 * 60;
    }
  }

  /// Booster: calm water — fish swim slowly for 6 s (plus a short shield).
  @override
  bool useBooster() {
    if (over) return false;
    calm = 360;
    shield = 360;
    return true;
  }

  @override
  double get progress => level.targetGrams <= 1 ? 0 : (grams / level.targetGrams).clamp(0.0, 1.0);

  String kg(int g) => (g / 1000).toStringAsFixed(1);

  @override
  String get goalText => level.targetGrams <= 1 ? '${kg(grams)} kg' : '${kg(grams)}/${kg(level.targetGrams)} kg';

  @override
  Map<String, int> get stats => {'fish_caught': caught, 'weight_kg': grams ~/ 1000, 'golden_fish': golden};

  @override
  int get stars => lifeStars(this, 3);
}

/// Autopilot: aims at the most valuable reachable fish, leads moving
/// targets, reels in as soon as something bites and keeps away from sharks.
ArcadeInput fishBot(ArcadeSim sim) {
  final s = sim as FishSim;
  if (s.carrying >= 0) {
    // reel; dodge a shark by shifting the boat
    for (final o in s.swim) {
      if (o.kind == kShark && (o.x + o.vx * 30 - s.hookX).abs() < 140 && o.y < s.hookY + 40) {
        return ArcadeInput(dirX: o.vx > 0 ? -1 : 1);
      }
    }
    return ArcadeInput.idle;
  }
  Swimmer? best;
  var bestV = 0.0;
  for (final o in s.swim) {
    if (!o.isFish || o.x < 30 || o.x > 970) continue;
    final t = ((o.y - s.hookY).abs() / 9 + (o.x - s.hookX).abs() / 7) + 4;
    final px = o.x + o.vx * t;
    if (px < 40 || px > 960) continue;
    var danger = false;
    for (final h in s.swim) {
      if (h.kind == kShark && (h.x + h.vx * t - px).abs() < 180) danger = true;
      if (h.kind == kJelly && (h.x + h.vx * t - px).abs() < 70 && (h.y - o.y).abs() < 220) danger = true;
    }
    if (danger) continue;
    final v = fishKinds[o.kind].weight / (t + (o.y - kSurface) / 10);
    if (v > bestV) {
      bestV = v;
      best = o;
    }
  }
  if (best == null) return ArcadeInput(down: true, x: s.boatX.roundToDouble(), y: kSurface + 200);
  final t = ((best.y - s.hookY).abs() / 9 + (best.x - s.hookX).abs() / 7);
  final px = clampD(best.x + best.vx * t * (s.calm > 0 ? 0.35 : 1), 60, 940);
  return ArcadeInput(down: true, x: px.roundToDouble(), y: best.y.roundToDouble());
}
