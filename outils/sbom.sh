#!/usr/bin/env bash
# Génère la SBOM (liste des ingrédients : système + bibliothèques) d'une image avec syft.
# Usage : ./outils/sbom.sh [image] [cyclonedx|spdx]      (défaut : nimbus-notes:local, cyclonedx)
# Les fichiers sont écrits dans sbom/ (ignoré par Git) : la SBOM (.json) et une liste lisible (.txt).
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
image="${1:-$IMAGE_APP}"
format="${2:-cyclonedx}"

case "$format" in
  cyclonedx) sortie_syft="cyclonedx-json"; suffixe="cdx.json" ;;
  spdx)      sortie_syft="spdx-json";      suffixe="spdx.json" ;;
  *) echec "Format inconnu : $format (cyclonedx ou spdx)"; exit 2 ;;
esac

if ! docker image inspect "$image" >/dev/null 2>&1; then
  echec "L'image $image n'existe pas en local. Construisez-la d'abord (docker build -t $image .)."
  exit 2
fi

nom="$(printf '%s' "$image" | tr '/:' '__')"
mkdir -p sbom
fichier="sbom/${nom}.${suffixe}"

titre "SBOM de $image (syft)"
info "La SBOM est l'inventaire de tout ce que contient l'image, comme la liste d'ingrédients d'un plat."

if ! docker run --rm -v /var/run/docker.sock:/var/run/docker.sock "$IMG_SYFT" \
     "docker:$image" -o "$sortie_syft" -q >"$fichier" 2>sbom/.syft-erreur.log; then
  cat sbom/.syft-erreur.log; rm -f "$fichier" sbom/.syft-erreur.log
  echec "syft n'a pas pu analyser l'image."
  exit 2
fi
rm -f sbom/.syft-erreur.log

# Version lisible par un humain : une ligne par composant (nom, version, type)
lisible="sbom/${nom}.txt"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock "$IMG_SYFT" "docker:$image" -o table -q >"$lisible" 2>/dev/null || true

nb="$(grep -o '"purl"' "$fichier" | wc -l | tr -d ' ')"
succes "SBOM écrite : $fichier ($nb composants identifiés)"
info "Pour y retrouver une dépendance :  grep -i flask $lisible"
info "(le fichier .json est la SBOM officielle, au format CycloneDX ; le .txt est la même liste, lisible.)"
