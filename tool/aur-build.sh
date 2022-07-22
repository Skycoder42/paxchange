#!/bin/bash
set -exo pipefail

sudo pacman -Sy --noconfirm dart namcap rsync

TMP_DIR=$(mktemp -d)
rsync -a "$PWD/" "$TMP_DIR/"
cd "$TMP_DIR"

dart pub get
dart run build_runner build

AUR_DIR=$(mktemp -d)
dart run tool/makepkg/generate_pkgbuild.dart "$AUR_DIR"

cd "$AUR_DIR"
updpkgsums
namcap -i PKGBUILD
makepkg -sfC --check --noconfirm

makepkg --printsrcinfo > .SRCINFO

cp *.pkg.tar.zst /deploy/
