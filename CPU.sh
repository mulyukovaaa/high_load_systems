#!/bin/bash

export LC_NUMERIC="C"

ALERT_COLOR='\e[1;31m'
INFO_COLOR='\e[1;32m'
RESET_COLOR='\e[0m'

CPU_LOAD_THRESHOLD=80.0
TEMP_THRESHOLD=75.0
MEMORY_USAGE_THRESHOLD=80.0
SWAP_USAGE_THRESHOLD=80.0
FREQUENCY_THRESHOLD=90.0
CONTEXT_SWITCHES_THRESHOLD=200

INTERVAL=1

get_cpu_load() {
    CPU_LOAD=$(mpstat 1 1 | grep "all" | awk '{print 100 - $NF}' | tr -d ' ' | head -n 1)
    echo $(echo $CPU_LOAD | sed 's/,/./')
}

get_temperature() {
    CURRENT_TEMP=$(sensors | grep 'Tctl' | awk '{print $2}' | tr -d '+°C')
    echo $CURRENT_TEMP
}

get_memory_usage() {
    MEMORY_INFO=$(free | grep -E 'Память|Mem')
    TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}' | sed 's/,/./')
    USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}' | sed 's/,/./')
    MEMORY_USAGE=$(echo "scale=2; ($USED_MEM / $TOTAL_MEM) * 100" | bc)
    echo $MEMORY_USAGE
}

get_swap_usage() {
    SWAP_INFO=$(free | grep -E 'Подкачка|Swap')
    TOTAL_SWAP=$(echo $SWAP_INFO | awk '{print $2}'| sed 's/,/./')
    USED_SWAP=$(echo $SWAP_INFO | awk '{print $3}'| sed 's/,/./')
    SWAP_USAGE=$(echo "scale=2; ($USED_SWAP / $TOTAL_SWAP) * 100" | bc)
    echo $SWAP_USAGE
}

get_cpu_frequency() {
    MAX_FREQ=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq | sort -n | tail -n 1)
    CURRENT_FREQ=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | sort -n | tail -n 1)
    FREQUENCY_USAGE=$(echo "scale=2; ($CURRENT_FREQ / $MAX_FREQ) * 100" | bc)
    echo $FREQUENCY_USAGE
}

get_context_switches() {
    CONTEXT_SWITCHES=$(vmstat $INTERVAL 2 | tail -n 1 | awk '{print $15}')
    
    if [ "$CONTEXT_SWITCHES" -gt "$CONTEXT_SWITCHES_THRESHOLD" ]; then
        printf "%b[ALERT]%b %-20s exceeds threshold!  Current: %d\tThreshold: %d\n" "$ALERT_COLOR" "$RESET_COLOR" "Context switches" "$CONTEXT_SWITCHES" "$CONTEXT_SWITCHES_THRESHOLD"
    else
        printf "%b[INFO]%b %-20s is within normal limits. Current: %d\tThreshold: %d\n" "$INFO_COLOR" "$RESET_COLOR" "Context switches" "$CONTEXT_SWITCHES" "$CONTEXT_SWITCHES_THRESHOLD"
    fi
}

check_alert() {
    local current_value=$1
    local threshold=$2
    local metric_name=$3

    if (( $(echo "$current_value > $threshold" | bc -l) )); then
        printf "%b[ALERT]%b %-20s exceeds threshold!  Current: %.2f%%\tThreshold: %.2f%%\n" "$ALERT_COLOR" "$RESET_COLOR" "$metric_name" "$current_value" "$threshold"
    else
        printf "%b[INFO]%b %-20s is within normal limits. Current: %.2f%%\tThreshold: %.2f%%\n" "$INFO_COLOR" "$RESET_COLOR" "$metric_name" "$current_value" "$threshold"
    fi
}

CPU_LOAD=$(get_cpu_load)
CURRENT_TEMP=$(get_temperature)
MEMORY_USAGE=$(get_memory_usage)
SWAP_USAGE=$(get_swap_usage)
FREQUENCY_USAGE=$(get_cpu_frequency)

check_alert $CPU_LOAD $CPU_LOAD_THRESHOLD "CPU load"
check_alert $CURRENT_TEMP $TEMP_THRESHOLD "Temperature"
check_alert $MEMORY_USAGE $MEMORY_USAGE_THRESHOLD "Memory usage"
check_alert $SWAP_USAGE $SWAP_USAGE_THRESHOLD "Swap usage"
check_alert $FREQUENCY_USAGE $FREQUENCY_THRESHOLD "CPU frequency"
get_context_switches
