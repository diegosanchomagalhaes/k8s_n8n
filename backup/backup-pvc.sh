#!/bin/bash

# Backup PVC (Persistent Volume Claims)
# Cria backup dos dados dos PVCs para /mnt/e/cluster/pvc/backup

set -e

# Configurações
NAMESPACE="default"
BACKUP_BASE_DIR="/mnt/e/cluster/pvc/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKUP_BASE_DIR}/${TIMESTAMP}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Verificar se kubectl está disponível
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl não está instalado ou não está no PATH"
        exit 1
    fi
}

# Verificar se tar está disponível
check_tar() {
    if ! command -v tar &> /dev/null; then
        error "tar não está instalado ou não está no PATH"
        exit 1
    fi
}

# Criar diretório de backup
create_backup_dir() {
    log "Criando diretório de backup: ${BACKUP_DIR}"
    
    if ! mkdir -p "${BACKUP_DIR}"; then
        error "Falha ao criar diretório de backup: ${BACKUP_DIR}"
        exit 1
    fi
    
    success "Diretório de backup criado"
}

# Obter lista de PVCs
get_pvcs() {
    log "Obtendo lista de PVCs..."
    
    local pvcs=$(kubectl get pvc -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$pvcs" ]; then
        warning "Nenhum PVC encontrado no namespace ${NAMESPACE}"
        return 1
    fi
    
    echo "$pvcs"
}

# Obter informações do PVC
get_pvc_info() {
    local pvc_name=$1
    
    # Obter informações básicas do PVC
    local pvc_info=$(kubectl get pvc ${pvc_name} -n ${NAMESPACE} -o json)
    
    # Extrair informações relevantes
    local storage_class=$(echo "$pvc_info" | jq -r '.spec.storageClassName // "default"')
    local access_modes=$(echo "$pvc_info" | jq -r '.spec.accessModes[]' | tr '\n' ',' | sed 's/,$//')
    local capacity=$(echo "$pvc_info" | jq -r '.status.capacity.storage // "unknown"')
    local volume_name=$(echo "$pvc_info" | jq -r '.spec.volumeName // "unknown"')
    local status=$(echo "$pvc_info" | jq -r '.status.phase // "unknown"')
    
    cat << EOF
{
  "name": "${pvc_name}",
  "storageClass": "${storage_class}",
  "accessModes": "${access_modes}",
  "capacity": "${capacity}",
  "volumeName": "${volume_name}",
  "status": "${status}"
}
EOF
}

# Encontrar pods que usam o PVC
find_pods_using_pvc() {
    local pvc_name=$1
    
    local pods=$(kubectl get pods -n ${NAMESPACE} -o json | \
        jq -r --arg pvc "${pvc_name}" '.items[] | 
        select(.spec.volumes[]?.persistentVolumeClaim?.claimName == $pvc) | 
        .metadata.name')
    
    echo "$pods"
}

# Criar pod temporário para backup
create_backup_pod() {
    local pvc_name=$1
    local pod_name="backup-${pvc_name}-$(date +%s)"
    
    log "Criando pod temporário para backup do PVC: ${pvc_name}"
    
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  namespace: ${NAMESPACE}
  labels:
    app: pvc-backup
    pvc: ${pvc_name}
spec:
  restartPolicy: Never
  containers:
  - name: backup
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data
      mountPath: /data
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "500m"
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ${pvc_name}
EOF

    # Aguardar pod ficar pronto
    log "Aguardando pod temporário ficar pronto..."
    kubectl wait --for=condition=Ready pod/${pod_name} -n ${NAMESPACE} --timeout=300s
    
    success "Pod temporário criado: ${pod_name}"
    echo "${pod_name}"
}

# Fazer backup dos dados do PVC
backup_pvc_data() {
    local pvc_name=$1
    local pod_name=$2
    local backup_file="${BACKUP_DIR}/${pvc_name}_data_${TIMESTAMP}.tar.gz"
    
    log "Fazendo backup dos dados do PVC: ${pvc_name}"
    
    # Verificar se há dados no volume
    local file_count=$(kubectl exec ${pod_name} -n ${NAMESPACE} -- find /data -type f | wc -l)
    
    if [ "$file_count" -eq 0 ]; then
        warning "PVC ${pvc_name} está vazio"
        touch "${backup_file%.tar.gz}.empty"
        return 0
    fi
    
    log "Encontrados ${file_count} arquivos no PVC ${pvc_name}"
    
    # Criar arquivo tar compactado
    if kubectl exec ${pod_name} -n ${NAMESPACE} -- tar -czf - -C /data . > "${backup_file}"; then
        if [ -s "${backup_file}" ]; then
            success "Backup do PVC ${pvc_name} criado: $(basename ${backup_file})"
            
            # Verificar integridade do arquivo
            if tar -tzf "${backup_file}" >/dev/null 2>&1; then
                success "Integridade do backup verificada"
            else
                error "Arquivo de backup corrompido: ${backup_file}"
                rm -f "${backup_file}"
                return 1
            fi
        else
            error "Arquivo de backup vazio para PVC ${pvc_name}"
            rm -f "${backup_file}"
            return 1
        fi
    else
        error "Falha no backup do PVC ${pvc_name}"
        return 1
    fi
}

# Remover pod temporário
cleanup_backup_pod() {
    local pod_name=$1
    
    log "Removendo pod temporário: ${pod_name}"
    
    kubectl delete pod ${pod_name} -n ${NAMESPACE} --grace-period=0 --force 2>/dev/null || true
    
    success "Pod temporário removido"
}

# Fazer backup de um PVC específico
backup_single_pvc() {
    local pvc_name=$1
    local pod_name=""
    
    log "=== Backup do PVC: ${pvc_name} ==="
    
    # Verificar se PVC existe
    if ! kubectl get pvc ${pvc_name} -n ${NAMESPACE} >/dev/null 2>&1; then
        error "PVC não encontrado: ${pvc_name}"
        return 1
    fi
    
    # Salvar informações do PVC
    get_pvc_info "${pvc_name}" > "${BACKUP_DIR}/${pvc_name}_info.json"
    
    # Encontrar pods que usam este PVC
    local using_pods=$(find_pods_using_pvc "${pvc_name}")
    if [ -n "$using_pods" ]; then
        log "Pods usando este PVC: ${using_pods}"
        echo "$using_pods" > "${BACKUP_DIR}/${pvc_name}_pods.txt"
    fi
    
    # Criar pod temporário para backup
    pod_name=$(create_backup_pod "${pvc_name}")
    
    # Fazer backup dos dados
    local success_backup=true
    if ! backup_pvc_data "${pvc_name}" "${pod_name}"; then
        success_backup=false
    fi
    
    # Limpar pod temporário
    cleanup_backup_pod "${pod_name}"
    
    if [ "$success_backup" = true ]; then
        success "Backup do PVC ${pvc_name} concluído"
        return 0
    else
        error "Falha no backup do PVC ${pvc_name}"
        return 1
    fi
}

# Criar arquivo de informações do backup
create_backup_info() {
    local info_file="${BACKUP_DIR}/backup_info.txt"
    
    log "Criando arquivo de informações do backup..."
    
    cat > "${info_file}" << EOF
=== INFORMAÇÕES DO BACKUP PVC ===
Data/Hora: $(date)
Timestamp: ${TIMESTAMP}
Namespace: ${NAMESPACE}
Diretório: ${BACKUP_DIR}

=== CLUSTER KUBERNETES ===
Cluster: $(kubectl config current-context)
Node: $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

=== PVCS INCLUÍDOS ===
EOF

    # Adicionar informações de cada PVC
    for info_file_pvc in "${BACKUP_DIR}"/*_info.json; do
        if [ -f "$info_file_pvc" ]; then
            local pvc_name=$(basename "$info_file_pvc" "_info.json")
            local capacity=$(jq -r '.capacity' "$info_file_pvc")
            local storage_class=$(jq -r '.storageClass' "$info_file_pvc")
            
            echo "- ${pvc_name} (${capacity}, ${storage_class})" >> "${info_file}"
        fi
    done
    
    echo "" >> "${info_file}"
    echo "=== ARQUIVOS DE BACKUP ===" >> "${info_file}"
    ls -la "${BACKUP_DIR}"/*.tar.gz "${BACKUP_DIR}"/*.empty 2>/dev/null >> "${info_file}" || true
    
    success "Arquivo de informações criado: $(basename ${info_file})"
}

# Limpeza de backups antigos (manter apenas os últimos 7 dias)
cleanup_old_backups() {
    log "Limpando backups antigos (mais de 7 dias)..."
    
    find "${BACKUP_BASE_DIR}" -type d -name "20*" -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
    
    success "Limpeza de backups antigos concluída"
}

# Função principal
main() {
    local specific_pvc=""
    
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pvc)
                specific_pvc="$2"
                shift 2
                ;;
            --help|-h)
                cat << EOF
BACKUP PVC (Persistent Volume Claims)

Uso: $0 [OPÇÕES]

OPÇÕES:
    --pvc PVC_NAME     Fazer backup apenas de um PVC específico
    --help             Mostrar esta ajuda

EXEMPLOS:
    $0                          # Backup de todos os PVCs
    $0 --pvc postgres-pvc       # Backup apenas do PVC postgres-pvc

CONFIGURAÇÕES:
    Namespace: ${NAMESPACE}
    Diretório de backup: ${BACKUP_BASE_DIR}

O backup inclui:
    - Dados de todos os arquivos no PVC
    - Informações do PVC (storage class, capacidade, etc.)
    - Lista de pods que usam o PVC
    - Arquivo de informações do backup

Os arquivos são compactados automaticamente com tar+gzip.
Backups antigos (mais de 7 dias) são removidos automaticamente.
EOF
                exit 0
                ;;
            *)
                error "Argumento desconhecido: $1"
                exit 1
                ;;
        esac
    done
    
    log "=== INICIANDO BACKUP PVC ==="
    
    check_kubectl
    check_tar
    create_backup_dir
    
    local failed_backups=0
    
    if [ -n "$specific_pvc" ]; then
        # Backup de PVC específico
        if ! backup_single_pvc "$specific_pvc"; then
            ((failed_backups++))
        fi
    else
        # Backup de todos os PVCs
        local pvcs=$(get_pvcs)
        
        if [ -z "$pvcs" ]; then
            warning "Nenhum PVC encontrado para backup"
            exit 1
        fi
        
        for pvc in $pvcs; do
            if ! backup_single_pvc "$pvc"; then
                ((failed_backups++))
            fi
            echo ""  # Linha em branco entre PVCs
        done
    fi
    
    # Criar arquivo de informações
    create_backup_info
    
    # Limpeza de backups antigos
    cleanup_old_backups
    
    if [ $failed_backups -eq 0 ]; then
        success "=== BACKUP PVC CONCLUÍDO COM SUCESSO ==="
        success "Diretório de backup: ${BACKUP_DIR}"
        success "Arquivos criados:"
        ls -la "${BACKUP_DIR}"
    else
        warning "=== BACKUP PVC CONCLUÍDO COM ${failed_backups} FALHAS ==="
        warning "Verifique os logs acima para detalhes"
        exit 1
    fi
}

# Executar função principal
main "$@"