#!/bin/bash
set -e

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Criando namespace do Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-namespace.yaml

echo "======== [2/7] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/grafana/grafana-secret-db.yaml

echo "======== [3/7] Criando PVCs Grafana (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/grafana/grafana-pvc.yaml

echo "======== [4/7] Verificando dependências (PostgreSQL) ========"
echo "  → Verificando PostgreSQL..."
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ PostgreSQL OK"

echo "======== [4.1/7] Criando database 'grafana' no PostgreSQL ========"
# Criar database grafana se não existir
kubectl exec -n postgres postgres-0 -- psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'grafana'" | grep -q 1 || \
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE grafana;"

# Criar usuário grafana se não existir
kubectl exec -n postgres postgres-0 -- psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = 'grafana'" | grep -q 1 || \
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE USER grafana WITH PASSWORD 'Grafana_Db_Password_2025_K8s_10243769';"

# Dar permissões
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;"
echo "  ✅ Database 'grafana' criado/configurado"

echo "======== [6/9] Criando Deployment Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-deployment.yaml

echo "======== [7/9] Criando Service Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-service.yaml

echo "======== [8/9] Criando HPA (Horizontal Pod Autoscaler) ========"
kubectl apply -f ./k8s/apps/grafana/grafana-hpa.yaml

echo "======== [5/7] Criando TLS Certificate ========"
kubectl apply -f ./k8s/apps/grafana/grafana-certificate.yaml

echo "======== [6/7] Deployando Grafana (Service + HPA + Deployment + Ingress) ========"
kubectl apply -f ./k8s/apps/grafana/grafana-service.yaml
kubectl apply -f ./k8s/apps/grafana/grafana-hpa.yaml
kubectl apply -f ./k8s/apps/grafana/grafana-deployment.yaml
kubectl apply -f ./k8s/apps/grafana/grafana-ingress.yaml

echo "[INFO] Aguardando Grafana ficar pronto..."
kubectl rollout status deployment/grafana -n grafana

echo "======== [7/7] Configurando hosts automaticamente ========"
GRAFANA_DOMAIN="grafana.local.127.0.0.1.nip.io"

if ! grep -q "$GRAFANA_DOMAIN" /etc/hosts; then
    echo "[INFO] Adicionando $GRAFANA_DOMAIN ao /etc/hosts..."
    echo "127.0.0.1 $GRAFANA_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "[OK] Domínio $GRAFANA_DOMAIN adicionado ao /etc/hosts"
else
    echo "[OK] Domínio $GRAFANA_DOMAIN já configurado no /etc/hosts"
fi

echo ""
echo "======== Grafana implantado com sucesso ========"
echo "🎉 Acesse: https://grafana.local.127.0.0.1.nip.io:8443"
echo "🔐 Login: admin / Admin_Grafana_2025_K8s_10243769"
echo "🔒 TLS/HTTPS habilitado via cert-manager"
echo "🗄️ PostgreSQL database configurado"
echo "📊 HPA configurado para auto-scaling"
echo ""
echo "⚠️  IMPORTANTE: Use a porta 8443 para acesso HTTPS"
echo "   Cluster k3d mapeia 443 -> 8443 no host"
echo ""
echo "🔧 Próximos passos:"
echo "   1. Acesse o Grafana e configure data sources"
echo "   2. Importe dashboards para monitoramento"
echo "   3. Configure alertas se necessário"