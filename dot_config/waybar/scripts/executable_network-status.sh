#!/bin/bash

# Combined network + VPN status for Waybar
# Replaces the built-in network module to add a KDE-style VPN shield badge
# Outputs JSON with Pango markup for use with "return-type": "json"

wifi_icons=("󰤯" "󰤟" "󰤢" "󰤥" "󰤨")
ethernet_icon="󰈀"
disconnected_icon="󰤭"
vpn_shield="󰒃"

# --- Detect network type ---
net_type=""
while IFS=: read -r _dev type state _rest; do
    if [[ "$state" == "connected" ]]; then
        case "$type" in
            wifi)     net_type="wifi" ;;
            ethernet) net_type="ethernet" ;;
        esac
    fi
done < <(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null)

# --- Get WiFi details ---
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

# --- Choose icon and tooltip ---
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

# --- Detect VPN ---
has_vpn=false
vpn_names=()

# WireGuard interfaces (wg0, wg1, ...)
while IFS= read -r iface; do
    [[ -n "$iface" ]] && vpn_names+=("$iface") && has_vpn=true
done < <(ls /sys/class/net/ 2>/dev/null | grep -E '^wg')

# TUN/TAP interfaces (OpenVPN, etc.)
while IFS= read -r iface; do
    [[ -n "$iface" ]] && vpn_names+=("$iface") && has_vpn=true
done < <(ls /sys/class/net/ 2>/dev/null | grep -E '^tun[0-9]|^tap[0-9]')

# NetworkManager-managed VPN connections
if command -v nmcli &>/dev/null; then
    while IFS= read -r name; do
        [[ -n "$name" ]] && vpn_names+=("$name") && has_vpn=true
    done < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
        | awk -F: '$2 ~ /vpn|wireguard/ {print $1}')
fi

# --- Build Pango output ---
if $has_vpn; then
    # Main icon with negative letter_spacing to pull the shield badge leftward,
    # then a smaller shield at a lower rise for the bottom-right badge effect
    text="<span font_size='20pt' rise='-3072' letter_spacing='-4096'>${icon}</span><span font_size='10pt' rise='-6144'>${vpn_shield}</span>"

    mapfile -t vpn_names < <(printf '%s\n' "${vpn_names[@]}" | sort -u)
    tooltip="${tooltip} | VPN: ${vpn_names[*]}"
else
    text="<span font_size='20pt' rise='-3072'>${icon}</span>"
fi

# Escape tooltip for JSON
tooltip="${tooltip//\\/\\\\}"
tooltip="${tooltip//\"/\\\"}"

printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
