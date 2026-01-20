#!/bin/sh

# Dynamic monitor detection and screenshot capture
MONITORS=$(hyprctl monitors -j | jq -r '.[] | .name' 2>/dev/null)
rm -f /tmp/*.png 2>/dev/null

for monitor in $MONITORS; do
    (grim -o "$monitor" "/tmp/$monitor.png" 2>/dev/null && \
     corrupter "/tmp/$monitor.png" "/tmp/$monitor.png") &
done
wait

# CSS file modification
CSS_FILE="/home/allisnull/nixos-config/gtklock.css"

# Remove old monitor-specific rules
sed -i '/^window#[^{]*{/,/^}$/d' "$CSS_FILE"

# Generate new monitor rules
MONITOR_CSS=""
for monitor in $MONITORS; do
    if [ -f "/tmp/$monitor.png" ]; then
        MONITOR_CSS="${MONITOR_CSS}window#$monitor {
    background-image: url(\"/tmp/$monitor.png\");
}
"
    fi
done

# Find insertion point and insert new rules
if [ -n "$MONITOR_CSS" ]; then
    # Find line number for insertion (second "^window" or first "^window#")
    INSERT_LINE=$(awk '/^window/ {count++; if (count == 2 && /^window#/) {print NR; exit} if (count == 1 && /^window#/) {print NR; exit}}' "$CSS_FILE")
    
    if [ -n "$INSERT_LINE" ]; then
        # Insert new rules at found line
        head -n $((INSERT_LINE - 1)) "$CSS_FILE" > "$CSS_FILE.tmp"
        echo "$MONITOR_CSS" >> "$CSS_FILE.tmp"
        tail -n +$INSERT_LINE "$CSS_FILE" >> "$CSS_FILE.tmp"
        mv "$CSS_FILE.tmp" "$CSS_FILE"
    else
        # If no insertion point found, append at end
        echo "$MONITOR_CSS" >> "$CSS_FILE"
    fi
fi

exec gtklock "$@"
