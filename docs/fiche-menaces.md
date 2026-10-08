# Fiche de modélisation des menaces : nimbus-notes (TP1, partie a)

**Objectif :** trouver au moins une menace pour chaque lettre de STRIDE. Pas besoin d'être expert : posez-vous les six questions du tableau en regardant le schéma.

## Le schéma de nimbus-notes

```
                       (1) HTTPS                         (3) fichier
  Utilisateur  ───────────────────►  API Flask  ──────────────────────►  Base SQLite
  (navigateur,          Internet     (conteneur Docker)                   (nimbus.db)
   application)
                                         ▲
                                         │ (2) jeton d'API
                                         │    (config.py)
   Développeur ──► Git/GitHub ──► Pipeline GitHub Actions ──► Image Docker ──► Serveur AWS
                      (4)               (5)                       (6)              (7)
                                                                            + bucket de sauvegardes
                                                                            + base PostgreSQL
```

Les flèches et les boîtes sont les endroits où quelque chose peut mal se passer. Les numéros vous aident à indiquer **où** vous placez chaque menace.

## STRIDE en six questions

| Lettre | La question à se poser | Exemple de la vie courante | Menace trouvée sur nimbus-notes | Où (n°) | Parade possible |
|---|---|---|---|---|---|
| **S**poofing (usurpation) | Quelqu'un peut-il se faire passer pour un autre ? | Un faux livreur sonne à la porte | | | |
| **T**ampering (altération) | Quelqu'un peut-il modifier ce qu'il ne devrait pas ? | Une lettre ouverte et recollée | | | |
| **R**epudiation (déni) | Peut-on nier avoir fait une action, faute de trace ? | « Ce n'est pas moi qui ai signé ! » sans registre | | | |
| **I**nformation disclosure (fuite) | Une information peut-elle être vue par qui ne devrait pas ? | Un dossier laissé ouvert sur un banc public | | | |
| **D**enial of service (indisponibilité) | Peut-on empêcher le service de fonctionner ? | Un camion garé devant l'entrée du magasin | | | |
| **E**levation of privilege (élévation de privilèges) | Quelqu'un peut-il obtenir plus de droits que prévu ? | Un stagiaire qui trouve le passe-partout | | | |

## Pour vous aider (si vous séchez)

- Qui peut appeler `POST /notes` ? Comment le serveur sait-il qui c'est ?
- Où est le jeton d'API ? Qui peut le lire ?
- Que se passe-t-il si une personne malveillante peut modifier le pipeline ou une dépendance ?
- Qu'est-ce qui est écrit dans les journaux ?
- Que se passe-t-il si quelqu'un envoie des milliers de requêtes ?

## Classez vos trois menaces les plus importantes

Risque = probabilité x impact. Choisissez les trois menaces qui, selon vous, méritent d'être traitées en premier et expliquez pourquoi en une phrase chacune.

1.
2.
3.
