#!/usr/bin/env bash
# Analyse une SBOM avec trivy : quelles vulnérabilités connues touchent les composants listés ?
# Usage : ./outils/scan-sbom.sh [fichier-sbom]       (défaut : la plus récente de sbom/)
# Pratique aussi pour savoir si une bibliothèque annoncée compromise est présente.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
fichier="${1:-}"
if [ -z "$fichier" ]; then
  fichier="$(ls -t sbom/*.json 2>/dev/null | head -1)"
fi
if [ -z "$fichier" ] || [ ! -f "$fichier" ]; then
  echec "Aucune SBOM trouvée. Générez-en une avec ./outils/sbom.sh"
  exit 2
fi

titre "Vulnérabilités listées dans la SBOM : $fichier (trivy)"
sortie="$(trivy_docker sbom --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "/src/$fichier" 2>&1)"
code=$?
printf '%s\n' "$sortie"
if [ "$code" -gt 1 ] || { [ "$code" -ne 0 ] && ! printf '%s' "$sortie" | grep -q 'Total:'; }; then
  echec "trivy n'a pas pu lire la SBOM (voir le message ci-dessus)."
  exit 2
fi
nb="$(somme_motif 'Total' "$sortie")"
if [ "$nb" -gt 0 ]; then
  echec "$nb vulnérabilité(s) HIGH/CRITICAL corrigeables dans la SBOM."
  exit 1
fi
succes "Aucune vulnérabilité HIGH/CRITICAL corrigeable dans la SBOM."
