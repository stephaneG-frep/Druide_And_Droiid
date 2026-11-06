# Feuille de route

| Phase | Sujet | État |
| --- | --- | --- |
| 1 | Fondations | Terminée le 2026-11-04 |
| 2 | Design | Terminée le 2026-11-04 |
| 3 | Persistance | Terminée le 2026-11-04 |
| 4 | Moteur pédagogique | Terminée le 2026-11-04 |
| 5 | Contenus Android | Terminée le 2026-11-06 |
| 6 | Professeur IA | Code terminé le 2026-11-06, à valider sur un vrai fournisseur |
| 7 | Android Lab | À faire |
| 8 | Chaudron des Bugs | À faire |
| 9 | Projets pratiques | À faire |
| 10 | Gamification | À faire |
| 11 | Sauvegardes et documentation | À faire |
| 12 | Audit général | À faire |
| 13 | Compilation et livraison | À faire |

## Points ouverts

- Branche `phase-6-professeur-ia` à fusionner dans `main`.
- Phase 6 : aucun fournisseur réel n'a été appelé. Il faut un essai avec Ollama, ou avec une clé et l'accord de l'utilisateur pour les frais.
- Android : Ollama n'est joignable en HTTP que sur `127.0.0.1` (avec `adb reverse`) ou `10.0.2.2`. Une adresse du réseau local exige HTTPS.
- Phase 9 : l'application ne suit pas encore le projet final du module 12. Elle affiche sa grille et un questionnaire, mais la validation reste déclarative. Il faudra relier ce projet aux projets pratiques et à leurs preuves.
- Phase 13 : le projet reste sur AGP 9.1.0 et Gradle 9.3.1. Les bibliothèques Android récentes exigent `compileSdk 37`, AGP 9.5 et Gradle 9.6.
- Barème d'expérience provisoire (`rewards.dart`), à ajuster en phase 10.
- Tables des projets personnels et de l'historique IA : à créer par migration dans leurs phases.
- Icône de la fenêtre et du paquet Linux : à faire avec le `.deb` en phase 13.
- Seuils d'expérience des grades provisoires, à ajuster en phase 10.
- Signature release Android : encore la clé de debug, à remplacer en phase 13.
