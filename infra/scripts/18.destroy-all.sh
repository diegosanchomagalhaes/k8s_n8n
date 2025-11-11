#!/bin/bash

###############################################################################
# Script: 18.destroy-all.sh
# Descrição: Destruição completa e simplificada do ambiente
#            1. Drop de databases (cluster rodando)
#            2. Delete cluster k3d (remove TODOS os namespaces automaticamente)
#            3. Limpeza de filesystem (PVs/PVCs/dados)
# Autor: DevOps Team
# Data: 2025-11-11
# Nota: Deletar o cluster k3d automaticamente remove TODOS os namespaces,
#       então não é necessário deletá-los manualmente.
###############################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║        DESTRUIÇÃO COMPLETA DO AMBIENTE K8S                   ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  ATENÇÃO: Este script irá executar na ordem:${NC}"
echo ""
echo -e "${BLUE}   1️⃣  Drop de databases (PostgreSQL + MariaDB)${NC}"
echo -e "${BLUE}   2️⃣  Destroy da infraestrutura (cluster k3d)${NC}"
echo -e "${BLUE}   3️⃣  Limpeza de filesystem (PVs/PVCs/dados)${NC}"
echo ""
echo -e "${RED}⚠️  TODOS OS DADOS SERÃO PERDIDOS PERMANENTEMENTE!${NC}"
echo ""
echo -e "${YELLOW}📋 Scripts que serão executados:${NC}"
echo -e "${YELLOW}   → 14.clean-cluster-data.sh${NC}"
echo -e "${YELLOW}   → 2.destroy-infra.sh${NC}"
echo -e "${YELLOW}   → 15.clean-cluster-pvc.sh${NC}"
echo ""
echo -e "${BLUE}💡 Nota: Será necessário digitar a senha sudo durante a execução${NC}"
echo ""

# Confirmação
read -p "Deseja continuar com a destruição completa? (SIM/não): " confirmacao
if [[ "$confirmacao" != "SIM" ]]; then
    echo -e "${YELLOW}❌ Operação cancelada pelo usuário${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  INICIANDO PROCESSO DE DESTRUIÇÃO${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

###############################################################################
# ETAPA 1: DROP DE DATABASES
###############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 1/3: Drop de Databases                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$SCRIPT_DIR/14.clean-cluster-data.sh" ]; then
    echo -e "${YELLOW}🔄 Executando 14.clean-cluster-data.sh...${NC}"
    echo ""
    
    # Executar com auto-confirmação
    echo "SIM" | "$SCRIPT_DIR/14.clean-cluster-data.sh"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Etapa 1 concluída: Databases removidos${NC}"
    else
        echo ""
        echo -e "${RED}❌ ERRO na Etapa 1: Falha ao dropar databases${NC}"
        echo -e "${YELLOW}💡 Verifique se o cluster está rodando${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ ERRO: Script 14.clean-cluster-data.sh não encontrado${NC}"
    exit 1
fi

###############################################################################
# ETAPA 2: DESTROY INFRAESTRUTURA
###############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 2/3: Destroy Infraestrutura                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$SCRIPT_DIR/2.destroy-infra.sh" ]; then
    echo -e "${YELLOW}🔄 Executando 2.destroy-infra.sh...${NC}"
    echo ""
    
    "$SCRIPT_DIR/2.destroy-infra.sh"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Etapa 2 concluída: Cluster destruído${NC}"
    else
        echo ""
        echo -e "${RED}❌ ERRO na Etapa 2: Falha ao destruir infraestrutura${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ ERRO: Script 2.destroy-infra.sh não encontrado${NC}"
    exit 1
fi

###############################################################################
# AGUARDAR CLUSTER PARAR COMPLETAMENTE
###############################################################################

echo ""
echo -e "${YELLOW}⏳ Aguardando cluster parar completamente...${NC}"
sleep 5

###############################################################################
# ETAPA 3: LIMPEZA DE FILESYSTEM
###############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ETAPA 3/3: Limpeza de Filesystem                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$SCRIPT_DIR/15.clean-cluster-pvc.sh" ]; then
    echo -e "${YELLOW}🔄 Executando 15.clean-cluster-pvc.sh...${NC}"
    echo ""
    
    # Executar com auto-confirmação
    echo "SIM" | "$SCRIPT_DIR/15.clean-cluster-pvc.sh"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Etapa 3 concluída: Filesystem limpo${NC}"
    else
        echo ""
        echo -e "${RED}❌ ERRO na Etapa 3: Falha ao limpar filesystem${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ ERRO: Script 15.clean-cluster-pvc.sh não encontrado${NC}"
    exit 1
fi

###############################################################################
# FINALIZAÇÃO
###############################################################################

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DESTRUIÇÃO COMPLETA CONCLUÍDA COM SUCESSO!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📋 Resumo das etapas executadas:${NC}"
echo -e "${GREEN}   ✅ Databases dropados (PostgreSQL + MariaDB)${NC}"
echo -e "${GREEN}   ✅ Cluster k3d destruído${NC}"
echo -e "${GREEN}   ✅ Filesystem limpo (PVs/PVCs/dados removidos)${NC}"
echo ""
echo -e "${BLUE}💡 Próximo passo:${NC}"
echo -e "${BLUE}   Execute: ./start-all.sh${NC}"
echo -e "${BLUE}   Isso criará um ambiente completamente limpo!${NC}"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
