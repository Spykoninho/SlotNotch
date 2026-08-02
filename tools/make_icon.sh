#!/bin/zsh
# Régénère Resources/AppIcon.icns depuis le code (CasinoArt + IconGen)
set -e
cd "$(dirname "$0")/.."

mkdir -p Resources
swiftc -O Sources/CasinoArt.swift tools/IconGen.swift -framework AppKit -o /tmp/slotch_icongen
/tmp/slotch_icongen Resources
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
echo "✅ Resources/AppIcon.icns"
