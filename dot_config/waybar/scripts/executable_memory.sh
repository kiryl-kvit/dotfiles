#!/bin/bash

# Read MemTotal and MemAvailable from /proc/meminfo.
# Using MemAvailable (not MemFree) correctly excludes reclaimable
# disk cache and buffers, showing only memory genuinely in use.
while read -r key value _; do
    case "$key" in
        MemTotal:)     mem_total=$value ;;
        MemAvailable:) mem_avail=$value ;;
    esac
done < /proc/meminfo

mem_used=$((mem_total - mem_avail))
percentage=$((mem_used * 100 / mem_total))

read -r used_gib total_gib <<< "$(awk "BEGIN {printf \"%.1f %.1f\", $mem_used/1048576, $mem_total/1048576}")"

icons=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
icon_index=$((percentage * 8 / 100))
[[ $icon_index -ge 8 ]] && icon_index=7

echo "{\"text\":\"${icons[$icon_index]}\",\"tooltip\":\"RAM: ${used_gib} GiB / ${total_gib} GiB (${percentage}%)\",\"percentage\":${percentage}}"
