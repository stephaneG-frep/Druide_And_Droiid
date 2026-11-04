# Architecture

Ce document décrit ce qui existe dans le code. Les éléments prévus sont marqués « prévu ».

## Structure

```
lib/
  main.dart                 Point d'entrée
  app/                      Assemblage de l'application
    app.dart                MaterialApp, locale française
    router.dart             Routes GoRouter
    sections.dart           Rubriques : source unique des routes et des menus
    theme/                  Palette, couleurs par thème, ThemeData
    shell/                  Coque de navigation, page Plus, page 404
  core/                     Services transverses
    persistence/            Base SQLite (Drift)
    security/               Coffre des secrets
  design_system/            Composants réutilisables, mascotte, animations
  features/<rubrique>/      Une rubrique par dossier
    presentation/           Écrans et contrôleurs
    domain/                 Modèles et catalogues
    data/                   Repositories
tool/                       Génération de l'icône et des aperçus
test/                       Tests unitaires et de widgets
integration_test/           Tests sur la plateforme réelle
assets/                     Polices et sources de l'icône
```

Séparation demandée par la spec, et emplacement de chaque couche :

| Couche | Emplacement |
| --- | --- |
| Présentation | `features/*/presentation`, `app/shell` |
| Logique métier | `features/*/domain` |
| Persistance | `core/persistence`, `features/*/data` |
| Contenu pédagogique | `features/*/domain` pour les catalogues ; leçons prévues en phases 4 et 5 |
| Fournisseurs IA | Prévu : phase 6 |
| Services de plateforme | Prévu : `core/platform`, phase 7 |

## Décisions

| Sujet | Choix | Raison |
| --- | --- | --- |
| État | Riverpod 3 | Exigé par la spec. Les services sont exposés par des `Provider`, remplaçables en test. |
| Navigation | GoRouter, `StatefulShellRoute.indexedStack` | Chaque onglet garde sa position. |
| Menus | 4 onglets + « Plus » | Neuf rubriques ne tiennent pas dans une barre basse lisible. Le même découpage sert au rail sur ordinateur. |
| SQLite | Drift | Requêtes typées et migrations versionnées. La bibliothèque SQLite est embarquée sur les deux plateformes. |
| Secrets | `flutter_secure_storage` derrière `SecretStore` | Keystore sur Android, libsecret sur Linux. |
| Sauvegarde Android | `allowBackup="false"` | Évite que la sauvegarde cloud du système embarque des données du coffre. Les sauvegardes passent par l'export de l'application (phase 11). |
| Identifiant | `com.druideanddroiid.druide_and_droiid` | Confirmé. Il ne peut plus changer après une publication. |
| Langue | Locale `fr` fixe | La spec demande une interface entièrement française. |

| Apparence | Chargée avant le premier rendu | Évite un flash du mauvais thème. Un échec de lecture n'empêche pas le démarrage. |
| Progression | `progressProvider` renvoie un état zéro | Point de branchement unique : la phase 3 le reliera à SQLite sans toucher aux écrans. |

## Dépendances système

- **Linux à l'exécution** : GTK 3 et libsecret, avec un service de trousseau actif (gnome-keyring ou équivalent). À déclarer dans le `.deb` en phase 13.
- **SQLite** : `libsqlite3.so` est fourni avec l'application, aucune dépendance système.
