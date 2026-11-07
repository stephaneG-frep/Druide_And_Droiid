# Rapport de tests

## Phase 10 — 2026-11-07

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 376 tests réussis, 6 ignorés (Ollama réel, à la demande) |
| Grand Druide atteignable avec le contenu réel, mais pas avec les trois quarts | Vérifié |
| Récompenses uniques, badges conservés, limite des bugs, défis réclamés une fois | Vérifiés |
| Série de jours, y compris au changement d'heure | Vérifiée |
| Certificats : conditions et mention interne | Vérifiés |
| Intégration Linux | Socle 5 sur 5, Maître 1 sur 1, Lab 3 sur 3 |
| Migration de la version 7 à la version 8 | Testée sur une base de fichier, sans perte |
| Mise à jour sur Honor | Base migrée en version 8, données identiques (45 XP), lancement sans plantage |
| Intégration sur Honor | **Non lancée** : elle désinstalle l'application |

Vérifié sur un rendu de test : la page Progression.

### Non vérifié

- **Équilibre du barème** : il est calculé sur le contenu, pas éprouvé par de vrais apprenants. Les seuils pourront changer.
- **Récompenses sur le Honor** : le premier badge de l'utilisateur ne sera attribué qu'à l'ouverture de la page Progression, qui n'a pas été ouverte sur le téléphone.
- **Leçons, quiz et exercices de l'Académie** : leurs badges ne s'annoncent pas au moment de l'action, mais à la prochaine ouverture de la page Progression.
- **Autoévaluations** : les exercices validés soi-même, les projets et l'évaluation finale rapportent de l'expérience sur la parole de l'apprenant.
- **Lecteur d'écran** : la page n'a pas été parcourue avec TalkBack.

## Phase 9 — 2026-11-07

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 348 tests réussis, 6 ignorés (Ollama réel, à la demande) |
| Tests des 20 projets | 20 sur 20 exécutés, sorties conformes |
| Extraits Android des projets | 40 compilés |
| Extraits Flutter et activité Kotlin hôte | 4 analysés, APK de preuve compilé |
| Open-Meteo et API GitHub | Réponses réelles relues avant la rédaction |
| Règles de validation et grille finale | Vérifiées, dont l'exemple de la leçon (69 points, à reprendre) |
| Intégration Linux | Socle 5 sur 5, Maître 1 sur 1, Lab 3 sur 3 |
| Migration de la version 6 à la version 7 | Testée sur une base de fichier, sans perte |
| Mise à jour sur Honor | Base migrée en version 7, données identiques, lancement sans plantage |
| Intégration sur Honor | **Non lancée** : elle désinstalle l'application |

Vérifié sur des rendus de test : une fiche de projet et la grille finale.

### Non vérifié

- **Les vingt applications** : je n'ai réalisé aucun projet de bout en bout. Le code fourni compile ou s'exécute par extraits, mais son assemblage et son comportement sur un appareil ne sont pas prouvés.
- **Lecture de médias, notifications, Keystore, Ollama depuis Android** : ce code compile, sans avoir tourné.
- **Conditions d'Open-Meteo** : l'usage non commercial sans clé vient de mes connaissances. La leçon invite à les vérifier.
- **Validation** : l'application ne lit ni le code ni les preuves. Une preuve écrite n'est pas contrôlée.
- **Lecteur d'écran** : ces écrans n'ont pas été parcourus avec TalkBack.

## Correctifs du Maître — 2026-11-07

Deux problèmes signalés par l'utilisateur après la phase 8.

- **« Pas de connexion » sur le Honor** : `adb reverse --list` était vide, donc le téléphone ne joignait plus Ollama. Ollama tournait toujours sur l'ordinateur. Le pont a été rétabli et `curl` répond depuis le téléphone. L'application explique désormais cette cause.
- **« Ça revient sur Ollama »** : les deux bases contenaient `ai.active = ollama`, avec Anthropic configuré. Seul le bouton **Enregistrer et activer** modifie ce réglage, et choisir dans la liste ne l'activait pas. Un nouveau test montre qu'un fournisseur enregistré survit à la fermeture : le défaut ne venait donc pas de la sauvegarde, mais d'un écran trop peu clair. C'est la cause la plus probable, pas une certitude, car le geste exact de l'utilisateur n'a pas été observé.

Vérifications : `flutter test` et l'intégration du Maître sur Linux réussissent, et la base du Honor reste identique après la mise à jour.

Non vérifié : le nouveau sélecteur et les nouveaux messages n'ont été essayés que dans les tests d'écran, pas à la main sur le Honor.

