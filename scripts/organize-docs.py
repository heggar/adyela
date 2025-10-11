#!/usr/bin/env python3
"""
Script para organizar documentos Markdown dispersos en la raíz del proyecto
y moverlos a la carpeta docs con una estructura organizada
"""

import os
import shutil
from pathlib import Path
from typing import Dict, List, Tuple

def get_doc_categories() -> Dict[str, List[str]]:
    """Definir categorías y archivos que pertenecen a cada una"""
    return {
        "deployment": [
            "DEPLOYMENT_STRATEGY.md",
            "DEPLOYMENT_PROGRESS.md", 
            "DEPLOYMENT_SUCCESS.md",
            "GCP_SETUP_QUICKSTART.md",
            "STAGING_DEPLOYMENT_GUIDE.md"
        ],
        "quality": [
            "QUALITY_EXECUTION_REPORT.md",
            "FINAL_QUALITY_REPORT.md",
            "CROSS_BROWSER_TESTING_REPORT.md",
            "QUALITY_AUTOMATION.md"
        ],
        "workflows": [
            "WORKFLOWS_VALIDATION.md",
            "MCP_GITHUB_SETUP.md"
        ],
        "planning": [
            "IMPROVEMENT_PLAN.md",
            "NEXT_STEPS.md",
            "FIXES_SUMMARY.md"
        ],
        "setup": [
            "LOCAL_SETUP.md"
        ],
        "security": [
            "SECURITY.md"
        ],
        "contributing": [
            "CONTRIBUTING.md"
        ],
        "ai": [
            "CLAUDE.md"
        ]
    }

def find_md_files_in_root() -> List[str]:
    """Encontrar todos los archivos .md en la raíz del proyecto"""
    root_path = Path(".")
    md_files = []
    
    for file in root_path.glob("*.md"):
        if file.name != "README.md":  # Mantener README.md en la raíz
            md_files.append(file.name)
    
    return sorted(md_files)

def create_docs_structure():
    """Crear estructura de directorios en docs/"""
    categories = get_doc_categories()
    
    for category in categories.keys():
        category_path = Path(f"docs/{category}")
        category_path.mkdir(parents=True, exist_ok=True)
        print(f"📁 Creado directorio: {category_path}")

def move_files_to_categories():
    """Mover archivos a sus categorías correspondientes"""
    categories = get_doc_categories()
    moved_files = []
    unmoved_files = []
    
    for category, files in categories.items():
        category_path = Path(f"docs/{category}")
        
        for file_name in files:
            source_path = Path(file_name)
            dest_path = category_path / file_name
            
            if source_path.exists():
                # Crear backup si el archivo destino ya existe
                if dest_path.exists():
                    backup_path = dest_path.with_suffix(f"{dest_path.suffix}.backup")
                    shutil.copy2(dest_path, backup_path)
                    print(f"💾 Backup creado: {backup_path}")
                
                # Mover archivo
                shutil.move(str(source_path), str(dest_path))
                moved_files.append((file_name, category))
                print(f"📄 Movido: {file_name} → docs/{category}/")
            else:
                print(f"⚠️  Archivo no encontrado: {file_name}")
    
    return moved_files, unmoved_files

def handle_unmoved_files():
    """Manejar archivos que no están en ninguna categoría específica"""
    all_md_files = find_md_files_in_root()
    categories = get_doc_categories()
    categorized_files = []
    
    for files in categories.values():
        categorized_files.extend(files)
    
    unmoved_files = [f for f in all_md_files if f not in categorized_files]
    
    if unmoved_files:
        print(f"\n📋 Archivos no categorizados encontrados:")
        for file in unmoved_files:
            print(f"   - {file}")
        
        # Crear directorio misc para archivos no categorizados
        misc_path = Path("docs/misc")
        misc_path.mkdir(exist_ok=True)
        
        for file in unmoved_files:
            source_path = Path(file)
            dest_path = misc_path / file
            shutil.move(str(source_path), str(dest_path))
            print(f"📄 Movido a misc: {file} → docs/misc/")
    
    return unmoved_files

