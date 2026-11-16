#!/bin/bash
# Lädt Godot 4.7.2 (Linux) in den Ordner ../.godot-bin und zeigt, wie man den Testlauf startet.
set -e
DIR="$(cd "$(dirname "$0")/.." && pwd)/.godot-bin"
mkdir -p "$DIR" && cd "$DIR"
[ -f Godot_v4.7.2-stable_linux.x86_64 ] || { curl -sSL -o godot.zip https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip; unzip -q -o godot.zip; rm godot.zip; chmod +x Godot_v4.7.2-stable_linux.x86_64; }
echo "Godot liegt in $DIR"
echo "Testlauf: xvfb-run -a $DIR/Godot_v4.7.2-stable_linux.x86_64 --path .. --rendering-driver opengl3 --fixed-fps 15 -- --autotest"