## Phase 8 — 2026-11-07

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 324 tests réussis, 6 ignorés (Ollama réel, à la demande) |
| 37 fiches : six parties complètes, exemples reconnus, journal sain sans fausse alerte | Vérifié |
| Messages réels relevés ici (ADB, `pub`, Gradle, plugin) | Reconnus |
| Masquage des secrets et réduction des longs journaux | Vérifiés |
| Parcours d'écran : sans IA, avec IA simulée, vérification, suppression | Vérifiés |
| Consigne du Chaudron face à un vrai Ollama (`gemma3:1b`) | Les six titres sortent, le contenu reste faible : voir ci-dessous |
| Intégration Linux | Socle 5 sur 5, Maître 1 sur 1, Lab 3 sur 3 |
| Migration de la version 5 à la version 6 | Testée sur une base de fichier, sans perte |
| Mise à jour sur Honor | Base migrée en version 6, données identiques, lancement sans plantage |
| Intégration sur Honor | **Non lancée** : elle désinstalle l'application |

### Qualité observée avec un petit modèle

Sur `INSTALL_FAILED_NO_MATCHING_ABIS`, `gemma3:1b` a respecté la structure, mais n'a pas identifié l'architecture du processeur et a proposé des pistes hors sujet, comme un antivirus. Un petit modèle local peut donc induire en erreur. Dans l'application, les fiches reconnues sont transmises au modèle, ce que cet essai direct ne faisait pas.

### Non vérifié

- **Analyse IA avec Anthropic** : la consigne du Chaudron n'a pas été essayée avec un grand modèle, faute de clé dans cette session.
- **Import de fichier** : la boîte de dialogue réelle n'a été ouverte ni sur Linux ni sur le Honor. Le test utilise un faux sélecteur.
- **Bouton ADB** : testé par la ligne de commande équivalente, pas depuis l'écran.
- **Fiches** : leurs exemples sont en partie rédigés d'après la documentation et mes connaissances. Seuls quelques messages ont été relevés pour de vrai, et leurs conseils n'ont pas été rejoués panne par panne.
- **Masquage** : il repère des formes connues, pas tous les secrets possibles.
- **Lecteur d'écran** : ces écrans n'ont pas été parcourus avec TalkBack.

## Phase 7 — 2026-11-06

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 293 tests réussis, 5 ignorés (Ollama réel, à la demande) |
| Limites d'exécution avec le vrai Dart | Boucle sans fin, sortie sans fin, arrêt, environnement minimal, dossier supprimé |
| Corrigés et codes de départ des 18 exercices | Exécutés avec les vrais compilateurs : `tool/check_lab_exercises.py` |
| Intégration Linux, Lab | 3 tests sur 3 : Kotlin, Java et Dart depuis l'application, erreur Kotlin, export réel |
| Intégration Linux, socle et Maître | 5 sur 5, 1 sur 1 |
| Migration de la version 4 à la version 5 | Testée sur une base de fichier, sans perte |
| Mise à jour sur Honor | Base migrée en version 5, données identiques (45 XP, conversation et réglages IA), lancement sans plantage |
| Intégration sur Honor | **Non lancée** : elle désinstalle l'application |

Vérifié sur des rendus de test : la liste du Lab et l'éditeur.

### Limites propres aux plateformes

- **Android** : aucune exécution de Kotlin, Java ou Dart. L'écran l'annonce et ne simule rien. Le XML est analysé pour de vrai. **Je valide moi-même** reste une autoévaluation.
- **Linux** : le code garde les droits de l'utilisateur. Ce n'est pas un bac à sable, et l'application le dit avant la première exécution. Les limites arrêtent les accidents, pas un code malveillant.
- **Analyse du XML** : elle vérifie la syntaxe et les éléments attendus, pas la validité pour Android.
- **Sortie des programmes** : elle s'affiche à la fin de l'exécution, pas en direct. Aucune saisie au clavier n'est possible.

### Non vérifié

- **Export sur Android** : le sélecteur de fichiers du système n'a pas été ouvert sur le Honor.
- **Éditeur sur le Honor** : la saisie au clavier tactile n'a pas été essayée.
- **Boutons Android Studio et émulateur** : ils n'ont été testés qu'avec un faux lanceur. Le lancement réel n'a pas été fait, et aucun appareil virtuel n'existe forcément sur cette machine.
- **Commandes `sudo` des procédures d'installation** : elles viennent de mes connaissances et n'ont pas été lancées.
- **Commandes Gradle et Flutter du panneau** : la détection est testée, mais leur exécution réelle n'a été prouvée que par les tests avec un faux outil.
- **Lecteur d'écran** : l'éditeur n'a pas été parcouru avec TalkBack.

## Phase 6 — 2026-11-06

