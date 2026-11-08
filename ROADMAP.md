# Feuille de route

| Phase | Sujet | État |
| --- | --- | --- |
| 1 | Fondations | Terminée le 2026-11-04 |
| 2 | Design | Terminée le 2026-11-04 |
| 3 | Persistance | Terminée le 2026-11-04 |
| 4 | Moteur pédagogique | Terminée le 2026-11-04 |
| 5 | Contenus Android | Terminée le 2026-11-06 |
| 6 | Professeur IA | Terminée le 2026-11-06 : validée avec Ollama et Anthropic |
| 7 | Android Lab | Terminée le 2026-11-06 |
| 8 | Chaudron des Bugs | Terminée le 2026-11-07 |
| 9 | Projets pratiques | Terminée le 2026-11-07 |
| 10 | Gamification | Terminée le 2026-11-07 |
| 11 | Sauvegardes et documentation | Terminée le 2026-11-07 |
| 12 | Audit général | Terminée le 2026-11-07 |
| 13 | Compilation et livraison | À faire |

## Points ouverts

- Branche `phase-12-audit` à fusionner dans `main`.
- OpenAI et Gemini restent à essayer avec une vraie clé. Leur code n'a été testé que face à un serveur local.
- Android : Ollama n'est joignable en HTTP que sur `127.0.0.1` (avec `adb reverse`) ou `10.0.2.2`. Une adresse du réseau local exige HTTPS.
- Phase 13 : le projet reste sur AGP 9.1.0 et Gradle 9.3.1. Les bibliothèques Android récentes exigent `compileSdk 37`, AGP 9.5 et Gradle 9.6.
- Icône de la fenêtre et du paquet Linux : à faire avec le `.deb` en phase 13.
- Signature release Android : encore la clé de debug, à remplacer en phase 13. Le module Flutter du cours le signale, phrase à mettre à jour à ce moment-là.
- Dépendances : `flutter_riverpod` 3.5.0 et `go_router` 18.1.3 disponibles, mises à jour mineures à faire avec la phase 13.
- Accessibilité : règles automatiques de Flutter respectées, parcours réel avec TalkBack et Orca à faire.
