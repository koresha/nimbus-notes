#!/usr/bin/env bash
# Construit l'image Docker de l'application (Dockerfile), puis l'analyse avec trivy.
# Usage : ./outils/scan-image.sh [image]       (défaut : construit et analyse nimbus-notes:local)
# On ne compte que les vulnérabilités HIGH/CRITICAL pour lesquelles un correctif existe
# (--ignore-unfixed) : ce sont celles qu'on peut réellement corriger.
# Code de sortie : 0 = rien, 1 = vulnérabilités, 2 = erreur.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
image="${1:-}"

if [ -z "$image" ]; then
  image="$IMAGE_APP"
  titre "Construction de l'image ($image)"
  journal="$(mktemp)"
  if ! docker build -t "$image" . >"$journal" 2>&1; then
    cat "$journal"; rm -f "$journal"
    echec "La construction de l'image a échoué."
    exit 2
  fi
  rm -f "$journal"
  succes "Image construite : $image"
fi

titre "Vulnérabilités de l'image (trivy)"
info "Une image contient un système (Debian...) et des bibliothèques : chacun peut avoir des CVE."

sortie="$(trivy_docker_image image --quiet --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed \
  --exit-code 1 "$image" 2>&1)"
code=$?
printf '%s\n' "$sortie"

if [ "$code" -gt 1 ] || { [ "$code" -ne 0 ] && ! printf '%s' "$sortie" | grep -q 'Total:'; }; then
  echec "trivy n'a pas pu analyser l'image (voir le message ci-dessus)."
  exit 2
fi
nb="$(somme_motif 'Total' "$sortie")"
ecrire_compte "$nb"

if [ "$nb" -gt 0 ]; then
  echec "$nb vulnérabilité(s) HIGH/CRITICAL corrigeables dans l'image."
  exit 1
fi
succes "Aucune vulnérabilité HIGH/CRITICAL corrigeable dans l'image."
