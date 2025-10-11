#!/bin/bash

# Script de inicialização da infraestrutura base
# Para usar: ./start-infra.sh

echo "🏗️ Iniciando infraestrutura base..."

# =================================================================
# 0. DEFINIR DIRETÓRIO BASE DO PROJETO
# =================================================================
# Detectar se estamos no diretório correto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "📁 Diretório do projeto: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# =================================================================
# 1. VERIFICAR PRÉ-REQUISITOS
# =================================================================
echo "� Verificando pré-requisitos..."

# Verificar se k3d está instalado
if ! command -v k3d &> /dev/null; then
    echo "❌ ERRO: k3d não está instalado!"
    echo "📝 Instale k3d: https://k3d.io/v5.7.4/#installation"
    exit 1
fi

# Verificar se kubectl está instalado  
if ! command -v kubectl &> /dev/null; then
    echo "❌ ERRO: kubectl não está instalado!"
    echo "📝 Instale kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo "✅ Pré-requisitos atendidos!"

# =================================================================
# 1.5. PREPARAR ESTRUTURA DE DIRETÓRIOS
# =================================================================
echo "📂 Preparando estrutura de diretórios..."
if [ -f "$PROJECT_ROOT/infra/scripts/9.setup-directories.sh" ]; then
    "$PROJECT_ROOT/infra/scripts/9.setup-directories.sh"
else
    echo "⚠️ Script de setup de diretórios não encontrado, continuando..."
fi

# =================================================================
# 2. DEPLOY DA INFRAESTRUTURA
# =================================================================

# Verificar se k3d cluster está rodando
if ! k3d cluster list k3d-cluster 2>/dev/null | grep -q "running"; then
    echo "📦 Criando cluster k3d..."
    "$PROJECT_ROOT/infra/scripts/3.create-cluster.sh"
    
    echo "🗄️ Configurando PostgreSQL..."
    "$PROJECT_ROOT/infra/scripts/5.create-postgres.sh"
    
    echo "🗂️ Configurando MariaDB..."
    "$PROJECT_ROOT/infra/scripts/16.create-mariadb.sh"
    
    echo "🔴 Configurando Redis..."
    "$PROJECT_ROOT/infra/scripts/11.create-redis.sh"
    
    echo "🔒 Configurando cert-manager..."
    "$PROJECT_ROOT/infra/scripts/7.create-cert-manager.sh"
    
    echo "⏳ Aguardando infraestrutura ficar pronta..."
    kubectl wait --for=condition=ready pod -l app=postgres -n postgres --timeout=300s
    kubectl wait --for=condition=ready pod -l app=mariadb -n mariadb --timeout=300s
    kubectl wait --for=condition=ready pod -l app=redis -n redis --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=300s
else
    echo "✅ Cluster já está rodando!"
    
    # Verificar se PostgreSQL está rodando
    if ! kubectl get pods -n postgres 2>/dev/null | grep -q "postgres.*Running"; then
        echo "🗄️ Iniciando PostgreSQL..."
        "$PROJECT_ROOT/infra/scripts/5.create-postgres.sh"
        kubectl wait --for=condition=ready pod -l app=postgres -n postgres --timeout=180s
    else
        echo "✅ PostgreSQL já está rodando!"
    fi
    
    # Verificar se MariaDB está rodando
    if ! kubectl get pods -n mariadb 2>/dev/null | grep -q "mariadb.*Running"; then
        echo "🗂️ Iniciando MariaDB..."
        "$PROJECT_ROOT/infra/scripts/16.create-mariadb.sh"
        kubectl wait --for=condition=ready pod -l app=mariadb -n mariadb --timeout=180s
    else
        echo "✅ MariaDB já está rodando!"
    fi
    
    # Verificar se Redis está rodando
    if ! kubectl get pods -n redis 2>/dev/null | grep -q "redis.*Running"; then
        echo "🔴 Iniciando Redis..."
        "$PROJECT_ROOT/infra/scripts/11.create-redis.sh"
        kubectl wait --for=condition=ready pod -l app=redis -n redis --timeout=180s
    else
        echo "✅ Redis já está rodando!"
    fi
    
    # Verificar se cert-manager está rodando
    if ! kubectl get pods -n cert-manager 2>/dev/null | grep -q "Running"; then
        echo "🔒 Iniciando cert-manager..."
        "$PROJECT_ROOT/infra/scripts/7.create-cert-manager.sh"
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=cert-manager -n cert-manager --timeout=180s
    else
        echo "✅ cert-manager já está rodando!"
    fi
fi

echo ""
echo "🎉 Infraestrutura pronta!"
echo ""
echo "📦 Componentes disponíveis:"
echo "   - k3d cluster: k3d-cluster (hostPath: /home/dsm/cluster:/mnt/cluster)"
echo "   - PostgreSQL: postgres.postgres.svc.cluster.local:5432"
echo "   - MariaDB: mariadb.mariadb.svc.cluster.local:3306"
echo "   - Redis: redis.redis.svc.cluster.local:6379" 
echo "   - cert-manager: ClusterIssuer k3d-selfsigned"
echo ""
echo "💾 Dados persistentes em:"
echo "   - PostgreSQL: /home/dsm/cluster/postgresql/"
echo "   - MariaDB: /home/dsm/cluster/mariadb/"
echo "   - Redis: /home/dsm/cluster/redis/"
echo "   - Aplicações: /home/dsm/cluster/applications/"
echo ""
echo "🚀 Para iniciar aplicações, execute os scripts em k8s/apps/*/scripts/"
echo ""