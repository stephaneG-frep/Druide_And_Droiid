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

## Professeur IA

`lib/features/maitre` est découpé en trois couches :

- `domain` : fournisseurs, réglages, messages, événements de réponse, erreurs et consignes pédagogiques. Rien n'y dépend du réseau.
- `data` : `AiClient`, le contrat commun, et ses quatre implémentations. `OpenAiClient` sert aussi aux API compatibles. `AiHttp` gère les délais, la traduction des erreurs et la lecture des flux.
- `presentation` : `ChatController` orchestre une réponse, enregistre le résultat et expose l'état à l'écran.

Pour ajouter un fournisseur, il suffit d'une valeur dans `AiProviderKind` et d'une implémentation de `AiClient`.

Règles à respecter :

- Une clé ne vit que dans `SecretStore`. La base retient seulement sa présence, pour ne pas solliciter le trousseau à chaque écran.
- Une clé ne part jamais en HTTP, sauf vers la machine locale. Gemini la reçoit en en-tête, jamais dans l'adresse.
- Le texte d'erreur d'un service est tronqué et nettoyé de la clé.
- `listModels` sert de test de connexion : il ne génère rien, donc ne coûte aucun jeton.
- L'historique envoyé à Claude ne contient que du texte. Les blocs de réflexion ne sont pas conservés, ce que l'API accepte sans usage d'outils.
- Dans `AiHttp.lines`, n'utilisez pas `yield*` : ses erreurs échappent au `try`. Pour arrêter une réponse, appelez `abort`.
- Les tests n'appellent aucun service payant. `aiClientBuilderProvider` remplace le client dans les tests d'écran.

## Android Lab

`lib/features/lab` suit le même découpage que le Maître. Les exercices vivent dans `assets/lab/exercises.json` : après une modification, lancez `tool/check_lab_exercises.py`, qui exécute les corrigés et les codes de départ.

- `LabCapabilities` décrit ce que la plateforme sait vraiment faire. L'interface s'y fie, sans tester la plateforme elle-même.
- `CodeRunner` exécute le code. `LocalCodeRunner` passe par `/bin/sh` pour poser `ulimit`, dans un dossier temporaire, avec un environnement minimal. Le texte du code n'entre jamais dans une commande.
- `ToolCommands` n'accepte que les valeurs de `LabCommand`, sans shell. N'ajoutez jamais de terminal libre.
- `ToolDetector` reçoit son environnement et sa fonction `exists`, ce qui le rend testable sans les outils.
- `SystemCodeExporter` écrit directement sur Linux, car la boîte de dialogue de `file_picker` y dépend d'outils souvent absents, et il n'écrase jamais un fichier.

## Chaudron des Bugs

`lib/features/chaudron` sépare trois choses, que l'interface ne doit jamais mélanger :

- Les **fiches** de `assets/bugs/rules.json` : du texte préenregistré, reconnu par des expressions régulières. L'écran dit toujours que ce n'est pas une IA. Pour ajouter une fiche, renseignez ses six parties et au moins un message dans `samples` : `test/features/chaudron/bug_rules_test.dart` vérifie qu'elle le reconnaît.
- L'**analyse IA** : une conversation normale du Maître en mode `diagnose`. Le message passe par `extractRelevant`, puis `redactSecrets`, puis l'écran de relecture.
- La **vérification** : `BugStatus` ne change que par une action de l'utilisateur, et `recordVerification` refuse une réussite sans résultat noté. Aucun code ne doit passer un dossier à `verified` à partir d'une réponse d'IA.

Le texte d'origine reste en clair dans la base locale : seul l'envoi est filtré.

## Projets pratiques

Les projets vivent dans `assets/projects/projects.json`. `tool/check_projects.py` les convertit en un cours temporaire, puis réutilise les contrôles des cours grâce à la variable `COURSES_DIR`. Lancez-le après toute modification.

Chaque test de projet doit être un programme autonome, avec sa sortie exacte dans `output`.

`ProjectRepository.complete` refuse un projet incomplet, et toute modification efface `completedAt` : une validation doit rester vraie. La grille finale se calcule dans `final_grid.dart`, qui doit rester alignée sur la leçon `exp-11-final`.

## Gamification

L'expérience passe toujours par `ProgressRepository.award`, avec une source unique : `lesson:`, `quiz:`, `exercise:`, `lab:`, `project:`, `bug:`, `final:` ou `challenge:`. Rien ne se paie deux fois, et rien n'est jamais retiré.

`GamificationRepository.reconcile` attribue ce qui est dû à partir de l'état de la base : exercices du Lab, projets, bugs vérifiés, évaluation finale et badges. On peut l'appeler à tout moment. `rewardAndCelebrate` l'appelle après ces actions, et la page Progression à son ouverture.

Les badges, défis, parcours et certificats sont des fonctions pures de `LearnerStats` : ajoutez-en dans `lib/features/progression/domain`. Si le barème change, `gamification_test.dart` vérifie que Grand Druide reste atteignable avec le contenu réel.
