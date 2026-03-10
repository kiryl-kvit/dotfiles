#!/bin/bash

profile_icons_balanced="󰗑"
profile_icons_performance="󱐌"
profile_icons_power_saver="󰌪"

red="#f38ba8"
green="#a6e3a1"
blue="#89b4fa"
yellow="#f9e2af"
text="#cdd6f4"

profile=$(powerprofilesctl get 2>/dev/null || echo "balanced")
case "$profile" in
performance)
  profile_icon="$profile_icons_performance"
  profile_color="$red"
  ;;
power-saver)
  profile_icon="$profile_icons_power_saver"
  profile_color="$blue"
  ;;
*)
  profile_icon="$profile_icons_balanced"
  profile_color="$green"
  ;;
esac

bat_path=""
for b in /sys/class/power_supply/BAT*; do
  [[ -d "$b" ]] && bat_path="$b" && break
done

classes=("$profile")

if [[ -n "$bat_path" ]]; then
  capacity=$(cat "$bat_path/capacity" 2>/dev/null || echo 0)
  status=$(cat "$bat_path/status" 2>/dev/null || echo "Unknown")

  if ((capacity >= 90)); then
    idx=4
  elif ((capacity >= 70)); then
    idx=3
  elif ((capacity >= 40)); then
    idx=2
  elif ((capacity >= 15)); then
    idx=1
  else
    idx=0
  fi
  bat_icon="${battery_icons[$idx]}"

  if [[ "$status" == "Charging" ]]; then
    bat_color="$green"
    classes+=("charging")
  elif ((capacity <= 15)); then
    bat_color="$red"
    classes+=("critical")
  elif ((capacity <= 30)); then
    bat_color="$yellow"
    classes+=("warning")
  else
    bat_color="$text"
  fi

  output="<span font_size='20pt' rise='-3072' foreground='${profile_color}'>${profile_icon}</span> <span rise='-1024' foreground='${text}'>${capacity}%</span>"
  tooltip="Battery: ${capacity}% (${status}) | Profile: ${profile}"
else
  output="<span font_size='20pt' rise='-3072' foreground='${profile_color}'>${profile_icon}</span>"
  tooltip="Profile: ${profile}"
fi

class_json=$(printf '"%s"' "${classes[0]}")
for c in "${classes[@]:1}"; do
  class_json+=", \"$c\""
done

tooltip="${tooltip//\\/\\\\}"
tooltip="${tooltip//\"/\\\"}"

printf '{"text": "%s", "tooltip": "%s", "class": [%s]}\n' "$output" "$tooltip" "$class_json"
