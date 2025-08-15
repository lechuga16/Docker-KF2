#!/bin/bash
# Script: KF2-workshop.sh
# Maneja las suscripciones de Steam Workshop para Killing Floor 2 usando la variable de entorno KF2_WORKSHOP

WORKSHOP_INI="$HOME/serverfiles/KFGame/Config/kf2server/LinuxServer-KFEngine.ini"

# Leer la variable de entorno como array

IFS=',' read -ra WORKSHOP_IDS <<< "${KF2_WORKSHOP//[\[\] ]/}"


if [ -z "${WORKSHOP_IDS[*]}" ] || [ "${WORKSHOP_IDS[*]}" = "" ]; then
    # Si no hay IDs, eliminar la sección completa de workshop de forma segura
    if [ -f "$WORKSHOP_INI" ]; then
        awk '
            BEGIN {in_section=0}
            /^\[OnlineSubsystemSteamworks.KFWorkshopSteamworks\]$/ {in_section=1; next}
            /^\[/ {if(in_section){in_section=0}}
            {if(!in_section) print}
        ' "$WORKSHOP_INI" > "$WORKSHOP_INI.tmp" && mv "$WORKSHOP_INI.tmp" "$WORKSHOP_INI"
        # Eliminar cualquier línea DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload y DownloadManagers= (vacía) de la sección [IpDrv.TcpNetDriver]
        tmpfile2=$(mktemp)
        awk '
            BEGIN {in_section=0}
            /^\[IpDrv.TcpNetDriver\]$/ {in_section=1; print; next}
            /^\[/ {in_section=0}
            in_section && ($0=="DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload" || $0=="DownloadManagers=") {next}
            {print}
        ' "$WORKSHOP_INI" > "$tmpfile2" && mv "$tmpfile2" "$WORKSHOP_INI"
        echo "[KF2-workshop.sh] Se eliminaron líneas DownloadManagers de [IpDrv.TcpNetDriver] porque no hay workshop."
        echo "[KF2-workshop.sh] Se eliminó la sección [OnlineSubsystemSteamworks.KFWorkshopSteamworks] de $WORKSHOP_INI porque KF2_WORKSHOP está vacío."
    else
        echo "[KF2-workshop.sh] No hay IDs de Workshop definidos y no existe $WORKSHOP_INI."
    fi
    exit 0
fi

if [ ! -f "$WORKSHOP_INI" ]; then
    echo "❌ No se encontró $WORKSHOP_INI"
    exit 1
fi


# Eliminar sección existente [OnlineSubsystemSteamworks.KFWorkshopSteamworks] de forma robusta
tmpfile=$(mktemp)
awk '
    BEGIN {in_section=0}
    /^\[OnlineSubsystemSteamworks.KFWorkshopSteamworks\]$/ {in_section=1; next}
    /^\[/ {if(in_section){in_section=0}}
    {if(!in_section) print}
' "$WORKSHOP_INI" > "$tmpfile" && mv "$tmpfile" "$WORKSHOP_INI"

# Agregar la sección con los nuevos IDs solo una vez al final
{
    echo ""  # Asegura salto de línea final
    echo "[OnlineSubsystemSteamworks.KFWorkshopSteamworks]"
    for id in "${WORKSHOP_IDS[@]}"; do
        echo "ServerSubscribedWorkshopItems=$id"
    done
} >> "$WORKSHOP_INI"

# --- Asegurar DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload en [IpDrv.TcpNetDriver] ---
tmpfile2=$(mktemp)
if [ -z "${WORKSHOP_IDS[*]}" ] || [ "${WORKSHOP_IDS[*]}" = "" ]; then
    # Si no hay IDs, eliminar cualquier línea DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload y DownloadManagers= (vacía) de la sección [IpDrv.TcpNetDriver]
    awk '
        BEGIN {in_section=0}
        /^\[IpDrv.TcpNetDriver\]$/ {in_section=1; print; next}
        /^\[/ {in_section=0}
        in_section && ($0=="DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload" || $0=="DownloadManagers=") {next}
        {print}
    ' "$WORKSHOP_INI" > "$tmpfile2" && mv "$tmpfile2" "$WORKSHOP_INI"
    echo "[KF2-workshop.sh] Se eliminaron líneas DownloadManagers de [IpDrv.TcpNetDriver] porque no hay workshop."
else
    # Si hay IDs, asegurar que la línea esté como la primera DownloadManagers en la sección
    awk '
        BEGIN {in_section=0; inserted=0}
        /^\[IpDrv.TcpNetDriver\]$/ {in_section=1; print; next}
        /^\[/ {
            if(in_section && !inserted){print "DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload"; inserted=1}
            in_section=0
        }
        in_section && $0=="DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload" {next}
        in_section && !inserted && $0 !~ /^DownloadManagers=/ {
            print "DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload"; inserted=1
        }
        {print}
        END{if(in_section && !inserted){print "DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload"}}
    ' "$WORKSHOP_INI" > "$tmpfile2" && mv "$tmpfile2" "$WORKSHOP_INI"
    echo "[KF2-workshop.sh] DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload asegurado en [IpDrv.TcpNetDriver] porque hay workshop."
fi

echo "[KF2-workshop.sh] Suscripciones de Workshop actualizadas en $WORKSHOP_INI: ${WORKSHOP_IDS[*]}"
