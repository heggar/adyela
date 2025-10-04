# Guía de Contribución

¡Gracias por tu interés en contribuir a Adyela! Esta guía te ayudará a empezar.

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Cómo Contribuir](#cómo-contribuir)
- [Configuración del Entorno](#configuración-del-entorno)
- [Flujo de Trabajo](#flujo-de-trabajo)
- [Estándares de Código](#estándares-de-código)
- [Commits](#commits)
- [Pull Requests](#pull-requests)
- [Revisión de Código](#revisión-de-código)

## 📜 Código de Conducta

Este proyecto sigue un código de conducta. Al participar, se espera que mantengas este código. Por favor reporta comportamientos inaceptables al equipo del proyecto.

### Nuestros Estándares

- Usar lenguaje acogedor e inclusivo
- Respetar diferentes puntos de vista y experiencias
- Aceptar críticas constructivas de manera profesional
- Enfocarse en lo mejor para la comunidad
- Mostrar empatía hacia otros miembros

## 🚀 Cómo Contribuir

### Reportar Bugs

1. Verifica que el bug no haya sido reportado anteriormente
2. Crea un issue usando la plantilla de bug report
3. Incluye toda la información solicitada en la plantilla
4. Añade el label `bug`

### Sugerir Funcionalidades

1. Verifica que la funcionalidad no haya sido sugerida antes
2. Crea un issue usando la plantilla de feature request
3. Explica claramente el problema que resuelve
4. Añade el label `enhancement`

### Contribuir con Código

1. Busca issues con los labels `good first issue` o `help wanted`
2. Comenta en el issue que te gustaría trabajar en él
3. Espera a que un maintainer te lo asigne
4. Sigue el flujo de trabajo descrito abajo

## 🛠️ Configuración del Entorno

### Prerrequisitos

- Node.js >= 20.0.0
- pnpm >= 9.0.0
- Python 3.12
- Git
- Google Cloud SDK (para desarrollo con servicios GCP)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/adyela/adyela.git
cd adyela

# Instalar dependencias
pnpm install

# Configurar variables de entorno
cp .env.example .env
# Edita .env con tus credenciales locales

# Configurar Husky
pnpm prepare

# Verificar que todo funciona
pnpm build
pnpm test
```

## 🔄 Flujo de Trabajo

### 1. Crear una Rama

```bash
# Actualizar main
git checkout main
git pull origin main

# Crear rama desde main
git checkout -b tipo/descripcion-corta

# Ejemplos:
# feat/add-appointment-notifications
# fix/patient-search-crash
# docs/update-api-readme
```

### Convención de Nombres de Ramas

- `feat/` - Nueva funcionalidad
- `fix/` - Corrección de bugs
- `docs/` - Documentación
- `refactor/` - Refactorización
- `test/` - Tests
- `chore/` - Tareas de mantenimiento

### 2. Desarrollar

```bash
# Iniciar en modo desarrollo
pnpm dev

# Ejecutar tests mientras desarrollas
pnpm test --watch

# Verificar tipos
pnpm type-check

# Ejecutar linter
pnpm lint
```

### 3. Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Usar commitizen para commits guiados
pnpm commit

# O manualmente:
git commit -m "tipo(scope): descripción breve"
```

#### Tipos de Commit

- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Documentación
- `style`: Formato (sin cambios en código)
- `refactor`: Refactorización
- `perf`: Mejora de rendimiento
- `test`: Tests
- `build`: Build system o dependencias
- `ci`: CI/CD
- `chore`: Mantenimiento

#### Scopes

- `api` - Backend API
- `web` - Frontend web
- `ops` - Observabilidad
- `ui` - Componentes UI
- `core` - SDK core
- `config` - Configuraciones
- `infra` - Infraestructura
- `docs` - Documentación
- `deps` - Dependencias

#### Ejemplos

```bash
feat(api): add appointment reminder endpoint
fix(web): resolve patient search infinite loop
docs(api): update authentication flow diagram
refactor(ui): extract modal component logic
test(api): add unit tests for appointment service
```

### 4. Push y Pull Request

```bash
# Push de tu rama
git push origin tu-rama

# Crear PR desde GitHub
# Usa la plantilla de PR proporcionada
```

## 📏 Estándares de Código

### TypeScript/JavaScript

- Usar TypeScript estricto
- Preferir interfaces sobre types
- Documentar funciones públicas con JSDoc
- Máximo 200 líneas por archivo (guía, no regla estricta)
- Usar nombres descriptivos y en inglés

```typescript
// ✅ Bien
interface AppointmentProps {
  /** Unique identifier for the appointment */
  id: string;
  /** ISO 8601 formatted date string */
  scheduledAt: string;
}

function createAppointment(props: AppointmentProps): Appointment {
  // Implementation
}

// ❌ Mal
type Props = {
  i: string;
  d: string;
};

function ca(p: Props) {
  // Implementation
}
```

### Python

- Seguir PEP 8
- Type hints obligatorios
- Docstrings en formato Google
- Máximo 100 caracteres por línea

```python
# ✅ Bien
def create_appointment(
    patient_id: str,
    doctor_id: str,
    scheduled_at: datetime
) -> Appointment:
    """Create a new appointment.

    Args:
        patient_id: The patient's unique identifier
        doctor_id: The doctor's unique identifier
        scheduled_at: When the appointment is scheduled

    Returns:
        The created appointment instance

    Raises:
        ValueError: If the scheduled time is in the past
    """
    pass

# ❌ Mal
def ca(p, d, s):
    pass
```

### Arquitectura

#### Backend (Hexagonal Architecture)

```
apps/api/src/
├── domain/          # Entidades y lógica de negocio
├── application/     # Casos de uso
├── infrastructure/  # Adaptadores (DB, APIs externas)
└── presentation/    # Controllers y routers
```

#### Frontend (Feature-based)

```
apps/web/src/
├── features/        # Features por módulo
│   ├── appointments/
│   ├── patients/
│   └── doctors/
├── shared/          # Código compartido
└── lib/             # Utilidades
```

## ✅ Tests

### Cobertura Mínima

- Unitarios: 80%
- Integración: 60%
- E2E: Flujos críticos

### Escribir Tests

```bash
# Ejecutar tests
pnpm test

# Tests con cobertura
pnpm test:coverage

# E2E
pnpm test:e2e
```

### Ejemplos

```typescript
describe("AppointmentService", () => {
  it("should create appointment with valid data", async () => {
    // Arrange
    const data = createMockAppointmentData();

    // Act
    const result = await service.create(data);

    // Assert
    expect(result).toBeDefined();
    expect(result.id).toBeTruthy();
  });
});
```

## 🔍 Pull Requests

### Antes de Crear un PR

- [ ] Todos los tests pasan localmente
- [ ] El código está formateado (`pnpm format`)
- [ ] No hay errores de linting (`pnpm lint`)
- [ ] No hay errores de tipos (`pnpm type-check`)
- [ ] Has añadido tests para tu código
- [ ] Has actualizado la documentación si es necesario

### Descripción del PR

- Usa la plantilla proporcionada
- Explica QUÉ cambios hiciste y POR QUÉ
- Referencia issues relacionados
- Incluye screenshots para cambios UI
- Marca todos los checkboxes aplicables

### Tamaño del PR

- Preferir PRs pequeños y enfocados
- Máximo 400 líneas cambiadas (guía, no regla estricta)
- Si es más grande, considera dividirlo

## 👀 Revisión de Código

### Como Autor

- Responde a comentarios constructivamente
- Realiza los cambios solicitados
- Marca conversaciones como resueltas cuando aplique
- Sé paciente y receptivo al feedback

### Como Revisor

- Sé respetuoso y constructivo
- Explica el PORQUÉ de tus sugerencias
- Usa prefijos claros:
  - `[nit]`: Sugerencia menor, opcional
  - `[question]`: Pregunta para entender mejor
  - `[blocker]`: Debe resolverse antes de merge
- Aprueba cuando esté listo

### Criterios de Aprobación

- ✅ Al menos 1 aprobación de CODEOWNER
- ✅ Todos los checks de CI pasan
- ✅ Sin conflictos con main
- ✅ Conversaciones resueltas

## 🏗️ Arquitectura y Decisiones

### ADRs (Architecture Decision Records)

Para cambios arquitectónicos significativos:

1. Crea un ADR en `docs/adrs/`
2. Usa el template proporcionado
3. Discute en el issue/PR correspondiente
4. Los ADRs son inmutables una vez aprobados

### RFCs (Request for Comments)

Para propuestas grandes:

1. Crea un RFC en `docs/rfcs/`
2. Presenta el problema y soluciones propuestas
3. Solicita feedback del equipo
4. Itera basado en comentarios

## 🆘 ¿Necesitas Ayuda?

- 💬 Comenta en el issue relevante
- 📧 Contacta a un maintainer
- 📚 Revisa la documentación en `/docs`
- 🔍 Busca en issues cerrados

## 📄 Licencia

Al contribuir, aceptas que tus contribuciones se licenciarán bajo la misma licencia del proyecto.

---

¡Gracias por contribuir a Adyela! 🎉
