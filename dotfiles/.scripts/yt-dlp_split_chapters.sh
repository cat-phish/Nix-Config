#!/bin/bash

# Download a YouTube video and split it into chapters
yt-dlp -P "$HOME/Downloads/Music/yt-dlp/$1" --split-chapters -x "$2" -o "chapter:%(section_number)02d. %(section_title)s.%(ext)s"
