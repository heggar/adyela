# Workflow Test Guide - Verificación Completa

## Objetivo

Esta guía te ayudará a probar el workflow completo de desarrollo de features con nombres descriptivos de branches basados en títulos de tareas.

## Pre-requisitos

Asegúrate de tener:

- ✅ Task Master AI configurado (`.taskmaster/` existe)
- ✅ Husky instalado (`pnpm prepare` ejecutado)
- ✅ Scripts ejecutables (`chmod +x scripts/*.sh`)
- ✅ Git configurado en el proyecto

## Prueba 1: Verificar Scripts

### 1.1 Verificar Permisos

```bash
ls -la scripts/task-*.sh scripts/dev-setup.sh
```

**Esperado**: Todos con `-rwxr-xr-x` (ejecutables)

### 1.2 Verificar Contenido del Script

```bash
head -20 scripts/task-start.sh
```

**Esperado**: Ver el script con la lógica de generación de nombres descriptivos (líneas 15-19)

## Prueba 2: Ver Tareas Disponibles

```bash
# Ver todas las tareas
make task-list

# Ver siguiente tarea disponible
make task-next
```

**Esperado**: Ver lista de tareas con sus títulos completos

## Prueba 3: Workflow Completo (Simulación)

### 3.1 Seleccionar una Tarea Simple

```bash
# Ejemplo: Selecciona una tarea con título descriptivo
# Supongamos Task #31: "Project Documentation Reorganization"
TASK_ID=31

# Ver detalles
npx task-master-ai show $TASK_ID
```

### 3.2 Iniciar la Tarea

```bash
# Asegúrate de estar en main/staging
git checkout main
git pull origin main

# Iniciar tarea
make task-start ID=31
```

**Esperado**:

```
✓ Feature branch created: feature/project-documentation-reorganization
✓ Task #31 status: in-progress
✓ Task context: .task-context/task-31/
✓ Checklist: .task-context/task-31/checklist.md
```

### 3.3 Verificar Branch Creado

```bash
# Ver branch actual
git branch --show-current
```

**Esperado**: `feature/project-documentation-reorganization`

**NO debe contener**: `task-31` en el nombre

### 3.4 Verificar Contexto de Tarea

```bash
# Ver directorio de contexto
ls -la .task-context/

# Ver checklist
cat .task-context/task-31/checklist.md

# Ver detalles JSON
cat .task-context/task-31/details.json | jq '.title'
```

### 3.5 Hacer un Cambio de Prueba

```bash
# Crear archivo de prueba
echo "# Test Workflow" > TEST_WORKFLOW.md
git add TEST_WORKFLOW.md
```

### 3.6 Commit con Hook

```bash
# Commit (el hook debe agregar "Task #31" automáticamente)
git commit -m "docs: add workflow test file"
```

**Durante el commit, deberías ver**:

```
🔍 Running pre-commit validations...
  → Type checking...
  → Linting changed files...
  → Scanning for secrets...
✓ Pre-commit checks passed
```

### 3.7 Verificar Commit Message

```bash
# Ver último commit
git log -1 --pretty=format:"%B"
```

**Esperado**:

```
docs: add workflow test file

Task #31
```

**Nota**: El hook debe haber añadido "Task #31" automáticamente, **sin** buscar el número en el nombre de la branch.

### 3.8 Probar Quality Checks (Opcional)

```bash
# Ejecutar validación completa
make quality-local
```

**Esperado**: Ver 10 pasos de validación (puede fallar por problemas existentes en el proyecto)

### 3.9 Completar Tarea (Simulación)

```bash
# Marcar como completa
make task-complete ID=31
```

**Esperado**:

- Ejecuta quality checks
- Actualiza Task Master a "done"
- Muestra siguiente pasos

### 3.10 Limpiar Prueba

```bash
# Volver a main
git checkout main

# Eliminar branch de prueba
git branch -D feature/project-documentation-reorganization

# Eliminar archivo de prueba
rm -f TEST_WORKFLOW.md

# Limpiar contexto
rm -rf .task-context/task-31/

# Revertir estado de tarea
npx task-master-ai set-status --id=31 --status=pending
```

## Prueba 4: Verificar Diferentes Títulos

### 4.1 Probar con Diferentes Formatos de Título

Crea tareas de prueba con diferentes títulos para verificar la conversión:

```bash
# Ejemplo 1: Título con espacios
# "Implement User Authentication"
# → Debe crear: feature/implement-user-authentication

# Ejemplo 2: Título con caracteres especiales
# "Fix Bug: API Timeout (Critical)"
# → Debe crear: feature/fix-bug-api-timeout-critical

# Ejemplo 3: Título muy largo
# "Implement Comprehensive User Authentication System"
# → Debe crear: feature/implement-comprehensive-user-authentication-system
```

### 4.2 Script de Prueba de Conversión

```bash
# Crear script de prueba
cat > test-branch-naming.sh << 'EOF'
#!/bin/bash

# Función de conversión (igual que task-start.sh)
convert_title() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Casos de prueba
echo "Casos de prueba de conversión de títulos:"
echo ""

echo "1. Implement User Authentication"
echo "   → feature/$(convert_title 'Implement User Authentication')"
echo ""

echo "2. Add Email Notification System"
echo "   → feature/$(convert_title 'Add Email Notification System')"
echo ""

echo "3. Fix Bug: API Timeout (Critical)"
echo "   → feature/$(convert_title 'Fix Bug: API Timeout (Critical)')"
echo ""

echo "4. Configure CI/CD Pipeline"
echo "   → feature/$(convert_title 'Configure CI/CD Pipeline')"
echo ""

echo "5. Optimize Database Queries - Performance"
echo "   → feature/$(convert_title 'Optimize Database Queries - Performance')"
EOF

chmod +x test-branch-naming.sh
./test-branch-naming.sh
rm test-branch-naming.sh
```

