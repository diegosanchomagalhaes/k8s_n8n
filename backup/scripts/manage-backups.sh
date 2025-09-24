#!/bin/bash
set -e

# =================================================================
# GERENCIADOR DE BACKUPS
# =================================================================
# Uso: ./manage-backups.sh [comando] [opções]
#
# Comandos:
#   list [app]          - Listar backups disponíveis
#   create [app] [type] - Criar backup manual
#   restore [app] [timestamp] - Restaurar backup
#   clean [app] [days]  - Limpar backups antigos
#   schedule [app]      - Ativar backup automático
#   unschedule [app]    - Desativar backup automático
#   status              - Status dos backups automáticos
# =================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_ROOT="$PROJECT_ROOT/backup"

COMMAND="${1}"
APP="${2:-n8n}"

# =================================================================
# FUNÇÕES
# =================================================================

show_help() {
    echo "🗄️ Gerenciador de Backups - Kubernetes"
    echo ""
    echo "📋 Comandos disponíveis:"
    echo "   list [app]              - Listar backups disponíveis"
    echo "   create [app] [type]     - Criar backup manual (type: db|files|full)"
    echo "   restore [app] [timestamp] - Restaurar backup específico"
    echo "   clean [app] [days]      - Limpar backups mais antigos que X dias"
    echo "   schedule [app]          - Ativar backup automático diário"
    echo "   unschedule [app]        - Desativar backup automático"
    echo "   status                  - Status dos backups automáticos"
    echo ""
    echo "📝 Exemplos:"
    echo "   $0 list n8n"
    echo "   $0 create n8n full"
    echo "   $0 restore n8n 20240924_143022"
    echo "   $0 clean n8n 7"
    echo "   $0 schedule n8n"
}

list_backups() {
    local app="${1:-n8n}"
    echo "📋 Backups disponíveis para $app:"
    echo ""
    
    if [[ -d "$BACKUP_ROOT/backups/$app" ]]; then
        for backup_dir in "$BACKUP_ROOT/backups/$app"/*; do
            if [[ -d "$backup_dir" ]]; then
                local timestamp=$(basename "$backup_dir")
                local size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1)
                local date_readable=$(date -d "${timestamp:0:8} ${timestamp:9:2}:${timestamp:11:2}:${timestamp:13:2}" 2>/dev/null || echo "Data inválida")
                
                echo "  📁 $timestamp"
                echo "     📅 Data: $date_readable"
                echo "     💾 Tamanho: $size"
                
                # Mostrar arquivos do backup
                echo "     📋 Arquivos:"
                ls -la "$backup_dir"/*.gz 2>/dev/null | while read -r line; do
                    local filename=$(basename $(echo "$line" | awk '{print $NF}'))
                    local file_size=$(echo "$line" | awk '{print $5}')
                    echo "        - $filename ($file_size bytes)"
                done
                echo ""
            fi
        done
    else
        echo "   ❌ Nenhum backup encontrado para $app"
    fi
}

create_backup() {
    local app="${1:-n8n}"
    local type="${2:-full}"
    
    echo "🗄️ Criando backup manual de $app (tipo: $type)..."
    "$BACKUP_ROOT/scripts/backup-app.sh" "$app" "$type"
}

restore_backup() {
    local app="${1:-n8n}"
    local timestamp="${2}"
    
    if [[ -z "$timestamp" ]]; then
        echo "❌ Timestamp do backup é obrigatório"
        echo "💡 Use: $0 list $app para ver backups disponíveis"
        exit 1
    fi
    
    echo "🔄 Restaurando backup de $app ($timestamp)..."
    "$BACKUP_ROOT/scripts/restore-app.sh" "$app" "$timestamp"
}

clean_backups() {
    local app="${1:-n8n}"
    local days="${2:-7}"
    
    echo "🧹 Limpando backups de $app mais antigos que $days dias..."
    
    if [[ -d "$BACKUP_ROOT/backups/$app" ]]; then
        find "$BACKUP_ROOT/backups/$app" -type d -mtime +$days -exec rm -rf {} \; 2>/dev/null || true
        echo "✅ Limpeza concluída"
        
        # Mostrar backups restantes
        echo ""
        list_backups "$app"
    else
        echo "❌ Diretório de backups não encontrado para $app"
    fi
}

schedule_backup() {
    local app="${1:-n8n}"
    
    echo "⏰ Ativando backup automático para $app..."
    
    # Aplicar RBAC
    kubectl apply -f "$BACKUP_ROOT/cronjobs/backup-rbac.yaml"
    
    # Aplicar CronJob
    kubectl apply -f "$BACKUP_ROOT/cronjobs/${app}-backup-cronjob.yaml"
    
    echo "✅ Backup automático ativado!"
    echo "📅 Agendamento: Diário às 02:00"
    echo "🔍 Verifique com: kubectl get cronjob -n $app"
}

unschedule_backup() {
    local app="${1:-n8n}"
    
    echo "⏰ Desativando backup automático para $app..."
    kubectl delete cronjob ${app}-backup -n $app --ignore-not-found
    echo "✅ Backup automático desativado!"
}

show_status() {
    echo "📊 Status dos Backups Automáticos:"
    echo ""
    
    # Verificar CronJobs
    echo "⏰ CronJobs ativos:"
    kubectl get cronjob -A | grep backup || echo "   Nenhum CronJob de backup encontrado"
    
    echo ""
    echo "📋 Últimos Jobs de Backup:"
    kubectl get jobs -A | grep backup | head -5 || echo "   Nenhum job de backup encontrado"
    
    echo ""
    echo "💾 Resumo de Backups por Aplicação:"
    if [[ -d "$BACKUP_ROOT/backups" ]]; then
        for app_dir in "$BACKUP_ROOT/backups"/*; do
            if [[ -d "$app_dir" ]]; then
                local app_name=$(basename "$app_dir")
                local count=$(ls -1 "$app_dir" 2>/dev/null | wc -l)
                local total_size=$(du -sh "$app_dir" 2>/dev/null | cut -f1)
                echo "   📱 $app_name: $count backups ($total_size)"
            fi
        done
    else
        echo "   ❌ Nenhum backup encontrado"
    fi
}

# =================================================================
# MAIN
# =================================================================

case "$COMMAND" in
    "list")
        list_backups "$APP"
        ;;
    "create")
        TYPE="${3:-full}"
        create_backup "$APP" "$TYPE"
        ;;
    "restore")
        TIMESTAMP="${3}"
        restore_backup "$APP" "$TIMESTAMP"
        ;;
    "clean")
        DAYS="${3:-7}"
        clean_backups "$APP" "$DAYS"
        ;;
    "schedule")
        schedule_backup "$APP"
        ;;
    "unschedule")
        unschedule_backup "$APP"
        ;;
    "status")
        show_status
        ;;
    *)
        show_help
        exit 1
        ;;
esac