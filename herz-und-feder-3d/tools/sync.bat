@echo off
rem Alles, was du lokal geändert hast, mit einem Befehl auf GitHub bringen (Windows).
rem Aufruf aus dem Repo-Ordner:   herz-und-feder-3d\tools\sync.bat "kurze Beschreibung"
cd /d "%~dp0\..\.."
git fetch -q origin
git checkout -q mac-pc 2>nul || git checkout -q -b mac-pc
git add -A
rem Godots eigene .import-Dateien nicht mitnehmen (werden beim Bauen neu erzeugt)
git reset -q -- ":(glob)**/*.import"
git diff --cached --quiet || git commit -q -m "%~1"
git pull --rebase --autostash -q origin main || (echo Konflikt: bitte Claude Bescheid sagen. & exit /b 1)
git push -q -u --force-with-lease origin mac-pc
echo Fertig. Dein Stand liegt auf GitHub im Zweig mac-pc.
