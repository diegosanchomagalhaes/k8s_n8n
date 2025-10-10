#!/bin/bash

# 🧹 Script para limpar dados persistentes do cluster
# Uso: ./infra/scripts/14.clean-cluster-data.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Definir diretório base
CLUSTER_BASE="/home/dsm/cluster"

echo -e "${YELLOW}🧹 Limpeza de Dados Persistentes do Cluster${NC}"
echo "========================================"
echo ""

# Verificar se o diretório existe
if [ ! -d "$CLUSTER_BASE" ]; then
    echo -e "${YELLOW}⚠️  Diretório $CLUSTER_BASE não existe. Nada para limpar.${NC}"
    exit 0
fi

# Mostrar o que será removido
echo -e "${BLUE}📁 Conteúdo atual em $CLUSTER_BASE:${NC}"
ls -la "$CLUSTER_BASE" 2>/dev/null || echo "Diretório vazio"
echo ""

# Confirmar ação
echo -e "${RED}⚠️  ATENÇÃO: Esta ação irá remover TODOS os dados persistentes!${NC}"
echo -e "${RED}   - PostgreSQL databases${NC}"
echo -e "${RED}   - Redis cache data${NC}"
echo -e "${RED}   - n8n workflows${NC}"
echo -e "${RED}   - Grafana dashboards${NC}"
echo ""
echo -e "${YELLOW}Esta ação é IRREVERSÍVEL!${NC}"
echo ""

read -p "🤔 Tem certeza que deseja continuar? (digite 'SIM' para confirmar): " confirm

if [ "$confirm" != "SIM" ]; then
    echo -e "${GREEN}✅ Operação cancelada pelo usuário.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🗑️  Removendo dados persistentes...${NC}"

# Remover subdiretórios específicos um por um
if [ -d "$CLUSTER_BASE/postgresql" ]; then
    echo -e "${BLUE}   🐘 Removendo dados PostgreSQL...${NC}"
    sudo rm -rf "$CLUSTER_BASE/postgresql"
fi

if [ -d "$CLUSTER_BASE/redis" ]; then
    echo -e "${BLUE}   🔴 Removendo dados Redis...${NC}"
    sudo rm -rf "$CLUSTER_BASE/redis"
fi

if [ -d "$CLUSTER_BASE/pvc" ]; then
    echo -e "${BLUE}   📁 Removendo PVCs (n8n, grafana)...${NC}"
    sudo rm -rf "$CLUSTER_BASE/pvc"
fi

# Remover outros diretórios que possam existir
for dir in "$CLUSTER_BASE"/*; do
    if [ -d "$dir" ]; then
        echo -e "${BLUE}   🗂️  Removendo $(basename "$dir")...${NC}"
        sudo rm -rf "$dir"
    fi
done

# Manter o diretório base
mkdir -p "$CLUSTER_BASE"
sudo chown dsm:dsm "$CLUSTER_BASE"

echo ""
echo -e "${GREEN}✅ Limpeza concluída!${NC}"
echo ""
echo -e "${BLUE}📋 Próximos passos:${NC}"
echo "   1. ./infra/scripts/9.setup-directories.sh  # Recriar estrutura"
echo "   2. ./start-all.sh                          # Deploy completo"
echo ""
echo -e "${YELLOW}💡 O diretório $CLUSTER_BASE está agora limpo e pronto para novo deploy.${NC}"