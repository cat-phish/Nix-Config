#!/usr/bin/env bash

# # Setup directories and setup wine
# mkdir ~/wineapps/musicbee
# WINEARCH=win32 WINEPREFIX=/home/jordan/wineapps/musicbee/wine winecfg
#
# # Download latest musicbee.exe and install
# WINEPREFIX=/home/jordan/wineapps/musicbee/wine wine MusicBeePortable_3_5.exe
#
# # Setup font rendering to anti-aliasing to make it look smooth (paste till /dev/null)
# cat << EOF > /tmp/fontsmoothing
# REGEDIT4
#
# [HKEY_CURRENT_USER\Control Panel\Desktop]
# "FontSmoothing"="2"
# "FontSmoothingOrientation"=dword:00000001
# "FontSmoothingType"=dword:00000002
# "FontSmoothingGamma"=dword:00000578
# EOF
#
# WINE=${WINE:-wine} WINEPREFIX=${WINEPREFIX:-$HOME/wineapps/musicbee/wine} $WINE regedit /tmp/fontsmoothing 2> /dev/null

# Set the path to your musicbee portable executable
MUSICBEE_PATH="$HOME/wineapps/musicbee/MusicBee/MusicBee.exe"

# Create a Wine prefix for musicbee portable if it doesn't exist
if [ ! -d "$HOME/wineapps/musicbee/wine" ]; then
  WINEPREFIX=/home/jordan/wineapps/musicbee/wine winetricks -q dotnet48 xmllite gdiplus
  WINEPREFIX="$HOME/wineapps/musicbee/wine" WINEARCH=win32 wineboot
fi

# Run musicbee portable
WINEPREFIX="$HOME/wineapps/musicbee/wine" WINEARCH=win32 wine "$MUSICBEE_PATH"

