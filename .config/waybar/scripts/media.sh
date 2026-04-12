#!/usr/bin/env bash

player=$(playerctl --list-all 2>/dev/null | head -n 1)

if [ -z "$player" ]; then
    echo '{"text": " No media", "class": "stopped"}'
    exit 0
fi

status=$(playerctl --player=$player status 2>/dev/null)

artist=$(playerctl --player=$player metadata artist 2>/dev/null)
title=$(playerctl --player=$player metadata title 2>/dev/null)

if [ "$status" = "Playing" ]; then
    icon=""
elif [ "$status" = "Paused" ]; then
    icon=""
else
    icon=""
fi

if [ -z "$artist$title" ]; then
    echo "{\"text\": \"$icon No track\", \"class\": \"$status\"}"
else
    echo "{\"text\": \"$icon $artist - $title\", \"class\": \"$status\"}"
fi