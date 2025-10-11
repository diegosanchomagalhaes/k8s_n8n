#!/bin/bash
set -e

# Script para limpeza completa da base de dados do Prometheus
# ATENÇÃO: Este script remove PERMANENTEMENTE todos os dados do Prometheus!

echo "🗑️ LIMPEZA COMPLETA - BASE DE DADOS PROMETHEUS"
echo "=============================================="
echo "⚠️  ATENÇÃO: Este script irá APAGAR PERMANENTEMENTE:"
echo "   • Todas as métricas do Prometheus"
echo "   • Todo histórico de monitoramento"
echo "   • Todas as configurações personalizadas"
echo "   • Todos os dados TSDB do Prometheus"
echo ""

# Solicitar confirmação
read -p "Tem certeza que deseja continuar? (digite 'CONFIRMAR' para prosseguir): " confirmation

if [ "$confirmation" != "CONFIRMAR" ]; then
    echo "❌ Operação cancelada pelo usuário"
    exit 1
fi

echo ""
echo "🔍 Verificando se PostgreSQL está disponível..."

# Verificar se PostgreSQL está rodando
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute primeiro: ./infra/scripts/10.start-infra.sh"
    exit 1
fi

echo "✅ PostgreSQL disponível"

echo ""
echo "🗑️ Removendo base de dados 'prometheus'..."

# Drop da database prometheus
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'prometheus' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS prometheus;
"

echo "✅ Base de dados 'prometheus' removida do PostgreSQL"

echo ""
echo "🗑️ Limpando cache Redis (database 3)..."

# Limpar cache Redis da database 3 (Prometheus)
kubectl exec -n redis -c redis redis-7f9d59f5c-94zrp -- redis-cli -n 3 FLUSHDB

echo "✅ Cache Redis (database 3) limpo"

echo ""
echo "🎯 Limpeza completa concluída!"
echo "💡 Para recriar o Prometheus com dados limpos:"
echo "   ./3.start-prometheus.sh"