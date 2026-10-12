#!/usr/bin/env bash
# Signe une image du registre local avec cosign (clé privée dans .cles/, ignorée par Git).
# Usage : ./outils/signer.sh --init-cles            crée la paire de clés (une seule fois)
#         ./outils/signer.sh [image]                signe l'image (défaut : localhost:5001/nimbus-notes:1.0)
# La clé est protégée par un mot de passe de TP FICTIF (variable COSIGN_PASSWORD pour le changer).
# La signature est enregistrée dans le registre, à côté de l'image. Aucun compte requis.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
mkdir -p .cles
utilisateur="$(utilisateur_docker)"

# $1 = réseau Docker à utiliser (« none » pour la création des clés, sinon le réseau du registre)
cosign_docker() {
  reseau="$1"; shift
  # shellcheck disable=SC2086
  docker run --rm ${utilisateur:+-u "$utilisateur"} -e HOME=/tmp -e COSIGN_PASSWORD="$MOT_DE_PASSE_COSIGN" \
    --network "$reseau" -v "$RACINE_HOTE/.cles":/cles -w /cles "$IMG_COSIGN" "$@"
}

creer_cles() {
  if [ -f .cles/cosign.key ]; then
    alerte "Une paire de clés existe déjà dans .cles/ : je ne l'écrase pas."
    return 0
  fi
  titre "Création de la paire de clés cosign"
  if ! cosign_docker none generate-key-pair >/dev/null; then
    echec "La création des clés a échoué."; exit 2
  fi
  succes "Clés créées : .cles/cosign.key (PRIVÉE, ne jamais partager) et .cles/cosign.pub (publique)."
  info "La clé publique sert à vérifier ; la clé privée sert à signer."
}

if [ "${1:-}" = "--init-cles" ]; then
  creer_cles
  exit 0
fi

ref="${1:-$REF_DEFAUT}"
[ -f .cles/cosign.key ] || creer_cles
if ! registre_en_marche; then
  echec "Le registre local est arrêté. Lancez ./outils/registre-local.sh"
  exit 2
fi
# On signe l'empreinte (digest) de l'image plutôt que son étiquette : c'est plus sûr, une étiquette peut bouger.
cible="$ref"
depot="${ref%:*}"
empreinte="$(docker inspect -f '{{range .RepoDigests}}{{println .}}{{end}}' "$ref" 2>/dev/null | grep "^${depot}@sha256:" | head -1 || true)"
[ -n "$empreinte" ] && cible="$empreinte"
ref_conteneur="$(ref_pour_conteneur "$cible")"

titre "Signature de $ref (cosign)"
info "Signer = prouver que cette image précise (son empreinte) a été validée par le détenteur de la clé."
if ! cosign_docker "container:$REGISTRE_NOM" sign --key cosign.key --yes --tlog-upload=false --allow-insecure-registry "$ref_conteneur"; then
  echec "La signature a échoué. Le registre tourne-t-il (./outils/registre-local.sh) et l'image est-elle poussée ?"
  exit 1
fi
succes "Image signée : $ref"
info "Vérification : ./outils/verifier.sh $ref"
