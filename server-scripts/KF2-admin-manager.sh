
#!/bin/bash
# Script: KF2-admin-manager.sh
# Descripción: Gestiona el valor de AdminPassword en LinuxServer-KFGame.ini según la variable KF2_ADMIN_PASSWORD
# y la opción de multi-admin en KFWebAdmin.ini según KF2_MULTI_ADMIN

CONFIG_FILE="$HOME/serverfiles/KFGame/Config/kf2server/LinuxServer-KFGame.ini"
WEBADMIN_INI="$HOME/serverfiles/KFGame/Config/kf2server/KFWebAdmin.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ No se encontró $CONFIG_FILE"
    exit 1
fi

ADMIN_PASSWORD="${KF2_ADMIN_PASSWORD}"
MULTI_ADMIN="${KF2_MULTI_ADMIN}"

if [ "$MULTI_ADMIN" = "false" ]; then
    if [ -f "$HOME/serverfiles/KFGame/Config/kf2server/KFMultiAdmin.ini" ]; then
        rm -f "$HOME/serverfiles/KFGame/Config/kf2server/KFMultiAdmin.ini"
        echo "[KF2-admin-manager.sh] Archivo KFMultiAdmin.ini eliminado porque KF2_MULTI_ADMIN=false."
    fi
fi

# --- Multi Admin WebAdmin ---
if [ -f "$WEBADMIN_INI" ]; then
    if [ "$MULTI_ADMIN" = "true" ]; then
        # Si la línea ya existe en la sección, no hacer nada
        if ! awk '/\[WebAdmin.WebAdmin\]/{f=1} /\[/{if($0!="[WebAdmin.WebAdmin]")f=0} f && /AuthenticationClass=WebAdmin.MultiWebAdminAuth/{found=1} END{exit !found}' "$WEBADMIN_INI"; then
            # Agregar la línea al final de la sección [WebAdmin.WebAdmin]
            awk '
                BEGIN{added=0}
                /^\[WebAdmin.WebAdmin\]/{print;in_section=1;next}
                /^\[/{if(in_section&&!added){print "AuthenticationClass=WebAdmin.MultiWebAdminAuth";added=1}in_section=0}
                {print}
                END{if(in_section&&!added)print "AuthenticationClass=WebAdmin.MultiWebAdminAuth"}
            ' "$WEBADMIN_INI" > "$WEBADMIN_INI.tmp" && mv "$WEBADMIN_INI.tmp" "$WEBADMIN_INI"
            echo "[KF2-admin-manager.sh] Multi admin habilitado en $WEBADMIN_INI"
        else
            echo "[KF2-admin-manager.sh] Multi admin ya estaba habilitado en $WEBADMIN_INI"
        fi
    else
        # Eliminar la línea si existe en la sección
        awk '
            BEGIN{in_section=0}
            /^\[WebAdmin.WebAdmin\]$/{in_section=1;print;next}
            /^\[/{if(in_section){in_section=0}}
            {if(!(in_section && $0=="AuthenticationClass=WebAdmin.MultiWebAdminAuth"))print}
        ' "$WEBADMIN_INI" > "$WEBADMIN_INI.tmp" && mv "$WEBADMIN_INI.tmp" "$WEBADMIN_INI"
        echo "[KF2-admin-manager.sh] Multi admin deshabilitado (o ya no estaba) en $WEBADMIN_INI"
    fi
else
    echo "⚠️  No se encontró $WEBADMIN_INI, se omite gestión de multi admin."
fi


# Si la variable está vacía, dejar AdminPassword vacío
if [ -z "$ADMIN_PASSWORD" ]; then
    sed -i 's/^AdminPassword=.*/AdminPassword=/' "$CONFIG_FILE"
    echo "[KF2-admin-manager.sh] AdminPassword eliminado (vacío) en $CONFIG_FILE"
else
    # Si existe la línea, modificarla; si no, agregarla
    if grep -q '^AdminPassword=' "$CONFIG_FILE"; then
        sed -i "s/^AdminPassword=.*/AdminPassword=${ADMIN_PASSWORD}/" "$CONFIG_FILE"
        echo "[KF2-admin-manager.sh] AdminPassword actualizado en $CONFIG_FILE"
    else
        echo "AdminPassword=${ADMIN_PASSWORD}" >> "$CONFIG_FILE"
        echo "[KF2-admin-manager.sh] AdminPassword agregado en $CONFIG_FILE"
    fi
fi