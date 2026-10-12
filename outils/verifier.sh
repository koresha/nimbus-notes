#!/usr/bin/env bash
# Vérifie la signature d'une image avec la clé publique .cles/cosign.pub.
# Usage : ./outils/verifier.sh [image]       (défaut : localhost:5001/nimbus-notes:1.0)
# Code de sortie : 0 = signature valide, 1 = image non signée ou modifiée, 2 = erreur d'environnement.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
ref="${1:-$REF_DEFAUT}"

if [ ! -f .cles/cosign.pub ]; then
  echec "Clé publique introuvable (.cles/cosign.pub). Créez les clés avec ./outils/signer.sh --init-cles"
  exit 2
fi
if ! registre_en_marche; then
  echec "Le registre local est arrêté. Lancez ./outils/registre-local.sh"
  exit 2
fi
ref_conteneur="$(ref_pour_conteneur "$ref")"

titre "Vérification de la signature de $ref (cosign)"
sortie="$(docker run --rm -e HOME=/tmp --network "container:$REGISTRE_NOM" -v "$RACINE_HOTE/.cles":/cles:ro "$IMG_COSIGN" \
  verify --key /cles/cosign.pub --insecure-ignore-tlog=true --allow-insecure-registry "$ref_conteneur" 2>&1)"
code=$?

if [ "$code" -eq 0 ]; then
  succes "Signature VALIDE : cette image a bien été signée avec votre clé."
  printf '%s\n' "$sortie" | head -4
  exit 0
fi
printf '%s\n' "$sortie" | tail -5
echec "Signature INVALIDE ou absente : ne déployez pas cette image."
exit 1
