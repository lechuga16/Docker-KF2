#!/bin/bash
# Script: KF2-headerbase-fix.sh
# Corrige el cierre de la etiqueta <link> en header_base.inc para cumplir con XHTML 1.1

HEADER_FILE="$HOME/serverfiles/KFGame/Web/ServerAdmin/header_base.inc"

if [ ! -f "$HEADER_FILE" ]; then
    echo "❌ No se encontró $HEADER_FILE"
    exit 1
fi

LINE_INCORRECTA="<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,700,700italic,600italic' rel='stylesheet' type='text/css'>"
LINE_CORRECTA="<link href='http://fonts.googleapis.com/css?family=Open+Sans:400,400italic,600,700,700italic,600italic' rel='stylesheet' type='text/css' />"

if grep -Fq "$LINE_INCORRECTA" "$HEADER_FILE"; then
    if ! grep -Fq "$LINE_CORRECTA" "$HEADER_FILE"; then
        sed -i "s|$LINE_INCORRECTA|$LINE_CORRECTA|g" "$HEADER_FILE"
        echo "[KF2-headerbase-fix.sh] Corrección aplicada en $HEADER_FILE"
    else
        echo "[KF2-headerbase-fix.sh] Ya corregido previamente en $HEADER_FILE"
    fi
else
    echo "[KF2-headerbase-fix.sh] No se requiere corrección en $HEADER_FILE"
fi
