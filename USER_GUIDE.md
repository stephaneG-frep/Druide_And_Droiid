# Mode d'emploi

Ce guide reprend l'essentiel. Dans l'application, la rubrique **Plus**, **Grimoire** en donne la version complète, et le bouton d'aide des écrans les plus riches ouvre directement le bon passage.

## Installer

- **Android** : ouvrez le fichier `Druide_And-Droiid_v1.0.0.apk` sur le téléphone et acceptez l'installation depuis cette source. Android 7.0 au minimum.
- **Ubuntu** : dans un terminal, `sudo apt install ./Druide_And-Droiid_v1.0.0_amd64.deb`. L'application apparaît dans le menu.

Vos données restent sur l'appareil. Une désinstallation sur Android les efface : exportez d'abord une sauvegarde. Sur Ubuntu, elles restent dans votre dossier personnel.

## Se déplacer

- **Sur téléphone** : utilisez la barre en bas de l'écran.
- **Sur ordinateur** : utilisez le rail à gauche de la fenêtre.
- **Rubrique Plus** : elle regroupe le Chaudron des Bugs, les Projets, la Progression, le Grimoire et les Paramètres.

Toucher à nouveau l'onglet actif ramène à sa page de départ.

## Ce qui est disponible

- **Accueil** : votre grade, vos statistiques et une question flash chaque jour.
- **Académie** : le programme des douze modules et vos favoris. Les douze modules sont rédigés. Le module Expert Android se termine par un projet réel, que vous évaluez avec sa grille : l'application ne le corrige pas à votre place.
- **Maître** : votre professeur IA, relié au fournisseur de votre choix. Sans fournisseur, l'application reste complète, mais le Maître ne répond pas.
- **Mes notes** : vos notes personnelles.
- **Lab** : un éditeur de code, des exercices Kotlin, Java, Dart et XML, et des feuilles libres.
- **Chaudron des Bugs** : l'analyse de vos erreurs, avec ou sans IA.
- **Projets** : vingt projets pratiques et l'évaluation finale.
- **Progression** : grades, badges, défis, statistiques et certificats internes.
- **Grimoire** : le mode d'emploi complet.
- **Paramètres** : le thème, les animations, le Maître, les sauvegardes et les licences.

Toutes vos données restent sur cet appareil, et s'enregistrent automatiquement. Pour les garder en cas de désinstallation ou de changement d'appareil, exportez une sauvegarde : voir plus bas.

## Suivre une leçon

Sur l'**Accueil**, le bouton **Continuer** ouvre votre prochaine leçon. Vous pouvez aussi passer par **Académie**, puis un module.

Une leçon contient un cours, un quiz et des exercices. Touchez **Terminer la leçon** quand vous avez fini : le quiz et les exercices restent facultatifs.

**Quiz** : répondez à toutes les questions, puis validez. Il faut 70 % pour réussir. Vous voyez ensuite la correction, et vous pouvez recommencer autant de fois que vous le voulez.

**Exercices** : il y en a deux sortes.

- **Réponse courte** : touchez **Vérifier** pour la correction automatique. Les majuscules ne comptent pas.
- **Réponse libre** : écrivez votre réponse, ouvrez la correction, puis indiquez vous-même si vous avez réussi.

Le code que vous écrivez n'est pas exécuté dans ces exercices. Vos réponses sont enregistrées automatiquement.

**Évaluation** : elle s'ouvre quand toutes les leçons du module sont terminées. C'est une évaluation interne à l'application, pas une certification professionnelle.

## Prendre des notes

Ouvrez **Plus**, puis **Mes notes**, et touchez **Nouvelle note**. Depuis la page d'un module, **Ajouter une note** la rattache à ce module.

Vos notes s'enregistrent toutes seules pendant que vous écrivez : il n'y a pas de bouton Enregistrer. Si un enregistrement échoue, votre texte reste à l'écran et un bouton **Réessayer** apparaît.

Pour supprimer une note, ouvrez-la et touchez la corbeille. Une confirmation vous est demandée, car cette action est définitive.

## Gagner de l'expérience

