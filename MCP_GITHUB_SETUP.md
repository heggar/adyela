# Configuración de MCP para GitHub

## ¿Qué es MCP?

Model Context Protocol (MCP) permite que Claude Code se conecte a servidores externos para obtener información y ejecutar acciones en tiempo real.

## Configurar GitHub MCP

### 1. Instalar el servidor MCP de GitHub

```bash
# Usando npm
npm install -g @modelcontextprotocol/server-github

# O usando npx (sin instalación global)
# npx @modelcontextprotocol/server-github
```

### 2. Crear Personal Access Token de GitHub

1. Ve a https://github.com/settings/tokens/new
2. Genera un token con estos permisos:
   - `repo` (acceso completo a repositorios)
   - `workflow` (acceso a GitHub Actions)
   - `read:org` (leer organizaciones)
3. Copia el token generado

### 3. Configurar Claude Code para usar el MCP

Edita el archivo de configuración de Claude Code:

**En macOS:**

```bash
code ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

**Contenido a agregar:**

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_TU_TOKEN_AQUI"
      }
    }
  }
}
```

### 4. Reiniciar Claude Code

Cierra y vuelve a abrir Claude Code para que cargue la nueva configuración.

## Uso del MCP de GitHub

Una vez configurado, puedes pedirle a Claude que:

```
@github list workflow runs for repo heggar/adyela
@github get workflow run 123456789
@github list workflow files
@github validate workflow .github/workflows/ci-api.yml
```

## Capacidades del MCP de GitHub

### Workflows

- ✅ Listar workflows
- ✅ Ver detalles de workflow runs
- ✅ Re-ejecutar workflows fallidos
- ✅ Cancelar workflows en ejecución
- ✅ Ver logs de workflow jobs

### Repositorio

- ✅ Listar issues
- ✅ Crear/actualizar issues
- ✅ Listar pull requests
- ✅ Ver detalles de PRs
- ✅ Merge PRs
- ✅ Ver archivos del repo
- ✅ Crear/actualizar archivos

### Actions

- ✅ Listar secrets
- ✅ Ver environments
- ✅ Ver status checks

## Alternativa: CLI de GitHub (gh)

Si no quieres configurar MCP, puedes usar el CLI de GitHub que ya tienes instalado:

```bash
# Ver workflows
gh workflow list

# Ver runs de un workflow
gh run list --workflow=ci-api.yml

# Ver detalles de un run
gh run view RUN_ID

# Ver logs
gh run view RUN_ID --log

# Re-ejecutar un workflow
gh run rerun RUN_ID

# Trigger manual workflow
gh workflow run cd-staging.yml -f version=v1.0.0
```

## Validación Recomendada

### 1. Validación de sintaxis (local)

```bash
# Con yamllint
yamllint .github/workflows/*.yml

# Con GitHub Actions CLI
gh workflow view ci-api.yml
```

### 2. Validación en PR (automática)

- GitHub Actions valida la sintaxis automáticamente
- Los workflows con errores aparecerán en "Checks" del PR

### 3. Test de workflows

```bash
# Crear un commit que active el workflow
git commit --allow-empty -m "test: trigger CI workflow"
git push

# Ver el resultado
gh run watch
```

## Troubleshooting

### MCP no conecta

1. Verificar que el token tiene los permisos correctos
2. Revisar logs de Claude Code (Help → Show Logs)
3. Verificar que `npx` está en el PATH

### Workflows no se ejecutan

1. Verificar que los paths en `on.push.paths` coinciden con los archivos modificados
2. Revisar que la rama está en la lista de `on.push.branches`
3. Verificar que no hay errores de sintaxis YAML

### Token expirado

1. GitHub tokens expiran según la configuración
2. Generar un nuevo token y actualizar el archivo de config
3. Reiniciar Claude Code

## Recursos

- [MCP Documentation](https://modelcontextprotocol.io)
- [GitHub MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- [GitHub CLI](https://cli.github.com/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
