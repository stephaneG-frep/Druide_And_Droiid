#!/bin/sh
# Archive des sources du commit courant, sans fichiers ignorés ni secrets :
# git archive ne prend que les fichiers suivis (key.properties, *.jks et
# local.properties sont ignorés par git).
set -eu
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain)" ]; then
  echo "Des modifications ne sont pas commitées : l'archive ne les contiendrait pas." >&2
  exit 1
fi
version=$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)
name="Druide_And-Droiid_v${version}"
mkdir -p dist
git archive --format=zip --prefix="${name}_sources/" -o "dist/${name}_sources.zip" HEAD
echo "Archive : dist/${name}_sources.zip ($(git rev-parse --short HEAD))"
