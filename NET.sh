#!/bin/bash

export LC_NUMERIC="C"

ALERT_COLOR='\e[1;31m'
INFO_COLOR='\e[1;32m'
RESET_COLOR='\e[0m'

MAX_CONNECTIONS_THRESHOLD=50
MAX_INTERFACE_LOAD_THRESHOLD=1000000

INTERVAL=1

check_ping() {
    TARGET="8.8.8.8"
    PING_RESULT=$(ping -c 3 $TARGET > /dev/null; echo $?)

    if [ $PING_RESULT -eq 0 ]; then
        printf "%b[INFO]%b %-20s is reachable.\n" "$INFO_COLOR" "$RESET_COLOR" "google.com"
    else
        printf "%b[ALERT]%b %-20s is not reachable!\n" "$ALERT_COLOR" "$RESET_COLOR" "google.com"
    fi
}

get_active_connections() {
    CONNECTIONS=$(netstat -tuln | grep -c LISTEN)
    echo $CONNECTIONS
}

get_routing_table_status() {
    DEFAULT_ROUTE=$(ip route | grep -c 'default')
    echo $DEFAULT_ROUTE
}

get_interface_stats() {
    INTERFACE_STATS=$(ip -s link | grep -A 1 'RX:' | tail -n1 | awk '{print $1}')
    echo $INTERFACE_STATS
}

check_alert() {
    local current_value=$1
    local threshold=$2
    local metric_name=$3

    if (( current_value > threshold )); then
        printf "%b[ALERT]%b %-20s exceeds threshold!  Current: %d\tThreshold: %d\n" "$ALERT_COLOR" "$RESET_COLOR" "$metric_name" "$current_value" "$threshold"
    else
        printf "%b[INFO]%b %-20s is within normal limits. Current: %d\tThreshold: %d\n" "$INFO_COLOR" "$RESET_COLOR" "$metric_name" "$current_value" "$threshold"
    fi
}

scan_open_ports() {
    TARGET="localhost"
    echo -e "$INFO_COLOR[INFO]$RESET_COLOR Сканирование открытых портов на $TARGET..."
    echo -e "$INFO_COLOR==============================$RESET_COLOR"

    OPEN_PORTS=$(nmap -p- --open $TARGET | grep '/tcp')

    if [ -n "$OPEN_PORTS" ]; then
        echo -e "$ALERT_COLOR[ALERT]$RESET_COLOR Найдены открытые порты на $TARGET:"
        echo -e "$INFO_COLOR------------------------------$RESET_COLOR"
        echo -e "$INFO_COLOR Порт\t\tСервис$RESET_COLOR"
        echo -e "$INFO_COLOR------------------------------$RESET_COLOR"
        
        echo "$OPEN_PORTS" | while read line; do
            PORT=$(echo $line | awk '{print $1}')
            SERVICE=$(echo $line | awk '{print $3}')
            printf "%b%-10s\t%s\n" "$ALERT_COLOR" "$PORT" "$SERVICE"
        done

        echo -e "$INFO_COLOR------------------------------$RESET_COLOR"
    else
        echo -e "$INFO_COLOR[INFO]$RESET_COLOR Открытых портов не найдено на $TARGET."
    fi
}

check_ping

ACTIVE_CONNECTIONS=$(get_active_connections)
check_alert $ACTIVE_CONNECTIONS $MAX_CONNECTIONS_THRESHOLD "Active connections"

DEFAULT_ROUTE_STATUS=$(get_routing_table_status)
if [ $DEFAULT_ROUTE_STATUS -gt 0 ]; then
    printf "%b[INFO]%b %-20s is present.\n" "$INFO_COLOR" "$RESET_COLOR" "Default route"
else
    printf "%b[ALERT]%b %-20s is missing!\n" "$ALERT_COLOR" "$RESET_COLOR" "Default route"
fi

INTERFACE_STATS=$(get_interface_stats)
check_alert $INTERFACE_STATS $MAX_INTERFACE_LOAD_THRESHOLD "Network interface load"

scan_open_ports
