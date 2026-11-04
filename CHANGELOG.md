# Journal des modifications

## Phase 2 — 2026-11-04

- Thèmes sombre et clair personnalisés, avec polices embarquées.
- Mascotte Maître And-Droiīd en vectoriel : cinq humeurs et animation discrète.
- Onze familles de composants réutilisables (voir [DESIGN.md](DESIGN.md)).
- Tableau de bord, avec question flash quotidienne.
- Écrans principaux de toutes les rubriques : programme des douze modules, vingt projets, huit grades.
- Paramètres : thème et niveau d'animation, conservés au redémarrage.
- Icône de l'application et écran de démarrage sombre sur Android.
- Corrections : débordement du rail en paysage, plantage de `AnimatedSize` avec animations désactivées.

## Phase 1 — 2026-11-04

- Projet Flutter créé pour Android et Linux.
- Dépendances ajoutées : Riverpod, GoRouter, Drift, flutter_secure_storage, localisations françaises.
- Navigation : quatre onglets plus « Plus », barre basse ou rail selon la largeur, page 404 en français.
- Rubriques en attente : chacune indique la phase qui la livrera.
- Base SQLite minimale et coffre des secrets.
- Android : nom de l'application, permission Internet, sauvegarde système désactivée.
- Linux : titre de la fenêtre, taille minimale 360 × 600.
- Documents de suivi créés, tests initiaux ajoutés.
