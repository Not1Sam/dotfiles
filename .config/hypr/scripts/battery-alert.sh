#!/usr/bin/env bash

# Battery Thresholds
T_20=20
T_15=15
T_10=10
T_5=5

# Cooldown for low battery alerts (120 seconds)
COOLDOWN=120
LAST_NOTIF=0

# Icons
ICON_CHG="battery-full-charging"
ICON_DIS="battery-full"
ICON_20="battery-low"
ICON_15="battery-caution"
ICON_10="battery-caution"
ICON_5="battery-empty"

# Sounds
S_PLUG="/usr/share/sounds/freedesktop/stereo/power-plug.oga"
S_UNPLUG="/usr/share/sounds/freedesktop/stereo/power-unplug.oga"
S_20="/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
S_15="/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
S_10="/usr/share/sounds/freedesktop/stereo/dialog-error.oga"
S_5="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

send_alert() {
    local urgency=$1
    local title=$2
    local msg=$3
    local icon=$4
    local sound=$5
    
    notify-send -u "$urgency" -a "Power" "$title" "$msg" -i "$icon" -t 5000
    paplay "$sound" || canberra-gtk-play -f "$sound" 2>/dev/null
}

# Initial status
BAT_PATH=$(find /sys/class/power_supply/ -name "BAT*" | head -n 1)
LAST_STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)

while true; do
    BAT_PATH=$(find /sys/class/power_supply/ -name "BAT*" | head -n 1)
    if [ -z "$BAT_PATH" ]; then sleep 60; continue; fi
    
    CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)
    NOW=$(date +%s)

    # 1. Improved Charger Detection
    if [ "$STATUS" != "$LAST_STATUS" ]; then
        if [ "$STATUS" = "Discharging" ]; then
            send_alert "normal" "󱐌 Charger Disconnected" "Power source removed. Battery: $CAPACITY%" "$ICON_DIS" "$S_UNPLUG"
            LAST_NOTIF=0
        elif [[ "$STATUS" == "Charging" || "$STATUS" == "Full" ]]; then
            send_alert "normal" "󱐋 Charger Connected" "Power source detected. Battery: $CAPACITY%" "$ICON_CHG" "$S_PLUG"
        fi
        LAST_STATUS="$STATUS"
    fi

    # 2. Low Battery Alerts
    if [ "$STATUS" = "Discharging" ]; then
        if [ $((NOW - LAST_NOTIF)) -ge $COOLDOWN ]; then
            if [ "$CAPACITY" -le "$T_5" ]; then
                send_alert "critical" "!!! EMERGENCY !!!" "Battery critically low: $CAPACITY%" "$ICON_5" "$S_5"
                LAST_NOTIF=$NOW
            elif [ "$CAPACITY" -le "$T_10" ]; then
                send_alert "critical" "!! DANGER !!" "Battery very low: $CAPACITY%" "$ICON_10" "$S_10"
                LAST_NOTIF=$NOW
            elif [ "$CAPACITY" -le "$T_15" ]; then
                send_alert "critical" "! WARNING !" "Battery low: $CAPACITY%" "$ICON_15" "$S_15"
                LAST_NOTIF=$NOW
            elif [ "$CAPACITY" -le "$T_20" ]; then
                send_alert "normal" "Battery Caution" "Battery level: $CAPACITY%" "$ICON_20" "$S_20"
                LAST_NOTIF=$NOW
            fi
        fi
    else
        LAST_NOTIF=0
    fi

    sleep 1
done
