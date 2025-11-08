#!/bin/bash

###############################################################################
# Script: 15.clean-cluster-pvc.sh
# Descrição: Remove PVs, PVCs e dados do filesystem
#            ⚠️ REQUER CLUSTER PARADO (após destroy-infra)
# Autor: DevOps Team
# Data: 2025-01-06
###############################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
CLUSTER_BASE_PATH="/home/dsm/cluster"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   LIMPEZA DE PVs, PVCs E FILESYSTEM                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá:${NC}"
echo -e "${YELLOW}   - Remover dados em: ${CLUSTER_BASE_PATH}${NC}"
echo ""
echo -e "${RED}⚠️  TODOS OS DADOS DO FILESYSTEM SERÃO PERDIDOS!${NC}"
echo ""
echo -e "${BLUE}💡 Nota: Pode ser necessário digitar a senha sudo durante a execução${NC}"
echo ""

# Confirmação
read -p "Deseja continuar? (SIM/não): " confirmacao
if [[ "$confirmacao" != "SIM" ]]; then
    echo -e "${YELLOW}❌ Operação cancelada pelo usuário${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔍 Verificando se o cluster está rodando...${NC}"

# Verificar se o cluster está rodando
if kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ ERRO: Cluster ainda está rodando!${NC}"
    echo -e "${YELLOW}💡 Execute primeiro: ./infra/scripts/2.destroy-infra.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Cluster não está rodando (correto)${NC}"

###############################################################################
# REMOÇÃO DE DADOS FILESYSTEM
###############################################################################

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  REMOVENDO DADOS DO FILESYSTEM${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

echo ""
echo -e "${YELLOW}🗑️  Removendo dados do filesystem...${NC}"

# Verificar se o diretório existe
if [ -d "$CLUSTER_BASE_PATH" ]; then
    # Lista de subdiretórios para remover
    SUBDIRS=(
        "postgresql"
        "mariadb"
        "redis"
        "applications"
        "pvc"
    )
    
    for subdir in "${SUBDIRS[@]}"; do
        target_dir="$CLUSTER_BASE_PATH/$subdir"
        if [ -d "$target_dir" ]; then
            echo -e "${BLUE}  → Removendo ${target_dir}...${NC}"
            sudo rm -rf "$target_dir"
            echo -e "${GREEN}    ✓ Removido${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Dados do filesystem removidos${NC}"
else
    echo -e "${YELLOW}⚠️  Diretório ${CLUSTER_BASE_PATH} não existe${NC}"
fi

###############################################################################
# FINALIZAÇÃO
###############################################################################

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ LIMPEZA DE FILESYSTEM CONCLUÍDA!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}💡 Próximo passo:${NC}"
echo -e "${BLUE}   Execute: ./start-all.sh${NC}"
echo ""
