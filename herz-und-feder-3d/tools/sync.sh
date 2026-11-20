#!/usr/bin/env bash
# Alles, was du lokal geändert hast, mit einem Befehl auf GitHub bringen (Mac/Linux).
# Aufruf aus dem Repo-Ordner:   bash herz-und-feder-3d/tools/sync.sh "kurze Beschreibung"
# Er holt zuerst den neuesten Stand, legt dann deine Änderungen darauf, speichert sie und lädt sie hoch.
set -e
cd "$(git rev-parse --show-toplevel)"
zweig="mac-pc"
git fetch -q origin
if git show-ref -q --verify "refs/heads/$zweig"; then git checkout -q "$zweig"; else git checkout -q -b "$zweig"; fi
git add -A
if ! git diff --cached --quiet; then git commit -q -m "${1:-Änderungen von Hand}"; fi
git pull --rebase -q origin main || { echo "Konflikt: bitte mir (Claude) Bescheid sagen, ich löse ihn."; exit 1; }
git push -q -u --force-with-lease origin "$zweig"
echo "Fertig. Dein Stand liegt auf GitHub im Zweig '$zweig'."
