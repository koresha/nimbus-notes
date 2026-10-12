#!/usr/bin/env bash
# Analyse de l'infrastructure as code (Terraform) avec trivy config : cherche les erreurs
# de configuration (bucket public, port ouvert au monde, absence de chiffrement...).
# Usage : ./outils/scan-iac.sh [dossier]     (défaut : infra ; essayez aussi « . » pour le Dockerfile)
# Rien n'est déployé : on lit seulement les fichiers.
# Code de sortie : 0 = rien, 1 = erreurs de configuration, 2 = erreur d'outil.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
cible="${1:-infra}"
titre "Configuration de l'infrastructure : $cible (trivy config)"
info "Les règles de sécurité sont du « policy as code » : écrites comme du code, vérifiées automatiquement."

sortie="$(trivy_docker config --quiet --severity HIGH,CRITICAL --exit-code 1 "/src/$cible" 2>&1)"
code=$?
printf '%s\n' "$sortie"

if [ "$code" -gt 1 ] || { [ "$code" -ne 0 ] && ! printf '%s' "$sortie" | grep -q 'Failures:'; }; then
  echec "trivy n'a pas pu s'exécuter correctement (voir le message ci-dessus)."
  exit 2
fi
nb="$(somme_motif 'Failures' "$sortie")"
ecrire_compte "$nb"

if [ "$nb" -gt 0 ]; then
  echec "$nb erreur(s) de configuration HIGH/CRITICAL."
  exit 1
fi
succes "Aucune erreur de configuration HIGH/CRITICAL."
