#!/usr/bin/env bash
# Recherche de secrets (mots de passe, jetons, clés) avec gitleaks.
# Usage : ./outils/scan-secrets.sh [--historique | --fichiers]
#   --historique (défaut) : tous les commits du dépôt Git
#   --fichiers            : les fichiers actuels du dossier (même non commités)
# Code de sortie : 0 = rien trouvé, 1 = secrets trouvés, 2 = Docker indisponible.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

mode="${1:---historique}"
verifier_docker

if [ "$mode" = "--fichiers" ]; then
  titre "Secrets dans les fichiers actuels (gitleaks)"
  commande="dir"
  option_config="--config /src/outils/gitleaks-fichiers.toml"
else
  titre "Secrets dans l'historique Git (gitleaks)"
  commande="git"
  option_config=""
fi
info "Un secret est une information qui donne un accès : mot de passe, jeton d'API, clé privée."

# shellcheck disable=SC2086
sortie="$(docker run --rm -w /src -v "$RACINE_HOTE":/src:ro $GIT_SAFE "$IMG_GITLEAKS" \
  "$commande" /src $option_config --no-banner --no-color --redact --verbose 2>&1)"
code=$?
printf '%s\n' "$sortie"

if [ "$code" -ne 0 ] && ! printf '%s' "$sortie" | grep -q 'leaks found'; then
  echec "gitleaks n'a pas pu s'exécuter correctement (voir le message ci-dessus)."
  exit 2
fi

nb="$(printf '%s\n' "$sortie" | sed -n 's/.*leaks found: \([0-9][0-9]*\).*/\1/p' | tail -1)"
nb="${nb:-0}"
ecrire_compte "$nb"

if [ "$nb" -gt 0 ]; then
  echec "$nb secret(s) trouvé(s). Un secret qui a fuité doit être révoqué, pas seulement supprimé."
  exit 1
fi
succes "Aucun secret trouvé."
