#!/usr/bin/env bash
# Lance les tests de l'API (pytest) dans un conteneur Python : rien à installer.
# La version de Python est celle de l'image de base du Dockerfile.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
base="$(awk 'toupper($1)=="FROM" {print $2; exit}' Dockerfile)"
titre "Tests de l'API (pytest) dans $base"
docker run --rm -v "$RACINE_HOTE":/app -w /app -e PYTHONDONTWRITEBYTECODE=1 -e PIP_ROOT_USER_ACTION=ignore \
  -e PIP_DISABLE_PIP_VERSION_CHECK=1 "$base" \
  sh -c "pip install -q -r requirements-dev.txt 2>&1 | grep -v -i 'warning' ; python -m pytest -q -p no:cacheprovider"
