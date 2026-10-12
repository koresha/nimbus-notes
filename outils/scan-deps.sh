#!/usr/bin/env bash
# Analyse des dépendances (SCA) avec trivy : cherche dans requirements.txt les bibliothèques
# qui ont des vulnérabilités connues (CVE). Seules les sévérités HIGH et CRITICAL bloquent.
# Les exceptions acceptées (datées, justifiées) se déclarent dans le fichier .trivyignore.
# Code de sortie : 0 = rien, 1 = vulnérabilités, 2 = erreur d'outil.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/_commun.sh"

verifier_docker
titre "Dépendances vulnérables (trivy)"
info "Une CVE est une faille connue et publique, identifiée par un numéro (CVE-ANNÉE-NUMÉRO)."
info "(Au premier lancement, la base de vulnérabilités se télécharge : environ une minute.)"

sortie="$(trivy_docker fs --quiet --scanners vuln --severity HIGH,CRITICAL --exit-code 1 \
  --skip-dirs .git /src 2>&1)"
code=$?
printf '%s\n' "$sortie"

if [ "$code" -gt 1 ] || { [ "$code" -ne 0 ] && ! printf '%s' "$sortie" | grep -q 'Total:'; }; then
  echec "trivy n'a pas pu s'exécuter correctement (voir le message ci-dessus)."
  exit 2
fi
nb="$(somme_motif 'Total' "$sortie")"
ecrire_compte "$nb"

if [ "$nb" -gt 0 ]; then
  echec "$nb vulnérabilité(s) HIGH/CRITICAL dans les dépendances."
  exit 1
fi
succes "Aucune vulnérabilité HIGH/CRITICAL dans les dépendances."
