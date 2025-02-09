#!/usr/bin/env bash

# Set the path to your foobar2000 portable executable
FOOBAR2000_PATH="$HOME/wineapps/foobar2000_2.0/foobar2000.exe"

# Create a Wine prefix for foobar2000 portable if it doesn't exist
if [ ! -d "$HOME/.wine-foobar2000" ]; then
  WINEPREFIX="$HOME/.wine-foobar2000" WINEARCH=win32 wineboot
fi

# Run foobar2000 portable
WINEPREFIX="$HOME/.wine-foobar2000" WINEARCH=win32 wine "$FOOBAR2000_PATH"
