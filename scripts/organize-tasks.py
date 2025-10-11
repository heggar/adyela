#!/usr/bin/env python3
"""
Script para organizar las tareas de Task Master AI
- Elimina tareas relacionadas con medicamentos/prescripciones
- Reorganiza las tareas por prioridad y dependencias
- Limpia tareas duplicadas o innecesarias
"""

import json
import re
from typing import Dict, List, Any

def load_tasks(file_path: str) -> Dict[str, Any]:
    """Cargar tareas desde el archivo JSON"""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_tasks(tasks: Dict[str, Any], file_path: str) -> None:
    """Guardar tareas al archivo JSON"""
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(tasks, f, indent=2, ensure_ascii=False)

def is_medication_related(task: Dict[str, Any]) -> bool:
    """Verificar si una tarea está relacionada con medicamentos/prescripciones"""
    medication_keywords = [
        'medicament', 'prescription', 'drug', 'pharmacy', 'medication', 
        'prescribe', 'dosage', 'pill', 'tablet', 'capsule', 'injection', 
        'syringe', 'medicina', 'medicamento', 'receta', 'farmacia', 
        'dosis', 'pastilla', 'inyección', 'jeringa'
    ]
    
    # Buscar en título y descripción
    text_to_search = f"{task.get('title', '')} {task.get('description', '')} {task.get('details', '')}"
    text_to_search = text_to_search.lower()
    
    return any(keyword in text_to_search for keyword in medication_keywords)

def clean_task_dependencies(task: Dict[str, Any], removed_task_ids: List[str]) -> None:
    """Limpiar dependencias de tareas eliminadas"""
    if 'dependencies' in task and task['dependencies']:
        # Filtrar dependencias eliminadas
        task['dependencies'] = [
            dep for dep in task['dependencies'] 
            if dep not in removed_task_ids
        ]
        
        # Si no quedan dependencias, eliminar la lista
        if not task['dependencies']:
            del task['dependencies']

def reorganize_tasks(tasks: Dict[str, Any]) -> Dict[str, Any]:
    """Reorganizar las tareas eliminando las relacionadas con medicamentos"""
    
    # Categorías de tareas por prioridad
    infrastructure_tasks = []
    security_tasks = []
    application_tasks = []
    monitoring_tasks = []
    removed_task_ids = []
    
    # Obtener tareas del tag master
    master_tasks = tasks.get('master', {}).get('tasks', [])
    
    # Procesar tareas principales
    for task in master_tasks:
        if is_medication_related(task):
            print(f"🗑️  Eliminando tarea relacionada con medicamentos: {task.get('title', 'Sin título')}")
            removed_task_ids.append(str(task.get('id', '')))
            continue
            
        # Categorizar tareas
        title = task.get('title', '').lower()
        if any(keyword in title for keyword in ['terraform', 'vpc', 'network', 'infrastructure', 'gcp', 'cloud']):
            infrastructure_tasks.append(task)
        elif any(keyword in title for keyword in ['security', 'armor', 'firewall', 'identity', 'auth', 'secret']):
            security_tasks.append(task)
        elif any(keyword in title for keyword in ['monitoring', 'logging', 'alert', 'metric', 'audit']):
            monitoring_tasks.append(task)
        else:
            application_tasks.append(task)
    
    # Limpiar dependencias en tareas restantes
    all_remaining_tasks = infrastructure_tasks + security_tasks + application_tasks + monitoring_tasks
    for task in all_remaining_tasks:
        clean_task_dependencies(task, removed_task_ids)
        
        # Limpiar dependencias en subtareas
        if 'subtasks' in task:
            for subtask in task['subtasks']:
                clean_task_dependencies(subtask, removed_task_ids)
    
    # Reorganizar por prioridad
    reorganized_tasks = []
    
    # 1. Infraestructura (prioridad alta)
    reorganized_tasks.extend(sorted(infrastructure_tasks, key=lambda x: x.get('id', 0)))
    
    # 2. Seguridad (prioridad alta)
    reorganized_tasks.extend(sorted(security_tasks, key=lambda x: x.get('id', 0)))
    
    # 3. Aplicación (prioridad media)
    reorganized_tasks.extend(sorted(application_tasks, key=lambda x: x.get('id', 0)))
    
    # 4. Monitoreo (prioridad baja)
    reorganized_tasks.extend(sorted(monitoring_tasks, key=lambda x: x.get('id', 0)))
    
    # Actualizar IDs secuencialmente
    for i, task in enumerate(reorganized_tasks, 1):
        old_id = task.get('id', i)
        task['id'] = i
        
        # Actualizar referencias en subtareas
        if 'subtasks' in task:
            for j, subtask in enumerate(task['subtasks'], 1):
                subtask['id'] = j
        
        print(f"📝 Tarea {old_id} → {i}: {task.get('title', 'Sin título')}")
    
    # Crear nuevo objeto de tareas manteniendo la estructura de tags
    new_tasks = {
        'master': {
            'tasks': reorganized_tasks
        }
    }
    
    print(f"\n✅ Reorganización completada:")
    print(f"   - Tareas eliminadas: {len(removed_task_ids)}")
    print(f"   - Tareas restantes: {len(reorganized_tasks)}")
    print(f"   - Infraestructura: {len(infrastructure_tasks)}")
    print(f"   - Seguridad: {len(security_tasks)}")
    print(f"   - Aplicación: {len(application_tasks)}")
    print(f"   - Monitoreo: {len(monitoring_tasks)}")
    
    return new_tasks

def main():
    """Función principal"""
    tasks_file = '.taskmaster/tasks/tasks.json'
    backup_file = '.taskmaster/tasks/tasks.json.backup'
    
    print("🔍 Organizando tareas de Task Master AI...")
    
    # Crear backup
    import shutil
    shutil.copy2(tasks_file, backup_file)
    print(f"💾 Backup creado: {backup_file}")
    
    # Cargar tareas
    tasks = load_tasks(tasks_file)
    master_tasks = tasks.get('master', {}).get('tasks', [])
    print(f"📊 Tareas cargadas: {len(master_tasks)}")
    
    # Reorganizar
    reorganized_tasks = reorganize_tasks(tasks)
    
    # Guardar
    save_tasks(reorganized_tasks, tasks_file)
    print(f"💾 Tareas guardadas en: {tasks_file}")
    
    print("\n🎉 ¡Organización completada!")

if __name__ == '__main__':
    main()
