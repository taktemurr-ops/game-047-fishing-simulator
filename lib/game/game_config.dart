import 'package:flutter/material.dart';

import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/game_rules.dart';
import 'fish_engine.dart';
import 'fish_view.dart';
import 'rules.dart';





final gameConfig = GameConfig(
  gameId: 'game-047-fishing-simulator',
  title: const ['Balıkçılık Simülatörü', 'Fishing Simulator', 'Fishing Simulator', 'Fishing Simulator', 'Fishing Simulator'],
  tagline: const ['Oltayı at, balığı tak, günün avını çek!', 'Cast, hook and reel in the catch of the day!', 'Cast, hook and reel in the catch of the day!', 'Cast, hook and reel in the catch of the day!', 'Cast, hook and reel in the catch of the day!'],
  seedColor: const Color(0xFFFFB703),
  icon: Icons.phishing,
  rules: FishRules(),
  buildPlay: (ctx) => ArcadeStage(
    ctx: ctx,
    create: () => FishSim((ctx.generated as GeneratedLevel<FishLevel>).puzzle),
    paint: (c, s, p, t) => paintFish(c, s, p, t, ctx.lang == 'tr'),
    sound: fishSound,
    boosterIcon: Icons.waves,
    boosterLabel: (l) => l == 'tr' ? 'Sakin deniz' : 'Calm water',
    howTo: const [
      'Parmağını suda tut: tekne yana gider, olta parmağının derinliğine iner. Balık takılınca bırak, olta yukarı çekilir. Süre bitmeden hedef ağırlığa ulaş.',
      'Hold your finger in the water: the boat follows and the hook sinks to your finger. When a fish bites, release to reel in. Reach the target weight in time.',
      'Hold to lower the hook, release to reel in.',
      'Hold to lower the hook, release to reel in.',
      'Hold to lower the hook, release to reel in.',
    ],
  ),
  tutorial: const [
    TutorialStep(Icons.touch_app, [
      'Basılı tut: olta parmağının olduğu yere iner. Bırak: olta çekilir.',
      'Hold: the hook goes to your finger. Release: reel in.',
      'Halten: Haken sinkt. Loslassen: einholen.',
      'Mantén: baja el anzuelo. Suelta: recoge.',
      'Maintenez : l\'hameçon descend. Relâchez : remontez.',
    ]),
    TutorialStep(Icons.warning, [
      'Köpekbalığı misinayı keser (can gider), denizanası taşıdığın balığı kaçırır.',
      'Sharks cut the line (lose a life), jellyfish free your fish.',
      'Haie kappen die Schnur, Quallen befreien den Fisch.',
      'Tiburones cortan el hilo, medusas liberan el pez.',
      'Les requins coupent la ligne, les méduses libèrent le poisson.',
    ]),
    TutorialStep(Icons.star, [
      'Derindeki büyük balıklar ve altın balık daha ağırdır. Sakin deniz güçlendirmesi balıkları yavaşlatır.',
      'Deep big fish and the golden fish weigh more. Calm water slows the fish.',
      'Große Fische tief unten wiegen mehr.',
      'Los peces grandes y profundos pesan más.',
      'Les gros poissons profonds pèsent plus.',
    ]),
  ],
);