Phase terminée : Ollama et Anthropic ont répondu pour de vrai. OpenAI et Gemini n'ont pas été essayés.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 249 tests sur 249 réussis |
| Clients des cinq fournisseurs, face à un serveur HTTP local | Requêtes, flux, usage, fin de réponse et erreurs vérifiés |
| Intégration Linux, socle | 5 tests sur 5 réussis |
| Intégration Linux, chat par le vrai réseau local et le vrai trousseau | 1 test sur 1 réussi |
| Migration de la version 3 à la version 4 | Testée sur une base de fichier, sans perte |
| Mise à jour sur Honor | Base sauvegardée, migrée en version 4, données identiques (45 XP, 1 leçon, 1 quiz, 3 réponses), lancement sans plantage |
| Intégration sur Honor | **Non lancée** : elle désinstalle l'application |
| Client Ollama face à un vrai serveur (0.40.15, `gemma3:1b`) | 5 tests sur 5 : liste des modèles, réponse par morceaux, usage, réponse coupée, modèle absent, arrêt |
| Honor et Linux, Ollama et Anthropic, dans l'écran | Fonctionnent, selon l'essai fait par l'utilisateur |

Le test réel se lance à la demande : `OLLAMA_MODEL=gemma3:1b flutter test test/features/maitre/ollama_live_test.dart`.

L'essai sur Anthropic a été fait par l'utilisateur, avec sa clé, sur ses deux appareils. Aucune clé n'est passée par cette session, et ce rapport ne détaille ni le modèle ni le coût.

Deux défauts réels ont été trouvés par ces tests et corrigés :

- Une erreur survenue au milieu d'une réponse échappait à la traduction en message clair, à cause de `yield*`.
- Arrêter une réponse ne coupait pas la connexion, car un générateur `async*` en attente ne voit l'annulation qu'à son prochain `yield`. Une méthode `abort` ferme désormais le client HTTP.

Les serveurs de test reproduisent les protocoles lus dans la documentation : API Messages et flux SSE d'Anthropic, types du SDK Python d'OpenAI, référence de l'API Gemini, documentation d'Ollama.

### Non vérifié

- **OpenAI et Gemini** : leur code n'a jamais rencontré le service réel. Un écart avec la documentation reste possible.
- **Essai utilisateur** : il confirme que les deux fournisseurs répondent sur les deux appareils. Les autres chemins, comme les erreurs réelles d'Anthropic, le refus et le coût affiché, n'ont pas été observés un par un.
- **Qualité pédagogique** : `gemma3:1b` répond en français, mais de façon approximative. Les douze modes n'ont pas été évalués un par un.
- **En-tête `x-goog-api-key` et liste des modèles Gemini** : la page lue ne les détaille pas, ils viennent de mes connaissances.
- **Filet Claude** : le mécanisme automatique de repli après un refus n'est pas activé, car il n'a pas pu être testé. Un refus s'affiche simplement à l'utilisateur.
- **Android sur réseau local** : une adresse HTTP autre que `127.0.0.1` ou `10.0.2.2` est bloquée par le système.
- **Lecteur d'écran** : le chat n'a pas été parcouru avec TalkBack.

## Phase 5, fin de phase — 2026-11-06

Phase terminée : douze modules, 121 leçons, 511 questions de quiz, 242 exercices corrigés et 121 questions d'évaluation.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux | 5 tests sur 5 réussis |
| Intégration sur Honor | Non lancée sur ce code : elle désinstalle l'application. Dernier passage à 5 sur 5 sur `main`, au tour 4 |
| Exemples Kotlin, Java et Dart compilés, exécutés et comparés | 127 sur 127 |
| Blocs C++ analysés par le NDK (syntaxe seulement) | 2 sur 2 |
| Extraits Android des onze modules concernés, compilés d'un seul passage | 106 sur 106 |
| Extraits Flutter des modules 7 et 12 | 18 sur 18, aucun problème, APK de preuve compilé |
| Workflows GitHub Actions du cours | 3 fragments YAML valides, étiquettes d'actions existantes |
| `keytool -genkeypair` | Testé, fichier de clés créé et relu |
| Liens de ressources | 90 sur 90 répondent |
| Exercices sans corrigé, texte de remplissage | Aucun |
| Thèmes du programme | Tous présents dans leur module, contrôle par mots puis relecture des 12 écarts de vocabulaire |
| Mise à jour sur Honor sans désinstallation | Empreinte de la base identique avant et après (`2f37174fda135b194272`), application au premier plan, aucun plantage |

Le premier passage complet a échoué sur dix extraits des modules 1 à 4. Ce n'étaient pas des erreurs de cours, mais des fragments : blocs Gradle, instructions hors d'une classe, imports et fonctions d'exemple absents de l'outil. L'outil a été complété, et ces extraits sont désormais compilés.

Vérifié sur des rendus de test : deux leçons du module 11 et deux du module 12.

