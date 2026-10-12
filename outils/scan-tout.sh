#!/usr/bin/env bash
# Lance tous les contrôles de sécurité et affiche un résumé chiffré : c'est votre SCORE.
# Usage : ./outils/scan-tout.sh [--sans-image]
#   --sans-image : saute la construction et l'analyse de l'image (plus rapide)
# Code de sortie : 0 = score de 0 problème, 1 = au moins un problème, 2 = environnement cassé.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

sans_image=0
[ "${1:-}" = "--sans-image" ] && sans_image=1

verifier_docker
dossier_tmp="$(mktemp -d)"
trap 'rm -rf "$dossier_tmp"' EXIT
erreur_env=0

# lancer <nom> <script> [arguments] : exécute un script, lit son compte, mémorise le résultat
lancer() {
  nom="$1"; script="$2"; shift 2
  NIMBUS_COMPTE_FICHIER="$dossier_tmp/$nom" "$RACINE/outils/$script" "$@"
  code=$?
  if [ "$code" -eq 2 ] || [ ! -f "$dossier_tmp/$nom" ]; then
    echo "?" > "$dossier_tmp/$nom"
    erreur_env=1
  fi
}

lancer secrets scan-secrets.sh
lancer code    scan-code.sh
lancer deps    scan-deps.sh
if [ "$sans_image" -eq 0 ]; then
  lancer image scan-image.sh
else
  echo "-" > "$dossier_tmp/image"
fi
lancer iac     scan-iac.sh

total=0
ligne() {
  valeur="$(cat "$dossier_tmp/$1")"
  printf '  %-34s %6s\n' "$2" "$valeur"
  case "$valeur" in ''|*[!0-9]*) ;; *) total=$((total + valeur)) ;; esac
}

printf '\n%s================ RÉSUMÉ DU SCAN ================%s\n' "$C_GRAS" "$C_FIN"
ligne secrets "Secrets (historique Git)"
ligne code    "Code (semgrep)"
ligne deps    "Dépendances (HIGH/CRITICAL)"
ligne image   "Image Docker (HIGH/CRITICAL)"
ligne iac     "Infrastructure (HIGH/CRITICAL)"
printf '  %s\n' "------------------------------------------"
printf '  %s%-34s %6s%s\n' "$C_GRAS" "SCORE (nombre de problèmes)" "$total" "$C_FIN"
printf '%s=================================================%s\n' "$C_GRAS" "$C_FIN"

if [ "$erreur_env" -eq 1 ]; then
  alerte "Un contrôle n'a pas pu s'exécuter (« ? » ci-dessus) : le score est incomplet."
  exit 2
fi
if [ "$total" -gt 0 ]; then
  echec "Score à battre : $total. Notez-le, on le fera descendre séance après séance."
  exit 1
fi
succes "Score de 0 problème : bravo, Nimbus est prêt pour l'audit."
