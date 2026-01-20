#!/run/current-system/sw/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$DIR/waybar.template.jsonc"

WORKSPACES_PER_MONITOR=5

pkill -f "waybar -c.*monitor" 2>/dev/null || true

mapfile -t monitors < <(hyprctl monitors -j | jq -r ".[].name" 2>/dev/null || true)
[[ ${#monitors[@]} -eq 0 ]] && { echo "No monitors" >&2; exit 1; }

echo "Setup: ${monitors[*]}"

for i in "${!monitors[@]}"; do
    monitor_name="${monitors[i]}"
    
    start_ws=$((i * WORKSPACES_PER_MONITOR + 1))
    end_ws=$((start_ws + WORKSPACES_PER_MONITOR - 1))
    
    workspaces_json="{"
    for ((ws = start_ws; ws <= end_ws; ws++)); do
        workspaces_json+="\n      \"$ws\": []"
        [[ $ws -lt $end_ws ]] && workspaces_json+=","
    done
    workspaces_json+="\n    }"
    
    waybar -b "$i" -c <(
        awk -v monitor="$monitor_name" -v workspaces="$workspaces_json" '
        {gsub(/{{MONITOR_NAME}}/, monitor); gsub(/{{WORKSPACES}}/, workspaces); print}
        ' "$TEMPLATE"
    ) & echo "Started: ${monitors[i]} (PID: $!)"
done
