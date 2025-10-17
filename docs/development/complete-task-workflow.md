# 🔄 Workflow Completo: Desde Inicio de Tarea hasta PR Mergeado

**Última actualización**: 11 de Octubre, 2025 **Proyecto**: Adyela Health System

---

## 📋 Resumen

Este documento describe el workflow completo y automatizado para trabajar con
tareas en Adyela, desde la selección de una tarea hasta el merge del Pull
Request en staging.

**Tiempo estimado por tarea**:

- Simple: 30 min - 2 horas
- Media: 2 - 4 horas
- Compleja: 4 - 8 horas

---

## 🎯 Workflow Completo (10 Pasos)

### **Paso 1: Seleccionar Próxima Tarea** ⏱️ 30 segundos

**Comando**:

```bash
make task-next
# o
npx task-master-ai next
```

**Qué hace**:

- Muestra la tarea con mayor prioridad
- Verifica que todas las dependencias estén completadas
- Muestra detalles de implementación

**Ejemplo de output**:

```
📋 Next Task: #5

Title: Implement User Authentication with Identity Platform
Priority: HIGH
Status: pending
Dependencies: All met ✓

Description:
Implement comprehensive user authentication system using GCP Identity Platform
with MFA support, JWT token validation, and RBAC...
```

---

### **Paso 2: Iniciar Trabajo en la Tarea** ⏱️ 10 segundos

**Comando**:

```bash
make task-start ID=5
# o
./scripts/utils/task-start.sh 5
```

**Qué hace automáticamente**:

1. ✅ Crea feature branch: `feature/implement-user-authentication`
2. ✅ Actualiza estado de tarea a `in-progress` en Task Master
3. ✅ Crea directorio `.task-context/task-5/`
4. ✅ Genera `checklist.md` con todos los pasos
5. ✅ Guarda detalles de la tarea en `details.json`

**Output**:

```
✓ Feature branch created: feature/implement-user-authentication
✓ Task #5 status: in-progress
✓ Task context: .task-context/task-5/
✓ Checklist: .task-context/task-5/checklist.md

Next steps:
  1. Review checklist: cat .task-context/task-5/checklist.md
  2. Start development
  3. Run quality checks: make quality-local
```

**Estado en Git**:

```bash
$ git branch
  main
  staging
* feature/implement-user-authentication
```

---

### **Paso 3: Revisar Checklist de la Tarea** ⏱️ 1 minuto

**Comando**:

```bash
cat .task-context/task-5/checklist.md
```

**Contenido del checklist**:

```markdown
# Task 5 Checklist

## Pre-Development

- [ ] Read task details and dependencies
- [ ] Review related PRD sections
- [ ] Identify affected services (API/Web/Infra)

## Development

- [ ] Write tests first (TDD)
- [ ] Implement feature
- [ ] Run local quality checks
- [ ] Update documentation

## Pre-Commit

- [ ] All tests passing
- [ ] Code formatted (auto via pre-commit)
- [ ] No linter errors
- [ ] Security scan clean

## PR Creation

- [ ] Conventional commit messages
- [ ] PR description references task #5
- [ ] All CI checks passing
- [ ] Code coverage maintained
```

---

### **Paso 4: Implementar la Feature** ⏱️ Variable (30 min - 8 horas)

**Desarrollo iterativo**:

1. **Escribe tests primero** (TDD):

   ```bash
   # Backend
   cd apps/api
   pytest tests/unit/test_auth.py

   # Frontend
   cd apps/web
   pnpm test src/features/auth/__tests__/
   ```

2. **Implementa el código**:
   - Sigue arquitectura hexagonal (backend)
   - Usa feature-based structure (frontend)
   - Consulta documentación en `/docs`

3. **Commit frecuentemente**:

   ```bash
   git add .
   git commit -m "feat(auth): add Identity Platform integration"
   ```

   **Los hooks automáticamente**:
   - ✅ Formatean código (Prettier, Black)
   - ✅ Ejecutan linting (ESLint, Ruff)
   - ✅ Type checking (TypeScript, MyPy)
   - ✅ Scanean secrets (gitleaks)
   - ✅ Agregan referencia a Task #5

