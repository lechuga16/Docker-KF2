#!/bin/bash
# Script: entrypoint-kf2.sh
# Description: KF2 custom entrypoint wrapper
# Executes original LinuxGSM entrypoint-user.sh then runs server configuration scripts

echo "=== KF2 Custom Entrypoint ==="
echo "Usuario: $(whoami)"
echo "Directorio: $(pwd)"
echo "HOME: ${HOME}"

# Función para ejecutar scripts de configuración del servidor
run_server_scripts() {
    local server_scripts_dir="/app/server-scripts"
    
    echo ""
    echo "🔧 Ejecutando scripts de configuración del servidor"
    echo "=================================================="
    
    if [ ! -d "${server_scripts_dir}" ]; then
        echo "ℹ️  No hay directorio server-scripts, omitiendo configuración personalizada"
        return 0
    fi
    
    echo "🔍 Buscando scripts en ${server_scripts_dir}"
    
    if ls "${server_scripts_dir}"/*.sh 1> /dev/null 2>&1; then
        for script in "${server_scripts_dir}"/*.sh; do
            script_name=$(basename "${script}")
            echo ""
            echo "▶️  Ejecutando: ${script_name}"
            echo "----------------------------------------"
            
            # Hacer el script ejecutable
            chmod +x "${script}"
            
            # Pasar variables de entorno y ejecutar
            KF2_GAME_PORT="${KF2_GAME_PORT}" \
            KF2_QUERY_PORT="${KF2_QUERY_PORT}" \
            KF2_WEBADMIN_PORT="${KF2_WEBADMIN_PORT}" \
            KF2_STEAM_PORT="${KF2_STEAM_PORT}" \
            KF2_NTP_PORT="${KF2_NTP_PORT}" \
            bash "${script}"
            
            local exit_code=$?
            if [ ${exit_code} -eq 0 ]; then
                echo "✅ ${script_name} ejecutado exitosamente"
            else
                echo "⚠️  ${script_name} terminó con código de error: ${exit_code}"
            fi
        done
    else
        echo "ℹ️  No se encontraron scripts .sh en ${server_scripts_dir}"
    fi
    
    echo ""
    echo "🎯 Scripts de configuración completados"
}

# Función principal
main() {
    echo ""
    echo "🚀 Iniciando entrypoint LinuxGSM original"
    echo "========================================"
    
    # Ejecutar el entrypoint original de LinuxGSM en background
    /app/entrypoint-user.sh &
    local entrypoint_pid=$!
    
    # Esperar un poco para que LinuxGSM se inicialice
    sleep 10
    
    # Ejecutar scripts de configuración
    run_server_scripts
    
    echo ""
    echo "✅ Entrypoint KF2 completado"
    echo "=========================="
    echo "ℹ️  Esperando proceso LinuxGSM (PID: ${entrypoint_pid})"
    
    # Esperar al proceso original de LinuxGSM
    wait ${entrypoint_pid}
}

# Ejecutar función principal
main "$@"
