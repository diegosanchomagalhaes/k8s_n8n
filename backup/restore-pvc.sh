#!/bin/bash

# Restore PVC (Persistent Volume Claims)
# Restaura dados dos PVCs a partir de /mnt/e/cluster/pvc/backup

set -e

# Configurações
NAMESPACE="default"
BACKUP_BASE_DIR="/mnt/e/cluster/pvc/backup"

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

# Função para mostrar ajuda
show_help() {
    cat << EOF
RESTORE PVC (Persistent Volume Claims)

Uso: $0 [BACKUP_TIMESTAMP] [OPÇÕES]

ARGUMENTOS:
    BACKUP_TIMESTAMP    Timestamp do backup a ser restaurado (formato: YYYYMMDD_HHMMSS)
                       Use 'list' para ver backups disponíveis
                       Use 'latest' para usar o backup mais recente

OPÇÕES:
    --pvc PVC_NAME     Restaurar apenas um PVC específico
    --recreate         Recriar o PVC se ele existir (CUIDADO: apaga dados atuais)
    --force            Não pedir confirmação antes de restaurar
    --dry-run          Mostrar o que seria feito sem executar
    --help             Mostrar esta ajuda

EXEMPLOS:
    $0 list                                    # Listar backups disponíveis
    $0 latest                                  # Restaurar backup mais recente
    $0 20241224_143022                        # Restaurar backup específico
    $0 20241224_143022 --pvc postgres-pvc     # Restaurar apenas PVC postgres-pvc
    $0 latest --recreate --force              # Recriar PVCs sem confirmação

CONFIGURAÇÕES:
    Namespace: ${NAMESPACE}
    Diretório de backup: ${BACKUP_BASE_DIR}

ATENÇÃO:
    - O restore substitui TODOS os dados no PVC
    - Use --recreate apenas se souber o que está fazendo
    - Sempre faça backup antes de fazer restore

EOF
}

# Verificar se kubectl está disponível
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl não está instalado ou não está no PATH"
        exit 1
    fi
}

# Verificar se jq está disponível
check_jq() {
    if ! command -v jq &> /dev/null; then
        error "jq não está instalado ou não está no PATH"
        echo "Instale jq para continuar: sudo apt-get install jq"
        exit 1
    fi
}