| Action | XP |
| --- | --- |
| Terminer une leçon | 20 |
| Réussir le quiz d'une leçon | 15 |
| Réussir un exercice | 10 |
| Réussir l'évaluation d'un module | 50 |
| Question flash du jour, juste du premier coup | 10 |

Chaque récompense n'est gagnée qu'une fois. Vous pouvez recommencer pour vous entraîner.

## Marquer un module en favori

Ouvrez un module et touchez l'étoile en haut de l'écran. Il apparaît alors dans **Vos favoris**, en haut de l'Académie.

## Changer l'apparence

Ouvrez **Plus**, puis **Paramètres**.

- **Thème** : Sombre, Clair, ou celui du système.
- **Animations** : Toutes, Réduites ou Aucune.

Vos choix sont conservés au redémarrage.

## Relier le Maître à une IA

1. Ouvrez **Plus**, **Paramètres**, puis **Réglages du Maître**.
2. Choisissez un fournisseur : Anthropic Claude, OpenAI, Google Gemini, Ollama ou une API compatible avec OpenAI.
3. Saisissez votre clé, si le service en demande une. Elle reste dans le stockage sécurisé de votre appareil : elle n'est jamais affichée, ni incluse dans les sauvegardes.
4. Touchez **Tester la connexion**. Ce test liste les modèles et ne génère aucune réponse.
5. Choisissez un modèle, puis touchez **Enregistrer et activer**.

Avant le premier envoi vers un service externe, l'application vous demande votre accord. Ces services peuvent facturer chaque réponse sur votre compte : fixez un plafond de dépenses chez eux. Les tarifs facultatifs des réglages servent seulement à afficher une estimation.

Avec Ollama sur Linux, gardez l'adresse proposée. Sur un téléphone relié en USB, lancez `adb reverse tcp:11434 tcp:11434`, à refaire après avoir débranché le câble. Sur l'émulateur, utilisez `http://10.0.2.2:11434`.

Les réponses sont générées par une IA et peuvent contenir des erreurs. Relisez tout code avant de l'utiliser : l'application ne l'exécute jamais.

## Utiliser le Lab

Votre code s'enregistre tout seul. **Enregistrer une version** le garde dans l'**Historique**, d'où vous pouvez le comparer ou y revenir. **Comparer au corrigé** montre les différences, et **Exporter** crée un fichier.

**Sur Linux**, **Exécuter** utilise les vrais compilateurs de votre machine. Un exercice est réussi quand la sortie correspond à celle attendue. Le code s'exécute avec vos droits : le Lab limite sa durée et sa sortie, mais ce n'est pas un bac à sable. N'exécutez que du code que vous avez lu et compris, y compris celui d'une IA.

Les fichiers exportés arrivent dans le dossier Téléchargements, sous `Druide And-Droiid`. **Outils Linux** indique ce qui est installé, avec la procédure pour le reste. Le Lab n'installe rien lui-même.

**Sur téléphone**, le code Kotlin, Java et Dart ne s'exécute pas, car aucun compilateur n'y tourne. Le Lab ne simule rien : comparez avec le corrigé, demandez une correction au Maître, ou reprenez le code sur Linux. **Je valide moi-même** marque un exercice comme réussi, sur votre seule appréciation. Le XML est réellement analysé sur les deux plateformes : syntaxe et éléments attendus, sans compilation Android.

## Utiliser le Chaudron des Bugs

Collez une erreur, importez un fichier de journal, décrivez le problème et ajoutez un extrait de code si besoin. Sur Linux, **Lire les plantages (ADB)** récupère le tampon des plantages de l'appareil branché.

**Fiches reconnues** : l'application cherche des mots-clés dans 37 fiches rédigées à l'avance, sans IA. Elle fonctionne sans connexion et peut se tromper. Les **diagnostics guidés** donnent accès aux mêmes fiches, par famille de panne.

**Analyse IA** : avec un fournisseur configuré, le Maître répond en six parties. Avant l'envoi, vous relisez exactement ce qui part. Les clés, mots de passe, courriels et noms d'utilisateur repérés sont masqués, mais ce filtre est imparfait. La qualité de l'analyse dépend du modèle : un petit modèle local peut se tromper franchement.