---

### **Paso 5: Validación Local (Pre-Commit)** ⏱️ 30 segundos

**Automático en cada commit**:

Los git hooks (`.husky/pre-commit`) ejecutan:

```bash
🔍 Running pre-commit validations...
  → Linting changed files...        ✓
  → Type checking...                ✓
  → Scanning for secrets...         ✓
  → Blocking build artifacts...     ✓
✓ Pre-commit checks passed
```

**Si falla**:

- El commit se bloquea
- Debes corregir los errores
- Reintentar el commit

---

### **Paso 6: Validación Completa (Pre-Push)** ⏱️ 2-3 minutos

**Comando**:

```bash
make quality-local
# o
./scripts/testing/quality-checks.sh
```

**Ejecuta 10 validaciones completas**:

```bash
[1/10] ✓ Code formatting (Prettier)
[2/10] ✓ Linting (ESLint)
[3/10] ✓ Type checking (TypeScript)
[4/10] ✓ Python quality (Black, Ruff, MyPy)
[5/10] ✓ Unit tests (≥65% coverage)
[6/10] ✓ Integration tests
[7/10] ✓ Build validation
[8/10] ✓ Security audit (Bandit, npm audit)
[9/10] ✓ License compliance
[10/10] ✓ Secret scanning (gitleaks)

✅ All quality checks passed!
```

**Si falla algún check**:

- Corrige el problema
- Ejecuta `make quality-local` nuevamente
- Repite hasta que todo pase

---

### **Paso 7: Completar la Tarea** ⏱️ 30 segundos

**Comando**:

```bash
make task-complete ID=5
# o
./scripts/utils/task-complete.sh 5
```

**Qué hace automáticamente**:

1. ✅ Ejecuta `quality-checks.sh` (validación final)
2. ✅ Marca tarea como `done` en Task Master
3. ✅ Agrega notas de completación con:
   - Nombre del branch
   - Número de commits
   - Último commit
   - Estado de quality checks
4. ✅ **Hace PUSH del branch al remoto** 🚀
5. ✅ Muestra instrucciones para crear PR

**Output**:

```bash
🎯 Completing Task #5...
Running final quality validation...
[1/10] ✓ Code formatting
...
[10/10] ✓ Secret scanning

✓ Task #5 marked as done
✓ Completion notes added

📤 Pushing changes to remote...
Enumerating objects: 45, done.
Counting objects: 100% (45/45), done.
To github.com:adyela/adyela.git
 * [new branch]      feature/implement-user-authentication -> feature/implement-user-authentication

✅ Task #5 completed successfully!

📋 Next steps:
  1. Create PR: gh pr create --base staging --title 'Task #5' --fill
  2. Or create PR manually on GitHub
  3. Request 2 reviews

💡 Tip: Run 'gh pr create --fill' to auto-create PR with task details
```

**Estado en GitHub**:

- ✅ Branch `feature/implement-user-authentication` existe remotamente
- ✅ Todos los commits están pusheados
- ✅ Listo para crear PR

---

### **Paso 8: Crear Pull Request** ⏱️ 1 minuto

#### **Opción A: Con GitHub CLI (Recomendado)**

**Comando**:

```bash
gh pr create --base staging --title "feat(auth): Implement user authentication" --fill
```

**Qué hace**:

- Crea PR automáticamente hacia `staging`
- Usa template de PR (`.github/PULL_REQUEST_TEMPLATE.md`)
- Auto-completa descripción con commits
- Asigna reviewers según CODEOWNERS

**Output**:

```
Creating pull request for feature/implement-user-authentication into staging in adyela/adyela

https://github.com/adyela/adyela/pull/42

✓ PR created successfully!
```

#### **Opción B: Manual en GitHub**

1. Ve a GitHub.com
2. Click "Compare & pull request"
3. Base: `staging` ← Compare: `feature/implement-user-authentication`
4. Completa el template (auto-filled)
5. Asigna reviewers (2 requeridos)
6. Click "Create pull request"

