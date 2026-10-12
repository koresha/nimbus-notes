#!/usr/bin/env bash
# Registre d'images Docker local (registry:2), utilisé au TP6 et au Game Day.
# Usage : ./outils/registre-local.sh [demarrer|arreter|etat|liste]      (défaut : demarrer)
#   liste : affiche les images et leurs étiquettes (tags) présentes dans le registre
# Adresse du registre : localhost:5001
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
action="${1:-demarrer}"

en_marche() { registre_en_marche; }

case "$action" in
  demarrer)
    if en_marche; then
      succes "Le registre tourne déjà sur localhost:${REGISTRE_PORT}"
    else
      docker rm -f "$REGISTRE_NOM" >/dev/null 2>&1 || true
      docker volume create nimbus-registry-data >/dev/null
      if ! docker run -d --name "$REGISTRE_NOM" --restart unless-stopped \
           -p "127.0.0.1:${REGISTRE_PORT}:5000" -v nimbus-registry-data:/var/lib/registry \
           "$IMG_REGISTRY" >/dev/null; then
        echec "Impossible de démarrer le registre (le port ${REGISTRE_PORT} est-il déjà utilisé ?)."
        exit 1
      fi
      sleep 2
      succes "Registre démarré sur localhost:${REGISTRE_PORT}"
    fi
    info "Pour y envoyer une image :"
    info "  docker tag nimbus-notes:local localhost:${REGISTRE_PORT}/nimbus-notes:1.0"
    info "  docker push localhost:${REGISTRE_PORT}/nimbus-notes:1.0"
    ;;
  arreter)
    docker rm -f "$REGISTRE_NOM" >/dev/null 2>&1 || true
    succes "Registre arrêté (les images restent dans le volume nimbus-registry-data)."
    info "Pour tout effacer : docker volume rm nimbus-registry-data"
    ;;
  etat)
    if en_marche; then succes "Le registre tourne sur localhost:${REGISTRE_PORT}"; else alerte "Le registre est arrêté."; exit 1; fi
    ;;
  liste)
    if ! en_marche; then echec "Le registre est arrêté (./outils/registre-local.sh)."; exit 1; fi
    titre "Contenu du registre localhost:${REGISTRE_PORT}"
    # On interroge l'API du registre depuis un conteneur qui partage son réseau (pas besoin de curl)
    depots="$(docker run --rm --network "container:$REGISTRE_NOM" "$IMG_REGISTRY" wget -qO- "http://localhost:5000/v2/_catalog" 2>/dev/null)"
    printf 'Dépôts : %s\n' "$depots"
    for depot in $(printf '%s' "$depots" | sed 's/.*\[\(.*\)\].*/\1/' | tr -d '"' | tr ',' ' '); do
      etiquettes="$(docker run --rm --network "container:$REGISTRE_NOM" "$IMG_REGISTRY" wget -qO- "http://localhost:5000/v2/${depot}/tags/list" 2>/dev/null)"
      printf '  %s -> %s\n' "$depot" "$etiquettes"
    done
    info "(Les étiquettes se terminant par .sig sont les signatures cosign.)"
    ;;
  *)
    echec "Action inconnue : $action (demarrer, arreter, etat, liste)"; exit 2 ;;
esac