**Esperado**:

```
1. Implement User Authentication
   → feature/implement-user-authentication

2. Add Email Notification System
   → feature/add-email-notification-system

3. Fix Bug: API Timeout (Critical)
   → feature/fix-bug-api-timeout-critical

4. Configure CI/CD Pipeline
   → feature/configure-ci-cd-pipeline

5. Optimize Database Queries - Performance
   → feature/optimize-database-queries-performance
```

## Prueba 5: Verificar Hook de Commit-Msg

### 5.1 Crear Branch Manual (Sin Task Master)

```bash
# Crear branch manual sin task-start
git checkout -b test/manual-branch

# Crear directorio de contexto manualmente
mkdir -p .task-context/task-99
```

### 5.2 Hacer Commit

```bash
echo "test" > test.txt
git add test.txt
git commit -m "test: verify hook"
```

**Esperado**: El hook debe encontrar "Task #99" del directorio `.task-context/task-99/` y agregarlo al commit.

### 5.3 Verificar

```bash
git log -1 --pretty=format:"%B"
```

**Esperado**:

```
test: verify hook

Task #99
```

### 5.4 Limpiar

```bash
git checkout main
git branch -D test/manual-branch
rm -rf .task-context/task-99/
```

## Checklist de Verificación

### ✅ Scripts

- [ ] `task-start.sh` existe y es ejecutable
- [ ] `task-complete.sh` existe y es ejecutable
- [ ] `dev-setup.sh` existe y es ejecutable
- [ ] Script de quality checks mejorado

### ✅ Hooks

- [ ] `.husky/pre-commit` validación mejorada
- [ ] `.husky/commit-msg` detección de Task ID desde contexto
- [ ] Hooks se ejecutan automáticamente en commit

### ✅ Naming

- [ ] Branches usan nombre descriptivo (sin `task-<id>`)
- [ ] Nombres son kebab-case (minúsculas con guiones)
- [ ] Caracteres especiales son sanitizados
- [ ] Espacios múltiples colapsados en un guión

### ✅ Task Linking

- [ ] Commits incluyen "Task #X" automáticamente
- [ ] Task ID se obtiene de `.task-context/`
- [ ] Funciona incluso sin número en branch name
- [ ] Fallback a branch name funciona

### ✅ Context

- [ ] `.task-context/task-<id>/` creado por `task-start`
- [ ] `details.json` contiene información completa
- [ ] `checklist.md` generado correctamente
- [ ] Directorio git-ignored

### ✅ Workflow

- [ ] `make task-start ID=X` funciona
- [ ] `make task-complete ID=X` funciona
- [ ] `make quality-local` ejecuta todas las validaciones
- [ ] Task Master se actualiza correctamente

## Problemas Comunes

### Problema 1: Branch con `task-<id>` en el nombre

**Síntoma**: La branch se llama `feature/task-31-project-documentation`

**Causa**: Usando versión antigua del script

**Solución**:

```bash
# Verificar contenido del script
cat scripts/task-start.sh | grep "BRANCH_NAME="

# Debe mostrar:
# BRANCH_NAME="feature/${TASK_TITLE}"
# NO debe mostrar:
# BRANCH_NAME="feature/task-${TASK_ID}-${TASK_TITLE}"
```

### Problema 2: Hook no añade Task ID

**Síntoma**: Commits no incluyen "Task #X"

**Causa**: No existe `.task-context/task-<id>/`

**Solución**:

```bash
# Verificar contexto
ls -la .task-context/

# Si no existe, usar task-start
make task-start ID=X

# NO crear branch manualmente con git checkout -b
```

### Problema 3: Caracteres raros en branch name

**Síntoma**: Branch con caracteres especiales

**Causa**: Título de tarea con caracteres no ASCII

**Solución**: Editar título de tarea para usar solo caracteres ASCII

### Problema 4: Branch name muy largo

**Síntoma**: Branch con 100+ caracteres

**Causa**: Título de tarea demasiado largo

**Solución**: Editar título para ser más conciso (20-40 caracteres ideal)

## Resultado Esperado

Después de seguir esta guía, deberías:

1. ✅ Entender cómo funciona el nuevo naming
2. ✅ Poder crear branches con nombres descriptivos
3. ✅ Ver commits con Task ID automático
4. ✅ Tener contexto de tarea en `.task-context/`
5. ✅ Workflow completo funcionando

## Siguientes Pasos

Si todo funciona:

1. Comparte esta guía con el equipo
2. Actualiza títulos de tareas existentes si es necesario
3. Comienza a usar el workflow en features reales
4. Documenta cualquier caso especial que encuentres

## Soporte

Si encuentras problemas:

1. Revisa `docs/guides/branch-naming-guide.md`
2. Verifica `docs/guides/feature-workflow.md`
3. Consulta `WORKFLOW_SETUP_COMPLETE.md`
4. Revisa el plan original en `/feature-development-workflow.plan.md`
