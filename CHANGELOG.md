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
- Script robusto para gestión de Steam Workshop (`KF2-workshop.sh`):
  - Elimina y agrega la sección de workshop de forma idempotente.
  - Inserta o elimina la línea DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload según la variable de entorno.
- Variable de entorno `KF2_TICKRATE` en `.env` para configurar el tickrate del servidor.
- Script `KF2-tickrate.sh` para aplicar automáticamente el tickrate en `LinuxServer-KFEngine.ini`.
- Gestión automatizada de WebAdmin:
  - Activación/desactivación vía variable de entorno `KF2_WEBADMIN`.
  - Soporte para multi-admin con la variable `KF2_MULTI_ADMIN` y manejo de credenciales desde `.env`.
  - Scripts para actualizar la configuración de WebAdmin y MultiAdmin de forma dinámica y segura.

### Cambiado
- Mapeo de puertos mejorado con sintaxis `${PUERTO:-default}:${PUERTO:-default}` para puertos configurables
- Mapeo de puertos fijos para `KF2_STEAM_PORT` y `KF2_NTP_PORT` (no configurables internamente)
- Documentación completa de configuración de red en README.md
- Todos los scripts usan rutas portables con `$HOME` y variables de entorno para máxima compatibilidad.
- Mejoras en la modularidad y automatización de la configuración del servidor (admin, multi-admin, workshop, tickrate).
- Reorganización y estandarización de scripts:
  - Algunos scripts cambiaron de nombre para mayor claridad y modularidad.
  - Se añadieron variantes con y sin guion bajo para compatibilidad y transición.
  - Estructura actual de carpetas:
    - `docker-scripts/`: scripts de configuración y post-instalación del entorno Docker.
      - Ejemplo: `KF2-post-install-config.sh`, `SSH-config.sh`.
    - `server-scripts/`: scripts de gestión y automatización del servidor KF2.
      - Ejemplo: `KF2-admin-manager.sh`, `KF2-tickrate.sh`, `KF2-workshop.sh`, `BASH-manager.sh`.

### Corregido
- Documentación de conflicto SSH_PORT: cuando se define SSH_PORT en environment junto con mapeo de puertos, genera conflicto de configuración
- Explicación clara de dos opciones válidas para configuración SSH
- Problema de PlayFab reportando puertos incorrectos con mapeo directo de puertos
- Documentación y comentarios mejorados en los scripts y `.env`.
- Corrección en `KF2-workshop.sh`:
  - Ahora elimina correctamente cualquier línea DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload y vacía de [IpDrv.TcpNetDriver] si KF2_WORKSHOP está vacío.
  - Garantiza que nunca se duplique la línea DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload.

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
