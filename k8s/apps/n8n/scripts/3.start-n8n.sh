#!/bin/bash#!/bin/bash



# Script de inicialização do n8n# Script de inicialização do n8n

# Para usar: ./3.start-n8n.sh# Para usar: ./3.start-n8# Verificar dependências compartilhadas (PostgreSQL + Redis)

echo "🔍 Verificando dependências compartilhadas..."

echo "🚀 Iniciando n8n..."

# Verificar PostgreSQL

# =================================================================if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then

# 0. DEFINIR DIRETÓRIO BASE DO PROJETO    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"

# =================================================================    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"

# Detectar se estamos no diretório correto    exit 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"fi

PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"echo "✅ PostgreSQL OK"



echo "📁 Diretório do projeto: $PROJECT_ROOT"# Verificar Redis

cd "$PROJECT_ROOT"if ! kubectl get pods -n redis -l app=redis 2>/dev/null | grep -q "Running"; then

    echo "❌ Redis não está rodando no namespace 'redis'"

# =================================================================    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"

# 1. VERIFICAR PRÉ-REQUISITOS    exit 1

# =================================================================fi

echo "🔍 Verificando pré-requisitos..."echo "✅ Redis OK"



# Verificar se cluster está rodando# Verificar se n8n está rodando

if ! k3d cluster list k3d-cluster 2>/dev/null | grep -q "k3d-cluster"; thenif ! kubectl get pods -n n8n -l app=n8n 2>/dev/null | grep -q "Running"; then

    echo "❌ Cluster k3d não encontrado"    echo "📱 n8n não está rodando - fazendo deploy..."

    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"    "$PROJECT_ROOT/k8s/apps/n8n/scripts/1.deploy-n8n.sh"

    exit 1    

fi    echo "⏳ Aguardando n8n ficar pronto..."

    kubectl wait --for=condition=ready pod -l app=n8n -n n8n --timeout=300s

# Verificar se cluster está runningelse

if ! k3d cluster list k3d-cluster 2>/dev/null | grep -q "running"; then    echo "✅ n8n já está rodando!"

    echo "❌ Cluster k3d não está rodando"fiiando n8n..."

    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"

    exit 1# =================================================================

fi# 0. DEFINIR DIRETÓRIO BASE DO PROJETO

# =================================================================

echo "✅ Cluster k3d OK"# Detectar se estamos no diretório correto

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =================================================================PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# 2. VERIFICAR DEPENDÊNCIAS COMPARTILHADAS

# =================================================================echo "📁 Diretório do projeto: $PROJECT_ROOT"

echo "🔍 Verificando dependências compartilhadas..."cd "$PROJECT_ROOT"



# Verificar PostgreSQL# =================================================================

if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then# 1. VERIFICAR PRÉ-REQUISITOS

    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"# =================================================================

    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"echo "🔍 Verificando pré-requisitos..."

    exit 1

fi# Verificar se cluster está rodando

echo "✅ PostgreSQL OK"if ! k3d cluster list k3d-cluster 2>/dev/null | grep -q "k3d-cluster"; then

    echo "❌ ERRO: Cluster k3d não está rodando!"

# Verificar Redis    echo ""

if ! kubectl get pods -n redis -l app=redis 2>/dev/null | grep -q "Running"; then    echo "📝 Inicie a infraestrutura primeiro:"

    echo "❌ Redis não está rodando no namespace 'redis'"    echo "   ./infra/scripts/9.start-infra.sh"

    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"    echo ""

    exit 1    exit 1

fifi

echo "✅ Redis OK"

# Verificar se PostgreSQL está rodando

echo "✅ Dependências verificadas!"if ! kubectl get pods | grep -q "postgres.*Running"; then

    echo "❌ ERRO: PostgreSQL não está rodando!"

# =================================================================    echo ""

# 3. DEPLOY DO N8N    echo "📝 Inicie a infraestrutura primeiro:"

# =================================================================    echo "   ./infra/scripts/9.start-infra.sh"

    echo ""

# Verificar se n8n está rodando    exit 1

