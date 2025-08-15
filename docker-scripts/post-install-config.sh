#!/bin/bash
# Script: post-install-config.sh
# Description: Executes server configuration scripts after KF2 installation
# Location: /app/docker-scripts/ (executed during container startup)

echo "=== Post-Installation Configuration ==="

# Función para crear script de configuración diferida
create_deferred_config_script() {
    local server_scripts_dir="/app/server-scripts"
    
    if [ ! -d "${server_scripts_dir}" ]; then
        echo "ℹ️  No hay directorio server-scripts, omitiendo configuración personalizada"
        return 0
    fi
    
    echo "🔍 Buscando scripts de configuración en ${server_scripts_dir}"
    
    # Crear script que se ejecutará como usuario linuxgsm después del inicio
    cat > "/data/run-server-config.sh" << 'EOF'
#!/bin/bash
# Script de configuración diferida - Se ejecuta como usuario linuxgsm

echo "=== Configuración Post-Instalación KF2 ==="
echo "Usuario: $(whoami)"
echo "Fecha: $(date)"

# Esperar a que el sistema esté completamente iniciado
sleep 10

# Ejecutar scripts de configuración del servidor
SERVER_SCRIPTS_DIR="/app/server-scripts"
if [ -d "${SERVER_SCRIPTS_DIR}" ] && ls "${SERVER_SCRIPTS_DIR}"/*.sh 1> /dev/null 2>&1; then
    for script in "${SERVER_SCRIPTS_DIR}"/*.sh; do
        script_name=$(basename "${script}")
        echo ""
        echo "📝 Ejecutando: ${script_name}"
        echo "----------------------------------------"
        
        # Pasar variables de entorno
        export KF2_GAME_PORT="${KF2_GAME_PORT}"
        export KF2_QUERY_PORT="${KF2_QUERY_PORT}"
        export KF2_WEBADMIN_PORT="${KF2_WEBADMIN_PORT}"
        export KF2_STEAM_PORT="${KF2_STEAM_PORT}"
        export KF2_NTP_PORT="${KF2_NTP_PORT}"
        
        # Ejecutar el script
        bash "${script}"
        echo "✅ ${script_name} completado"
    done
else
    echo "ℹ️  No se encontraron scripts de configuración"
fi

echo "🎯 Configuración post-instalación completada"

# Auto-eliminar este script después de la ejecución
rm -f "/data/run-server-config.sh"
EOF

    # Hacer el script ejecutable
    chmod +x "/data/run-server-config.sh"
    chown linuxgsm:linuxgsm "/data/run-server-config.sh"
    
    echo "✅ Script de configuración diferida creado: /data/run-server-config.sh"
    
    # Programar la ejecución del script en segundo plano
    cat > "/data/start-config.sh" << 'EOF'
#!/bin/bash
# Ejecutar configuración en segundo plano después del inicio del usuario
sleep 5 && /data/run-server-config.sh > /data/config-log.txt 2>&1 &
EOF
    
    chmod +x "/data/start-config.sh"
    chown linuxgsm:linuxgsm "/data/start-config.sh"
    
    echo "✅ Script de inicio diferido creado: /data/start-config.sh"
}

# Función principal
main() {
    echo "🔧 Configurando scripts post-instalación"
    echo "Usuario actual: $(whoami)"
    echo ""
    
    # Crear script de configuración diferida
    create_deferred_config_script
    
    echo ""
    echo "✅ Configuración post-instalación completada"
    echo "ℹ️  Los scripts se ejecutarán después del inicio del usuario"
}

# Ejecutar función principal
main "$@"
