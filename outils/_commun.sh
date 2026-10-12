#!/usr/bin/env bash
# Fonctions et réglages communs aux scripts de outils/. Ne se lance pas directement.
# Compatible macOS (bash 3.2), Linux, Git Bash et WSL2.

# --- Versions des outils (images Docker épinglées : mêmes résultats pour tout le monde) ---
IMG_GITLEAKS="ghcr.io/gitleaks/gitleaks:v8.28.0"
IMG_SEMGREP="semgrep/semgrep:1.130.0"
IMG_TRIVY="aquasec/trivy:0.65.0"
IMG_SYFT="anchore/syft:v1.30.0"
IMG_COSIGN="ghcr.io/sigstore/cosign/cosign:v2.5.3"
IMG_REGISTRY="registry:2.8.3"
IMG_ACTIONLINT="rhysd/actionlint:1.7.7"
IMG_TERRAFORM="hashicorp/terraform:1.12.2"

IMAGE_APP="nimbus-notes:local"          # image construite à partir du Dockerfile
REGISTRE_PORT="5001"                    # 5000 est déjà pris par AirPlay sur macOS
REGISTRE_NOM="nimbus-registry"
REF_DEFAUT="localhost:${REGISTRE_PORT}/nimbus-notes:1.0"
MOT_DE_PASSE_COSIGN="${COSIGN_PASSWORD:-nimbus-lab}"   # mot de passe FICTIF de la clé de TP

# Git Bash (Windows) ne doit pas réécrire les chemins passés à Docker.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# --- Couleurs (seulement dans un terminal) ---
if [ -t 1 ]; then
  C_ROUGE=$'\033[31m'; C_VERT=$'\033[32m'; C_JAUNE=$'\033[33m'; C_BLEU=$'\033[36m'; C_GRAS=$'\033[1m'; C_FIN=$'\033[0m'
else
  C_ROUGE=""; C_VERT=""; C_JAUNE=""; C_BLEU=""; C_GRAS=""; C_FIN=""
fi

titre()  { printf '\n%s== %s ==%s\n' "$C_BLEU$C_GRAS" "$1" "$C_FIN"; }
info()   { printf '%s\n' "$1"; }
succes() { printf '%sOK%s  %s\n' "$C_VERT$C_GRAS" "$C_FIN" "$1"; }
alerte() { printf '%sATTENTION%s  %s\n' "$C_JAUNE$C_GRAS" "$C_FIN" "$1"; }
echec()  { printf '%sPROBLÈME%s  %s\n' "$C_ROUGE$C_GRAS" "$C_FIN" "$1"; }

# --- Dossier du dépôt (on travaille toujours depuis la racine) ---
RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE" || exit 2
# Chemin vu par Docker : sous Git Bash, `pwd -W` donne C:/Users/... ; ailleurs on garde pwd.
RACINE_HOTE="$( (pwd -W 2>/dev/null) || pwd )"

# Options Docker pour que git (dans le conteneur) accepte le dépôt monté
GIT_SAFE="-e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0=/src"

# Mode « hors ligne » : on ne met pas à jour la base Trivy (après ./outils/precharger.sh)
TRIVY_ENV="-e TRIVY_SKIP_JAVA_DB_UPDATE=true"
if [ -n "${NIMBUS_HORS_LIGNE:-}" ]; then
  TRIVY_ENV="$TRIVY_ENV -e TRIVY_SKIP_DB_UPDATE=true -e TRIVY_SKIP_CHECK_UPDATE=true"
fi

verifier_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echec "Docker n'est pas installé (ou pas dans le PATH)."
    info "  -> Installez Docker Desktop, puis relancez ce terminal. Sous Windows, utilisez Git Bash ou WSL2."
    exit 2
  fi
  if ! docker info >/dev/null 2>&1; then
    echec "Docker est installé mais ne répond pas."
    info "  -> Lancez Docker Desktop, attendez que l'icône soit stable, puis réessayez."
    exit 2
  fi
}

# Lance Trivy dans un conteneur. Le dépôt est monté en lecture seule dans /src.
trivy_docker() {
  # shellcheck disable=SC2086
  docker run --rm -w /src -v "$RACINE_HOTE":/src:ro -v nimbus-trivy-cache:/root/.cache/ $TRIVY_ENV "$IMG_TRIVY" "$@"
}

# Même chose, avec accès au démon Docker (pour analyser une image locale)
trivy_docker_image() {
  # shellcheck disable=SC2086
  docker run --rm -w /src -v "$RACINE_HOTE":/src:ro -v nimbus-trivy-cache:/root/.cache/ \
    -v /var/run/docker.sock:/var/run/docker.sock $TRIVY_ENV "$IMG_TRIVY" "$@"
}

# Les scripts appelés par scan-tout.sh y déposent leur nombre de problèmes
ecrire_compte() {
  if [ -n "${NIMBUS_COMPTE_FICHIER:-}" ]; then
    printf '%s\n' "$1" > "$NIMBUS_COMPTE_FICHIER"
  fi
}

# Additionne les nombres qui suivent un motif dans un texte. Usage : somme_motif "Total" "$texte"
somme_motif() {
  printf '%s\n' "$2" | sed -n "s/.*$1: \([0-9][0-9]*\).*/\1/p" | awk '{s+=$1} END {print s+0}'
}

# Identifiant utilisateur:groupe pour ne pas créer de fichiers appartenant à root (Linux/macOS)
utilisateur_docker() {
  if command -v id >/dev/null 2>&1; then printf '%s:%s' "$(id -u)" "$(id -g)"; fi
}

# Cosign tourne dans un conteneur qui partage le réseau du registre : vu de l'intérieur,
# le registre est donc sur "localhost:5000" (et non "localhost:5001" comme depuis votre poste).
ref_pour_conteneur() {
  printf '%s' "$1" | sed "s#^localhost:${REGISTRE_PORT}/#localhost:5000/#; s#^127.0.0.1:${REGISTRE_PORT}/#localhost:5000/#"
}

registre_en_marche() {
  [ "$(docker inspect -f '{{.State.Running}}' "$REGISTRE_NOM" 2>/dev/null)" = "true" ]
}
