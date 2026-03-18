#!/bin/bash

locked_icon="󰌾"
unlocked_icon="󰿆"

text="#cdd6f4"

if pidof hypridle > /dev/null 2>&1; then
  icon="$unlocked_icon"
  tooltip="Idle lock: ON (click to disable)"
  class="active"
else
  icon="$locked_icon"
  tooltip="Idle lock: OFF (click to enable)"
  class="inactive"
fi

printf '{"text": "<span font_size='"'"'20pt'"'"' rise='"'"'-3072'"'"' foreground='"'"'%s'"'"'>%s</span>", "tooltip": "%s", "class": "%s"}\n' \
    "$text" "$icon" "$tooltip" "$class"