# Listar backups disponíveis
list_backups() {
    log "Backups disponíveis em ${BACKUP_BASE_DIR}:"
    echo ""
    
    if [ ! -d "${BACKUP_BASE_DIR}" ]; then
        error "Diretório de backup não existe: ${BACKUP_BASE_DIR}"
        exit 1
    fi
    
    local backups=$(find "${BACKUP_BASE_DIR}" -type d -name "20*" | sort -r)
    
    if [ -z "$backups" ]; then
        warning "Nenhum backup encontrado"
        exit 1
    fi
    
    local count=1
    for backup_dir in $backups; do
        local timestamp=$(basename "$backup_dir")
        local date_formatted=$(echo "$timestamp" | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
        local info_file="${backup_dir}/backup_info.txt"
        local file_count=$(find "$backup_dir" -name "*.tar.gz" | wc -l)
        local empty_count=$(find "$backup_dir" -name "*.empty" | wc -l)
        
        echo -e "${count}. ${GREEN}${timestamp}${NC}"
        echo -e "   Data: ${date_formatted}"
        echo -e "   PVCs com dados: ${file_count}"
        echo -e "   PVCs vazios: ${empty_count}"
        
        if [ -f "$info_file" ]; then
            echo -e "   Localização: ${backup_dir}"
            
            # Mostrar lista de PVCs se disponível
            local pvcs=$(grep "^- " "$info_file" 2>/dev/null | head -3)
            if [ -n "$pvcs" ]; then
                echo -e "   PVCs: $(echo "$pvcs" | sed 's/^- //' | tr '\n' ', ' | sed 's/, $//')"
            fi
        else
            echo -e "   ${YELLOW}Aviso: Arquivo de informações não encontrado${NC}"
        fi
        echo ""
        
        ((count++))
    done
}

# Obter o backup mais recente
get_latest_backup() {
    local latest=$(find "${BACKUP_BASE_DIR}" -type d -name "20*" | sort -r | head -1)
    
    if [ -z "$latest" ]; then
        error "Nenhum backup encontrado"
        exit 1
    fi
    
    basename "$latest"
}

# Verificar se backup existe
verify_backup() {
    local timestamp=$1
    local backup_dir="${BACKUP_BASE_DIR}/${timestamp}"
    
    if [ ! -d "$backup_dir" ]; then
        error "Backup não encontrado: ${backup_dir}"
        exit 1
    fi
    
    local backup_files=$(find "$backup_dir" -name "*.tar.gz" -o -name "*.empty" | wc -l)
    if [ "$backup_files" -eq 0 ]; then
        error "Nenhum arquivo de backup encontrado em: ${backup_dir}"
        exit 1
    fi
    
    success "Backup verificado: ${timestamp} (${backup_files} PVCs)"
    echo "$backup_dir"
}

# Obter lista de PVCs no backup
get_backup_pvcs() {
    local backup_dir=$1
    local specific_pvc=$2
    
    local pvcs=""
    
    if [ -n "$specific_pvc" ]; then
        # Verificar se PVC específico existe no backup
        if [ -f "${backup_dir}/${specific_pvc}_data_"*.tar.gz ] || [ -f "${backup_dir}/${specific_pvc}_"*.empty ]; then
            pvcs="$specific_pvc"
        else
            error "PVC ${specific_pvc} não encontrado no backup"
            exit 1
        fi
    else
        # Obter todos os PVCs do backup
        for file in "${backup_dir}"/*_info.json; do
            if [ -f "$file" ]; then
                local pvc_name=$(basename "$file" "_info.json")
                pvcs="$pvcs $pvc_name"
            fi
        done
    fi
    
    echo "$pvcs" | xargs  # Remove espaços extras
}

# Confirmar operação
confirm_restore() {
    local timestamp=$1
    local pvcs=$2
    local recreate=$3
    
    echo ""
    warning "=== ATENÇÃO: OPERAÇÃO DE RESTORE PVC ==="
    echo ""
    
    echo "Esta operação irá RESTAURAR os seguintes PVCs com o backup:"
    echo "  Timestamp: ${timestamp}"
    echo "  Diretório: ${BACKUP_BASE_DIR}/${timestamp}"
    echo ""
    
    echo "PVCs a serem restaurados:"
    for pvc in $pvcs; do
        echo "  - ${pvc}"
    done
    echo ""
    
    if [ "$recreate" = true ]; then
        warning "MODO RECREATE ATIVO: PVCs existentes serão DELETADOS e RECRIADOS!"
    fi
    
    warning "DADOS ATUAIS NOS PVCs SERÃO PERDIDOS!"
    echo ""
    
    read -p "Deseja continuar? (digite 'CONFIRMAR' para prosseguir): " confirm
    
    if [ "$confirm" != "CONFIRMAR" ]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi
}

# Verificar se PVC existe
pvc_exists() {
    local pvc_name=$1
    kubectl get pvc ${pvc_name} -n ${NAMESPACE} >/dev/null 2>&1
}

# Criar PVC a partir das informações do backup
create_pvc_from_backup() {
    local backup_dir=$1
    local pvc_name=$2
    local info_file="${backup_dir}/${pvc_name}_info.json"
    
    if [ ! -f "$info_file" ]; then
        error "Arquivo de informações não encontrado para PVC: ${pvc_name}"
        return 1
    fi
    
    log "Criando PVC: ${pvc_name}"
    
    # Ler informações do PVC
    local storage_class=$(jq -r '.storageClass' "$info_file")
    local access_modes=$(jq -r '.accessModes' "$info_file" | sed 's/,/\n/g')
    local capacity=$(jq -r '.capacity' "$info_file")
    
    # Verificar se storage class é válida
    if [ "$storage_class" = "null" ] || [ -z "$storage_class" ]; then
        storage_class="local-path"  # Default para k3d
    fi
    
    # Criar manifesto do PVC
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${pvc_name}
  namespace: ${NAMESPACE}
spec:
  accessModes:
$(echo "$access_modes" | sed 's/^/  - /')
  resources:
    requests:
      storage: ${capacity}
  storageClassName: ${storage_class}
EOF

    # Aguardar PVC ficar bound
    log "Aguardando PVC ficar disponível..."
    kubectl wait --for=condition=Bound pvc/${pvc_name} -n ${NAMESPACE} --timeout=300s
    
    success "PVC criado: ${pvc_name}"
}

# Criar pod temporário para restore
create_restore_pod() {
    local pvc_name=$1
    local pod_name="restore-${pvc_name}-$(date +%s)"
    
    log "Criando pod temporário para restore do PVC: ${pvc_name}"
    
    cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  namespace: ${NAMESPACE}
  labels:
    app: pvc-restore
    pvc: ${pvc_name}
spec:
  restartPolicy: Never
  containers:
  - name: restore
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

# Restaurar dados para o PVC
restore_pvc_data() {
    local backup_dir=$1
    local pvc_name=$2
    local pod_name=$3
    local data_file="${backup_dir}/${pvc_name}_data_"*.tar.gz
    local empty_file="${backup_dir}/${pvc_name}_"*.empty
    
    # Verificar se é um PVC vazio
    if ls ${empty_file} >/dev/null 2>&1; then
        log "PVC ${pvc_name} estava vazio no backup - nenhum dado para restaurar"
        return 0
    fi
    
    # Encontrar arquivo de dados
    local data_path=$(ls ${data_file} 2>/dev/null | head -1)
    
    if [ -z "$data_path" ]; then
        error "Arquivo de dados não encontrado para PVC: ${pvc_name}"
        return 1
    fi
    
    log "Restaurando dados para PVC: ${pvc_name}"
    
    # Limpar dados existentes
    kubectl exec ${pod_name} -n ${NAMESPACE} -- rm -rf /data/* /data/.[^.]* 2>/dev/null || true
    
    # Restaurar dados
    if cat "$data_path" | kubectl exec -i ${pod_name} -n ${NAMESPACE} -- tar -xzf - -C /data; then
        success "Dados restaurados para PVC: ${pvc_name}"
        
        # Verificar alguns arquivos restaurados
        local file_count=$(kubectl exec ${pod_name} -n ${NAMESPACE} -- find /data -type f | wc -l)
        log "Arquivos restaurados: ${file_count}"
        
        return 0
    else
        error "Falha ao restaurar dados para PVC: ${pvc_name}"
        return 1
    fi
}

# Remover pod temporário
cleanup_restore_pod() {
    local pod_name=$1
    
    log "Removendo pod temporário: ${pod_name}"
    
    kubectl delete pod ${pod_name} -n ${NAMESPACE} --grace-period=0 --force 2>/dev/null || true
    
    success "Pod temporário removido"
}

# Restaurar um PVC específico
restore_single_pvc() {
    local backup_dir=$1
    local pvc_name=$2
    local recreate=$3
    local pod_name=""
    
    log "=== Restore do PVC: ${pvc_name} ==="
    
    # Verificar se PVC existe
    if pvc_exists "$pvc_name"; then
        if [ "$recreate" = true ]; then
            log "Deletando PVC existente: ${pvc_name}"
            kubectl delete pvc ${pvc_name} -n ${NAMESPACE} --grace-period=0 --force
            
            # Aguardar PVC ser completamente removido
            while pvc_exists "$pvc_name"; do
                log "Aguardando remoção do PVC..."
                sleep 2
            done
            
            # Criar novo PVC
            if ! create_pvc_from_backup "$backup_dir" "$pvc_name"; then
                return 1
            fi
        else
            log "PVC já existe: ${pvc_name}"
        fi
    else
        # Criar PVC a partir do backup
        if ! create_pvc_from_backup "$backup_dir" "$pvc_name"; then
            return 1
        fi
    fi
    
    # Criar pod temporário para restore
    pod_name=$(create_restore_pod "${pvc_name}")
    
    # Restaurar dados
    local success_restore=true
    if ! restore_pvc_data "$backup_dir" "$pvc_name" "$pod_name"; then
        success_restore=false
    fi
    
    # Limpar pod temporário
    cleanup_restore_pod "$pod_name"
    
    if [ "$success_restore" = true ]; then
        success "Restore do PVC ${pvc_name} concluído"
        return 0
    else
        error "Falha no restore do PVC ${pvc_name}"
        return 1
    fi
}

# Função principal
main() {
    local timestamp=""
    local specific_pvc=""
    local recreate=false
    local force_restore=false
    local dry_run=false
    
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pvc)
                specific_pvc="$2"
                shift 2
                ;;
            --recreate)
                recreate=true
                shift
                ;;
            --force)
                force_restore=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            list)
                list_backups
                exit 0
                ;;
            latest)
                timestamp=$(get_latest_backup)
                shift
                ;;
            20[0-9][0-9][0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9][0-9][0-9])
                timestamp="$1"
                shift
                ;;
            *)
                error "Argumento desconhecido: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
    
    # Verificar se timestamp foi fornecido
    if [ -z "$timestamp" ]; then
        error "Timestamp do backup é obrigatório"
        echo ""
        show_help
        exit 1
    fi
    
    log "=== INICIANDO RESTORE PVC ==="
    
    check_kubectl
    check_jq
    
    # Verificar backup
    local backup_dir=$(verify_backup "$timestamp")
    
    # Obter lista de PVCs
    local pvcs=$(get_backup_pvcs "$backup_dir" "$specific_pvc")
    
    if [ "$dry_run" = true ]; then
        log "=== MODO DRY-RUN (SIMULAÇÃO) ==="
        log "Timestamp: ${timestamp}"
        log "Diretório: ${backup_dir}"
        log "PVCs a serem restaurados: ${pvcs}"
        
        if [ "$recreate" = true ]; then
            log "Modo recreate: PVCs seriam recriados"
        fi
        
        success "Simulação concluída - nenhuma alteração foi feita"
        exit 0
    fi
    
    # Confirmação (a menos que --force seja usado)
    if [ "$force_restore" = false ]; then
        confirm_restore "$timestamp" "$pvcs" "$recreate"
    fi
    
    # Executar restore
    local failed_restores=0
    
    for pvc in $pvcs; do
        if ! restore_single_pvc "$backup_dir" "$pvc" "$recreate"; then
            ((failed_restores++))
        fi
        echo ""  # Linha em branco entre PVCs
    done
    
    # Resultado final
    if [ $failed_restores -eq 0 ]; then
        success "=== RESTORE PVC CONCLUÍDO COM SUCESSO ==="
        success "PVCs restaurados: ${pvcs}"
        success "Backup usado: ${timestamp}"
    else
        warning "=== RESTORE PVC CONCLUÍDO COM ${failed_restores} FALHAS ==="
        warning "Verifique os logs acima para detalhes"
        exit 1
    fi
}

# Executar função principal
main "$@"