#!/bin/bash
set -e

echo "======== Removendo banco de dados do GLPI ========"
echo ""

# Obter dados de conexão do secret
DB_HOST=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_POSTGRESDB_HOST}' | base64 -d 2>/dev/null || echo "postgres.postgres.svc.cluster.local")
DB_PORT=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_POSTGRESDB_PORT}' | base64 -d 2>/dev/null || echo "5432")
DB_USER=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_POSTGRESDB_USER}' | base64 -d 2>/dev/null || echo "postgres")
DB_PASSWORD=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_POSTGRESDB_PASSWORD}' | base64 -d 2>/dev/null || echo "postgres")

echo "🔍 Verificando se o banco 'glpi' existe..."

# Criar pod temporário para executar comandos no PostgreSQL
kubectl run temp-postgres-glpi --rm -i --tty --restart=Never --image=postgres:16 --env="PGPASSWORD=$DB_PASSWORD" -- bash -c "
echo '🔌 Conectando ao PostgreSQL...'
if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -lqt | cut -d \| -f 1 | grep -qw glpi; then
    echo '🗑️  Removendo banco de dados glpi...'
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c 'DROP DATABASE IF EXISTS glpi;'
    echo '✅ Banco de dados glpi removido com sucesso!'
else
    echo '⚠️  Banco de dados glpi não encontrado'
fi
"

echo ""
echo "✅ Operação de remoção do banco concluída!"