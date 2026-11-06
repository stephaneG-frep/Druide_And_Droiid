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
| Contenu pédagogique | `assets/courses/` pour les cours, `features/*/domain` pour les catalogues |
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
| Éditeur de note | Route hors de la coque de navigation | Laisse la place au clavier, et le retour revient à l'écran d'origine, module ou liste. |

## Contenu pédagogique

Chaque module rédigé est un fichier `assets/courses/<module>.json`, déclaré dans `assets/courses/index.json`. Les cours sont embarqués : ils fonctionnent hors ligne.

```json
{
  "moduleId": "fondations",
  "lessons": [{
    "id": "fondations-01-histoire",
    "title": "…",
    "minutes": 8,
    "blocks": [{ "type": "paragraph", "text": "**gras** et `code`" }],
    "quiz": [{ "prompt": "…", "options": ["…"], "answers": [1], "explanation": "…" }],
    "exercises": [{ "id": "…", "kind": "fill", "prompt": "…", "accepted": ["…"], "solution": "…" }]
  }],
  "evaluation": { "passPercent": 80, "questions": [] },
  "resources": [{ "title": "…", "url": "…" }]
}
```

| Élément | Valeurs |
| --- | --- |
| Langages de code | `kotlin`, `java`, `dart`, `xml`, `shell`, `text` |
| Blocs | `heading`, `paragraph`, `list`, `code` (avec `output` facultatif), `info`, `warning`, `tip`, `layers` |
| Questions | Une ou plusieurs bonnes réponses ; une question multiple n'est juste que si elle est entièrement juste |
| Exercices | `fill` : réponse courte corrigée automatiquement ; `self` : réponse libre, comparée au corrigé par l'apprenant |

Aucun exercice n'exécute de code : la correction ne prétend jamais avoir compilé quoi que ce soit.

`Course.fromJson` valide tout et indique l'emplacement de l'erreur. Un cours illisible devient l'état `CourseUnreadable`, affiché par l'écran concerné. `test/content/courses_test.dart` contrôle les vrais fichiers : à lancer après toute modification de contenu.

`tool/check_course_code.py` compile et exécute avec `kotlinc` et `javac` chaque exemple contenant `fun main` ou `public class Main`, y compris les corrigés, et compare la sortie au champ `output`. Les extraits utilisant des API Android ne s'exécutent pas sur un ordinateur : l'outil les liste comme non vérifiés. À lancer après toute modification d'un cours.

`tool/check_android_snippets.py` compile les extraits Android des modules indiqués dans un vrai projet Gradle, généré dans `build/android_snippets` : Kotlin, KSP pour vérifier le SQL de Room, mises en page et fichiers XML de sécurité réseau. Il prouve que le code compile, pas qu'il se comporte comme annoncé. Les lignes `import` étant omises dans les cours, il les ajoute. Ses versions sont fixées en tête du script.

Ce même outil exécute aussi les exemples Dart sans paquet, avec `dart run`, et analyse la syntaxe des blocs C++ avec le compilateur du NDK.

`tool/check_flutter_snippets.py` crée dans `build/flutter_snippets` un projet Flutter avec les paquets du cours, y lance `flutter analyze` sur les extraits Dart, puis compile le code Kotlin hôte dans un APK. Il prouve que le code se type, pas qu'il se comporte comme annoncé.

Règles de progression, dans `rewards.dart` :

| Action | Condition | XP |
| --- | --- | --- |
| Terminer une leçon | Une fois | 20 |
| Quiz de leçon | 70 %, première réussite | 15 |
| Exercice | Première réussite | 10 |
| Évaluation de module | Leçons terminées, seuil du cours, première réussite | 50 |

## Données

Base SQLite locale gérée par Drift, schéma en version 3 (`lib/core/persistence/`).

| Table | Contenu |
| --- | --- |
| `app_meta` | Réglages (clé/valeur) |
| `lesson_progress` | Leçons terminées |
| `quiz_attempts` | Toutes les tentatives de quiz |
| `xp_events` | Registre de l'expérience ; `source` unique, donc une action ne rapporte qu'une fois |
| `notes` | Notes, liées ou non à un module |
| `favorites` | Favoris, par type et identifiant |
| `exercise_answers` | Dernière réponse et résultat de chaque exercice |

L'expérience totale est la somme du registre : elle n'est jamais stockée à part, et ne peut donc pas diverger.

Emplacement du fichier :

- **Android** : dossier privé de l'application.
- **Linux** : `~/.local/share/com.druideanddroiid.druide_and_droiid/`.

Chaque hausse de `schemaVersion` exige une étape de migration et un test partant d'un vrai fichier de l'ancienne version (`test/core/migration_test.dart`). La migration doit aussi aboutir au même schéma qu'une base neuve.

Les repositories sont dans `features/*/data`. Les lectures sont des flux : les écrans se mettent à jour d'eux-mêmes après une écriture.

**Sauvegarde automatique** (`Autosaver`, utilisé par les notes et les exercices) : écriture 300 ms après la dernière frappe, et immédiatement en quittant l'écran ou en passant en arrière-plan. Les écritures sont sérialisées pour ne jamais créer de doublon. Limite connue : si le processus est tué brutalement moins de 300 ms après une frappe, cette frappe peut être perdue.

## Dépendances système

- **Linux à l'exécution** : GTK 3 et libsecret, avec un service de trousseau actif (gnome-keyring ou équivalent). À déclarer dans le `.deb` en phase 13.
- **SQLite** : `libsqlite3.so` est fourni avec l'application, aucune dépendance système.
