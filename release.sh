#!/bin/zsh
# Release signée + notarisée + DMG — usage: ./release.sh <version>
#
# Prérequis (une seule fois) :
#   1. Certificat « Developer ID Application » installé dans le trousseau
#      (developer.apple.com → Certificates → Developer ID Application)
#   2. Identifiants de notarisation enregistrés :
#      xcrun notarytool store-credentials slotch-notary \
#        --apple-id "ton@email" --team-id "TONTEAMID" \
#        --password "mot-de-passe-app-specifique"
#      (mot de passe d'app à créer sur appleid.apple.com → Connexion et sécurité)
set -e
cd "$(dirname "$0")"

VERSION="${1:?usage: ./release.sh <version>  (ex: ./release.sh 1.0)}"
PROFILE="slotch-notary"

IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application/{print $2; exit}')
[[ -z "$IDENTITY" ]] && { echo "❌ Aucun certificat « Developer ID Application » dans le trousseau."; exit 1; }
echo "🔏 Signature : $IDENTITY"

# Version injectée dans le bundle
./build.sh
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Slotch.app/Contents/Info.plist

# Signature Developer ID + hardened runtime (requis pour la notarisation)
codesign --force --options runtime --timestamp --sign "$IDENTITY" Slotch.app

# Notarisation de l'app
echo "📤 Notarisation (quelques minutes)…"
ditto -c -k --keepParent Slotch.app /tmp/Slotch-notarize.zip
xcrun notarytool submit /tmp/Slotch-notarize.zip --keychain-profile "$PROFILE" --wait
xcrun stapler staple Slotch.app

# DMG avec raccourci /Applications
echo "💿 DMG…"
rm -rf dist/dmg && mkdir -p dist/dmg
cp -R Slotch.app dist/dmg/
ln -s /Applications dist/dmg/Applications
DMG="dist/Slotch-$VERSION.dmg"
hdiutil create -volname "Slotch" -srcfolder dist/dmg -ov -format UDZO "$DMG" -quiet
codesign --force --timestamp --sign "$IDENTITY" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
rm -rf dist/dmg /tmp/Slotch-notarize.zip

SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')

# Mise à jour automatique du tap Homebrew
TAP_URL="https://github.com/Spykoninho/homebrew-tap.git"
TAP_TMP=$(mktemp -d)
if git clone -q --depth 1 "$TAP_URL" "$TAP_TMP" 2>/dev/null; then
  sed -i '' -E "s/version \"[^\"]+\"/version \"$VERSION\"/; s/sha256 \"[^\"]+\"/sha256 \"$SHA\"/" \
    "$TAP_TMP/Casks/slotch.rb"
  if git -C "$TAP_TMP" diff --quiet; then
    echo "🍺 Tap Homebrew déjà à jour."
  elif git -C "$TAP_TMP" commit -aqm "slotch $VERSION" && git -C "$TAP_TMP" push -q origin HEAD; then
    echo "🍺 Tap Homebrew mis à jour : slotch $VERSION ($SHA)"
  else
    echo "⚠️  Push du tap impossible — reporte à la main dans Casks/slotch.rb :"
    echo "    version \"$VERSION\" · sha256 \"$SHA\""
  fi
  rm -rf "$TAP_TMP"
else
  echo "⚠️  Clone du tap impossible — reporte à la main : version \"$VERSION\" · sha256 \"$SHA\""
fi

# Copie de référence dans le repo principal (à committer avec la release)
sed -i '' -E "s/version \"[^\"]+\"/version \"$VERSION\"/; s/sha256 \"[^\"]+\"/sha256 \"$SHA\"/" \
  packaging/homebrew/slotch.rb

echo ""
echo "✅ $DMG"
echo "➡️  Publie EXACTEMENT ce fichier dans une Release GitHub, tag $VERSION (sans « v »)."
echo "    Si tu relances ce script, le sha change : le tap suit toujours le DERNIER DMG produit."
