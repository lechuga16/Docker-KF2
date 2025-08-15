#!/bin/bash
# Script: KF2-tickrate.sh
# Aplica el tickrate definido en la variable de entorno KF2_TICKRATE al archivo LinuxServer-KFEngine.ini

WORKSHOP_INI="$HOME/serverfiles/KFGame/Config/kf2server/LinuxServer-KFEngine.ini"

if [ -z "$KF2_TICKRATE" ]; then
    echo "[KF2-tickrate.sh] La variable KF2_TICKRATE no está definida."
    exit 1
fi

if [ ! -f "$WORKSHOP_INI" ]; then
    echo "[KF2-tickrate.sh] No se encontró $WORKSHOP_INI"
    exit 1
fi

tmpfile=$(mktemp)
awk -v tickrate="$KF2_TICKRATE" '
    BEGIN {in_section=0; found=0}
    /^\[IpDrv.TcpNetDriver\]$/ {in_section=1; print; next}
    /^\[/ {
        if(in_section && !found){print "NetServerMaxTickRate="tickrate; found=1}
        in_section=0
    }
    in_section && $0 ~ /^NetServerMaxTickRate=/ {
        if(!found){print "NetServerMaxTickRate="tickrate; found=1}
        next
    }
    {print}
    END{if(in_section && !found){print "NetServerMaxTickRate="tickrate}}
' "$WORKSHOP_INI" > "$tmpfile" && mv "$tmpfile" "$WORKSHOP_INI"

echo "[KF2-tickrate.sh] NetServerMaxTickRate actualizado a $KF2_TICKRATE en $WORKSHOP_INI."