Sources contrôlées : developer.android.com pour la signature, le niveau d'API cible, R8, les Baseline Profiles, les mises à jour intégrées, la stabilité Compose, la modularisation et l'architecture ; support.google.com pour Play Console, les parcours et l'exigence de testeurs ; firebase.google.com pour Crashlytics ; f-droid.org pour l'inclusion.

### Non vérifié

- **Lecture sur le téléphone** : la mise à jour est installée et lancée, mais personne n'a encore confirmé que les modules 11 et 12 s'ouvrent sur le Honor.
- **Workflows GitHub Actions** : le YAML est valide, mais aucun n'a tourné sur GitHub.
- **Compilation signée** : `bundleRelease` avec `keystore.properties` et la signature par la CI n'ont pas été exécutés.
- **Play Console, Crashlytics, Macrobenchmark, mises à jour intégrées, Fastlane** : présentés d'après la documentation. Le code de Crashlytics et de Macrobenchmark compile, mais aucun n'a tourné.
- **Envoi des fichiers de correspondance par le plugin Crashlytics, exigence d'une politique de confidentialité, seuils d'Android vitals, délais d'examen** : la page lue ne les détaille pas, ces points viennent de mes connaissances.
- **Projets Grimoire et Quêtes** : le cahier des charges est écrit et ses extraits sont vérifiés, mais je n'ai pas réalisé ces applications de bout en bout.
- **Évaluation finale** : le module 12 se termine par une grille et un questionnaire. L'application ne vérifie pas le projet réel : la validation reste à relier à la phase 9.

## Phase 5, tour 5 — 2026-11-06

La phase n'est pas terminée : modules 1 à 10 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux | 5 tests sur 5 réussis |
| Intégration sur Honor | **Non lancée** : elle désinstalle l'application, et ce tour ne change que du contenu |
| Exemples Kotlin, Java et Dart compilés, exécutés et comparés | 109 sur 109 |
| Blocs C++ analysés par le NDK (syntaxe seulement) | 2 sur 2 |
| Extraits Android des modules 9 et 10 compilés | 21 sur 21 |
| Bibliothèques citées (ML Kit, LiteRT) | Versions présentes sur les dépôts Maven |
| Police de code | Tous les caractères des modules 9 et 10 sont présents |
| Mise à jour sur Honor sans désinstallation | Empreinte de la base identique avant et après (`fcdad39c312487c9b38b`), lancement sans plantage |

Commandes d'analyse lancées sur l'APK de debug de ce projet : `aapt2 dump permissions`, `aapt2 dump badging`, `apksigner verify --print-certs`, `apkanalyzer manifest print`.

Le chiffrement AES-GCM est réellement exécuté dans un exemple : le texte revient intact, deux IV diffèrent, et une donnée modifiée est rejetée.

Sources contrôlées : mas.owasp.org, developer.android.com pour le Keystore, les bonnes pratiques, les risques, l'IA, `SpeechRecognizer` et `TextToSpeech` ; les dépôts GitHub de MobSF et JADX ; docs.ollama.com ; developers.google.com pour ML Kit GenAI et LiteRT ; la référence embarquée de l'API Claude pour la forme de la requête.

### Non vérifié

- **API payantes** : aucun appel réel n'a été fait, conformément à la règle du projet. La lecture d'une réponse Claude s'appuie sur un exemple écrit à la main.
- **Ollama** : il n'est pas installé sur la machine. Les commandes et `/api/chat` viennent de la documentation, et le code Android n'est que compilé.
- **MobSF, JADX, Frida, mitmproxy, Burp** : présentés d'après la documentation, sans exécution. Docker est présent, mais l'image de MobSF n'a pas été téléchargée.
- **Keystore, voix, images, WorkManager** : le code compile, mais il n'a pas été exécuté sur un appareil.
- **ML Kit GenAI et LiteRT** : aucun modèle n'a été lancé. La disponibilité de Gemini Nano sur le Honor n'est pas connue.
- **Article 323-1 du Code pénal, RGPD** : cités de mes connaissances, sans page lue pendant ce tour. Ce n'est pas un avis juridique.
- **Niveaux de vérification du MASVS** : les pages lues ne les décrivent pas, le cours n'en parle donc pas.

## Phase 5, tour 4 — 2026-11-06

La phase n'est pas terminée : modules 1 à 8 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux | 5 tests sur 5 réussis |
| Intégration sur Honor | Réussie au début du tour, sur le code de `main` : 5 sur 5, voir ci-dessous |
| Exemples Kotlin, Java et Dart compilés, exécutés et comparés | 93 sur 93 |
| Blocs C++ analysés par le NDK (syntaxe seulement) | 2 sur 2 |
| Extraits Flutter analysés dans un projet Flutter | 17 sur 17, aucun problème |
| Activité Kotlin hôte du module 7 compilée dans un APK | Réussi |
| Extraits Android du module 8 compilés | 10 sur 10 |
| Extraits Android des modules 5 et 6, après modification de l'outil | 53 sur 53 |
| Police de code | Tous les caractères des modules 7 et 8 sont présents |
| Mise à jour sur Honor sans désinstallation | Empreinte de la base identique avant et après (`fcdad39c312487c9b38b`), lancement sans plantage |

