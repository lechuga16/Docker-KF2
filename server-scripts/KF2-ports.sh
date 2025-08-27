#!/bin/bash
# Script: KF2-ports.sh (antes configure-kf2-ports.sh)
# Description: Configures KF2 server ports in LinuxServer-KFEngine.ini
# Execution: Post-installation, runs as linuxgsm user

# (Contenido copiado de KF2_ports.sh)
echo "=== Configurando puertos personalizados KF2 ==="

# Rutas de archivos de configuración
KF2_CONFIG_FILE="$HOME/serverfiles/KFGame/Config/kf2server/LinuxServer-KFEngine.ini"
LGSM_CONFIG_FILE="$HOME/config-lgsm/kf2server/kf2server.cfg"
WEBADMIN_CONFIG_FILE="$HOME/serverfiles/KFGame/Config/kf2server/KFWeb.ini"

# Función para verificar archivos de configuración
check_config_files() {
    echo "Verificando archivos de configuración..."
    
    # Verificar archivo KF2
    if [ ! -f "${KF2_CONFIG_FILE}" ]; then
        echo "❌ Error: Archivo LinuxServer-KFEngine.ini no encontrado"
        echo "    Ruta esperada: ${KF2_CONFIG_FILE}"
        echo "    ℹ️  Esto puede indicar que el servidor KF2 no está instalado"
        return 1
    fi
    echo "✅ LinuxServer-KFEngine.ini encontrado"
    
    # Verificar archivo LinuxGSM (debe existir siempre)
    if [ ! -f "${LGSM_CONFIG_FILE}" ]; then
        echo "❌ Error: Archivo kf2server.cfg no encontrado"
        echo "    Ruta esperada: ${LGSM_CONFIG_FILE}"
        return 1
    fi
    echo "✅ kf2server.cfg encontrado"
    
    # Verificar archivo WebAdmin (puede no existir inicialmente)
    if [ ! -f "${WEBADMIN_CONFIG_FILE}" ]; then
        echo "⚠️  Archivo KFWeb.ini no encontrado, se creará si es necesario"
        echo "    Ruta esperada: ${WEBADMIN_CONFIG_FILE}"
    else
        echo "✅ KFWeb.ini encontrado"
    fi
    
    return 0
}

"# Función para configurar puerto del juego (usando LinuxGSM kf2server.cfg)"
configure_game_port() {
    local new_port="${1}"
    # Si está vacío, restablecer a valor por defecto 7777
    if [ -z "${new_port}" ]; then
        echo "⚠️  KF2_GAME_PORT no definido, usando puerto por defecto 7777"
        new_port="7777"
    fi

    echo "🔧 Configurando game port en LinuxGSM: ${new_port}"

    # Backup del archivo LGSM
    if [ ! -f "${LGSM_CONFIG_FILE}.backup" ]; then
        cp "${LGSM_CONFIG_FILE}" "${LGSM_CONFIG_FILE}.backup" 2>/dev/null || true
        echo "📦 Backup creado: ${LGSM_CONFIG_FILE}.backup"
    fi

    # Mostrar contenido antes (para debug rápido)
    echo "📄 kf2server.cfg (antes):"; head -n 20 "${LGSM_CONFIG_FILE}" 2>/dev/null || true

    # Escribir/actualizar 'port="<valor>"'
    if grep -q '^port=' "${LGSM_CONFIG_FILE}" 2>/dev/null; then
        sed -i "s/^port=.*/port=\"${new_port}\"/" "${LGSM_CONFIG_FILE}"
        echo "✅ Game port actualizado en kf2server.cfg"
    else
        echo "port=\"${new_port}\"" >> "${LGSM_CONFIG_FILE}"
        echo "✅ Game port agregado en kf2server.cfg"
    fi

    # Mostrar contenido después
    echo "📄 kf2server.cfg (después):"; head -n 20 "${LGSM_CONFIG_FILE}" 2>/dev/null || true

    # Verificación
    if grep -q "^port=\"${new_port}\"" "${LGSM_CONFIG_FILE}" 2>/dev/null; then
        echo "✅ Verificación exitosa: port=\"${new_port}\""
    else
        echo "❌ Error: No se pudo verificar el game port"
        return 1
    fi
}

