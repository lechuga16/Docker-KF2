# Contribuir a Docker-KF2

¡Gracias por considerar contribuir! 🎮

## 🚀 Cómo Contribuir

### 🐛 Reportar Bugs
1. Verificar que no esté ya reportado en [Issues](https://github.com/lechuga16/Docker-KF2/issues)
2. Crear issue con template de bug report
3. Incluir logs y configuración

### ✨ Sugerir Features
1. Verificar que no esté ya sugerida
2. Crear issue con template de feature request
3. Explicar el caso de uso

### 📤 Pull Requests
```bash
# Fork y clonar
git clone https://github.com/tu-usuario/Docker-KF2.git
cd Docker-KF2

# Crear rama desde develop
git checkout develop
git checkout -b feature/mi-cambio

# Desarrollar y probar
cp example.env .env
docker compose -f docker-compose.dev.yml up -d --build

# Enviar PR hacia develop
```

## 📋 Estándares

### Commits
```
tipo: descripción breve

Tipos: feat, fix, docs, style, refactor, test, chore
```

### Testing Mínimo
- [ ] `docker compose -f docker-compose.dev.yml build` ✅
- [ ] `docker compose -f docker-compose.dev.yml up -d` ✅
- [ ] `ssh linuxgsm@localhost -p 22` ✅
- [ ] Actualizar CHANGELOG.md si aplica

## 🔄 Flujo de Ramas
- `main` → Producción estable
- `develop` → Desarrollo (target para PRs)
- `feature/*` → Nuevas características

## 📞 Soporte
- **Issues técnicos**: [GitHub Issues](https://github.com/lechuga16/Docker-KF2/issues)
- **Maintainer**: lechuga16

¡Gracias por contribuir! 🙏
