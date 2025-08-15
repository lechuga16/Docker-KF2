#!/bin/bash
# Script: manage-authorized-keys.sh
# Descripción: Gestiona el archivo authorized_keys del usuario linuxgsm según la variable SSH_KEY

set -e


SSH_DIR="$HOME/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

# Crear el directorio si no existe (migrado desde entrypoint.sh)
if [ ! -d "$SSH_DIR" ]; then
    echo "[manage-authorized-keys.sh] Creando $SSH_DIR"
    mkdir -p "$SSH_DIR"
    echo "[manage-authorized-keys.sh] Asignando permisos y propietario a $SSH_DIR"
    chown linuxgsm:linuxgsm "$SSH_DIR"
    chmod 700 "$SSH_DIR"
else
    echo "[manage-authorized-keys.sh] $SSH_DIR ya existe"
fi

# Si SSH_KEY está vacío, eliminar authorized_keys
if [ -z "$SSH_KEY" ]; then
    echo "[manage-authorized-keys.sh] SSH_KEY vacío. Eliminando $AUTH_KEYS si existe."
    rm -f "$AUTH_KEYS"
    exit 0
fi

# Procesar claves separadas por coma
IFS=',' read -ra KEYS <<< "$SSH_KEY"
unset SSH_KEY  # Elimina la variable tan pronto como se procesa
echo "[manage-authorized-keys.sh] Escribiendo claves en $AUTH_KEYS:"
> "$AUTH_KEYS"
for key in "${KEYS[@]}"; do
    key_trimmed="$(echo -e "$key" | xargs)"
    if [ -n "$key_trimmed" ]; then
        echo "$key_trimmed" >> "$AUTH_KEYS"
        # Mostrar solo tipo y fingerprint parcial, no la clave completa
        tipo=$(echo "$key_trimmed" | awk '{print $1}')
        fingerprint=$(echo "$key_trimmed" | awk '{print $2}' | cut -c1-8)
        echo "  - $tipo $fingerprint..."
    fi
done
unset KEYS  # Elimina el array de claves

chown linuxgsm:linuxgsm "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
echo "[manage-authorized-keys.sh] Operación completada."
