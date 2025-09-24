#!/bin/bash
set -e

# =================================================================
# SCRIPT DE BACKUP PARA APLICAÇÕES KUBERNETES
# =================================================================
# Uso: ./backup-app.sh [app_name] [backup_type]
# 
# Tipos de backup:
#   - db: Backup apenas do banco de dados
#   - files: Backup apenas dos arquivos/volumes
#   - full: Backup completo (db + files + configs)
#
# Exemplos:
#   ./backup-app.sh n8n full
#   ./backup-app.sh n8n db
# =================================================================

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_ROOT="$PROJECT_ROOT/backup"

# Diretórios de backup organizados
DB_BACKUP_DIR="/mnt/e/cluster/postgresql/backup"
PVC_BACKUP_DIR="/mnt/e/cluster/pvc/backup"

# Configurações
APP_NAME="${1:-n8n}"
BACKUP_TYPE="${2:-full}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Criar estrutura de backup organizada
BACKUP_DIR="$BACKUP_ROOT/backups/$APP_NAME/$TIMESTAMP"
DB_BACKUP_PATH="$DB_BACKUP_DIR/$APP_NAME/$TIMESTAMP"
PVC_BACKUP_PATH="$PVC_BACKUP_DIR/$APP_NAME/$TIMESTAMP"

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
        echo "📋 Aplicações disponíveis: n8n"
        exit 1
        ;;
esac

echo "🗄️ Iniciando backup da aplicação: $APP_NAME"
echo "📂 Tipo de backup: $BACKUP_TYPE"
echo "📅 Timestamp: $TIMESTAMP"
echo ""

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"

# =================================================================
# FUNÇÕES DE BACKUP
# =================================================================

backup_database() {
    echo "💾 [1/3] Fazendo backup do banco de dados..."
    
    # Criar diretório de backup do banco
    mkdir -p "$DB_BACKUP_PATH"
    mkdir -p "$BACKUP_DIR"
    
    # Obter senha do PostgreSQL
    DB_PASSWORD=$(kubectl get secret postgres-admin-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)
    
    # Executar backup usando pg_dump dentro do cluster
    kubectl exec -n default postgres-0 -- sh -c "
        export PGPASSWORD='$DB_PASSWORD'
        pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --verbose --clean --no-owner --no-privileges
    " > "$DB_BACKUP_PATH/${APP_NAME}_database_${TIMESTAMP}.sql"
    
    # Comprimir backup do banco
    gzip "$DB_BACKUP_PATH/${APP_NAME}_database_${TIMESTAMP}.sql"
    
    # Link simbólico para manter compatibilidade com scripts existentes
    ln -sf "$DB_BACKUP_PATH/${APP_NAME}_database_${TIMESTAMP}.sql.gz" "$BACKUP_DIR/${APP_NAME}_database_${TIMESTAMP}.sql.gz"
    
    echo "✅ Backup do banco salvo em: $DB_BACKUP_PATH/${APP_NAME}_database_${TIMESTAMP}.sql.gz"
}

backup_files() {
    echo "📁 [2/3] Fazendo backup dos arquivos/volumes..."
    
    # Criar diretório de backup do PVC
    mkdir -p "$PVC_BACKUP_PATH"
    
    # Criar um pod temporário para acessar o PVC
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: backup-pod-${APP_NAME}
  namespace: $NAMESPACE
spec:
  containers:
  - name: backup
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
    echo "⏳ Aguardando pod de backup ficar pronto..."
    kubectl wait --for=condition=ready pod/backup-pod-${APP_NAME} -n $NAMESPACE --timeout=60s
    
    # Fazer backup dos arquivos
    kubectl exec -n $NAMESPACE backup-pod-${APP_NAME} -- tar czf - -C /data . > "$PVC_BACKUP_PATH/${APP_NAME}_files_${TIMESTAMP}.tar.gz"
    
    # Link simbólico para manter compatibilidade
    ln -sf "$PVC_BACKUP_PATH/${APP_NAME}_files_${TIMESTAMP}.tar.gz" "$BACKUP_DIR/${APP_NAME}_files_${TIMESTAMP}.tar.gz"
    
    # Remover pod temporário
    kubectl delete pod backup-pod-${APP_NAME} -n $NAMESPACE
    
    echo "✅ Backup dos arquivos salvo em: $PVC_BACKUP_PATH/${APP_NAME}_files_${TIMESTAMP}.tar.gz"
}

backup_configs() {
    echo "⚙️ [3/3] Fazendo backup das configurações Kubernetes..."
    
    # Backup dos manifestos Kubernetes
    mkdir -p "$BACKUP_DIR/k8s-configs"
    
    # Exportar recursos principais (sem secrets por segurança)
    kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o yaml > "$BACKUP_DIR/k8s-configs/deployment.yaml"
    kubectl get service -n $NAMESPACE -o yaml > "$BACKUP_DIR/k8s-configs/services.yaml"
    kubectl get ingress -n $NAMESPACE -o yaml > "$BACKUP_DIR/k8s-configs/ingress.yaml"
    kubectl get pvc -n $NAMESPACE -o yaml > "$BACKUP_DIR/k8s-configs/pvc.yaml"
    kubectl get hpa -n $NAMESPACE -o yaml > "$BACKUP_DIR/k8s-configs/hpa.yaml" 2>/dev/null || true
    kubectl get certificate -n $NAMESPACE -o yaml > "$BACKUP_DIR/k8s-configs/certificates.yaml" 2>/dev/null || true
    
    # Comprimir configs
    tar czf "$BACKUP_DIR/${APP_NAME}_configs_${TIMESTAMP}.tar.gz" -C "$BACKUP_DIR" k8s-configs/
    rm -rf "$BACKUP_DIR/k8s-configs"
    
    echo "✅ Backup das configurações salvo: ${APP_NAME}_configs_${TIMESTAMP}.tar.gz"
}

# =================================================================
# EXECUÇÃO DO BACKUP
# =================================================================

case "$BACKUP_TYPE" in
    "db")
        backup_database
        ;;
    "files")
        backup_files
        ;;
    "full")
        backup_database
        backup_files
        backup_configs
        ;;
    *)
        echo "❌ Tipo de backup '$BACKUP_TYPE' inválido"
        echo "📋 Tipos disponíveis: db, files, full"
        exit 1
        ;;
esac

# =================================================================
# FINALIZAÇÃO
# =================================================================

# Calcular tamanho do backup
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# Criar arquivo de metadados
cat > "$BACKUP_DIR/backup_info.json" <<EOF
{
    "app_name": "$APP_NAME",
    "backup_type": "$BACKUP_TYPE",
    "timestamp": "$TIMESTAMP",
    "date": "$(date -Iseconds)",
    "kubernetes_version": "$(kubectl version --short --client | grep Client)",
    "backup_size": "$BACKUP_SIZE",
    "files": $(ls -1 "$BACKUP_DIR"/*.gz 2>/dev/null | wc -l)
}
EOF

echo ""
echo "🎉 Backup concluído com sucesso!"
echo "📂 Local: $BACKUP_DIR"
echo "💾 Tamanho: $BACKUP_SIZE"
echo "📋 Arquivos criados:"
ls -la "$BACKUP_DIR"

echo ""
echo "🔄 Para restaurar, use: ./restore-app.sh $APP_NAME $TIMESTAMP"