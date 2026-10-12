#!/usr/bin/env bash
# Hook Git « pre-commit » : refuse le commit si les fichiers préparés (git add) contiennent un secret.
# Installé par ./outils/installer-hook.sh (copie dans .git/hooks/pre-commit).
set -u
RACINE="$(git rev-parse --show-toplevel)"
cd "$RACINE" || exit 1
. "$RACINE/outils/_commun.sh"

if ! docker info >/dev/null 2>&1; then
  echo "Hook gitleaks : Docker ne répond pas, le contrôle des secrets n'a pas pu être fait." >&2
  echo "Lancez Docker Desktop, ou contournez en connaissance de cause avec : git commit --no-verify" >&2
  exit 1
fi

# shellcheck disable=SC2086
if ! docker run --rm -v "$RACINE_HOTE":/src $GIT_SAFE -w /src "$IMG_GITLEAKS" \
     git /src --pre-commit --staged --redact --no-banner --no-color --verbose; then
  echo >&2
  echo "COMMIT REFUSÉ : un secret a été détecté dans les fichiers préparés." >&2
  echo "Retirez-le du fichier (variable d'environnement), puis refaites git add et git commit." >&2
  exit 1
fi