# Función para configurar query port en LinuxGSM
configure_query_port() {
    local new_port="${1}"
    
    if [ -z "${new_port}" ]; then
        echo "⚠️  KF2_QUERY_PORT no definido, usando puerto por defecto 27015"
        new_port="27015"
    fi
    
    echo "🔧 Configurando query port: ${new_port}"
    
    # Mostrar contenido actual del archivo para debug
    echo "📄 kf2server.cfg antes de modificar:"
    if [ -s "${LGSM_CONFIG_FILE}" ]; then
        echo "    Archivo tiene contenido:"
        cat "${LGSM_CONFIG_FILE}" | head -10
    else
        echo "    ℹ️  Archivo vacío o sin contenido"
    fi
    
    # Hacer backup del archivo original
    if [ ! -f "${LGSM_CONFIG_FILE}.backup" ]; then
        cp "${LGSM_CONFIG_FILE}" "${LGSM_CONFIG_FILE}.backup"
        echo "📦 Backup creado: ${LGSM_CONFIG_FILE}.backup"
    fi
    
    # Verificar si ya existe la línea queryport
    if grep -q "^queryport=" "${LGSM_CONFIG_FILE}" 2>/dev/null; then
        # Modificar línea existente
        sed -i "s/^queryport=.*/queryport=\"${new_port}\"/" "${LGSM_CONFIG_FILE}"
        echo "✅ Query port actualizado en kf2server.cfg (línea existente)"
    else
        # Agregar nueva línea al final del archivo
        echo "queryport=\"${new_port}\"" >> "${LGSM_CONFIG_FILE}"
        echo "✅ Query port agregado en kf2server.cfg (nueva línea)"
    fi
    
    # Mostrar contenido después de modificar
    echo "📄 kf2server.cfg después de modificar:"
    if [ -s "${LGSM_CONFIG_FILE}" ]; then
        echo "    Contenido actual:"
        cat "${LGSM_CONFIG_FILE}" | head -10
    else
        echo "    ⚠️  Archivo sigue vacío - problema en escritura"
    fi
    
    # Verificar el cambio
    if grep -q "queryport=\"${new_port}\"" "${LGSM_CONFIG_FILE}" 2>/dev/null; then
        echo "✅ Verificación exitosa: Query port ${new_port} configurado"
    else
        echo "❌ Error: No se pudo verificar el cambio de query port"
        echo "📋 Contenido actual del archivo:"
        cat "${LGSM_CONFIG_FILE}" 2>/dev/null || echo "    Error al leer archivo"
        return 1
    fi
}

# Función para configurar WebAdmin en KFWeb.ini
configure_webadmin() {
    local webadmin_enabled="${1}"
    local webadmin_port="${2}"
    
    echo "🌐 Configurando WebAdmin..."
    echo "  KF2_WEBADMIN: ${webadmin_enabled:-'false'}"
    echo "  KF2_WEBADMIN_PORT: ${webadmin_port:-'8080'}"
    
    # Valores por defecto
    [ -z "${webadmin_enabled}" ] && webadmin_enabled="false"
    [ -z "${webadmin_port}" ] && webadmin_port="8080"
    
    # Crear directorio si no existe
    local webadmin_dir="$(dirname "${WEBADMIN_CONFIG_FILE}")"
    if [ ! -d "${webadmin_dir}" ]; then
        echo "📁 Creando directorio: ${webadmin_dir}"
        mkdir -p "${webadmin_dir}"
    fi
    
    # Crear archivo si no existe
    if [ ! -f "${WEBADMIN_CONFIG_FILE}" ]; then
        echo "📄 Creando archivo KFWeb.ini"
        cat > "${WEBADMIN_CONFIG_FILE}" << EOF
[IpDrv.WebServer]
bEnabled=${webadmin_enabled}
ListenPort=${webadmin_port}
EOF
        echo "✅ Archivo KFWeb.ini creado con configuración inicial"
    else
        # Hacer backup del archivo original
        if [ ! -f "${WEBADMIN_CONFIG_FILE}.backup" ]; then
            cp "${WEBADMIN_CONFIG_FILE}" "${WEBADMIN_CONFIG_FILE}.backup"
            echo "📦 Backup creado: ${WEBADMIN_CONFIG_FILE}.backup"
        fi
        
        # Configurar bEnabled
        if grep -q "^bEnabled=" "${WEBADMIN_CONFIG_FILE}"; then
            sed -i "s/^bEnabled=.*/bEnabled=${webadmin_enabled}/" "${WEBADMIN_CONFIG_FILE}"
            echo "✅ WebAdmin habilitado actualizado: ${webadmin_enabled}"
        else
            # Agregar bEnabled en la sección [IpDrv.WebServer]
            if grep -q "^\[IpDrv.WebServer\]" "${WEBADMIN_CONFIG_FILE}"; then
                sed -i "/^\[IpDrv.WebServer\]/a bEnabled=${webadmin_enabled}" "${WEBADMIN_CONFIG_FILE}"
            else
                echo -e "\n[IpDrv.WebServer]\nbEnabled=${webadmin_enabled}" >> "${WEBADMIN_CONFIG_FILE}"
            fi
            echo "✅ WebAdmin habilitado agregado: ${webadmin_enabled}"
        fi
        
        # Configurar ListenPort
        if grep -q "^ListenPort=" "${WEBADMIN_CONFIG_FILE}"; then
            sed -i "s/^ListenPort=.*/ListenPort=${webadmin_port}/" "${WEBADMIN_CONFIG_FILE}"
            echo "✅ Puerto WebAdmin actualizado: ${webadmin_port}"
        else
            # Agregar ListenPort en la sección [IpDrv.WebServer]
            if grep -q "^\[IpDrv.WebServer\]" "${WEBADMIN_CONFIG_FILE}"; then
                sed -i "/^\[IpDrv.WebServer\]/a ListenPort=${webadmin_port}" "${WEBADMIN_CONFIG_FILE}"
            else
                echo -e "\n[IpDrv.WebServer]\nListenPort=${webadmin_port}" >> "${WEBADMIN_CONFIG_FILE}"
            fi
            echo "✅ Puerto WebAdmin agregado: ${webadmin_port}"
        fi
    fi
    
    # Verificar configuración final
    echo "🔍 Verificando configuración WebAdmin:"
    if grep -q "bEnabled=${webadmin_enabled}" "${WEBADMIN_CONFIG_FILE}" && grep -q "ListenPort=${webadmin_port}" "${WEBADMIN_CONFIG_FILE}"; then
        echo "✅ Configuración WebAdmin verificada correctamente"
    else
        echo "❌ Error: No se pudo verificar la configuración WebAdmin"
        return 1
    fi
}

