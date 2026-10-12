#!/usr/bin/env bash
# À lancer UNE FOIS avant le cours, avec une bonne connexion (maison, ou réseau de l'école hors cours).
# Télécharge toutes les images Docker utilisées par les TP et la base de vulnérabilités de trivy,
# pour que les scans fonctionnent ensuite même avec un Wi-Fi lent.
# Compter 2 à 4 Go de téléchargement et 5 à 15 minutes.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
titre "Téléchargement des images Docker"

# Images des outils (versions épinglées dans outils/_commun.sh) et images de base des TP
IMAGES="$IMG_GITLEAKS $IMG_SEMGREP $IMG_TRIVY $IMG_SYFT $IMG_COSIGN $IMG_REGISTRY
$IMG_ACTIONLINT $IMG_TERRAFORM
python:3.9.18-slim python:3.12-slim-bookworm alpine:3.20"

echecs=0
for image in $IMAGES; do
  printf '  %-52s ' "$image"
  if docker image inspect "$image" >/dev/null 2>&1; then
    echo "déjà présente"
  elif docker pull -q "$image" >/dev/null 2>&1; then
    echo "téléchargée"
  else
    echo "ÉCHEC"
    echecs=$((echecs + 1))
  fi
done

titre "Téléchargement de la base de vulnérabilités et des règles de trivy"
docker volume create nimbus-trivy-cache >/dev/null
# Une analyse à blanc suffit : trivy télécharge la base de CVE et ses règles de configuration.
if trivy_docker fs --quiet --scanners vuln --skip-dirs .git /src >/dev/null 2>&1 \
   && trivy_docker config --quiet /src/infra >/dev/null 2>&1; then
  succes "Base trivy prête (cache : volume Docker nimbus-trivy-cache)."
else
  echec "Le téléchargement de la base trivy a échoué (connexion ?). Relancez le script."
  echecs=$((echecs + 1))
fi

titre "Fournisseur Terraform AWS (pour la validation du TP5, facultatif)"
if "$RACINE/outils/valider-terraform.sh" >/dev/null 2>&1; then
  succes "Fournisseur AWS téléchargé (cache : volume nimbus-tf-cache)."
else
  alerte "Validation Terraform non préchargée (pas bloquant : le TP5 se fait sans)."
fi

echo
if [ "$echecs" -gt 0 ]; then
  echec "$echecs téléchargement(s) en échec. Relancez ./outils/precharger.sh avec une meilleure connexion."
  exit 1
fi
succes "Tout est prêt. Vous pouvez travailler hors ligne : export NIMBUS_HORS_LIGNE=1 évite les mises à jour de trivy."
