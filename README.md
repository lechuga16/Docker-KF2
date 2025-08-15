# Servidor Docker KF2

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/lechuga16/Docker-KF2/docker-build.yml?branch=main&label=Build)](https://github.com/lechuga16/Docker-KF2/actions)
[![GitHub Release](https://img.shields.io/github/v/release/lechuga16/Docker-KF2?label=Release)](https://github.com/lechuga16/Docker-KF2/releases)
[![KF2 Version](https://img.shields.io/badge/KF2-Latest-blue?label=Killing%20Floor%202)](https://store.steampowered.com/app/232090/Killing_Floor_2/)
[![LinuxGSM](https://img.shields.io/badge/LinuxGSM-Supported-green)](https://linuxgsm.com/)

Servidor dedicado de Killing Floor 2 usando LinuxGSM con soporte SSH ejecutándose en Docker.

## Características

- ✅ **Servidor Dedicado Killing Floor 2** usando LinuxGSM
- ✅ **Acceso SSH** para gestión del servidor
- ✅ **Puertos Configurables** via variables de entorno

## Inicio Rápido

1. **Clonar el repositorio:**
```bash
git clone https://github.com/lechuga16/Docker-KF2.git
cd Docker-KF2
```

2. **Copiar y configurar variables de entorno:**
```bash
cp example.env .env
# Editar .env con tu configuración
```

3. **Iniciar el servidor:**
```bash
docker compose up -d
```

4. **Conectar via SSH para configurar:**
```bash
ssh linuxgsm@localhost -p 22
```

## Configuración

### Variables de Entorno

Edita el archivo `.env` para personalizar:

| Variable               | Por Defecto | Descripción                                                        |
|------------------------|-------------|--------------------------------------------------------------------|
| `LGSM_PASSWORD`        | (blank)     | Contraseña para el usuario linuxgsm (SSH y sudo)                   |
| `SSH_PORT`             | 22          | Puerto SSH para acceso al contenedor                               |
| `SSH_KEY`              | (blank)     | Clave(s) pública(s) SSH para autenticación                         |
| `KF2_GAME_PORT`        | 7777        | Puerto principal del juego (UDP)                                   |
| `KF2_QUERY_PORT`       | 27015       | Puerto Steam Master Server (UDP)                                   |
| `KF2_WEBADMIN_PORT`    | 8080        | Puerto del panel Web Admin (TCP)                                   |
| `KF2_STEAM_PORT`       | 20560       | Puerto de red Steam (UDP)                                          |
| `KF2_NTP_PORT`         | 123         | Puerto NTP para Weekly Outbreak (UDP)                              |
| `KF2_WEBADMIN`         | false       | Habilita/deshabilita el panel Web Admin (true/false)               |
| `KF2_ADMIN_PASSWORD`   | (blank)     | Contraseña de administrador para WebAdmin                          |
| `KF2_MULTI_ADMIN`      | false       | Habilita soporte multi-admin en WebAdmin (true/false)              |
| `KF2_WORKSHOP`         | []          | IDs de Workshop a suscribir (ej: [123,456])                       |
| `KF2_TICKRATE`         | 30          | Tickrate del servidor (NetServerMaxTickRate)                       |


### Configuración del Servidor

Después de iniciar el contenedor, conecta via SSH y configura:

```bash
# Conectar al contenedor
ssh linuxgsm@localhost -p 22

# Instalar/Actualizar servidor KF2
./kf2server install

# Configurar ajustes del servidor
nano /data/config-lgsm/kf2server/kf2server.cfg

# Iniciar el servidor
./kf2server start
```

## 🔧 Configuración de Red

Este proyecto soporta dos modos de red. **Elige UNO de los dos:**

- **Opción A: Red Docker (Bridge) - Recomendado**
  - Usa la red interna de Docker con mapeo de puertos.
  - Configuración en: `docker-compose.yml`

- **Opción B: Red Host**
  - Usa directamente la red del host (más simple, menos aislamiento).
  - Configuración en: `docker-compose.host.yml`

- **Opción Desarrollo:**
  - Para desarrollo local y pruebas, usa: `docker-compose.dev.yml`

Consulta los archivos mencionados para ver todas las variables y ejemplos de uso actualizados.

### **⚠️ Importante:**

- **NO mezcles** ambos enfoques
- **Red Docker**: Variables de puerto en `.env`, NO en `environment`
- **Red Host**: Variables de puerto en `environment`, NO usar `ports:`

### **¿Cuál elegir?**

| Característica | Red Docker | Red Host |
|---------------|------------|----------|
| **Aislamiento** | ✅ Alto | ❌ Bajo |
| **Configuración** | ⚠️ Más compleja | ✅ Simple |
| **Múltiples instancias** | ✅ Fácil | ❌ Conflictos de puerto |
| **Debugging** | ⚠️ Más difícil | ✅ Directo |
| **Recomendado para** | Producción | Desarrollo/Testing |

## Archivos Docker Compose

### Red Docker Bridge (`docker-compose.yml`)
Configuración por defecto con red Docker y mapeo de puertos:
```bash
docker compose up -d
```

### Red Host (`docker-compose.host.yml`)
Configuración con red del host para máximo rendimiento:
```bash
docker compose -f docker-compose.host.yml up -d
```

### Desarrollo (`docker-compose.dev.yml`)
Construye imagen localmente para desarrollo:
```bash
docker compose -f docker-compose.dev.yml up -d --build
```

## Imágenes Disponibles

| Tag | Descripción | Rama |
|-----|-------------|------|
| `latest` | Última versión estable | `main` |
| `develop` | Build de desarrollo | `develop` |
| `main` | Build de rama main | `main` |

## Gestión del Servidor


### Acceso Web Admin

Accede al panel de administración web en: `http://tu-ip-servidor:8080`

Las credenciales por defecto se configuran en los archivos de configuración del servidor.

## Puertos

| Puerto | Protocolo | Descripción |
|--------|-----------|-------------|
| 7777 | UDP | Puerto del Juego - Los jugadores se conectan aquí |
| 27015 | UDP | Puerto de Consulta - Steam Master Server |
| 8080 | TCP | Web Admin - Interfaz de gestión |
| 20560 | UDP | Puerto Steam - Red de Steam |
| 123 | UDP | Puerto NTP - Solo Weekly Outbreak |
| 22 | TCP | Puerto SSH - Acceso al contenedor |

## Volúmenes

- `/data` - Directorio de datos persistentes que contiene:
  - Archivos del servidor
  - Archivos de configuración
  - Archivos de guardado
  - Logs
  - Claves SSH

## Solución de Problemas

### El contenedor no inicia
Revisar los logs:
```bash
docker compose logs -f
```

### No se puede conectar via SSH
Verificar configuración SSH:
```bash
# Verificar si el servicio SSH está ejecutándose
docker exec -it kf2-server service ssh status

# Verificar configuración SSH
docker exec -it kf2-server cat /etc/ssh/sshd_config
```

**Problema común:** SSH no responde en el puerto esperado
- Si definiste `SSH_PORT` en environment, SSH escuchará en ese puerto interno
- Si usas mapeo de puertos `"${SSH_PORT}:22/tcp"`, SSH debe escuchar en puerto 22 interno
- **Solución:** Remover `SSH_PORT` del environment o usar `network_mode: host`

### El servidor no aparece en el navegador
1. Verificar que los puertos estén correctamente reenviados
2. Verificar configuración del firewall
3. Asegurar que el puerto de consulta Steam sea accesible

## Desarrollo

### Construcción local
```bash
# Construir imagen de desarrollo
docker compose -f docker-compose.dev.yml build

# Ejecutar con construcción personalizada
docker compose -f docker-compose.dev.yml up -d
```

### Contribuir
1. Hacer fork del repositorio
2. Crear una rama de característica desde `develop`
3. Hacer tus cambios
4. Enviar un pull request

## Soporte

- [Documentación LinuxGSM](https://docs.linuxgsm.com/)
- [Wiki Killing Floor 2](https://wiki.killingfloor2.com/)
- [GitHub Issues](https://github.com/lechuga16/Docker-KF2/issues)

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## Reconocimientos

- [LinuxGSM](https://linuxgsm.com/) - Linux Game Server Managers
- [Tripwire Interactive](https://tripwireinteractive.com/) - Desarrolladores de Killing Floor 2