---

### **Paso 9: CI/CD Pipeline Automático** ⏱️ 10-15 minutos

**GitHub Actions ejecuta automáticamente**:

```yaml
CI/CD Checks:
├─ API CI (ci-api.yml)
│  ├─ Lint (Black, Ruff)        ✓
│  ├─ Type check (MyPy)         ✓
│  ├─ Tests (80% coverage)      ✓
│  ├─ Security (Bandit)         ✓
│  ├─ Docker build              ✓
│  ├─ Container scan (Trivy)    ✓
│  └─ HIPAA audit log           ✓
│
├─ Web CI (ci-web.yml)
│  ├─ Lint (ESLint)             ✓
│  ├─ Format (Prettier)         ✓
│  ├─ Type check (TypeScript)   ✓
│  ├─ Tests (70% coverage)      ✓
│  ├─ Build                     ✓
│  ├─ Lighthouse (PWA)          ✓
│  └─ Accessibility (axe)       ✓
│
└─ Infra CI (ci-infra.yml)
   ├─ Terraform validate        ✓
   ├─ Security scan (tfsec)     ✓
   └─ Terraform plan            ✓
```

**Resultado esperado**:

- ✅ Todos los checks en verde
- ✅ 0 vulnerabilidades detectadas
- ✅ Code coverage ≥ target
- ✅ Build exitoso

**Si algún check falla**:

1. Revisa los logs en GitHub Actions
2. Corrige el problema localmente
3. Commit y push
4. CI/CD se ejecuta nuevamente

---

### **Paso 10: Code Review y Merge** ⏱️ Variable (depende de reviewers)

#### **A. Code Review (2 aprobaciones requeridas)**

**Reviewers verifican**:

- ✅ Código sigue convenciones del proyecto
- ✅ Tests adecuados y pasando
- ✅ Documentación actualizada
- ✅ No hay hardcoded secrets
- ✅ PHI access logging (si aplica)
- ✅ Seguridad HIPAA considerada

**Template de PR incluye checklist**:

```markdown
## Testing

- [x] Unit tests added/updated
- [x] Integration tests passing
- [x] E2E tests passing
- [x] Manual testing completed

## Security

- [x] No hardcoded secrets
- [x] PHI access logged (if applicable)
- [x] HIPAA compliance verified
- [x] Security scans passed

## Quality

- [x] Code coverage ≥ 65%
- [x] Linting passed
- [x] Type checking passed
- [x] Documentation updated
```

#### **B. Merge a Staging**

**Cuando tienes 2 aprobaciones**:

1. **Verificar que todos los checks pasen**:

   ```
   ✓ API CI
   ✓ Web CI
   ✓ Infra CI
   ✓ 2 approvals
   ```

2. **Merge strategy: Squash merge** (recomendado):
   - Condensa todos los commits en uno
   - Mensaje limpio
   - Historia de Git más clara

3. **Click "Squash and merge"**

**Después del merge**:

- ✅ Branch feature se puede eliminar
- ✅ Task Master mantiene la tarea como `done`
- ✅ Staging deploy se activa automáticamente (si configurado)

---

## 🔄 Resumen del Flujo Completo

```
1. make task-next                     → Ver próxima tarea
2. make task-start ID=5               → Crear feature branch + actualizar estado
3. cat .task-context/task-5/...      → Revisar checklist
4. [DESARROLLO]                       → Implementar + commits
5. [GIT HOOKS AUTO]                   → Validación en cada commit
6. make quality-local                 → Validación completa pre-push
7. make task-complete ID=5            → Validación final + push + marcar done
8. gh pr create --fill                → Crear PR
9. [CI/CD AUTO]                       → GitHub Actions valida todo
10. [REVIEWERS]                       → 2 aprobaciones → Merge
```

---

## ⚡ Comandos Rápidos

### Workflow Completo en 5 Comandos

