# Direction artistique

Univers : une académie technomagique, entre laboratoire de savant fou, atelier électronique et grimoires numériques. Référence complète : section 2 de [SPEC.md](SPEC.md).

Le code du système de design se trouve dans `lib/design_system/` et `lib/app/theme/`.

## Couleurs

La palette de la spec est définie dans `palette.dart`. `techno_colors.dart` la décline par thème.

| Rôle | Sombre | Clair |
| --- | --- | --- |
| Émeraude | `#00D68F` | `#00704C` |
| Violet | `#B9A3FF` | `#5B35D5` |
| Orange | `#FFAA33` | `#8A4F00` |
| Cyan | `#00D9FF` | `#00657C` |
| Fond | `#0B1020` | `#F7F5FF` |

Le violet `#865DFF` de la spec est trop sombre pour du texte sur fond sombre. Il reste utilisé dans la mascotte, et une version éclaircie sert au texte. Le thème clair utilise des teintes foncées pour la même raison. Tous les textes atteignent un contraste WCAG AA d'au moins 4,5:1, vérifié par `test/design_system/contrast_test.dart`.

Le thème sombre est le thème par défaut. Il porte l'identité de l'application.

## Typographie

Les polices sont embarquées dans `assets/fonts/`, sous licence SIL OFL, pour fonctionner hors ligne.

| Usage | Police |
| --- | --- |
| Titres | Chakra Petch |
| Texte courant | Atkinson Hyperlegible, conçue pour la lisibilité |
| Code | IBM Plex Mono |

Les trois couvrent le français et le **ī** de « Droiīd ». Toute nouvelle police doit être contrôlée sur ce caractère.

## Signature visuelle

- **Coins biseautés** en haut à droite et en bas à gauche, sur tous les composants.
- **Circuit imprimé** discret en arrière-plan de chaque écran.
- **Dégradé émeraude vers cyan** réservé à l'action principale.

## Mascotte : Maître And-Droiīd

Dessinée en vectoriel dans `mascot_painter.dart`, sans fichier image : capuche, yeux à LED, barbe en fibres optiques, bâton lumineux, oreillettes électroniques.

Humeurs : neutre, joyeux, pensif, surpris, encourageant.

Animation discrète, sur une boucle de 7 secondes : clignement, onde dans la barbe, pulsation du bâton. Elle ne tourne qu'au niveau d'animation « Toutes ».

## Animations

| Niveau | Effet |
| --- | --- |
| Toutes | Transitions et boucle de la mascotte |
| Réduites | Transitions raccourcies de moitié, aucune boucle |
| Aucune | Aucune animation |

La réduction demandée par le système prime toujours sur ce réglage.

## Composants

| Spec | Composant | Utilisé dans |
| --- | --- | --- |
| Cartes de cours | `CourseCard`, sur `TechnoCard` | Académie |
| Grimoires interactifs | `GrimoirePanel` | Grimoire |
| Boutons technomagiques | `ArcaneButton` | Accueil, page 404 |
| Badges de progression | `RuneBadge` | Progression |
| Barres d'expérience | `XpBar` | Accueil, Progression |
| Fenêtres de dialogue IA | `DialogueBubble` | Maître, Chaudron |
| Éditeur de code | `CodePanel`, en lecture seule | Lab |
| Console pédagogique | `ConsolePanel` | Lab |
| Tableaux de bord | `StatTile`, `AdaptiveGrid` | Accueil |
| Quiz animés | `QuizCard` | Accueil |
| Notifications visuelles | `showDruideToast` | Copie de code, erreurs de réglage |

L'édition de code proprement dite arrive en phase 7.

`DialogueBubble` exige d'indiquer l'origine du message, pour qu'un texte rédigé à l'avance ne passe jamais pour une réponse d'IA.

## Mise en page

- Rail latéral à partir de 840 × 560 px, barre basse sinon. Les téléphones en paysage gardent la barre basse.
- Contenu limité à 1 100 px de large et centré.
- Grilles à nombre de colonnes adaptatif.
- Cibles tactiles d'au moins 48 px.