Vérifié sur des rendus de test : deux leçons du module 8, dont les avertissements de la leçon Fastboot.

Commandes lancées sur le Honor pour le module 8, toutes en lecture seule : `getprop`, `getconf PAGE_SIZE`, `top -n 1`, `ps -A`, `pm path`, `pidof`, `wm size`, `am get-inactive`, `dumpsys battery`, `dumpsys deviceidle whitelist`, `dumpsys gfxinfo`, `dumpsys activity activities`, `logcat -b crash -d`. Le temps de démarrage a été mesuré avec `am start -W`.

Sources contrôlées : developer.android.com pour ADB, les ANR, Doze, WorkManager, la mémoire, les ABI, JNI, les pages de 16 Ko et les limites de mémoire d'Android 17 ; source.android.com pour Fastboot et le déverrouillage ; le dépôt GitHub de Termux.

### Test d'intégration sur le Honor

Le test a été lancé avec l'accord de l'utilisateur, suivant cette procédure : sauvegarde de la base, 5 tests sur 5, réinstallation, restauration de la base, puis contrôle de l'empreinte et du contenu (45 XP, une leçon, un quiz, trois exercices).

### Non vérifié

- **Commandes qui modifient l'appareil** : Doze forcé, `pm grant` et `revoke`, `am kill`, `pm clear`, `adb pair`, `fastboot` n'ont pas été lancés sur le Honor. Leur syntaxe vient de la documentation. `fastboot version` a seulement été contrôlé.
- **JNI** : les blocs C++ passent l'analyse syntaxique, mais aucune bibliothèque n'a été construite ni chargée.
- **Comportement des extraits Flutter et Android** : ils se typent et compilent, mais aucun n'a été exécuté.
- **CMake, `ndk-stack`, `retrace`, LeakCanary** : présentés d'après la documentation, sans exécution.
- **Autres fabricants** : la remarque sur leurs restrictions de batterie ne repose sur aucun test.

## Phase 5, tour 3 — 2026-11-05

La phase n'est pas terminée : modules 1 à 6 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux | 5 tests sur 5 réussis, trousseau déverrouillé : voir ci-dessous |
| Intégration sur Honor | **Non lancée** : voir ci-dessous |
| Exemples Kotlin et Java compilés, exécutés et comparés | 83 sur 83 |
| Extraits Android compilés dans un projet Gradle | 53 sur 53 |
| Requêtes SQL du cours | Exécutées sur SQLite, résultats cohérents |
| Police de code | Tous les caractères des blocs sont présents |

L'outil de compilation a été éprouvé : une table inexistante dans une requête Room et une erreur de type ont bien fait échouer la compilation. 141 classes ont été produites, et KSP a généré le code Room.

Vérifié sur des rendus de test : quatre leçons des modules 5 et 6.

Sources contrôlées : developer.android.com pour l'état, la navigation, le cycle de vie, ViewModel, les fenêtres adaptatives, Room, DataStore, la sécurité réseau, le hors-ligne et Credential Manager ; le dépôt GitHub de Retrofit ; les dépôts Maven pour les versions.

### Test d'intégration Linux avec un trousseau verrouillé

Le test du coffre a d'abord échoué avec `PlatformException(KeyringLocked)` : le trousseau GNOME était verrouillé après un redémarrage de la machine. Une fois le trousseau déverrouillé par l'utilisateur, les 5 tests sont passés le 2026-11-06.

Ce résultat montre un manque : l'application ne présente pas encore ce cas à l'utilisateur. C'est à traiter en phase 6.

### Tests d'intégration non lancés sur le Honor

Ces tests désinstallent l'application, et la base du téléphone contient désormais la progression réelle de l'utilisateur. Ils n'ont donc pas été lancés. L'utilisateur a accepté une sauvegarde suivie d'une restauration, mais le téléphone n'était plus branché : le test reste à faire. L'APK a été installé par-dessus, et le contenu de la base est identique avant et après l'installation. L'application n'a pas été parcourue sur le téléphone, qui était verrouillé.

### Non vérifié