# Función para mostrar configuración actual
show_current_config() {
    echo ""
    echo "📋 Configuración actual de puertos:"
    echo "=================================="
    
    echo "🎮 LinuxServer-KFEngine.ini:"
    if [ -f "${KF2_CONFIG_FILE}" ]; then
        grep -n "Port=" "${KF2_CONFIG_FILE}" | head -3
    else
        echo "    ❌ Archivo no encontrado"
    fi
    
    echo ""
    echo "⚙️  kf2server.cfg:"
    if [ -f "${LGSM_CONFIG_FILE}" ]; then
        grep -n "^port=\|^queryport=" "${LGSM_CONFIG_FILE}" || echo "    ℹ️  port/queryport no configurados"
    else
        echo "    ❌ Archivo no encontrado"
    fi
    
    echo ""
    echo "🌐 KFWeb.ini:"
    if [ -f "${WEBADMIN_CONFIG_FILE}" ]; then
        grep -n "bEnabled=\|ListenPort=" "${WEBADMIN_CONFIG_FILE}" || echo "    ℹ️  WebAdmin no configurado"
    else
        echo "    ℹ️  Archivo no existe (se creará si es necesario)"
    fi
    echo ""
}

# Función principal
main() {
    echo "Usuario actual: $(whoami)"
    echo "Variables de entorno:"
    echo "  KF2_GAME_PORT: ${KF2_GAME_PORT:-'no definido'}"
    echo "  KF2_QUERY_PORT: ${KF2_QUERY_PORT:-'no definido'}"
    echo "  KF2_WEBADMIN: ${KF2_WEBADMIN:-'false'}"
    echo "  KF2_WEBADMIN_PORT: ${KF2_WEBADMIN_PORT:-'8080'}"
    echo ""
    
    # Verificar que existen los archivos de configuración
    if ! check_config_files; then
        echo "❌ No se pudieron encontrar los archivos de configuración básicos"
        echo "ℹ️  Asegúrate de que el servidor KF2 esté instalado correctamente"
        exit 1
    fi
    
    # Mostrar configuración antes del cambio
    show_current_config
    
    # Configurar puerto del juego
    configure_game_port "${KF2_GAME_PORT}"
    
    # Configurar query port
    configure_query_port "${KF2_QUERY_PORT}"
    
    # Configurar WebAdmin
    configure_webadmin "${KF2_WEBADMIN}" "${KF2_WEBADMIN_PORT}"
    
    # Mostrar configuración después del cambio
    show_current_config
    
    echo "🎮 Configuración de puertos completada"
}

# Ejecutar función principal
main "$@"
