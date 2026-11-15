#!/bin/zsh
# Baut die App und erzeugt dist/SoundLadder-<Version>.pkg
set -e
cd "$(dirname "$0")/.."
VERSION=${VERSION:-1.3}
export VERSION
./build.sh

WORK=$(mktemp -d)
mkdir -p "$WORK/root/Applications" dist
ditto --norsrc --noextattr --noqtn build/SoundLadder.app "$WORK/root/Applications/SoundLadder.app"
export COPYFILE_DISABLE=1

# Nicht relokierbar: sonst "aktualisiert" der Installer evtl. eine andere Kopie der App
pkgbuild --analyze --root "$WORK/root" "$WORK/component.plist" >/dev/null
plutil -replace 0.BundleIsRelocatable -bool NO "$WORK/component.plist"

pkgbuild --root "$WORK/root" --component-plist "$WORK/component.plist" \
  --scripts Installer/scripts --identifier de.mbmf17.soundladder.pkg \
  --version "$VERSION" --install-location / "$WORK/SoundLadder.pkg"

cat > "$WORK/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>SoundLadder</title>
  <welcome file="welcome.html" mime-type="text/html"/>
  <conclusion file="conclusion.html" mime-type="text/html"/>
  <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
  <domains enable_localSystem="true"/>
  <volume-check><allowed-os-versions><os-version min="13.0"/></allowed-os-versions></volume-check>
  <choices-outline><line choice="default"/></choices-outline>
  <choice id="default" title="SoundLadder"><pkg-ref id="de.mbmf17.soundladder.pkg"/></choice>
  <pkg-ref id="de.mbmf17.soundladder.pkg" version="$VERSION">SoundLadder.pkg</pkg-ref>
</installer-gui-script>
XML

OUT="dist/SoundLadder-$VERSION.pkg"
productbuild --distribution "$WORK/distribution.xml" --resources Installer/resources \
  --package-path "$WORK" "$OUT"
rm -rf "$WORK"
echo "Installer: $PWD/$OUT"
