#!/bin/zsh
# Entfernt Audio-Prioritäten vollständig
pkill -x AudioPriority 2>/dev/null
sudo rm -rf /Applications/AudioPriority.app
sudo pkgutil --forget local.audiopriority.pkg 2>/dev/null
defaults delete local.audiopriority 2>/dev/null
echo "Audio-Prioritäten wurde entfernt."
