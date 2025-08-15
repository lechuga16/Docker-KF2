#!/bin/bash
# Script: manage-bashrc.sh
# Descripción: Gestiona la existencia y permisos de .bashrc para el usuario linuxgsm


BASHRC="$HOME/.bashrc"

if [ ! -f "$BASHRC" ]; then
    echo "[manage-bashrc.sh] Creando $BASHRC"
    cp /etc/skel/.bashrc "$BASHRC"
    echo "[manage-bashrc.sh] Asignando propietario a $BASHRC"
    chown linuxgsm:linuxgsm "$BASHRC"
else
    echo "[manage-bashrc.sh] $BASHRC ya existe"
fi
