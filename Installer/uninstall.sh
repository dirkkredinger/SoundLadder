#!/bin/zsh
# Entfernt SoundLadder vollständig (inkl. Einstellungen und Vorgängerversion)
pkill -x SoundLadder 2>/dev/null
pkill -x AudioPriority 2>/dev/null
sudo rm -rf /Applications/SoundLadder.app /Applications/AudioPriority.app
sudo pkgutil --forget de.mbmf17.soundladder.pkg 2>/dev/null
sudo pkgutil --forget local.audiopriority.pkg 2>/dev/null
defaults delete de.mbmf17.soundladder 2>/dev/null
defaults delete local.audiopriority 2>/dev/null
echo "SoundLadder wurde entfernt."
