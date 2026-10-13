# FICTIF – EXERCICE – FICTIF

> **Ce document est inventé pour l'exercice du Game Day.** Il ne décrit aucun incident réel et ne vise aucune personne ni aucun projet réel. La bibliothèque citée est utilisée uniquement parce qu'elle est présente dans nimbus-notes.

---

## Bulletin de sécurité NIMBUS-FICTIF-2026-001

**Émetteur (fictif) :** cellule sécurité de la Banque Azur
**Niveau :** CRITIQUE (fictif)
**Objet :** publication compromise de la bibliothèque Python `click`

### Ce que nous savons (fictivement)

Un mainteneur aurait vu son compte détourné. Des versions de la bibliothèque `click` publiées avec le code d'un attaquant circuleraient sur l'index de paquets. Le code ajouté chercherait à lire des variables d'environnement.

| | Versions |
|---|---|
| **Touchées** | `8.0.0` à `8.1.8` (incluses) |
| **Saines** | `8.2.0` et supérieures |

### Ce que la Banque Azur demande à ses fournisseurs, sous 24 heures

1. Dire si vos livrables **contiennent** cette bibliothèque, et dans quelle version. Une réponse sans preuve ne sera pas acceptée.
2. Si oui, livrer une version corrigée et **relancer** votre pipeline de sécurité.
3. Confirmer qu'**aucune image non vérifiée** n'est en circulation chez vous.
4. Transmettre un compte rendu d'incident (post-mortem).

### Deuxième alerte (fictive)

Le registre d'images de Nimbus contient **une étiquette (tag) qui n'était pas prévue** : une image « hotfix » dont personne ne retrouve l'origine. Il faut établir laquelle des images présentes a été signée par Nimbus, et laquelle ne l'a pas été.

---

*Rappel : ceci est un exercice. Ne partagez pas ce bulletin comme s'il était réel.*
