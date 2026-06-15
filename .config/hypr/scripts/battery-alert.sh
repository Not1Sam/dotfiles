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

send_alert() {
    local urgency=$1
    local title=$2
    local msg=$3
    local icon=$4
    
    # We only send the notification. SwayNC handles the sound via its script.
    notify-send -u "$urgency" -a "Power" "$title" "$msg" -i "$icon" -t 5000
}

# Initial status
BAT_PATH=$(find /sys/class/power_supply/ -name "BAT*" | head -n 1)
LAST_STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)

while true; do
    # Only find BAT_PATH if it's not set
    if [ -z "$BAT_PATH" ]; then
        BAT_PATH=$(find /sys/class/power_supply/ -name "BAT*" | head -n 1)
        if [ -z "$BAT_PATH" ]; then sleep 60; continue; fi
    fi
    
    CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null)
    STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)
    NOW=$(date +%s)

    # 1. Improved Charger Detection
    if [ "$STATUS" != "$LAST_STATUS" ]; then
        if [ "$STATUS" = "Discharging" ]; then
            send_alert "normal" "󱐌 Charger Disconnected" "Power source removed. Battery: $CAPACITY%" "$ICON_DIS"
            LAST_NOTIF=0
        elif [[ "$STATUS" == "Charging" || "$STATUS" == "Full" ]]; then
            send_alert "normal" "󱐋 Charger Connected" "Power source detected. Battery: $CAPACITY%" "$ICON_CHG"
        fi
        LAST_STATUS="$STATUS"
    fi

    # 2. Low Battery Alerts
    if [ "$STATUS" = "Discharging" ]; then
        if [ $((NOW - LAST_NOTIF)) -ge $COOLDOWN ]; then
            if [ "$CAPACITY" -le "$T_5" ]; then
                send_alert "critical" "!!! EMERGENCY !!!" "Battery critically low: $CAPACITY%" "$ICON_5"
                LAST_NOTIF=$NOW
            elif [ "$CAPACITY" -le "$T_20" ]; then
                send_alert "normal" "Battery Caution" "Battery level: $CAPACITY%" "$ICON_20"
                LAST_NOTIF=$NOW
            fi
        fi
    else
        LAST_NOTIF=0
    fi

    # Increased sleep interval to 60 seconds to reduce CPU wakeups
    sleep 60
done
