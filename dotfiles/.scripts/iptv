#!/usr/bin/env bash

APPIMAGE_FILE=$(find "$HOME/.appimage" -name "IPTVnator-*.AppImage" -print -quit)

if [[ -n "$APPIMAGE_FILE" ]]; then
    appimage-run "$APPIMAGE_FILE"
else
    echo "No IPTVnator AppImage file found in $HOME/.appimage"
    exit 1
fi
