#!/bin/bash
set -e

# =================================================================
# SCRIPT DE RESTORE PARA APLICAÇÕES KUBERNETES
# =================================================================
# Uso: ./restore-app.sh [app_name] [backup_timestamp] [restore_type]
#
# Tipos de restore:
#   - db: Restore apenas do banco de dados
#   - files: Restore apenas dos arquivos/volumes
#   - full: Restore completo (db + files)
#
# Exemplos:
#   ./restore-app.sh n8n 20240924_143022 full
#   ./restore-app.sh n8n 20240924_143022 db
# =================================================================

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Diretórios de backup no cluster
POSTGRESQL_BACKUP_DIR="/mnt/host-cluster/postgresql/backup"
PVC_BACKUP_DIR="/mnt/host-cluster/pvc/backup"

# Parâmetros
APP_NAME="${1}"
BACKUP_TIMESTAMP="${2}"
RESTORE_TYPE="${3:-full}"

if [[ -z "$APP_NAME" || -z "$BACKUP_TIMESTAMP" ]]; then
    echo "❌ Uso: $0 [app_name] [backup_timestamp] [restore_type]"
    echo ""
    echo "📋 Backups disponíveis:"
    echo "🐘 PostgreSQL:"
    find "$POSTGRESQL_BACKUP_DIR" -name "*${APP_NAME:-}*" -type f 2>/dev/null | head -5 || echo "   Nenhum backup de DB encontrado"
    echo "📁 PVC/Files:"
    find "$PVC_BACKUP_DIR" -name "*${APP_NAME:-}*" -type f 2>/dev/null | head -5 || echo "   Nenhum backup de arquivos encontrado"
    exit 1
fi

# Arquivos de backup específicos
DB_BACKUP_FILE="$POSTGRESQL_BACKUP_DIR/${APP_NAME}_db_${BACKUP_TIMESTAMP}.sql.gz"
PVC_BACKUP_FILE="$PVC_BACKUP_DIR/${APP_NAME}_files_${BACKUP_TIMESTAMP}.tar.gz"
CONFIG_BACKUP_FILE="$PVC_BACKUP_DIR/${APP_NAME}_configs_${BACKUP_TIMESTAMP}.tar.gz"

# Verificar se backups existem
check_backup_files() {
    local missing_files=()
    
    case "$RESTORE_TYPE" in
        "db")
            [[ ! -f "$DB_BACKUP_FILE" ]] && missing_files+=("$DB_BACKUP_FILE")
            ;;
        "files")
            [[ ! -f "$PVC_BACKUP_FILE" ]] && missing_files+=("$PVC_BACKUP_FILE")
            ;;
        "full")
            [[ ! -f "$DB_BACKUP_FILE" ]] && missing_files+=("$DB_BACKUP_FILE")
            [[ ! -f "$PVC_BACKUP_FILE" ]] && missing_files+=("$PVC_BACKUP_FILE")
            ;;
    esac
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "❌ Arquivos de backup não encontrados:"
        printf '   - %s\n' "${missing_files[@]}"
        echo ""
        echo "📋 Backups disponíveis para $APP_NAME:"
        find "$POSTGRESQL_BACKUP_DIR" "$PVC_BACKUP_DIR" -name "*${APP_NAME}*" -type f 2>/dev/null | sort || echo "   Nenhum backup encontrado"
        exit 1
    fi
}

check_backup_files

# Configurações por aplicação
case "$APP_NAME" in
    "n8n")
        NAMESPACE="n8n"
        DB_HOST="postgres.default.svc.cluster.local"
        DB_PORT="5432"
        DB_NAME="n8n"
        DB_USER="postgres"
        PVC_NAME="n8n-data-pvc"
        DEPLOYMENT_NAME="n8n"
        ;;
    *)
        echo "❌ Aplicação '$APP_NAME' não suportada"
        exit 1
        ;;
esac

echo "🔄 Iniciando restore da aplicação: $APP_NAME"
echo "📂 Backup: $BACKUP_TIMESTAMP"
echo "🔧 Tipo de restore: $RESTORE_TYPE"
echo ""

