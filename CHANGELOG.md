# Changelog
Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]
### Agregado
- Sistema de configuración automática de puertos KF2 post-instalación
- Script `server-scripts/configure-kf2-ports.sh` para configuración de puertos personalizados
- Script `entrypoint-kf2.sh` como wrapper del entrypoint original
- Soporte para configuración de WebAdmin con variable `KF2_WEBADMIN`
- Configuración automática de `KF2_GAME_PORT` en `LinuxServer-KFEngine.ini`
- Configuración automática de `KF2_QUERY_PORT` en `kf2server.cfg`
- Configuración automática de `KF2_WEBADMIN_PORT` y `KF2_WEBADMIN` en `KFWeb.ini`
- Dos modos de red: Docker Bridge y Host Network con archivos separados
- Archivo `docker-compose.host.yml` para configuración de red host

### Cambiado
- Mapeo de puertos mejorado con sintaxis `${PUERTO:-default}:${PUERTO:-default}` para puertos configurables
- Mapeo de puertos fijos para `KF2_STEAM_PORT` y `KF2_NTP_PORT` (no configurables internamente)
- Documentación completa de configuración de red en README.md

### Corregido
- Documentación de conflicto SSH_PORT: cuando se define SSH_PORT en environment junto con mapeo de puertos, genera conflicto de configuración
- Explicación clara de dos opciones válidas para configuración SSH
- Problema de PlayFab reportando puertos incorrectos con mapeo directo de puertos

### Removido

### Deprecated

### Seguridad

## [1.0.0] - 2025-08-14
### Agregado
- Servidor dedicado Killing Floor 2 con LinuxGSM
- Soporte SSH para gestión remota del servidor
- Configuración completa via variables de entorno
- Docker Compose para fácil despliegue (producción y desarrollo)
- Health checks automáticos para monitoreo del contenedor
- Volúmenes persistentes para datos del servidor
- GitHub Actions para build y push automático de imágenes
- Scripts personalizados en docker-scripts/ para configuración SSH
- Documentación completa en español
- Configuración de todos los puertos necesarios para KF2:
  - Puerto de juego (7777/UDP)
  - Puerto de consulta Steam (27015/UDP)  
  - Puerto Web Admin (8080/TCP)
  - Puerto Steam (20560/UDP)
  - Puerto NTP para Weekly Outbreak (123/UDP)
  - Puerto SSH (22/TCP)
- Archivo .gitignore completo para proteger datos sensibles
- Archivo .gitattributes para normalización de líneas
- Licencia MIT
- Badges informativos en README

[Unreleased]: https://github.com/lechuga16/Docker-KF2/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/lechuga16/Docker-KF2/releases/tag/v1.0.0
