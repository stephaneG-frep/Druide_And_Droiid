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
    theme/                  Palette et thèmes
    shell/                  Coque de navigation, page Plus, page 404, placeholders
  core/                     Services transverses
    persistence/            Base SQLite (Drift)
    security/               Coffre des secrets
  features/<rubrique>/      Prévu dès la phase 2
    presentation/           Écrans et widgets
    domain/                 Logique métier
    data/                   Repositories et sources de données
test/                       Tests unitaires et de widgets
integration_test/           Tests sur la plateforme réelle
```

Séparation demandée par la spec, et emplacement de chaque couche :

| Couche | Emplacement |
| --- | --- |
| Présentation | `features/*/presentation`, `app/shell` |
| Logique métier | `features/*/domain` |
| Persistance | `core/persistence`, `features/*/data` |
| Contenu pédagogique | Prévu : `assets/` chargés en local, phase 4 |
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
| Identifiant | `com.druideanddroiid.druide_and_droiid` | À confirmer avant toute publication : il ne peut plus changer ensuite. |
| Langue | Locale `fr` fixe | La spec demande une interface entièrement française. |

## Dépendances système

- **Linux à l'exécution** : GTK 3 et libsecret, avec un service de trousseau actif (gnome-keyring ou équivalent). À déclarer dans le `.deb` en phase 13.
- **SQLite** : `libsqlite3.so` est fourni avec l'application, aucune dépendance système.
