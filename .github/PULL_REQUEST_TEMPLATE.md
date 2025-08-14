## 📋 Descripción
Descripción breve y clara de los cambios realizados.

## 🔗 Issue Relacionado
Fixes #(issue)
Closes #(issue)
Relates to #(issue)

## ✅ Tipo de Cambio
- [ ] 🐛 Bug fix (cambio que no rompe funcionalidad existente y arregla un issue)
- [ ] ✨ Nueva característica (cambio que no rompe funcionalidad existente y agrega funcionalidad)
- [ ] 💥 Breaking change (fix o feature que causaría que funcionalidad existente no funcione como se espera)
- [ ] 📝 Cambios de documentación solamente
- [ ] 🔧 Refactoring (cambios de código que no agregan funcionalidad ni arreglan bugs)
- [ ] ⚡ Mejoras de performance
- [ ] 🧪 Agregar tests faltantes
- [ ] 🏗️ Cambios en build system o dependencias externas

## 🧪 Cómo ha sido probado
Describe las pruebas que ejecutaste para verificar tus cambios:

### Pruebas realizadas:
- [ ] Build local exitoso: `docker compose -f docker-compose.dev.yml build`
- [ ] Contenedor inicia correctamente: `docker compose -f docker-compose.dev.yml up -d`
- [ ] SSH funciona: `ssh linuxgsm@localhost -p 22`
- [ ] Servidor KF2 instala correctamente
- [ ] Health check pasa
- [ ] Puertos están expuestos correctamente
- [ ] Variables de entorno funcionan

### Comandos de prueba ejecutados:
```bash
# Incluir los comandos específicos que usaste para probar
```

## 📸 Screenshots (si aplica)
Agregar screenshots para ayudar a explicar los cambios, especialmente para cambios de UI o configuración.

## ✅ Checklist:
- [ ] He probado los cambios localmente con `docker compose -f docker-compose.dev.yml up -d`
- [ ] El código funciona correctamente (build, start, SSH, health check)
- [ ] He actualizado la documentación relevante (README.md, CHANGELOG.md)
- [ ] No he incluido secretos o información sensible

## 💭 Comentarios Adicionales
Agregar cualquier comentario adicional sobre el PR o áreas que requieren atención especial.