```bash
# 1. Iniciar
make task-next
make task-start ID=5

# 2. Desarrollar
# ... (tu código aquí) ...
git add . && git commit -m "feat(auth): implement authentication"

# 3. Validar
make quality-local

# 4. Completar y Push
make task-complete ID=5

# 5. Crear PR
gh pr create --base staging --title "feat(auth): Task #5" --fill
```

---

## 🛠️ Troubleshooting

### Problema: Pre-commit hooks fallan

**Síntoma**: Commit se bloquea por linting/format

**Solución**:

```bash
# Fix formatting
pnpm format

# Fix linting
pnpm lint --fix

# Re-intentar commit
git add . && git commit -m "..."
```

### Problema: Quality checks fallan

**Síntoma**: `make quality-local` falla en algún paso

**Solución**:

1. Lee el output para identificar qué falló
2. Corrige el problema específico
3. Ejecuta solo ese check:
   ```bash
   pnpm test              # Solo tests
   pnpm type-check        # Solo tipos
   pnpm lint              # Solo linting
   ```
4. Re-ejecuta `make quality-local`

### Problema: Task Master no encuentra el proyecto

**Síntoma**: `npx task-master-ai` falla

**Solución**:

```bash
# Verificar que estás en el root del proyecto
pwd  # debe mostrar: /path/to/adyela

# Verificar Task Master está instalado
npx task-master-ai --version

# Reinicializar si necesario
npx task-master-ai initialize
```

### Problema: Push falla

**Síntoma**: `git push` rechazado

**Solución**:

```bash
# Verificar estado del branch
git status

# Verificar remote
git remote -v

# Verificar autenticación
gh auth status

# Re-autenticar si necesario
gh auth login
```

---

## 📊 Métricas de Éxito

### Tiempos Esperados por Paso

| Paso               | Tiempo Esperado | Notas                  |
| ------------------ | --------------- | ---------------------- |
| 1. task-next       | 30 seg          | Instantáneo            |
| 2. task-start      | 10 seg          | Crea branch            |
| 3. Checklist       | 1 min           | Lectura                |
| 4. Desarrollo      | 30 min - 8h     | Depende de complejidad |
| 5. Pre-commit      | 30 seg          | Por commit             |
| 6. quality-local   | 2-3 min         | Validación completa    |
| 7. task-complete   | 30 seg          | Con push               |
| 8. PR creation     | 1 min           | Con gh CLI             |
| 9. CI/CD           | 10-15 min       | Automático             |
| 10. Review + Merge | Variable        | Depende de reviewers   |

**Total para tarea simple**: ~1-2 horas **Total para tarea compleja**: ~4-8
horas

### Calidad Garantizada

Al seguir este workflow, garantizas:

- ✅ 100% de cobertura de quality checks
- ✅ 0 secrets en código
- ✅ Compliance HIPAA en audit trail
- ✅ Code coverage ≥ 65%
- ✅ Todos los tests pasando
- ✅ Documentación actualizada

---

## 🎯 Próximos Pasos

### Para Desarrolladores Nuevos

1. **Lee esta guía completa**
2. **Setup environment**: `make dev-setup`
3. **Práctica con tarea simple**:
   ```bash
   make task-next
   make task-start ID=X
   ```
4. **Sigue el workflow paso a paso**

### Para Desarrolladores Experimentados

**Workflow rápido**:

```bash
make task-next && make task-start ID=$(task-master next --id-only)
# ... develop ...
make quality-local && make task-complete ID=$(git branch --show-current | grep -o '[0-9]*')
gh pr create --fill
```

---

## 📚 Referencias

- **[Task Start Script](../../scripts/utils/task-start.sh)** - Script de inicio
- **[Task Complete Script](../../scripts/utils/task-complete.sh)** - Script de
  completación
- **[Quality Checks](../../scripts/testing/quality-checks.sh)** - Validaciones
- **[Workflow Implementation](./workflow-implementation.md)** - Detalles
  técnicos
- **[Feature Workflow Guide](./feature-workflow.md)** - Guía detallada

---

**Última actualización**: 11 de Octubre, 2025 **Versión**: 1.0 **Mantenido
por**: Equipo de DevOps Adyela
