# Post-mortem : [titre court de l'incident]

**Équipe :** [noms]  **Date :** [jj/mm/2026]  **Rédigé en :** [x] minutes

> Un post-mortem n'est pas un tribunal. On cherche ce qui a permis l'incident et ce qu'on change, pas un coupable. Une page suffit.

## 1. Résumé (3 phrases maximum)
Que s'est-il passé, quel était l'impact, comment cela s'est-il terminé ?

## 2. Chronologie
| Heure | Événement | Qui |
|---|---|---|
| | Alerte reçue | |
| | | |
| | Incident clos | |

## 3. Impact
- Notre application était-elle touchée ? **Preuve** (commande, extrait de SBOM) :
- Des images non vérifiées étaient-elles en circulation ? **Preuve** :

## 4. Comment l'avons-nous détecté / vérifié ?
Outils utilisés (SBOM, scan, vérification de signature) et ce qu'ils ont montré.

## 5. Cause(s)
Pourquoi cela a-t-il été possible ? (Pensez système et processus, pas personne.)
- Cause directe :
- Cause profonde (« pourquoi ? » posé trois fois) :

## 6. Ce que nous avons fait
- Correction appliquée (fichier, version avant/après) :
- Pipeline relancé : [vert / rouge] — lien ou capture :
- Image(s) retirée(s) / bloquée(s) :

## 7. Ce qui a bien fonctionné
-

## 8. Ce qui a mal fonctionné ou manqué
-

## 9. Actions pour que cela ne se reproduise pas
| Action | Responsable | Échéance |
|---|---|---|
| | | |
| | | |
| | | |
