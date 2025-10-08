#!/bin/bash
set -e

# Script para limpeza completa da base de dados do n8n
# ATENÇÃO: Este script remove PERMANENTEMENTE todos os dados do n8n!

echo "🗑️ LIMPEZA COMPLETA - BASE DE DADOS N8N"
echo "========================================"
echo "⚠️  ATENÇÃO: Este script irá APAGAR PERMANENTEMENTE:"
echo "   • Todos os workflows do n8n"
echo "   • Todas as credenciais do n8n"
echo "   • Todo histórico de execuções"
echo "   • Todas as configurações do n8n"
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
echo "🗑️ Removendo base de dados 'n8n'..."

# Drop da database n8n
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'n8n' AND pid <> pg_backend_pid();
"

kubectl exec -n postgres postgres-0 -- psql -U postgres -c "DROP DATABASE IF EXISTS n8n;"

echo "✅ Base de dados 'n8n' removida com sucesso!"

echo ""
echo "🔄 Recriando base de dados 'n8n' vazia..."

# Recriar database vazia
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE n8n;"

echo "✅ Base de dados 'n8n' recriada (vazia)"

echo ""
echo "🎉 Limpeza da base de dados n8n concluída!"
echo ""
echo "💡 Próximos passos:"
echo "   • Se o n8n estiver rodando, reinicie-o para aplicar as mudanças:"
echo "     ./k8s/apps/n8n/scripts/3.start-n8n.sh"
echo "   • Todos os workflows e configurações precisarão ser recriados"
echo ""