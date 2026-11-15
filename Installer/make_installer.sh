#!/bin/zsh
# Baut die App und erzeugt dist/AudioPriority-<Version>.pkg
set -e
cd "$(dirname "$0")/.."
VERSION=${VERSION:-1.1}
export VERSION
./build.sh

WORK=$(mktemp -d)
mkdir -p "$WORK/root/Applications" dist
ditto --norsrc --noextattr --noqtn build/AudioPriority.app "$WORK/root/Applications/AudioPriority.app"
export COPYFILE_DISABLE=1

# Nicht relokierbar: sonst "aktualisiert" der Installer evtl. eine andere Kopie der App
pkgbuild --analyze --root "$WORK/root" "$WORK/component.plist" >/dev/null
plutil -replace 0.BundleIsRelocatable -bool NO "$WORK/component.plist"

pkgbuild --root "$WORK/root" --component-plist "$WORK/component.plist" \
  --scripts Installer/scripts --identifier local.audiopriority.pkg \
  --version "$VERSION" --install-location / "$WORK/AudioPriority.pkg"

cat > "$WORK/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>Audio-Prioritäten</title>
  <welcome file="welcome.html" mime-type="text/html"/>
  <conclusion file="conclusion.html" mime-type="text/html"/>
  <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
  <domains enable_localSystem="true"/>
  <volume-check><allowed-os-versions><os-version min="13.0"/></allowed-os-versions></volume-check>
  <choices-outline><line choice="default"/></choices-outline>
  <choice id="default" title="Audio-Prioritäten"><pkg-ref id="local.audiopriority.pkg"/></choice>
  <pkg-ref id="local.audiopriority.pkg" version="$VERSION">AudioPriority.pkg</pkg-ref>
</installer-gui-script>
XML

OUT="dist/AudioPriority-$VERSION.pkg"
productbuild --distribution "$WORK/distribution.xml" --resources Installer/resources \
  --package-path "$WORK" "$OUT"
rm -rf "$WORK"
echo "Installer: $PWD/$OUT"
