## 🎮 Killing Floor 2 Docker Server v{TAG_NAME}

### ✨ Nuevas Características
- 

### 🐛 Correcciones
- 

### 🔧 Mejoras
- 

### 📦 Imagen Docker
```bash
docker pull ghcr.io/lechuga16/docker-kf2:{TAG_NAME}
```

### 🔄 Actualización desde versión anterior
```bash
# Detener el contenedor actual
docker compose down

# Actualizar la imagen en docker-compose.yml
sed -i 's|docker-kf2:.*|docker-kf2:{TAG_NAME}|' docker-compose.yml

# Descargar nueva imagen e iniciar
docker compose pull
docker compose up -d

# Verificar que esté funcionando
docker compose ps
docker compose logs -f kf2-server
```

### 🔍 Verificación de la instalación
```bash
# Verificar estado del contenedor
docker ps

# Conectar via SSH
ssh linuxgsm@localhost -p 22

# Verificar servidor KF2 (dentro del contenedor)
./kf2server details
```

### 📋 Changelog Completo
Ver [CHANGELOG.md](CHANGELOG.md) para detalles completos de todos los cambios.

### ⚠️ Breaking Changes (solo para versiones major)
- 

### 🛠️ Configuración Adicional Requerida
- 

### 📊 Compatibilidad
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **OS**: Linux (x86_64)
- **Memoria RAM**: Mínimo 2GB recomendado
- **Espacio disco**: Mínimo 10GB para instalación completa de KF2

---
**📖 Documentación:** [README.md](README.md) | **🐛 Reportar problemas:** [Issues](https://github.com/lechuga16/Docker-KF2/issues) | **💬 Contribuir:** [CONTRIBUTING.md](CONTRIBUTING.md)
