#!/usr/bin/env bash
# Vérifie la syntaxe et les erreurs courantes des workflows GitHub Actions (.github/workflows/*.yml)
# avec actionlint, avant de pousser. Code de sortie : 0 = valide, 1 = erreurs, 2 = erreur d'outil.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
titre "Vérification des workflows GitHub Actions (actionlint)"
if ! ls .github/workflows/*.yml >/dev/null 2>&1; then
  alerte "Aucun workflow trouvé dans .github/workflows/."; exit 0
fi
if docker run --rm -v "$RACINE_HOTE":/repo:ro -w /repo "$IMG_ACTIONLINT" -color; then
  succes "Workflows valides."
else
  echec "actionlint a trouvé des erreurs (voir ci-dessus)."
  exit 1
fi
