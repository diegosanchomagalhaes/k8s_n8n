#!/bin/bash

# Script de inicialização do n8n
# Para usar: ./3.start-n8n.sh

echo "📱 Iniciando n8n..."

# =================================================================
# 0. DEFINIR DIRETÓRIO BASE DO PROJETO
# =================================================================
# Detectar se estamos no diretório correto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "📁 Diretório do projeto: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# =================================================================
# 1. VERIFICAR PRÉ-REQUISITOS
# =================================================================
echo "🔍 Verificando pré-requisitos..."

# Verificar se cluster está rodando
if ! k3d cluster list k3d-cluster 2>/dev/null | grep -q "k3d-cluster"; then
    echo "❌ ERRO: Cluster k3d não está rodando!"
    echo ""
    echo "📝 Inicie a infraestrutura primeiro:"
    echo "   ./infra/scripts/9.start-infra.sh"
    echo ""
    exit 1
fi

# Verificar se PostgreSQL está rodando
if ! kubectl get pods | grep -q "postgres.*Running"; then
    echo "❌ ERRO: PostgreSQL não está rodando!"
    echo ""
    echo "📝 Inicie a infraestrutura primeiro:"
    echo "   ./infra/scripts/9.start-infra.sh"
    echo ""
    exit 1
fi

# Verificar se n8n secret existe
if [ ! -f "k8s/apps/n8n/n8n-secret-db.yaml" ]; then
    echo "❌ ERRO: Arquivo n8n-secret-db.yaml não encontrado!"
    echo ""
    echo "📝 Configure as credenciais primeiro:"
    echo "   cd $PROJECT_ROOT"
    echo "   cp k8s/apps/n8n/n8n-secret-db.yaml.template \\"
    echo "      k8s/apps/n8n/n8n-secret-db.yaml"
    echo ""
    echo "   Depois edite o arquivo e substitua YOUR_POSTGRES_ADMIN_PASSWORD_HERE"
    echo "📖 Veja detalhes em: README-SECURITY.md"
    exit 1
fi

if grep -q "YOUR_POSTGRES_ADMIN_PASSWORD_HERE" k8s/apps/n8n/n8n-secret-db.yaml; then
    echo "❌ ERRO: Senha não configurada em n8n-secret-db.yaml"
    echo ""
    echo "📝 Edite o arquivo e substitua YOUR_POSTGRES_ADMIN_PASSWORD_HERE por uma senha real"
    echo "💡 Use a MESMA senha do postgres-secret-admin.yaml"
    echo ""
    exit 1
fi

echo "✅ Pré-requisitos verificados!"

# =================================================================
# 2. DEPLOY DO N8N
# =================================================================

# Verificar se n8n está rodando
if ! kubectl get pods -n n8n 2>/dev/null | grep -q "Running"; then
    echo "📱 Fazendo deploy do n8n..."
    "$PROJECT_ROOT/k8s/apps/n8n/scripts/1.deploy-n8n.sh"
    
    echo "⏳ Aguardando n8n ficar pronto..."
    kubectl wait --for=condition=ready pod -l app=n8n -n n8n --timeout=300s
else
    echo "✅ n8n já está rodando!"
fi

# Verificar /etc/hosts
if ! grep -q "n8n.local.127.0.0.1.nip.io" /etc/hosts; then
    echo "🌐 Configurando /etc/hosts..."
    echo '127.0.0.1 n8n.local.127.0.0.1.nip.io' | sudo tee -a /etc/hosts
fi

echo ""
echo "🎉 n8n pronto!"
echo ""
echo "🔗 Acesso HTTPS: https://n8n.local.127.0.0.1.nip.io:8443"
echo ""
echo "⚠️  No browser: Clique 'Avançado' → 'Continuar' no aviso de certificado"
echo ""
echo "📊 Recursos configurados:"
echo "   - CPU: 200m request / 1000m limit"
echo "   - RAM: 512Mi request / 1536Mi limit"
echo "   - HPA: 1-3 replicas"
echo ""