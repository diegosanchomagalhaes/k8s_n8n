#!/bin/bash
set -e

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [0/9] Configurando hosts ========"
"$SCRIPT_DIR/0.setup-hosts-glpi.sh" add

echo "======== [1/9] Criando namespace do GLPI ========"
kubectl apply -f ./k8s/apps/glpi/glpi-namespace.yaml

echo "======== [2/8] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/glpi/glpi-secret-db.yaml

echo "======== [3/8] Criando PVs GLPI (Persistent Volumes) ========"
kubectl apply -f ./k8s/apps/glpi/glpi-pv-hostpath.yaml

echo "======== [4/8] Criando PVCs GLPI (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/glpi/glpi-pvc.yaml

echo "======== [5/9] Verificando dependências (MariaDB e Redis) ========"
echo "  → Verificando MariaDB..."
if ! kubectl get pods -n mariadb -l app=mariadb 2>/dev/null | grep -q "Running"; then
    echo "❌ MariaDB não está rodando no namespace 'mariadb'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ MariaDB OK"

echo "  → Verificando Redis..."
if ! kubectl get pods -n redis -l app=redis 2>/dev/null | grep -q "Running"; then
    echo "❌ Redis não está rodando no namespace 'redis'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ Redis OK"

echo "======== [6/9] Criando database 'glpi' no MariaDB ========"
# Criar database glpi se não existir
kubectl exec -n mariadb mariadb-0 -- mariadb -uroot -pmariadb_root -e "CREATE DATABASE IF NOT EXISTS glpi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || echo "Database já existe ou foi criada"

# Conceder permissões ao usuário mariadb
kubectl exec -n mariadb mariadb-0 -- mariadb -uroot -pmariadb_root -e "GRANT ALL PRIVILEGES ON glpi.* TO 'mariadb'@'%'; FLUSH PRIVILEGES;" 2>/dev/null
echo "  ✅ Database 'glpi' criado e permissões concedidas (usando credenciais root do MariaDB)"

echo "======== [7/9] Criando TLS Certificate ========"
kubectl apply -f ./k8s/apps/glpi/glpi-certificate.yaml

echo "======== [8/9] Criando Deployment GLPI ========"
kubectl apply -f ./k8s/apps/glpi/glpi-deployment.yaml

echo "======== [9/9] Criando Service GLPI ========"
kubectl apply -f ./k8s/apps/glpi/glpi-service.yaml

echo "======== [10/10] Criando HPA e Ingress ========"
kubectl apply -f ./k8s/apps/glpi/glpi-hpa.yaml
kubectl apply -f ./k8s/apps/glpi/glpi-ingress.yaml

echo ""
echo "🎉 GLPI deploy concluído com sucesso!"
echo ""
echo "📋 Status dos recursos:"
kubectl get all -n glpi
echo ""
echo "🌐 Acesso ao GLPI:"
echo "   → Local: https://glpi.local.127.0.0.1.nip.io"
echo "   → Credenciais padrão: glpi/glpi (admin/admin)"
echo ""
echo "⚠️  IMPORTANTE: Use a porta 8443 para acesso HTTPS"
echo "✅ Entrada DNS já configurada no /etc/hosts"