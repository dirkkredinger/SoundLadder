#!/bin/zsh
# Baut AudioPriority.app (Release) im Ordner build/
set -e
cd "$(dirname "$0")"
swift build -c release
APP=build/AudioPriority.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/AudioPriority "$APP/Contents/MacOS/AudioPriority"
if [ ! -f Resources/AppIcon.icns ]; then
  swift Tools/make_icon.swift Resources
  iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>AudioPriority</string>
  <key>CFBundleDisplayName</key><string>Audio-Prioritäten</string>
  <key>CFBundleIdentifier</key><string>local.audiopriority</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleExecutable</key><string>AudioPriority</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION:-1.1}</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Fertig: $PWD/$APP"
