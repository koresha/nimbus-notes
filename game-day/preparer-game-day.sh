#!/usr/bin/env bash
# Met en place la situation du Game Day dans VOTRE registre local :
#   - une image légitime (nimbus-notes:1.2.0), construite depuis votre dépôt et SIGNÉE ;
#   - une image suspecte (nimbus-notes:1.2.1-hotfix), NON signée.
# Elle prépare aussi votre requirements.txt pour que « click » soit dans une version touchée
# par le bulletin fictif. Lancez-la depuis la racine du dépôt :  ./game-day/preparer-game-day.sh
# (Suggestion : créez d'abord une branche :  git switch -c game-day)
set -u
. "$(dirname "${BASH_SOURCE[0]}")/../outils/_commun.sh"

verifier_docker
titre "Game Day : mise en place de la situation"

# 1. Le registre (remis à zéro : les images de test du TP6 disparaissent) et les clés (celles du TP6)
docker rm -f "$REGISTRE_NOM" >/dev/null 2>&1 || true
docker volume rm nimbus-registry-data >/dev/null 2>&1 || true
"$RACINE/outils/registre-local.sh" >/dev/null || { echec "Registre local indisponible."; exit 1; }
succes "Registre local remis à zéro et prêt (localhost:${REGISTRE_PORT})."
"$RACINE/outils/signer.sh" --init-cles >/dev/null || exit 1

# 2. Le scénario : la bibliothèque click est dans une version touchée par le bulletin
if grep -q '^click==' requirements.txt; then
  actuelle="$(sed -n 's/^click==\(.*\)$/\1/p' requirements.txt | head -1)"
  if [ "$actuelle" != "8.1.8" ]; then
    sed 's/^click==.*/click==8.1.8/' requirements.txt > requirements.txt.tmp && mv requirements.txt.tmp requirements.txt
    alerte "requirements.txt : click $actuelle -> 8.1.8 (situation de départ du scénario). À commiter."
  fi
else
  printf 'click==8.1.8\n' >> requirements.txt
  alerte "requirements.txt : ligne click==8.1.8 ajoutée (situation de départ du scénario). À commiter."
fi

# 3. L'image légitime : construite depuis le dépôt, poussée, signée
titre "Image légitime 1.2.0"
journal="$(mktemp)"
if ! docker build -t "$IMAGE_APP" . >"$journal" 2>&1; then
  cat "$journal"; rm -f "$journal"
  echec "La construction de l'image a échoué (corrigez le Dockerfile ou requirements.txt)."
  exit 1
fi
rm -f "$journal"
legitime="localhost:${REGISTRE_PORT}/nimbus-notes:1.2.0"
docker tag "$IMAGE_APP" "$legitime"
docker push -q "$legitime" >/dev/null || { echec "Envoi de l'image impossible."; exit 1; }
"$RACINE/outils/signer.sh" "$legitime" >/dev/null || { echec "Signature impossible."; exit 1; }
succes "$legitime construite, envoyée et signée."

# 4. L'image suspecte : arrivée dans le registre sans passer par le pipeline, jamais signée
titre "Image suspecte"
suspecte="localhost:${REGISTRE_PORT}/nimbus-notes:1.2.1-hotfix"
printf 'FROM alpine:3.20\nLABEL org.opencontainers.image.title="nimbus-notes hotfix" origine="inconnue"\nCMD ["sh", "-c", "echo hotfix; sleep 3600"]\n' \
  | docker build -q -t "$suspecte" - >/dev/null || { echec "Construction de l'image suspecte impossible."; exit 1; }
docker push -q "$suspecte" >/dev/null || { echec "Envoi de l'image suspecte impossible."; exit 1; }
succes "Une image supplémentaire est apparue dans le registre (à vous de la repérer)."

echo
info "Situation prête. Lisez game-day/bulletin-FICTIF.md, puis :"
info "  ./outils/registre-local.sh liste      # ce qui est dans le registre"
info "  ./outils/sbom.sh localhost:${REGISTRE_PORT}/nimbus-notes:1.2.0   # la SBOM de l'image livrée (voir sbom/*.txt)"
info "  ./outils/verifier.sh <image>          # signature valide ou non ?"