- **Comportement des extraits Android** : ils compilent, mais aucun n'a été exécuté.
- **Compilation du projet par rapport aux modules 1 à 4** : `tool/check_android_snippets.py` n'a été lancé que sur les modules 5 et 6.
- **Fragments XML** : les balises isolées, comme `<uses-permission>`, ne sont pas compilées.
- **Recommandation sur Navigation 3** : déduite de la documentation, qui l'oriente vers les projets Compose. Aucune page lue ne le formule comme une consigne générale.
- **Repères d'accessibilité** : 48 dp et 4,5:1 viennent de mes connaissances, la page d'accueil lue ne les cite pas.
- **Site de Retrofit** : la page historique renvoie une erreur 404, et le README renvoie vers un domaine non vérifié. Le cours pointe vers le dépôt GitHub.
- **Le contenu n'a pas été relu par un tiers.**

## Phase 5, tour 2 — 2026-11-04

La phase n'est pas terminée : modules 1 à 4 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux et sur Honor | 5 tests sur 5 réussis sur chacun |
| Exemples Kotlin et Java compilés, exécutés et comparés | 70 sur 70 |

Vérifications complémentaires, faites à part :

- **Blocs Gradle du module 4** : assemblés dans un projet Android jetable avec AGP 9.1.0 et Gradle 9.3.1. Variantes, suffixe d'identifiant, catalogue de versions, R8, AAB et signature par `keystore.properties` fonctionnent. L'APK de release porte bien le certificat de la clé de test, lu avec `apksigner`.
- **Interopérabilité** : la classe Kotlin `Potion` et son appel en Java ont été compilés ensemble. La sortie correspond au cours.
- **Commandes lancées sur cette machine** : `emulator -accel-check`, `emulator -list-avds`, `sdkmanager --list_installed`, `avdmanager list device -c`, `keytool -genkeypair`, `keytool -list`, `apksigner verify`, et l'existence des tâches `assembleDebug`, `assembleRelease`, `bundleRelease`, `installDebug`, `lintDebug` et `signingReport`.
- **Police de code** : tous les caractères des blocs existent, y compris le dessin de l'arborescence.

Sources contrôlées sur developer.android.com : accélération de l'émulateur, appareils USB, build, Logcat, signature, débogage, Profiler, `sdkmanager`, interopérabilité et `AsyncTask`.

Vérifié à la main sur le Honor : liste des modules, module Android Studio, leçon de structure de projet avec l'arborescence. Aucun crash ni erreur Flutter dans logcat.

### Non vérifié

- **Extraits non exécutés** : 25 extraits utilisent des API Android ou sont des fragments, listés par `tool/check_course_code.py`. Six d'entre eux relèvent des vérifications complémentaires ci-dessus : quatre blocs Gradle et deux blocs d'interopérabilité. Les 19 autres n'ont été ni compilés ni exécutés.
- **Commandes non lancées** : `avdmanager create avd` et `emulator -avd`, faute d'image système ; `sudo tar`, `apt-get install`, `usermod`, qui modifieraient la machine ; `sdkmanager --licenses`.
- **Installation d'Android Studio** : la procédure n'a pas été rejouée. La page lue ne donnait pas la procédure Linux, l'extraction de l'archive repose sur l'installation présente dans `/opt`. La configuration requise n'est pas chiffrée : le cours renvoie à la page officielle.
- **Interface d'Android Studio** : les noms de menus viennent de la documentation, et ils n'ont pas été vérifiés dans l'application. Les raccourcis F7, F8, F9 et Maj + F8 n'ont pas été recoupés sur une page lue.
- **Nouvelle commande `android sdk`** : mentionnée comme remplaçante de `sdkmanager`, mais non essayée.
- **Le contenu n'a pas été relu par un tiers**, et toutes les leçons n'ont pas été parcourues sur le téléphone.

## Phase 5, tour 1 — 2026-11-04

La phase n'est pas terminée : modules 1 et 2 sur douze.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 192 tests sur 192 réussis |
| Intégration sur Linux et sur Honor | 5 tests sur 5 réussis sur chacun |
| Exemples Kotlin compilés, exécutés et comparés | 41 sur 41 |
| Cohérence des cours | Identifiants, réponses et index validés par les tests |

L'outil de contrôle a été éprouvé : une sortie faussée et un code qui ne compile pas ont bien été signalés.

Sources contrôlées sur developer.android.com : niveaux d'API, AAB, notifications et canaux, stockage, services et types de premier plan, processus, permissions, mémoire. Aucune correction n'a été nécessaire sur les trois leçons existantes.

Vérifié à la main sur le Honor : liste des modules, module Kotlin, lecture d'une leçon avec sa console de résultat. Aucun crash ni erreur Flutter dans logcat.

### Non vérifié

- **Neuf extraits non exécutés** : ils utilisent des API Android, ou sont des fragments, et n'ont été ni compilés ni exécutés.
  - Module 1 : niveaux d'API (2), corrigé `defaultConfig`, permissions, mémoire (2), notifications (2).
  - Module 2 : `viewModelScope`.