if ! kubectl get pods -n n8n -l app=n8n 2>/dev/null | grep -q "Running"; thenfi

    echo "📱 n8n não está rodando - fazendo deploy..."

    "$PROJECT_ROOT/k8s/apps/n8n/scripts/1.deploy-n8n.sh"# Verificar se n8n secret existe

    if [ ! -f "k8s/apps/n8n/n8n-secret-db.yaml" ]; then

    echo "⏳ Aguardando n8n ficar pronto..."    echo "❌ ERRO: Arquivo n8n-secret-db.yaml não encontrado!"

    kubectl wait --for=condition=ready pod -l app=n8n -n n8n --timeout=300s    echo ""

else    echo "📝 Configure as credenciais primeiro:"

    echo "✅ n8n já está rodando!"    echo "   cd $PROJECT_ROOT"

fi    echo "   cp k8s/apps/n8n/n8n-secret-db.yaml.template \\"

    echo "      k8s/apps/n8n/n8n-secret-db.yaml"

# =================================================================    echo ""

# 4. CONFIGURAR HOSTS (se necessário)    echo "   Depois edite o arquivo e substitua YOUR_POSTGRES_ADMIN_PASSWORD_HERE"

# =================================================================    echo "📖 Veja detalhes em: README-SECURITY.md"

N8N_DOMAIN="n8n.local.127.0.0.1.nip.io"    exit 1

fi

if ! grep -q "$N8N_DOMAIN" /etc/hosts; then

    echo "🌐 Configurando /etc/hosts..."if grep -q "YOUR_POSTGRES_ADMIN_PASSWORD_HERE" k8s/apps/n8n/n8n-secret-db.yaml; then

    echo '127.0.0.1 n8n.local.127.0.0.1.nip.io' | sudo tee -a /etc/hosts    echo "❌ ERRO: Senha não configurada em n8n-secret-db.yaml"

fi    echo ""

    echo "📝 Edite o arquivo e substitua YOUR_POSTGRES_ADMIN_PASSWORD_HERE por uma senha real"

echo ""    echo "💡 Use a MESMA senha do postgres-secret-admin.yaml"

echo "🎉 n8n pronto!"    echo ""

echo ""    exit 1

echo "🔗 Acesso HTTPS: https://n8n.local.127.0.0.1.nip.io:8443"fi

echo ""

echo "⚠️  No browser: Clique 'Avançado' → 'Continuar' no aviso de certificado"echo "✅ Pré-requisitos verificados!"

echo ""

echo "📊 Recursos configurados:"# =================================================================

echo "   n8n (namespace: n8n):"# 2. DEPLOY DO N8N

echo "   - CPU: 200m request / 1000m limit"# =================================================================

echo "   - RAM: 512Mi request / 1536Mi limit"

echo "   - HPA: 1-3 replicas"# Verificar se Redis está rodando (dependência do n8n)

echo "   PostgreSQL (namespace: postgres):"if ! kubectl get pods -n n8n -l app=redis 2>/dev/null | grep -q "Running"; then

echo "   - Shared database infrastructure"    echo "🔴 Redis cache não está rodando - necessário para n8n"

echo "   Redis Cache (namespace: redis):"    echo "📱 Fazendo deploy completo do n8n + Redis..."

echo "   - Shared cache infrastructure (DB 0 para n8n)"    "$PROJECT_ROOT/k8s/apps/n8n/scripts/1.deploy-n8n.sh"

echo ""    
    echo "⏳ Aguardando serviços ficarem prontos..."
    kubectl wait --for=condition=ready pod -l app=redis -n n8n --timeout=300s
    kubectl wait --for=condition=ready pod -l app=n8n -n n8n --timeout=300s
elif ! kubectl get pods -n n8n -l app=n8n 2>/dev/null | grep -q "Running"; then
    echo "� n8n não está rodando mas Redis está OK"
    echo "�📱 Fazendo deploy do n8n..."
    "$PROJECT_ROOT/k8s/apps/n8n/scripts/1.deploy-n8n.sh"
    
    echo "⏳ Aguardando n8n ficar pronto..."
    kubectl wait --for=condition=ready pod -l app=n8n -n n8n --timeout=300s
else
    echo "✅ n8n + Redis já estão rodando!"
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
echo "   n8n (namespace: n8n):"
echo "   - CPU: 200m request / 1000m limit"
echo "   - RAM: 512Mi request / 1536Mi limit"
echo "   - HPA: 1-3 replicas"
echo "   PostgreSQL (namespace: postgres):"
echo "   - Shared database infrastructure"
echo "   Redis Cache (namespace: redis):"
echo "   - Shared cache infrastructure (DB 0 para n8n)"
echo ""