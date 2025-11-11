#!/bin/bash

###############################################################################
# Script: 2.destroy-infra.sh
# Descrição: Destroi o cluster k3d (que automaticamente remove todos os namespaces)
# MANTÉM: Dados persistentes em hostPath
# Nota: Deletar o cluster remove TODOS os namespaces automaticamente:
#       - n8n, grafana, glpi, prometheus, zabbix
#       - postgres, mariadb, redis
#       - cert-manager
###############################################################################

echo "🗑️ Destruindo cluster k3d (remove todos os namespaces automaticamente)..."

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "📋 O que será removido:"
echo "   ✅ Cluster k3d completo"
echo "   ✅ TODOS os namespaces (apps + infra)"
echo "   ✅ Todos os pods, services, deployments, etc"
echo ""
echo "💾 O que será PRESERVADO:"
echo "   📁 /home/dsm/cluster/ (PVs hostPath com dados)"
echo ""

echo "======== Removendo cluster k3d ========"
# Remove o cluster - isso automaticamente remove TODOS os namespaces
k3d cluster delete k3d-cluster

echo ""
echo "🎉 Infraestrutura base removida!"
echo "💾 DADOS PRESERVADOS em:"
echo "   📁 /home/dsm/cluster/postgresql (databases: postgres, n8n, grafana)"
echo "   📁 /home/dsm/cluster/mariadb (database: glpi)"
echo "   📁 /home/dsm/cluster/redis (cache: db0=n8n, db1=grafana, db2=glpi)" 
echo ""
echo "🎉 Cluster k3d removido com sucesso!"
echo ""
echo "� DADOS PRESERVADOS em /home/dsm/cluster/:"
echo "   📁 postgresql/ (databases: postgres, n8n, grafana, zabbix, prometheus)"
echo "   📁 mariadb/ (databases: glpi, zabbix_proxy)"
echo "   📁 redis/ (cache: db0=n8n, db1=grafana, db2=glpi, db3=prometheus, db4=zabbix)"
echo "   📁 pvc/zabbix/ (server, web, proxy, snmptraps)"
echo "   📁 applications/ (n8n, grafana, glpi, prometheus)"
echo ""
echo "💡 Para recriar tudo:"
echo "   ./start-all.sh [app]              # Infraestrutura + aplicação"
echo "   ./infra/scripts/1.create-infra.sh # Somente infraestrutura"
echo ""