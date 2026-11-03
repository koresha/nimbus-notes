# Exigences de l'audit — Banque Azur (document fictif, distribué en séance 6)

**De :** Direction de la sécurité, Banque Azur
**À :** Nimbus, équipe plateforme
**Objet :** audit de la chaîne de livraison de `nimbus-notes`, jeudi matin

Avant de signer, nous auditons la manière dont votre logiciel est construit et livré. Voici ce que nous vérifierons. Cochez chaque ligne lorsque vous pouvez la prouver dans le dépôt ou dans le pipeline.

| # | Exigence | Preuve attendue | Séance | Fait |
|---|---|---|---|---|
| 1 | Aucun secret dans le code ni dans l'historique non traité | Rapport gitleaks vide ou exceptions documentées dans `.gitleaksignore`, hook pre-commit installé | S2 | ☐ |
| 2 | Le code est analysé automatiquement | semgrep sans constat grave, règles présentes dans le dépôt | S3 | ☐ |
| 3 | Les dépendances vulnérables sont corrigées ou justifiées | trivy sur `requirements.txt` sans vulnérabilité critique non justifiée, exceptions datées dans `.trivyignore` | S3 | ☐ |
| 4 | Le pipeline bloque les problèmes graves | Workflow `securite.yml` avec permissions minimales, actions épinglées par SHA, échec sur constat grave | S4 | ☐ |
| 5 | L'image de conteneur est minimale et ne tourne pas en root | Dockerfile multi-stage, utilisateur non-root, scan d'image dans le pipeline | S5 | ☐ |
| 6 | L'infrastructure as code est scannée et sans erreur de configuration critique | trivy config sur `infra/` sans constat critique, scan IaC dans le pipeline | S6 | ☐ |
| 7 | Une SBOM est produite pour chaque image livrée | Fichier SBOM généré dans le pipeline, scanné | S7 | ☐ |
| 8 | Les images sont signées et la signature est vérifiable | Signature cosign dans le registre, vérification documentée | S7 | ☐ |

Nous nous réservons le droit de vous soumettre un scénario d'incident pendant l'audit.

*Tout ce document est un exercice pédagogique. La Banque Azur n'existe pas.*
