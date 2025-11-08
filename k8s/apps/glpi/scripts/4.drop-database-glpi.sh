echo '🔌 Conectando ao MariaDB...'
#!/bin/bash
set -euo pipefail

echo "======== Removendo banco de dados do GLPI ========"
echo ""

# Obter dados de conexão do secret (GLPI usa MariaDB). Se a chave não existir, usar valores padrão.
DB_HOST=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_MARIADB_HOST}' 2>/dev/null | base64 -d 2>/dev/null || true)
DB_PORT=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_MARIADB_PORT}' 2>/dev/null | base64 -d 2>/dev/null || true)
DB_USER=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_MARIADB_USER}' 2>/dev/null | base64 -d 2>/dev/null || true)
DB_PASSWORD=$(kubectl get secret glpi-db-secret -n glpi -o jsonpath='{.data.DB_MARIADB_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null || true)

DB_HOST=${DB_HOST:-mariadb.mariadb.svc.cluster.local}
DB_PORT=${DB_PORT:-3306}
DB_USER=${DB_USER:-glpi}
DB_PASSWORD=${DB_PASSWORD:-}

# Obter credenciais administrativas do MariaDB (secret criado pela infra)
ADMIN_USER=root
ADMIN_PASSWORD=$(kubectl get secret mariadb-admin-secret -n mariadb -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null || true)
ADMIN_PASSWORD=${ADMIN_PASSWORD:-root}

echo "🔍 Verificando se o banco 'glpi' existe..."

# Criar pod temporário para executar comandos no MariaDB. Passamos as variáveis como env para evitar expansões
kubectl run temp-mariadb-glpi --rm -i --tty --restart=Never --image=mariadb:12.0.2 \
    --env="DB_HOST=${DB_HOST}" --env="DB_PORT=${DB_PORT}" --env="DB_USER=${DB_USER}" --env="DB_PASSWORD=${DB_PASSWORD}" \
    --env="ADMIN_USER=${ADMIN_USER}" --env="ADMIN_PASSWORD=${ADMIN_PASSWORD}" -- bash -ec '
echo "🔌 Conectando ao MariaDB em ${DB_HOST}:${DB_PORT}..."
# Detectar cliente disponível
if command -v mysql >/dev/null 2>&1; then
    CLIENT="mysql"
elif command -v mariadb >/dev/null 2>&1; then
    CLIENT="mariadb"
else
    echo "❌ Nenhum cliente MySQL/MariaDB encontrado na imagem." >&2
    exit 2
fi

# Função para executar comando SQL com flags longas (para evitar parsing de -p sem valor)
run_sql() {
    local user="$1"; shift
    local pass="$1"; shift
    local sql="$*"
    "$CLIENT" --host="${DB_HOST}" --port="${DB_PORT}" --user="$user" --password="$pass" -e "$sql"
}

# Primeiro tentamos com as credenciais do app (glpi). Se falhar por acesso negado, tentamos com admin.
if run_sql "${DB_USER}" "${DB_PASSWORD}" "SHOW DATABASES;" 2>/tmp/db_check.err | grep -qw glpi; then
    echo "🗑️  Removendo banco de dados glpi com usuário ${DB_USER}..."
    run_sql "${DB_USER}" "${DB_PASSWORD}" "DROP DATABASE IF EXISTS glpi;"
    echo "✅ Banco de dados glpi removido com sucesso!"
else
    if grep -q "Access denied" /tmp/db_check.err 2>/dev/null; then
        echo "⚠️  Acesso negado com ${DB_USER}, tentando com usuário admin..."
        if run_sql "${ADMIN_USER}" "${ADMIN_PASSWORD}" "SHOW DATABASES;" | grep -qw glpi; then
            echo "🗑️  Removendo banco de dados glpi com usuário admin ${ADMIN_USER}..."
            run_sql "${ADMIN_USER}" "${ADMIN_PASSWORD}" "DROP DATABASE IF EXISTS glpi;"
            echo "✅ Banco de dados glpi removido com sucesso (admin)!"
        else
            echo "⚠️  Banco de dados glpi não encontrado mesmo com usuário admin"
        fi
    else
        echo "⚠️  Banco de dados glpi não encontrado"
    fi
fi
'

echo ""
echo "✅ Operação de remoção do banco concluída!"