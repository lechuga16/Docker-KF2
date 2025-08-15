#!/bin/bash
# Script: entrypoint-user.sh
# Description: User-level entrypoint executed as linuxgsm user

echo "=== Inicio como usuario linuxgsm ==="
echo "Usuario: $(whoami)"
echo "Directorio: $(pwd)"
echo "HOME: ${HOME}"

# Función para ejecutar scripts de servidor programados
run_scheduled_server_scripts() {
    echo ""
    echo "🔧 Ejecutando scripts de servidor programados"
    echo "============================================"
    
    if ls /tmp/run_*.sh 1> /dev/null 2>&1; then
        for script in /tmp/run_*.sh; do
            script_name=$(basename "${script}")
            echo ""
            echo "▶️  Ejecutando: ${script_name}"
            bash "${script}"
            
            # Limpiar script temporal
            rm -f "${script}"
            echo "🧹 Script temporal removido: ${script_name}"
        done
    else
        echo "ℹ️  No hay scripts programados para ejecutar"
    fi
}

# Función para verificar/instalar el servidor
check_install_server() {
    echo ""
    echo "🎮 Verificando instalación del servidor"
    echo "======================================"
    
    # Verificar si el script del servidor existe
    if [ ! -f "./${GAMESERVER}" ]; then
        echo "❌ Script del servidor no encontrado: ./${GAMESERVER}"
        echo "ℹ️  Ejecuta './kf2server install' para instalar el servidor"
        return 1
    fi
    
    # Verificar si el servidor está instalado
    if ! ./"${GAMESERVER}" details | grep -q "Status.*Stopped\|Status.*Started"; then
        echo "🔄 Servidor no instalado, iniciando instalación..."
        ./"${GAMESERVER}" install
    else
        echo "✅ Servidor ya está instalado"
    fi
}

# Función principal
main() {
    # Cambiar al directorio de datos
    cd /data || {
        echo "❌ Error: No se pudo cambiar al directorio /data"
        exit 1
    }
    
    # Ejecutar scripts de servidor programados (después de la instalación)
    run_scheduled_server_scripts
    
    # Verificar/instalar el servidor si es necesario
    check_install_server
    
    echo ""
    echo "🎯 Entrypoint de usuario completado"
    echo "================================="
    echo "ℹ️  El contenedor está listo para usar"
    echo "ℹ️  Conecta via SSH para gestionar el servidor:"
    echo "   ssh linuxgsm@localhost -p ${SSH_PORT:-22}"
    echo ""
    
    # Mantener el contenedor vivo
    while true; do
        sleep 30
    done
}

# Ejecutar función principal
main "$@"
