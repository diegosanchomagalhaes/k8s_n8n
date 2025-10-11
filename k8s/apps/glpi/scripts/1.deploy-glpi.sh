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

echo "======== [5/8] Verificando dependências (PostgreSQL + Redis) ========"
echo "  → Verificando PostgreSQL..."
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ PostgreSQL OK"

echo "  → Verificando Redis..."
if ! kubectl get pods -n redis -l app=redis 2>/dev/null | grep -q "Running"; then
    echo "❌ Redis não está rodando no namespace 'redis'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ Redis OK"

echo "======== [6/9] Criando database 'glpi' no PostgreSQL ========"
# Criar database glpi se não existir (GLPI usará credenciais postgres admin do secret)
kubectl exec -n postgres postgres-0 -- psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'glpi'" | grep -q 1 || \
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE glpi;"
echo "  ✅ Database 'glpi' criado (usando credenciais postgres admin do secret)"

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