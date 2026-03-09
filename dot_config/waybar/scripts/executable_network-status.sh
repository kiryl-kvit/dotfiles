#!/bin/bash

wifi_icons=("󰤯" "󰤟" "󰤢" "󰤥" "󰤨")
ethernet_icon="󰈀"
disconnected_icon="󰤭"
vpn_shield="󰒃"

net_type=""
while IFS=: read -r _dev type state _rest; do
    if [[ "$state" == "connected" ]]; then
        case "$type" in
            wifi)     net_type="wifi" ;;
            ethernet) net_type="ethernet" ;;
        esac
    fi
done < <(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null)

essid=""
signal=""
if [[ "$net_type" == "wifi" ]]; then
    while IFS=: read -r active sig rest; do
        if [[ "$active" == "yes" ]]; then
            signal="$sig"
            essid="$rest"
            break
        fi
    done < <(nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null)
fi

case "$net_type" in
    wifi)
        if [[ -n "$signal" ]]; then
            if   (( signal >= 80 )); then idx=4
            elif (( signal >= 60 )); then idx=3
            elif (( signal >= 40 )); then idx=2
            elif (( signal >= 20 )); then idx=1
            else idx=0
            fi
        else
            idx=4
        fi
        icon="${wifi_icons[$idx]}"
        tooltip="${essid} (${signal}%)"
        ;;
    ethernet)
        icon="$ethernet_icon"
        tooltip="Ethernet"
        ;;
    *)
        icon="$disconnected_icon"
        tooltip="Disconnected"
        ;;
esac

has_vpn=false
vpn_names=()

while IFS= read -r iface; do
    [[ -n "$iface" ]] && vpn_names+=("$iface") && has_vpn=true
done < <(ls /sys/class/net/ 2>/dev/null | grep -E '^wg')

while IFS= read -r iface; do
    [[ -n "$iface" ]] && vpn_names+=("$iface") && has_vpn=true
done < <(ls /sys/class/net/ 2>/dev/null | grep -E '^tun[0-9]|^tap[0-9]')

if command -v nmcli &>/dev/null; then
    while IFS= read -r name; do
        [[ -n "$name" ]] && vpn_names+=("$name") && has_vpn=true
    done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
        | awk -F: '$2 ~ /vpn|wireguard/ {print $1}')
fi

if $has_vpn; then
    text="<span font_size='20pt' rise='-3072' letter_spacing='-4096'>${icon}</span><span font_size='10pt' rise='-6144'>${vpn_shield}</span>"

    mapfile -t vpn_names < <(printf '%s\n' "${vpn_names[@]}" | sort -u)
    tooltip="${tooltip} | VPN: ${vpn_names[*]}"
else
    text="<span font_size='20pt' rise='-3072'>${icon}</span>"
fi

tooltip="${tooltip//\\/\\\\}"
tooltip="${tooltip//\"/\\\"}"

printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
