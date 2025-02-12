#!/usr/bin/env bash

# Set the path to your foobar2000 portable executable
FOOBAR2000_PATH="$HOME/wineapps/foobar2000/foobar2000_2.0/foobar2000.exe"

# Create a Wine prefix for foobar2000 portable if it doesn't exist
if [ ! -d "$HOME/wineapps/foobar2000/wine" ]; then
  WINEPREFIX="$HOME/wineapps/foobar2000/wine" WINEARCH=win32 wineboot
fi

# Run foobar2000 portable
WINEPREFIX="$HOME/wineapps/foobar2000/wine" WINEARCH=win32 wine "$FOOBAR2000_PATH"