**Vérification** : un dossier reste **Non vérifié** tant que vous n'avez pas noté le résultat d'un essai. Ni une fiche ni une IA ne peut déclarer un problème résolu.

## Suivre un projet

**Plus**, **Projets** propose vingt projets, du débutant à l'expert. Chacun donne un objectif, des prérequis, des étapes avec du code, un test, un questionnaire et des critères de réussite.

Les projets se réalisent dans Android Studio ou votre éditeur : le code fourni guide votre travail, et ne forme pas toujours une application complète. Cochez une étape quand vous avez observé ce qu'elle demande.

**Valider le projet** exige toutes les étapes, le questionnaire, tous les critères et une preuve écrite, comme l'adresse de votre dépôt. Décocher un élément annule la validation. C'est une autoévaluation : l'application ne lit pas votre code.

**Évaluation finale** : la grille du module Expert Android, notée sur 100. Une note sans preuve compte pour zéro. La validation demande 70 points, avec au moins 10 en sécurité et 10 en tests.

## Progresser

**Plus**, **Progression** rassemble votre grade, votre objectif de la semaine, votre parcours, les défis, vos statistiques, vos badges et vos certificats.

- **Expérience** : chaque action ne rapporte qu'une fois. Leçon 20 XP, quiz 15, exercice 10, évaluation de module 50, exercice du Lab 15, projet de 50 à 200 selon son niveau, évaluation finale 500. Un bug vérifié rapporte 20 XP, pour dix dossiers au plus. Grand Druide And-Droiīd demande 9 000 XP : il faut avoir parcouru presque tout le programme.
- **Défis** : deux défis du jour et un de la semaine. Une fois accompli, touchez **Réclamer**.
- **Parcours** : choisissez un objectif. **Continuer** ouvre la prochaine leçon à suivre.
- **Badges** : ils se débloquent automatiquement, et restent acquis.
- **Certificats internes** : un par module terminé, avec son évaluation. Ce ne sont ni des diplômes, ni des certifications professionnelles officielles.

L'expérience du Lab, des projets, des bugs et de l'évaluation finale s'ajoute au moment de l'action, ou à la prochaine ouverture de la page Progression. Sur téléphone, un exercice du Lab validé par vous-même rapporte la même expérience : la note repose sur votre honnêteté.

## Sauvegarder et restaurer

Dans **Plus**, **Paramètres**, **Sauvegardes** :

- **Exporter en JSON** : un fichier qui contient toutes vos données.
- **Sauvegarde complète (ZIP)** : la même sauvegarde, plus vos notes, vos réponses et votre code dans des fichiers lisibles.
- **Mes exercices (Markdown)** et **Mes notes (PDF)** : des copies à lire ou à imprimer.
- **Restaurer depuis un fichier** : choisissez une sauvegarde JSON ou ZIP. Toutes vos données actuelles sont remplacées, après confirmation. Une copie de l'état actuel est créée juste avant.

Chaque jour d'utilisation, une copie de sécurité est créée dans le dossier privé de l'application. Les cinq plus récentes sont gardées, et elles se restaurent depuis le même écran. Elles disparaissent avec l'application : seule une sauvegarde exportée vous protège d'une désinstallation.

Les clés d'API ne sont jamais sauvegardées : saisissez-les de nouveau après une restauration.

Sur téléphone, le sélecteur du système vous laisse choisir l'emplacement. Sur Linux, une boîte de dialogue s'ouvre. Si elle ne peut pas s'ouvrir, le fichier va dans Téléchargements, sous `Druide And-Droiid`.

## Exporter en PDF

Le bouton PDF, en haut de l'écran, exporte un module de l'Académie (cours et corrigés), vos notes, une fiche de projet ou un certificat interne.

## Sans connexion

Les cours, quiz, exercices, corrigés, notes, le Lab, le Chaudron, les projets et la progression fonctionnent sans Internet. Les fournisseurs IA distants ont besoin d'une connexion, et la page Maître l'indique. Ollama fonctionne sans Internet, s'il est installé et lancé.
