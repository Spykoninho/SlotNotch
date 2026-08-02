#!/bin/zsh
# Construit Slotch.app — usage: ./build.sh [--run]
set -e
cd "$(dirname "$0")"

APP="Slotch.app"
NAME="Slotch"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O Sources/*.swift \
  -framework AppKit -framework QuartzCore -framework ServiceManagement \
  -o "$APP/Contents/MacOS/$NAME"

[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>Slotch</string>
	<key>CFBundleIdentifier</key>
	<string>fr.mathis.slotch</string>
	<key>CFBundleName</key>
	<string>Slotch</string>
	<key>CFBundleDisplayName</key>
	<string>Slotch</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>12.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

codesign --force -s - "$APP" 2>/dev/null

echo "✅ $APP construit."
if [[ "$1" == "--run" ]]; then
  open "$APP"
  echo "🎰 Lancé — approche ton curseur de l'encoche."
fi
