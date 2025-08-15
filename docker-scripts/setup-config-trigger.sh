#!/bin/bash
# Script: setup-config-trigger.sh
# Description: Sets up automatic execution of server configuration
# Executed as root during container startup

echo "=== Configurando trigger de configuración ==="

# Crear script que se ejecute automáticamente cuando el usuario linuxgsm haga login
PROFILE_SCRIPT="/data/.profile-config"

cat > "${PROFILE_SCRIPT}" << 'EOF'
#!/bin/bash
# Auto-configuración KF2 - Se ejecuta una vez al iniciar como linuxgsm

CONFIG_FLAG="/data/.config-completed"

# Solo ejecutar si no se ha ejecutado antes
if [ ! -f "${CONFIG_FLAG}" ]; then
    echo ""
    echo "🔧 Ejecutando configuración inicial del servidor KF2..."
    
    # Ejecutar script de configuración si existe
    if [ -f "/data/run-server-config.sh" ]; then
        /data/run-server-config.sh
        
        # Marcar como completado
        touch "${CONFIG_FLAG}"
        echo "✅ Configuración inicial completada"
    fi
fi
EOF

chmod +x "${PROFILE_SCRIPT}"
chown linuxgsm:linuxgsm "${PROFILE_SCRIPT}"

# Agregar la ejecución al .bashrc del usuario linuxgsm
BASHRC_FILE="/data/.bashrc"

if [ -f "${BASHRC_FILE}" ]; then
    # Verificar si ya está agregado
    if ! grep -q "profile-config" "${BASHRC_FILE}"; then
        echo "" >> "${BASHRC_FILE}"
        echo "# Auto-configuración KF2" >> "${BASHRC_FILE}"
        echo "[ -f /data/.profile-config ] && /data/.profile-config" >> "${BASHRC_FILE}"
        echo "✅ Trigger agregado a .bashrc"
    else
        echo "ℹ️  Trigger ya existe en .bashrc"
    fi
else
    echo "⚠️  .bashrc no encontrado, se creará durante el primer inicio"
fi

echo "✅ Configuración de trigger completada"
