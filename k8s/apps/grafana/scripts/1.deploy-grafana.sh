#!/bin/bash
set -e

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/9] Criando namespace do Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-namespace.yaml

echo "======== [2/9] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/grafana/grafana-secret-db.yaml

echo "======== [3/9] Criando PVCs Grafana (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/grafana/grafana-pvc.yaml

echo "======== [4/9] Verificando dependências (PostgreSQL) ========"
echo "  → Verificando PostgreSQL..."
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ PostgreSQL OK"

echo "======== [5/9] Criando database 'grafana' no PostgreSQL ========"
# Criar database grafana se não existir (Grafana usará credenciais postgres admin do secret)
kubectl exec -n postgres postgres-0 -- psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'grafana'" | grep -q 1 || \
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE grafana;"
echo "  ✅ Database 'grafana' criado (usando credenciais postgres admin do secret)"

echo "======== [6/9] Criando TLS Certificate ========"
kubectl apply -f ./k8s/apps/grafana/grafana-certificate.yaml

echo "======== [7/9] Criando Deployment Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-deployment.yaml

echo "======== [8/9] Criando Service Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-service.yaml

echo "======== [9/9] Criando HPA e Ingress ========"
kubectl apply -f ./k8s/apps/grafana/grafana-hpa.yaml
kubectl apply -f ./k8s/apps/grafana/grafana-ingress.yaml

echo "[INFO] Aguardando Grafana ficar pronto..."
kubectl rollout status deployment/grafana -n grafana

echo "======== [10/10] Configurando hosts automaticamente ========"
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
echo "🔐 Login: admin / admin (altere na primeira execução)"
echo "🔒 TLS/HTTPS habilitado via cert-manager"
echo "🗄️ PostgreSQL database configurado (credenciais no secret)"
echo "📊 HPA configurado para auto-scaling"
echo ""
echo "⚠️  IMPORTANTE: Use a porta 8443 para acesso HTTPS"
echo "   Cluster k3d mapeia 443 -> 8443 no host"
echo ""
echo "🔧 Próximos passos:"
echo "   1. Acesse o Grafana e configure data sources"
echo "   2. Importe dashboards para monitoramento"
echo "   3. Configure alertas se necessário"