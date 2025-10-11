# 🤖 Integración Task Master AI + Claude Code

## 📋 Descripción

Esta guía te muestra cómo usar Task Master AI con Claude Code para **desarrollo asistido por IA** con gestión automática de tareas.

---

## ✅ Estado Actual

Tu proyecto ya tiene Task Master AI configurado correctamente:

- ✅ Task Master AI instalado vía MCP
- ✅ API key de Anthropic configurada
- ✅ Tasks generados desde PRD
- ✅ Workflow de feature branches implementado

---

## 🎯 Cómo Usar Task Master AI con Claude Code

### 1️⃣ **Ver Tareas Disponibles**

**Pregúntale a Claude**:

```
¿Cuáles son las tareas pendientes en Task Master?
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_get_tasks({
    projectRoot: "/path/to/adyela",
    status: "pending",
  });
```

**Verás**:

- Lista de tareas pendientes
- IDs, títulos, descripciones
- Dependencias
- Prioridades

---

### 2️⃣ **Ver Próxima Tarea a Trabajar**

**Pregúntale a Claude**:

```
¿Cuál es la siguiente tarea que debo hacer?
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_next_task({
    projectRoot: "/path/to/adyela",
  });
```

**Verás**:

- La tarea con todas las dependencias cumplidas
- Mayor prioridad
- Detalles de implementación
- Subtareas si existen

---

### 3️⃣ **Ver Detalles de una Tarea Específica**

**Pregúntale a Claude**:

```
Muéstrame los detalles de la tarea 5
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_get_task({
    id: "5",
    projectRoot: "/path/to/adyela",
  });
```

**Verás**:

- Título y descripción completa
- Detalles de implementación
- Estrategia de testing
- Subtareas (si las tiene)
- Dependencias

---

### 4️⃣ **Expandir una Tarea en Subtareas**

**Pregúntale a Claude**:

```
Expande la tarea 5 en subtareas detalladas
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_expand_task({
    id: "5",
    projectRoot: "/path/to/adyela",
    research: true, // Usa Perplexity para mejor contexto
  });
```

**Claude generará**:

- 5-10 subtareas específicas
- Orden lógico de implementación
- Detalles técnicos por subtarea

---

### 5️⃣ **Iniciar Trabajo en una Tarea**

**Pregúntale a Claude**:

```
Inicia trabajo en la tarea 5
```

**Claude hará**:

1. Ejecutar `scripts/task-start.sh 5`
2. Crear branch `feature/implement-user-authentication`
3. Actualizar estado a `in-progress`
4. Crear checklist en `.task-context/task-5/`

**O hazlo manualmente**:

```bash
make task-start ID=5
```

---

### 6️⃣ **Implementar con Claude**

**Pregúntale a Claude**:

```
Implementa la subtarea 5.1: "Configurar Identity Platform"
```

**Claude hará**:

1. Leer detalles de la subtarea
2. Explorar archivos relevantes
3. Implementar el código
4. Ejecutar tests
5. Actualizar la subtarea con progreso

---

### 7️⃣ **Actualizar Progreso de Subtarea**

**Durante la implementación, Claude puede**:

```
Actualiza la subtarea 5.1 con: "Identity Platform configurado con MFA, JWT tokens funcionando correctamente"
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_update_subtask({
    id: "5.1",
    prompt:
      "Identity Platform configurado con MFA, JWT tokens funcionando correctamente",
    projectRoot: "/path/to/adyela",
  });
```

**Resultado**:

- Subtarea actualizada con timestamp
- Log de implementación preservado
- Historia completa del desarrollo

---

### 8️⃣ **Marcar Subtarea como Completada**

**Pregúntale a Claude**:

```
Marca la subtarea 5.1 como completada
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_set_task_status({
    id: "5.1",
    status: "done",
    projectRoot: "/path/to/adyela",
  });
```

---

### 9️⃣ **Completar Tarea y Crear PR**

**Pregúntale a Claude**:

```
Completa la tarea 5
```

**Claude hará**:

1. Verificar todas las subtareas completadas
2. Ejecutar `scripts/task-complete.sh 5`
3. Correr validaciones finales
4. Marcar tarea como `done`
5. Sugerir crear PR

**O hazlo manualmente**:

```bash
make task-complete ID=5
```

---

### 🔟 **Crear Pull Request**