- **Trois affirmations du module 1** n'ont pas été recoupées sur une page lue : permissions accordées une seule fois et retrait automatique, depuis Android 11 ; permissions d'exécution depuis Android 6.0 ; message `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- **Android 37** : le SDK de cette machine contient la plateforme 37, absente de la page officielle consultée. La liste des versions est présentée comme des repères.
- **Le contenu n'a pas été relu par un tiers**, et les leçons n'ont pas toutes été parcourues sur le téléphone.
- **Les liens des ressources** ne s'ouvrent pas, et les cinq liens du module Kotlin n'ont pas été testés.

## Phase 4 — 2026-11-04

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 190 tests sur 190 réussis |
| Intégration sur Linux | 5 tests sur 5 réussis |
| Intégration sur Honor MTN-NX1M (Android 16, arm64) | 5 tests sur 5 réussis |

Couvert par les tests :

- **Lecture des cours** : chaque type de bloc, et onze formes de contenu invalide avec localisation de l'erreur.
- **Vrais fichiers de cours** : concordance avec le programme, identifiants uniques, leçons complètes, solutions acceptées, évaluation réalisable.
- **Notation** : questions multiples, seuil inclusif, calcul entier sans erreur d'arrondi.
- **Leçon** : affichage, fin de leçon, passage à la suivante, retour au module, leçon inconnue, cours illisible.
- **Quiz** : réussite, échec, reprise, expérience créditée une fois, réponses conservées au défilement.
- **Exercices** : réponse juste ou fausse, autoévaluation, texte retrouvé en rouvrant la leçon.
- **Évaluation** : fermée tant que des leçons manquent, réussite, échec puis nouvel essai.
- **Reprise** : le bouton Continuer suit la progression.
- **Migration** : d'un vrai fichier v2 vers v3, sans perte, et même schéma qu'une base neuve.

Vérifié à la main sur le Honor :

| Vérification | Résultat |
| --- | --- |
| Mise à jour de la version phase 3 par-dessus | Fichier passé de v2 à v3 |
| Accueil, lecture d'une leçon, défilement | Corrects |
| Réponse à un exercice, validation | « Exercice réussi », +10 XP |
| Fin de leçon, arrêt forcé, relance | 30 XP affichés, Continuer propose la leçon 2, données correctes en base |
| Logcat | Aucun crash ni erreur Flutter |

La base du téléphone ne contenait que des données de test. Elle a été effacée par les tests d'intégration, et l'application réinstallée repart de zéro.

### Non vérifié

- **Contenu** : les trois leçons n'ont pas été relues par un tiers. Les faits, notamment les dates et niveaux d'API, viennent de mes connaissances, sans contrôle en ligne.
- **Quiz et évaluation sur le téléphone** : testés par widgets, pas parcourus à la main sur le Honor.
- **Liens des ressources** : affichés et sélectionnables, ils ne s'ouvrent pas. Leur validité n'a pas été contrôlée.
- **Performances** de longues leçons.
- **Lecteur d'écran** sur les leçons.

## Phase 3 — 2026-11-04

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 137 tests sur 137 réussis |
| Intégration sur Linux | 4 tests sur 4 réussis |
| Intégration sur Honor MTN-NX1M (Android 16, arm64) | 4 tests sur 4 réussis |

Couvert par les tests :

- **Migration** : d'un vrai fichier v1 vers v2, sans perte, et même schéma qu'une base neuve.
- **Progression** : leçons, quiz, expérience créditée une seule fois, y compris en appels simultanés.
- **Notes** : création, relecture, accents et emoji, tri, filtre par module, suppression, note inconnue.
- **Sauvegarde automatique** : délai, sortie immédiate de l'écran, passage en arrière-plan, frappe pendant une écriture, note vide jamais créée, échec puis nouvel essai.
- **Écrans** : annulation et confirmation de suppression, note liée à un module, favoris, question flash.
- **Persistance sur fichier** : notes, progression et favoris relus après fermeture, sur Linux et Android.

Vérifié à la main sur les appareils réels :

| Vérification | Résultat |
| --- | --- |
| Honor : mise à jour de la version phase 2 par-dessus, sans désinstaller | Fichier passé de v1 à v2, réglage conservé, thème clair affiché |
| Honor : bonne réponse à la question flash, arrêt forcé, relance | 10 XP et 1 quiz réussi affichés et présents dans la base |
| Honor : suppression d'une note avec confirmation | Note retirée de la base |
| Honor : logcat | Aucun crash ni erreur Flutter |
| Linux : lancement réel | Base v2 créée dans `~/.local/share/`, plus rien écrit dans `~/Documents` |

Sauvegarde des notes sur le Honor, avec arrêt forcé :

| Scénario | Résultat |
| --- | --- |
| Arrêt 2 s après la frappe | Note conservée |
| Arrêt environ 860 ms après le début de la frappe | Note conservée |
| Touche Accueil puis arrêt forcé immédiat, délai alors de 600 ms | **Note perdue** |

Le délai a ensuite été réduit à 300 ms. Le scénario perdant n'a pas été rejoué : la fenêtre est réduite, pas supprimée. L'enregistrement au passage en arrière-plan est prouvé par un test de widget, mais il n'a pas été isolé sur le téléphone.

Bugs trouvés et corrigés pendant la phase :

- La base était écrite dans `~/Documents` sur Linux.
- La tuile « Badges obtenus » affichait un zéro figé pour une fonction inexistante.

### Non vérifié

- **Base corrompue ou disque plein** sur un appareil réel : seules des erreurs simulées sont testées.
- **Performances** avec un grand nombre de notes.
- **Saisie sur Linux** : l'écran des notes n'y a pas été essayé à la main.

## Phase 2 — 2026-11-04

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 89 tests sur 89 réussis |
| Intégration sur Linux | 3 tests sur 3 réussis |
| Intégration sur Honor MTN-NX1M (Android 16, arm64) | 3 tests sur 3 réussis |

Couvert par les tests :

- **Mise en page** : tous les écrans, en 6 formats, thèmes clair et sombre, texte à 100 % et 200 %, sans débordement.
- **Contraste** : texte sur toutes les surfaces des deux thèmes, code et console, à 4,5:1 minimum.
- **Composants** : correction du quiz, mascotte dans chaque humeur, arrêt de sa boucle, dépliage du grimoire, copie réelle du code, barre d'expérience.
- **Apparence** : enregistrement, relecture, valeur invalide, échec de lecture et d'écriture.
- **Navigation** : onglets, programme d'un module et retour, raccourcis, chemins inconnus.

Bugs trouvés et corrigés pendant la phase :

- Le rail débordait sur un téléphone en paysage.
- `AnimatedSize` plantait quand les animations étaient désactivées.
- Les tuiles laissaient un vide à droite sur grand écran, défaut vu sur la capture Linux.

Vérifié à la main sur l'application réelle :

| Vérification | Résultat |
| --- | --- |
| Honor : écrans Accueil, Plus et Paramètres | Corrects |
| Honor : thème clair et animations réduites, puis arrêt forcé et relance | Réglages conservés, nouveau processus confirmé |
| Honor : logcat | Aucun crash ni erreur Flutter |
| Linux : accueil en thème sombre | Correct sur capture de la fenêtre |

Sur le Honor, les captures montrent des couleurs légèrement différentes de la palette. Les valeurs correspondent à l'espace colorimétrique Display P3 utilisé par Flutter sur cet appareil : c'est un artefact de capture, pas une erreur de couleur.

### Non vérifié

- **Performances** : seul le mode debug a été exécuté, aucune mesure n'a été faite.
- **Lecteur d'écran** : les libellés sont testés, mais TalkBack et Orca n'ont pas été essayés.
- **Icône Android** : générée et installée, mais pas contrôlée à l'œil sur l'écran d'accueil du téléphone.
- **Sur Linux**, seul l'écran d'accueil a été regardé. Les autres écrans ont été vus sur des rendus de test et, pour trois d'entre eux, sur le Honor.

## Phase 1 — 2026-11-04

Environnement : Ubuntu 22.04 x86_64, Flutter 3.47.2, Dart 3.13.2.

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Aucun problème |
| `flutter test` | 12 tests sur 12 réussis |
| `flutter test integration_test -d linux` | 3 tests sur 3 réussis |
| `flutter test integration_test` sur Honor MTN-NX1M (Android 16, API 36, arm64) | 3 tests sur 3 réussis |
| Lancement de l'application sur le Honor (debug) | Démarrage en 3,3 s, écran d'accueil correct sur capture, aucune erreur dans logcat |

Couvert par les tests :

- Démarrage, onglets, page Plus, position conservée entre onglets, chemin inconnu.
- Barre basse et rail selon la largeur.
- Affichage sur 320 × 568 avec texte à 150 %. Ce test a révélé un débordement, corrigé en rendant les pages défilantes.
- SQLite : lecture et écriture en mémoire, conservation après réouverture d'un fichier sur Linux et Android.
- Coffre : écriture, lecture et effacement dans le vrai trousseau Linux et dans le stockage sécurisé Android.

## Non vérifié

- **Android release** : seul le mode debug a été exécuté.
- **Autres appareils Android** : un seul modèle testé, arm64. Les versions armeabi-v7a et x86_64 n'ont pas été lancées.
- **Rendu visuel Linux** : capture noire pendant cette phase, sous l'économiseur d'écran. Confirmé en phase 2.
