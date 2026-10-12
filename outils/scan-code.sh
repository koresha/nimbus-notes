#!/usr/bin/env bash
# Analyse du code (SAST) avec semgrep, sans connexion internet : les règles sont dans
# outils/regles-semgrep.yml. Code de sortie : 0 = rien, 1 = problèmes, 2 = erreur d'outil.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
titre "Analyse du code (semgrep)"
info "Semgrep lit le code sans l'exécuter et signale les motifs dangereux décrits dans outils/regles-semgrep.yml."

# shellcheck disable=SC2086
sortie="$(docker run --rm -v "$RACINE_HOTE":/src:ro $GIT_SAFE -e SEMGREP_SEND_METRICS=off "$IMG_SEMGREP" \
  semgrep scan --config /src/outils/regles-semgrep.yml --metrics=off --disable-version-check \
  --no-rewrite-rule-ids --error /src 2>&1)"
code=$?
printf '%s\n' "$sortie"

nb="$(printf '%s\n' "$sortie" | sed -n 's/.*Ran [0-9]* rules\{0,1\} on [0-9]* files\{0,1\}: \([0-9][0-9]*\) findings\{0,1\}.*/\1/p' | tail -1)"
if [ -z "$nb" ]; then
  if [ "$code" -eq 0 ]; then nb=0; else
    echec "semgrep n'a pas pu s'exécuter correctement (voir le message ci-dessus)."
    exit 2
  fi
fi
ecrire_compte "$nb"

if [ "$nb" -gt 0 ]; then
  echec "$nb problème(s) trouvé(s) dans le code."
  exit 1
fi
succes "Aucun problème trouvé dans le code."