**Pregúntale a Claude**:

```
Crea un PR para la tarea 5
```

**Claude hará**:

1. Usar GitHub MCP para crear PR
2. Título: "feat(auth): Implement user authentication"
3. Descripción: Detalles de la tarea
4. Asignar reviewers
5. Añadir labels

---

## 🚀 Workflows Avanzados

### A. Análisis de Complejidad

**Pregúntale a Claude**:

```
Analiza la complejidad de todas las tareas pendientes
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_analyze_project_complexity({
    projectRoot: "/path/to/adyela",
    research: true,
    threshold: 5,
  });
```

**Verás**:

- Tareas con score de complejidad (1-10)
- Recomendaciones de expansión
- Tareas que necesitan más planificación

---

### B. Expandir Todas las Tareas Pendientes

**Pregúntale a Claude**:

```
Expande todas las tareas pendientes en subtareas
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_expand_all({
    projectRoot: "/path/to/adyela",
    research: true,
  });
```

**Claude generará**:

- Subtareas para todas las tareas pendientes
- Basado en complejidad
- Con contexto de research

---

### C. Actualizar Tareas Futuras (Drift de Implementación)

**Pregúntale a Claude**:

```
Actualiza las tareas desde la 15 en adelante porque cambié a usar React Query en lugar de Redux
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_update({
    from: "15",
    prompt:
      "Cambio de Redux a React Query para data fetching. Actualizar todas las tareas relacionadas con estado global.",
    research: true,
    projectRoot: "/path/to/adyela",
  });
```

**Claude actualizará**:

- Tareas 15+ con nuevo contexto
- Detalles de implementación
- Estrategias de testing

---

### D. Research-Backed Development

**Pregúntale a Claude**:

```
Investiga las mejores prácticas para implementar la tarea 8
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_research({
    query:
      "Best practices for implementing HIPAA-compliant video calls with Jitsi Meet in React",
    taskIds: "8",
    research: true,
    saveTo: "8",
    projectRoot: "/path/to/adyela",
  });
```

**Claude hará**:

1. Buscar información actualizada con Perplexity
2. Analizar mejores prácticas
3. Guardar findings en la tarea 8
4. Actualizar detalles de implementación

---

### E. Gestión de Tags (Contextos Múltiples)

**Para features grandes o branches**:

```
Crea un tag "feature-video-calls" para trabajar en las videollamadas
```

**Claude ejecutará**:

```javascript
mcp_task -
  master -
  ai_add_tag({
    name: "feature-video-calls",
    description: "Implementación completa de videollamadas con Jitsi",
    copyFromCurrent: false,
    projectRoot: "/path/to/adyela",
  });
```

**Luego puedes**:

```
Cambia al tag "feature-video-calls"
```

```javascript
mcp_task -
  master -
  ai_use_tag({
    name: "feature-video-calls",
    projectRoot: "/path/to/adyela",
  });
```

---

## 💡 Comandos Útiles para Claude

### Ver Estado General

```
Dame un resumen del proyecto en Task Master
```

### Ver Tareas por Status

```
Muéstrame las tareas en review
```

### Ver Tareas con Subtareas

```
Lista las tareas con sus subtareas
```

### Validar Dependencias

```
Verifica que no haya problemas en las dependencias de las tareas
```

### Generar Archivos Markdown

```
Genera archivos markdown para todas las tareas
```

---

## 🔄 Flujo Completo de Desarrollo

### 1. Inicio de Sesión

```
Claude, ¿cuál es la siguiente tarea que debo hacer?
```

### 2. Planificación

```
Expande la tarea X en subtareas detalladas
```

### 3. Research (Opcional)

```
Investiga las mejores prácticas para la tarea X
```

### 4. Inicio de Trabajo

```
Inicia trabajo en la tarea X
```

### 5. Implementación Iterativa

```
Implementa la subtarea X.1
```

_(Claude codifica, testea, actualiza subtarea)_

### 6. Testing

```
Ejecuta los tests para verificar la implementación
```

### 7. Completar Tarea

```
Completa la tarea X
```

### 8. Pull Request

```
Crea un PR para la tarea X
```

### 9. Repetir

```
¿Cuál es la siguiente tarea?
```

---

## 🎯 Ejemplos Prácticos

### Ejemplo 1: Feature Nueva