# Confirmar operação
read -p "⚠️  ATENÇÃO: Esta operação irá SUBSTITUIR os dados atuais. Continuar? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada"
    exit 1
fi

# =================================================================
# FUNÇÕES DE RESTORE
# =================================================================

restore_database() {
    echo "💾 [1/2] Restaurando banco de dados..."
    
    # Verificar se arquivo de backup existe
    if [[ ! -f "$DB_BACKUP_FILE" ]]; then
        echo "❌ Arquivo de backup do banco não encontrado: $DB_BACKUP_FILE"
        return 1
    fi
    
    # Obter senha do PostgreSQL
    DB_PASSWORD=$(kubectl get secret postgres-admin-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)
    
    # Parar aplicação temporariamente
    echo "⏸️ Parando aplicação temporariamente..."
    kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=0
    kubectl wait --for=delete pod -l app=$APP_NAME -n $NAMESPACE --timeout=60s
    
    # Descompactar e restaurar banco
    echo "🔄 Restaurando dados do banco..."
    zcat "$DB_BACKUP_FILE" | kubectl exec -i -n default postgres-0 -- sh -c "
        export PGPASSWORD='$DB_PASSWORD'
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
    "
    
    # Reiniciar aplicação
    echo "▶️ Reiniciando aplicação..."
    kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=1
    kubectl wait --for=condition=available deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=180s
    
    echo "✅ Banco de dados restaurado com sucesso!"
}

restore_files() {
    echo "📁 [2/2] Restaurando arquivos/volumes..."
    
    # Verificar se arquivo de backup existe
    if [[ ! -f "$PVC_BACKUP_FILE" ]]; then
        echo "❌ Arquivo de backup dos arquivos não encontrado: $PVC_BACKUP_FILE"
        return 1
    fi
    
    # Parar aplicação temporariamente
    echo "⏸️ Parando aplicação temporariamente..."
    kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=0
    kubectl wait --for=delete pod -l app=$APP_NAME -n $NAMESPACE --timeout=60s
    
    # Criar pod temporário para restore
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: restore-pod-${APP_NAME}
  namespace: $NAMESPACE
spec:
  containers:
  - name: restore
    image: busybox
    command: ['sleep', '3600']
    volumeMounts:
    - name: app-data
      mountPath: /data
  volumes:
  - name: app-data
    persistentVolumeClaim:
      claimName: $PVC_NAME
  restartPolicy: Never
EOF

    # Aguardar pod ficar pronto
    echo "⏳ Aguardando pod de restore ficar pronto..."
    kubectl wait --for=condition=ready pod/restore-pod-${APP_NAME} -n $NAMESPACE --timeout=60s
    
    # Limpar dados antigos e restaurar
    echo "🔄 Limpando dados antigos e restaurando arquivos..."
    kubectl exec -n $NAMESPACE restore-pod-${APP_NAME} -- sh -c "rm -rf /data/* /data/.*" 2>/dev/null || true
    cat "$PVC_BACKUP_FILE" | kubectl exec -i -n $NAMESPACE restore-pod-${APP_NAME} -- tar xzf - -C /data
    
    # Remover pod temporário
    kubectl delete pod restore-pod-${APP_NAME} -n $NAMESPACE
    
    # Reiniciar aplicação
    echo "▶️ Reiniciando aplicação..."
    kubectl scale deployment $DEPLOYMENT_NAME -n $NAMESPACE --replicas=1
    kubectl wait --for=condition=available deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=180s
    
    echo "✅ Arquivos restaurados com sucesso!"
}

# =================================================================
# EXECUÇÃO DO RESTORE
# =================================================================

case "$RESTORE_TYPE" in
    "db")
        restore_database
        ;;
    "files")
        restore_files
        ;;
    "full")
        restore_database
        restore_files
        ;;
    *)
        echo "❌ Tipo de restore '$RESTORE_TYPE' inválido"
        echo "📋 Tipos disponíveis: db, files, full"
        exit 1
        ;;
esac

echo ""
echo "🎉 Restore concluído com sucesso!"
echo "🌐 Verifique a aplicação: https://${APP_NAME}.local.127.0.0.1.nip.io"