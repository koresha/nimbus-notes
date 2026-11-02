# nimbus-notes

API de prise de notes de **Nimbus**, une jeune startup. Écrite vite, sans sécurité. Dans quelques jours, un gros client (la banque fictive *Banque Azur*) va auditer la chaîne de livraison. Votre mission, séance après séance : la rendre présentable.

> **Tout ce dépôt est un exercice.** Les secrets, mots de passe, jetons et ressources AWS qu'il contient sont **fictifs** : ils ne donnent accès à rien. Rien n'est jamais déployé.

Ce dépôt accompagne le cours DevSecOps de l'ESGI (M2 Systèmes, Réseaux et Cloud Computing). Les fiches de TP sont fournies à part par votre formateur.

## Ce qu'il y a dedans

| Chemin | Rôle |
|---|---|
| `app/` | L'API Flask : `__init__.py` (démarrage, `/health`), `notes.py` (routes), `db.py` (SQLite) |
| `config.py`, `run.py` | Configuration et point d'entrée |
| `tests/` | Tests `pytest` (quelques tests simples) |
| `requirements.txt` | Les bibliothèques Python utilisées (versions épinglées) |
| `Dockerfile` | Construit l'image de l'API |
| `infra/` | Terraform AWS (bucket, réseau, base) : **jamais appliqué** |
| `exercices/` | Ancien pipeline à relire au TP3 (rangé ici pour ne pas s'exécuter) |
| `.github/workflows/` | Pipelines GitHub Actions (créé au TP3) |
| `outils/` | Scripts de sécurité (tout tourne dans Docker) |
| `docs/fiche-menaces.md` | Fiche de modélisation des menaces (TP1) |
| `game-day/` | Matériel de la dernière séance |

## Prérequis

- **Git**, **Docker** (Docker Desktop lancé) et **VS Code**.
- Un compte GitHub.
- Windows : travaillez dans **Git Bash** ou **WSL2** (les scripts sont en bash).
- Rien d'autre : gitleaks, semgrep, trivy, syft, cosign tournent dans des conteneurs.

## Lancer l'API

```bash
docker build -t nimbus-notes:local .
docker run --rm -p 8000:5000 nimbus-notes:local
```

Dans un deuxième terminal :

```bash
curl http://localhost:8000/health
curl http://localhost:8000/notes
curl "http://localhost:8000/notes/search?q=audit"
```

Arrêt : `Ctrl+C` dans le premier terminal.

| Route | Rôle |
|---|---|
| `GET /health` | Santé du service : `{"status": "ok"}` |
| `GET /notes` | Liste toutes les notes |
| `POST /notes` | Crée une note (JSON `{"titre": "...", "contenu": "..."}`, en-tête `X-Nimbus-Token` obligatoire) |
| `GET /notes/search?q=mot` | Cherche `mot` dans le titre des notes |

## Lancer les tests

```bash
./outils/tester.sh
```

## Les scripts de sécurité (`outils/`)

Tous se lancent depuis la racine du dépôt, sans rien installer d'autre que Docker. Chacun affiche un résultat lisible et se termine par un **code de sortie non nul en cas de problème** (c'est ce qui fait échouer un pipeline).

| Script | Rôle | Outil |
|---|---|---|
| `./outils/scan-tout.sh` | Lance tout et affiche le **score** (nombre de problèmes) | tous |
| `./outils/scan-secrets.sh` | Secrets dans l'historique Git (`--fichiers` : dans les fichiers actuels) | gitleaks |
| `./outils/scan-code.sh` | Motifs dangereux dans le code (règles dans `outils/regles-semgrep.yml`, hors ligne) | semgrep |
| `./outils/scan-deps.sh` | Dépendances vulnérables (`requirements.txt`) | trivy |
| `./outils/scan-image.sh` | Construit puis analyse l'image Docker | trivy |
| `./outils/scan-iac.sh` | Erreurs de configuration Terraform (`infra/`) | trivy config |
| `./outils/sbom.sh` | Génère la SBOM d'une image | syft |
| `./outils/scan-sbom.sh` | Analyse une SBOM | trivy |
| `./outils/registre-local.sh` | Démarre un registre d'images local (`localhost:5001`) | registry:2 |
| `./outils/signer.sh` | Crée les clés (`--init-cles`) et signe une image | cosign |
| `./outils/verifier.sh` | Vérifie la signature d'une image | cosign |
| `./outils/lint-workflows.sh` | Vérifie la syntaxe des workflows GitHub Actions avant de pousser | actionlint |
| `./outils/valider-terraform.sh` | Valide la syntaxe Terraform de `infra/` (rien n'est déployé) | terraform |
| `./outils/tester.sh` | Lance les tests pytest | python |
| `./outils/installer-hook.sh` | Installe un hook Git qui bloque les commits contenant un secret | gitleaks |
| `./outils/precharger.sh` | **À lancer avant le cours** : télécharge images et base de vulnérabilités | docker |

Les versions des outils sont **épinglées** dans `outils/_commun.sh` : tout le monde obtient les mêmes résultats.

Astuce : `export NIMBUS_HORS_LIGNE=1` empêche trivy de chercher des mises à jour de sa base (après `precharger.sh`, utile si le Wi-Fi est lent).

## Les codes de sortie

| Code | Signification |
|---|---|
| 0 | Rien à signaler |
| 1 | Au moins un problème trouvé : le pipeline doit échouer |
| 2 | L'outil n'a pas pu s'exécuter (Docker éteint, pas de réseau...) |

## Avertissement

Les « mauvaises pratiques » de ce dépôt sont **volontaires et fictives**. Ne copiez jamais ce code en production.