**Tú**:

```
Claude, quiero implementar autenticación de usuarios. ¿Cómo empiezo?
```

**Claude**:

1. Busca la tarea relacionada: `get_tasks` con filtro
2. Muestra la tarea encontrada (ej: Tarea 5)
3. Propone: "Veo la tarea 5: 'Implementar Autenticación'. ¿Quieres que la expanda en subtareas?"

**Tú**:

```
Sí, expándela
```

**Claude**:

1. Ejecuta `expand_task` con research
2. Muestra las subtareas generadas
3. Propone: "¿Empezamos con la subtarea 5.1?"

**Tú**:

```
Sí, inicia trabajo en la tarea 5
```

**Claude**:

1. Ejecuta script de inicio
2. Crea branch
3. Actualiza estado
4. Dice: "Branch creado. Implementando subtarea 5.1..."
5. Lee archivos relevantes
6. Implementa código
7. Ejecuta tests
8. Actualiza subtarea con progreso

---

### Ejemplo 2: Bug Fix Durante Implementación

**Claude** (durante implementación):

```
He detectado que necesitamos actualizar las tareas futuras porque cambié el enfoque de autenticación
```

**Claude hace automáticamente**:

```javascript
mcp_task -
  master -
  ai_update({
    from: "6",
    prompt:
      "Cambio en autenticación: ahora usamos Identity Platform en lugar de custom JWT. Actualizar tareas relacionadas.",
    projectRoot: "/path/to/adyela",
  });
```

---

### Ejemplo 3: Research Before Implementation

**Tú**:

```
Antes de implementar la tarea 10 (videollamadas), investiga las mejores prácticas
```

**Claude**:

1. Ejecuta `research` con Perplexity
2. Encuentra información actualizada sobre Jitsi + React + HIPAA
3. Guarda findings en la tarea 10
4. Actualiza detalles de implementación
5. Propone: "Basado en la investigación, sugiero este enfoque..."

---

## 🔧 Configuración Avanzada

### 1. Añadir Perplexity API Key

Para research-backed development:

```json
{
  "mcpServers": {
    "task-master-ai": {
      "env": {
        "PERPLEXITY_API_KEY": "pplx-xxx-your-key-here"
      }
    }
  }
}
```

**Beneficios**:

- Research actualizado al 2024-2025
- Mejores prácticas actuales
- Información sobre librerías nuevas
- Soluciones a problemas conocidos

---

### 2. Configurar Modelos AI

```bash
# Ver modelos disponibles
npx task-master-ai models --list-available

# Configurar modelo principal
npx task-master-ai models --set-main claude-code/sonnet

# Configurar modelo de research
npx task-master-ai models --set-research perplexity/sonar-pro
```

---

### 3. Configurar Response Language

```bash
# Cambiar idioma a español
npx task-master-ai response-language --language "Español"
```

---

## 📚 Comandos Rápidos

### MCP (Claude Code)

| Acción        | Comando para Claude                        |
| ------------- | ------------------------------------------ |
| Ver tareas    | "Muestra las tareas pendientes"            |
| Próxima tarea | "¿Cuál es la siguiente tarea?"             |
| Ver tarea     | "Muestra detalles de la tarea X"           |
| Expandir      | "Expande la tarea X en subtareas"          |
| Iniciar       | "Inicia trabajo en la tarea X"             |
| Implementar   | "Implementa la subtarea X.Y"               |
| Actualizar    | "Actualiza la subtarea X.Y con [info]"     |
| Completar     | "Marca la subtarea X.Y como completada"    |
| Finalizar     | "Completa la tarea X"                      |
| Research      | "Investiga mejores prácticas para tarea X" |

### CLI (Terminal Manual)

| Acción        | Comando                                    |
| ------------- | ------------------------------------------ |
| Ver tareas    | `task-master list`                         |
| Próxima tarea | `task-master next`                         |
| Ver tarea     | `task-master show X`                       |
| Expandir      | `task-master expand --id=X`                |
| Iniciar       | `make task-start ID=X`                     |
| Completar     | `make task-complete ID=X`                  |
| Research      | `task-master research "query" --save-to=X` |

---

## 🎓 Mejores Prácticas

### ✅ DO

1. **Usa Claude para tareas repetitivas**:

   ```
   Implementa todas las subtareas de la tarea 5 una por una
   ```

