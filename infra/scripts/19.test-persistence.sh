#!/bin/bash
set -e

# Script para remover APENAS o cluster k3d mantendo TODOS os dados persistentes
# Ideal para testar persistência de dados

echo "🧪 TESTE DE PERSISTÊNCIA: Removendo cluster k3d (mantendo dados)..."
echo ""

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "📊 Estado atual do cluster:"
echo "   Pods ativos:"
kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l || echo "   (cluster não acessível)"
echo "   PVCs:"
kubectl get pvc --all-namespaces --no-headers 2>/dev/null | wc -l || echo "   (cluster não acessível)"

echo ""
echo "🗑️ Removendo cluster k3d..."
k3d cluster delete k3d-cluster

echo ""
echo "✅ Cluster removido com sucesso!"
echo ""
echo "💾 DADOS PRESERVADOS no WSL2:"
echo "   📁 /home/dsm/cluster/postgresql/     # Databases completos"
echo "   📁 /home/dsm/cluster/redis/          # Cache Redis"
echo "   📁 /home/dsm/cluster/applications/   # Dados das aplicações"
echo ""

# Verificar se os dados ainda existem
echo "🔍 Verificando se os dados persistentes existem:"
if [ -d "/home/dsm/cluster/postgresql" ]; then
    echo "   ✅ PostgreSQL data: $(du -sh /home/dsm/cluster/postgresql 2>/dev/null | cut -f1 || echo "presente")"
fi

if [ -d "/home/dsm/cluster/redis" ]; then
    echo "   ✅ Redis data: $(du -sh /home/dsm/cluster/redis 2>/dev/null | cut -f1 || echo "presente")"
fi

if [ -d "/home/dsm/cluster/applications" ]; then
    echo "   ✅ Applications data: $(du -sh /home/dsm/cluster/applications 2>/dev/null | cut -f1 || echo "presente")"
    if [ -d "/home/dsm/cluster/applications/n8n" ]; then
        echo "      📁 n8n: $(du -sh /home/dsm/cluster/applications/n8n 2>/dev/null | cut -f1 || echo "presente")"
    fi
    if [ -d "/home/dsm/cluster/applications/grafana" ]; then
        echo "      📁 grafana: $(du -sh /home/dsm/cluster/applications/grafana 2>/dev/null | cut -f1 || echo "presente")"
    fi
fi

echo ""
echo "🚀 Para recriar o ambiente completo com os dados preservados:"
echo "   $PROJECT_ROOT/start-all.sh"
echo ""
echo "🎯 Teste de persistência:"
echo "   1. Execute $PROJECT_ROOT/start-all.sh"
echo "   2. Verifique se n8n e Grafana mantiveram dados/configurações" 
echo "   3. Os logins devem funcionar sem reconfiguração"