#!/bin/bash
set -e

# Script para iniciar o n8n (deploy completo)

echo "🚀 Iniciando n8n..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

# Verificar se o arquivo de secret existe
if [ ! -f "./k8s/apps/n8n/n8n-secret-db.yaml" ]; then
    echo "❌ ERRO: Arquivo n8n-secret-db.yaml não encontrado!"
    echo ""
    echo "📝 Configure as credenciais primeiro:"
    echo "   cd $PROJECT_ROOT"
    echo "   cp k8s/apps/n8n/n8n-secret-db.yaml.template \\"
    echo "      k8s/apps/n8n/n8n-secret-db.yaml"
    echo ""
    echo "   Depois edite o arquivo e configure as credenciais do PostgreSQL"
    echo ""
    exit 1
fi

# Verificar se ainda contém placeholders
if grep -q "YOUR_POSTGRES_ADMIN_PASSWORD_HERE" ./k8s/apps/n8n/n8n-secret-db.yaml; then
    echo "❌ ERRO: Credenciais não configuradas em n8n-secret-db.yaml"
    echo ""
    echo "📝 Edite o arquivo e substitua os placeholders por valores reais"
    echo ""
    exit 1
fi

echo "✅ Credenciais configuradas corretamente!"

# Executar deploy completo do n8n
echo "📦 Executando deploy do n8n..."
"$PROJECT_ROOT/k8s/apps/n8n/scripts/1.deploy-n8n.sh"

echo ""
echo "🎉 n8n iniciado com sucesso!"
echo "🌐 URL: https://n8n.local.127.0.0.1.nip.io:8443"
echo "⚙️ Configure seu primeiro usuário admin no primeiro acesso"
echo ""
