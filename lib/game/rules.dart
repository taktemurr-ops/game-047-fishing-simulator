import '../core/arcade.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'fish_engine.dart';

class FishRules extends ArcadeRules<FishLevel> {
  @override
  String get gameId => 'game-047-fishing-simulator';

  @override
  List<String> get optionalMechanics => const ['sharks', 'jelly', 'current', 'junk', 'night'];

  @override
  List<GameStat> get gameStats => const [
        GameStat('fish_caught', 'Tutulan balık', 'Fish caught', scale: 200),
        GameStat('weight_kg', 'Toplam ağırlık (kg)', 'Total weight (kg)', scale: 500),
        GameStat('golden_fish', 'Altın balık', 'Golden fish', scale: 10),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('fish_caught', 'fish_caught', [66, 133, 200]),
        MissionTemplate('weight_kg', 'weight_kg', [166, 333, 500]),
      ];

  @override
  FishLevel generate(LevelSpec spec) => generateFishLevel(spec);

  @override
  ArcadeMeta metaOf(FishLevel l) => l.meta;

  @override
  ArcadeSim createSim(FishLevel l) => FishSim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => fishBot(sim);

  @override
  int maxTicks(FishLevel l) => l.limitTicks + 60;
}

ArcadeRules createRules() => FishRules();
