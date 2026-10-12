#!/usr/bin/env bash
# Installe le hook pre-commit qui lance gitleaks avant chaque commit.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

if [ ! -d .git ]; then
  echec "Ce dossier n'est pas un dépôt Git (pas de .git)."; exit 2
fi
mkdir -p .git/hooks
cp outils/pre-commit-gitleaks.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
succes "Hook installé : .git/hooks/pre-commit (gitleaks s'exécutera avant chaque commit)."
info "Pour le tester : créez un fichier avec un faux secret, git add, git commit -> le commit doit être refusé."
