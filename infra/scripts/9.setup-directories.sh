#!/bin/bash
set -e

echo "📂 Criando nova estrutura de diretórios organizada..."

# Diretório base do cluster
CLUSTER_BASE="/mnt/e/cluster"

# Criar estrutura de diretórios
echo "🗂️ Criando diretórios base..."
mkdir -p "$CLUSTER_BASE/postgresql"
mkdir -p "$CLUSTER_BASE/postgresql/backup"
mkdir -p "$CLUSTER_BASE/pvc"
mkdir -p "$CLUSTER_BASE/pvc/backup"

echo "🏗️ Criando subdiretórios para aplicações..."

# Diretórios específicos do PostgreSQL
mkdir -p "$CLUSTER_BASE/postgresql/n8n"
mkdir -p "$CLUSTER_BASE/postgresql/backup/n8n"

# Diretórios específicos de PVC
mkdir -p "$CLUSTER_BASE/pvc/n8n"
mkdir -p "$CLUSTER_BASE/pvc/backup/n8n"

# Definir permissões adequadas
echo "🔐 Configurando permissões..."
chmod -R 755 "$CLUSTER_BASE"

# Verificar estrutura criada
echo "✅ Estrutura criada com sucesso!"
echo ""
echo "📋 Nova estrutura de diretórios:"
tree "$CLUSTER_BASE" 2>/dev/null || find "$CLUSTER_BASE" -type d | sort

echo ""
echo "🎯 Próximos passos:"
echo "1. Execute o destroy da infraestrutura atual"
echo "2. Suba novamente com: ./infra/scripts/9.start-infra.sh"
echo "3. Deploy do n8n com: ./k8s/apps/n8n/scripts/1.deploy-n8n.sh"

echo ""
echo "💡 Os novos locais serão:"
echo "   - PostgreSQL data: $CLUSTER_BASE/postgresql/"
echo "   - PVC data: $CLUSTER_BASE/pvc/"
echo "   - DB backups: $CLUSTER_BASE/postgresql/backup/"
echo "   - PVC backups: $CLUSTER_BASE/pvc/backup/"