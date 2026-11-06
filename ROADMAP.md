# Feuille de route

| Phase | Sujet | État |
| --- | --- | --- |
| 1 | Fondations | Terminée le 2026-11-04 |
| 2 | Design | Terminée le 2026-11-04 |
| 3 | Persistance | Terminée le 2026-11-04 |
| 4 | Moteur pédagogique | Terminée le 2026-11-04 |
| 5 | Contenus Android | Terminée le 2026-11-06 |
| 6 | Professeur IA | À faire |
| 7 | Android Lab | À faire |
| 8 | Chaudron des Bugs | À faire |
| 9 | Projets pratiques | À faire |
| 10 | Gamification | À faire |
| 11 | Sauvegardes et documentation | À faire |
| 12 | Audit général | À faire |
| 13 | Compilation et livraison | À faire |

## Points ouverts

- Branche `phase-5-modules-11-12` à fusionner dans `main`.
- Phase 9 : l'application ne suit pas encore le projet final du module 12. Elle affiche sa grille et un questionnaire, mais la validation reste déclarative. Il faudra relier ce projet aux projets pratiques et à leurs preuves.
- Phase 6 : gérer un trousseau Linux verrouillé (`KeyringLocked`) avec un message clair. Le stockage des clés d'API en dépend.
- Phase 13 : le projet reste sur AGP 9.1.0 et Gradle 9.3.1. Les bibliothèques Android récentes exigent `compileSdk 37`, AGP 9.5 et Gradle 9.6.
- Barème d'expérience provisoire (`rewards.dart`), à ajuster en phase 10.
- Tables des projets personnels et de l'historique IA : à créer par migration dans leurs phases.
- Icône de la fenêtre et du paquet Linux : à faire avec le `.deb` en phase 13.
- Seuils d'expérience des grades provisoires, à ajuster en phase 10.
- Signature release Android : encore la clé de debug, à remplacer en phase 13.
