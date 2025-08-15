#!/bin/bash
# Script: KF2-current-fix.sh
# Corrige el cierre de la etiqueta <a> en current.html para cumplir con XHTML 1.1

CURRENT_FILE="$HOME/serverfiles/KFGame/Web/ServerAdmin/current.html"

TH_LINE_INCORRECTA='<th><a href="<%page.fulluri%>?sortby=perk&amp;reverse=<%reverse.perk%>" class="sortable <%sorted.perk%>">Perk</th>'
TH_LINE_CORRECTA='<th><a href="<%page.fulluri%>?sortby=perk&amp;reverse=<%reverse.perk%>" class="sortable <%sorted.perk%>">Perk</a></th>'

if [ -f "$CURRENT_FILE" ]; then
    if grep -Fq "$TH_LINE_INCORRECTA" "$CURRENT_FILE"; then
        if ! grep -Fq "$TH_LINE_CORRECTA" "$CURRENT_FILE"; then
            sed -i "s|$TH_LINE_INCORRECTA|$TH_LINE_CORRECTA|g" "$CURRENT_FILE"
            echo "[KF2-current-fix.sh] Corrección aplicada en $CURRENT_FILE"
        else
            echo "[KF2-current-fix.sh] Ya corregido previamente en $CURRENT_FILE"
        fi
    else
        echo "[KF2-current-fix.sh] No se requiere corrección en $CURRENT_FILE"
    fi
else
    echo "[KF2-current-fix.sh] No se encontró $CURRENT_FILE"
fi