def create_index_files():
    """Crear archivos README.md para cada categoría"""
    categories = get_doc_categories()
    
    for category, files in categories.items():
        category_path = Path(f"docs/{category}")
        readme_path = category_path / "README.md"
        
        if not readme_path.exists():
            readme_content = f"""# {category.title()} Documentation

Esta carpeta contiene documentación relacionada con {category}.

## Archivos

"""
            for file in files:
                if (category_path / file).exists():
                    readme_content += f"- [{file}](./{file})\n"
            
            readme_content += f"""
## Descripción

Documentación específica para {category} del proyecto Adyela.
"""
            
            with open(readme_path, 'w', encoding='utf-8') as f:
                f.write(readme_content)
            
            print(f"📝 Creado README: {readme_path}")

def update_main_docs_readme():
    """Actualizar el README.md principal de docs/"""
    docs_readme_path = Path("docs/README.md")
    
    if docs_readme_path.exists():
        # Leer contenido existente
        with open(docs_readme_path, 'r', encoding='utf-8') as f:
            existing_content = f.read()
        
        # Agregar sección de organización si no existe
        if "## Organización de Documentos" not in existing_content:
            organization_section = """

## Organización de Documentos

Los documentos han sido organizados en las siguientes categorías:

### 📁 Categorías

- **[deployment/](./deployment/)** - Documentación de despliegue y configuración
- **[quality/](./quality/)** - Reportes de calidad y testing
- **[workflows/](./workflows/)** - Validación de workflows y CI/CD
- **[planning/](./planning/)** - Planes de mejora y próximos pasos
- **[setup/](./setup/)** - Guías de configuración local
- **[security/](./security/)** - Documentación de seguridad
- **[contributing/](./contributing/)** - Guías de contribución
- **[ai/](./ai/)** - Documentación de integración con IA
- **[misc/](./misc/)** - Documentos varios no categorizados

### 📋 Estructura

```
docs/
├── deployment/     # Estrategias y progreso de despliegue
├── quality/        # Reportes de calidad y testing
├── workflows/      # Validación de workflows
├── planning/       # Planes y mejoras
├── setup/          # Configuración local
├── security/       # Seguridad
├── contributing/   # Contribución
├── ai/            # Integración IA
└── misc/          # Documentos varios
```

"""
            with open(docs_readme_path, 'a', encoding='utf-8') as f:
                f.write(organization_section)
            
            print(f"📝 Actualizado README principal: {docs_readme_path}")

def main():
    """Función principal"""
    print("📚 Organizando documentos Markdown...")
    
    # Verificar que estamos en el directorio correcto
    if not Path("docs").exists():
        print("❌ Error: No se encontró la carpeta 'docs'")
        return
    
    # 1. Crear estructura de directorios
    print("\n1️⃣ Creando estructura de directorios...")
    create_docs_structure()
    
    # 2. Mover archivos a categorías
    print("\n2️⃣ Moviendo archivos a categorías...")
    moved_files, unmoved_files = move_files_to_categories()
    
    # 3. Manejar archivos no categorizados
    print("\n3️⃣ Manejando archivos no categorizados...")
    unmoved_files = handle_unmoved_files()
    
    # 4. Crear archivos README para cada categoría
    print("\n4️⃣ Creando archivos README...")
    create_index_files()
    
    # 5. Actualizar README principal
    print("\n5️⃣ Actualizando README principal...")
    update_main_docs_readme()
    
    # Resumen
    print(f"\n✅ Organización completada:")
    print(f"   - Archivos movidos: {len(moved_files)}")
    print(f"   - Archivos no categorizados: {len(unmoved_files)}")
    print(f"   - Categorías creadas: {len(get_doc_categories())}")
    
    print(f"\n📋 Archivos movidos por categoría:")
    for file_name, category in moved_files:
        print(f"   - {file_name} → docs/{category}/")
    
    if unmoved_files:
        print(f"\n📁 Archivos movidos a misc:")
        for file_name in unmoved_files:
            print(f"   - {file_name} → docs/misc/")
    
    print(f"\n🎉 ¡Documentos organizados exitosamente!")

if __name__ == '__main__':
    main()