2. **Deja que Claude actualice el progreso**:
   Claude automáticamente actualiza subtareas con:
   - Qué implementó
   - Qué funcionó
   - Qué no funcionó
   - Decisiones tomadas

3. **Usa research para tecnologías nuevas**:

   ```
   Investiga cómo implementar X antes de codificar
   ```

4. **Confía en el workflow de branches**:
   Task Master + Claude manejan automáticamente:
   - Creación de branches
   - Nombres descriptivos
   - Commits con formato correcto
   - Task IDs en mensajes

5. **Revisa el código de Claude**:
   Siempre verifica que:
   - Tests pasen
   - Linting esté limpio
   - Código siga estándares del proyecto

### ❌ DON'T

1. **No edites `tasks.json` manualmente**:
   Usa siempre los comandos de Task Master

2. **No cambies task status manualmente en múltiples lugares**:
   Usa `set-status` para mantener consistencia

3. **No ignores las dependencias**:
   Task Master previene trabajar en tareas con dependencias incompletas

4. **No hagas commits sin completar la tarea**:
   Usa el workflow completo: task-start → implement → task-complete

---

## 🐛 Troubleshooting

### Claude no ejecuta comandos de Task Master

**Problema**: Claude dice "no puedo acceder a Task Master"

**Solución**:

1. Verifica que MCP esté corriendo:

   ```bash
   ps aux | grep task-master
   ```

2. Reinicia Cursor/Claude Code

3. Verifica API key en `.cursor/mcp.json`

---

### "Task Master no encuentra el proyecto"

**Problema**: Error `projectRoot not found`

**Solución**:
Claude debe usar la ruta absoluta:

```javascript
projectRoot: "/Users/hevergonzalezgarcia/TFM Agentes IA/CLAUDE/adyela";
```

---

### Research no funciona

**Problema**: `PERPLEXITY_API_KEY` no configurado

**Solución**:

1. Obtén API key: https://www.perplexity.ai/settings/api
2. Añade a `.cursor/mcp.json`:
   ```json
   "PERPLEXITY_API_KEY": "pplx-xxx-your-key"
   ```
3. Reinicia Cursor

---

### Tareas no se actualizan

**Problema**: Cambios no se reflejan

**Solución**:

```bash
# Regenera archivos markdown
task-master generate

# O deja que Claude lo haga
"Regenera los archivos de tareas"
```

---

## 🚀 Tips Pro

### 1. Chain de Implementación Completa

Pídele a Claude:

```
Implementa completamente la tarea 5 desde cero: expande en subtareas, implementa cada una, testea, y crea el PR
```

Claude hará todo el flujo automáticamente.

---

### 2. Batch Processing

```
Implementa las tareas 5, 6 y 7 en secuencia
```

Claude trabajará en múltiples tareas seguidas.

---

### 3. Context-Aware Development

Claude puede leer:

- Tasks anteriores completadas
- Código existente
- Tests escritos
- PRD original

Todo automáticamente para implementar mejor.

---

### 4. Intelligent Task Updates

Claude detecta automáticamente cuándo:

- Una decisión de implementación afecta tareas futuras
- Hay un cambio de tecnología
- Se encuentra un mejor enfoque

Y actualiza las tareas relevantes.

---

## 📖 Recursos Adicionales

- **[Task Master AI Docs](https://github.com/cyanheads/task-master-ai)**
- **[Workflow Guide](./docs/guides/feature-workflow.md)**
- **[MCP Servers Guide](./docs/MCP_SERVERS_GUIDE.md)**
- **[Project Commands Reference](./docs/PROJECT_COMMANDS_REFERENCE.md)**

---

## 🎯 Próximos Pasos

1. **Practica con una tarea simple**:

   ```
   Claude, muéstrame la tarea más fácil para empezar
   ```

2. **Deja que Claude haga el heavy lifting**:

   ```
   Claude, implementa esta tarea completamente
   ```

3. **Aprende del progreso**:
   Revisa cómo Claude actualiza las subtareas para aprender patrones

4. **Escala gradualmente**:
   Empieza con tareas pequeñas, luego deja que Claude maneje features completas

---

**¡Listo para empezar! 🚀**

Pregúntale a Claude:

```
¿Cuál es la siguiente tarea que debo hacer en Task Master?
```
