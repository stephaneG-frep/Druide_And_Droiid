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
| 10 | Gamification | À faire |
| 11 | Sauvegardes et documentation | À faire |
| 12 | Audit général | À faire |
| 13 | Compilation et livraison | À faire |

## Points ouverts

- Branche `phase-9-projets` à fusionner dans `main`.
- Phase 10 : les exercices du Lab, les projets et l'évaluation finale ne rapportent pas encore d'expérience.
- Phase 11 : prévoir les brouillons et versions du Lab, les dossiers du Chaudron et le suivi des projets, dans les sauvegardes.
- OpenAI et Gemini restent à essayer avec une vraie clé. Leur code n'a été testé que face à un serveur local.
- Android : Ollama n'est joignable en HTTP que sur `127.0.0.1` (avec `adb reverse`) ou `10.0.2.2`. Une adresse du réseau local exige HTTPS.
- Phase 13 : le projet reste sur AGP 9.1.0 et Gradle 9.3.1. Les bibliothèques Android récentes exigent `compileSdk 37`, AGP 9.5 et Gradle 9.6.
- Barème d'expérience provisoire (`rewards.dart`), à ajuster en phase 10.
- Tables des projets personnels et de l'historique IA : à créer par migration dans leurs phases.
- Icône de la fenêtre et du paquet Linux : à faire avec le `.deb` en phase 13.
- Seuils d'expérience des grades provisoires, à ajuster en phase 10.
- Signature release Android : encore la clé de debug, à remplacer en phase 13.
