#!/bin/sh

# This script will download a youtube video and convert it to mp4
yt-dlp --cookies-from-browser chrome "$1" -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o "$2".mp4
