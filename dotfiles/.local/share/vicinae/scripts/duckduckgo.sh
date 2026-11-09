#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Search DuckDuckGo
# @vicinae.description Web search; DuckDuckGo !bangs work (e.g. "!yt cats")
# @vicinae.mode silent
# @vicinae.icon 🦆
# @vicinae.keywords ["web", "search", "ddg", "bang"]
# @vicinae.argument1 { "type": "text", "placeholder": "query", "percentEncoded": true }

xdg-open "https://duckduckgo.com/?q=$1" >/dev/null 2>&1 &
