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
| 13 | Compilation et livraison | Livrables produits le 2026-11-08, vérifications restantes ci-dessous |

## Critères de livraison (SPEC, section 15)

| Critère | État |
| --- | --- |
| 1. Fonctionnalités annoncées | Implémentées |
| 2. Contenus pédagogiques | Douze modules, exemples vérifiés |
| 3. Navigation | Testée (tests automatiques, Honor en release, Linux installé) |
| 4. Progression persistante | Vérifiée, y compris après mise à jour de l'APK |
| 5. Quiz | Fonctionnent |
| 6. Exercices | Exploitables |
| 7. Intégrations IA configurées | Ollama et Anthropic validés. OpenAI et Gemini : seulement face à un serveur local |
| 8. Hors ligne | Vérifié sur le Honor en mode avion et sur Linux réseau coupé |
| 9. Sauvegardes et restaurations | Sauvegarde vérifiée sur le Honor. Restauration testée sur Linux, pas sur le Honor |
| 10. Exports | PDF et ZIP vérifiés sur le Honor |
| 11. Tests automatisés | 438 réussis |
| 12. Livrables compilés | APK, `.deb`, archive des sources |
| 13. Tests d'installation | APK installé sur le Honor. `.deb` installé sur Ubuntu 22.04 ; désinstallation essayée seulement dans une racine factice |
| 14. Documentation | README, BUILD, USER_GUIDE, rapports |
| 15. Limitations documentées | Ci-dessous et dans TEST_REPORT |

L'application n'est donc pas déclarée « complète et testée » : les points 7, 9 et 13 gardent des vérifications à faire.

## Points ouverts

- Branches `phase-12-audit` et `phase-13-livraison` à fusionner dans `main`.
- Désinstaller puis réinstaller le `.deb` sur Ubuntu (`sudo` nécessaire).
- Restaurer une sauvegarde sur le Honor depuis l'application.
- OpenAI et Gemini restent à essayer avec une vraie clé. Leur code n'a été testé que face à un serveur local.
- Android : Ollama n'est joignable en HTTP que sur `127.0.0.1` (avec `adb reverse`) ou `10.0.2.2`. Une adresse du réseau local exige HTTPS.
- Publication : l'APK est signé avec la clé de debug. Avant toute publication, créer une clé et `android/key.properties` (voir BUILD.md), puis désinstaller l'ancienne version après une sauvegarde.
- Licence de l'application : pas encore choisie par l'auteur, le paquet indique « tous droits réservés ».
- Dépendances : `flutter_riverpod` 3.5.0 et `go_router` 18.1.3 disponibles, mises à jour mineures.
- AGP 9.1.0 et Gradle 9.3.1 suffisent à l'application. Les projets d'exemple des cours utilisent AGP 9.5 et Gradle 9.6.
- Accessibilité : règles automatiques de Flutter respectées, parcours réel avec TalkBack et Orca à faire.
- Paquet `arm64` : possible avec le même script sur une machine ARM, jamais compilé.
