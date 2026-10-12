#!/usr/bin/env bash
# Valide la syntaxe Terraform de infra/ dans un conteneur (terraform init -backend=false + validate).
# Rien n'est créé, aucun compte AWS n'est utilisé. Le premier lancement télécharge le fournisseur
# AWS (plus de 100 Mo) : il est ensuite gardé dans le volume Docker nimbus-tf-cache.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
titre "Validation Terraform (terraform validate)"
docker volume create nimbus-tf-cache >/dev/null
# On travaille sur une copie dans le conteneur : rien n'est écrit dans votre dossier infra/
sortie="$(docker run --rm --entrypoint sh -v "$RACINE_HOTE/infra":/infra-src:ro -v nimbus-tf-cache:/cache \
  -e TF_PLUGIN_CACHE_DIR=/cache -e TF_IN_AUTOMATION=1 -e TF_INPUT=0 "$IMG_TERRAFORM" \
  -c 'mkdir -p /work && cp /infra-src/*.tf /work/ && cd /work && terraform init -backend=false -no-color >/dev/null && terraform validate -no-color' 2>&1)"
code=$?
printf '%s\n' "$sortie"
if [ "$code" -ne 0 ]; then
  echec "Terraform signale des erreurs (ou le fournisseur n'a pas pu être téléchargé)."
  exit 1
fi
succes "Configuration Terraform valide."
