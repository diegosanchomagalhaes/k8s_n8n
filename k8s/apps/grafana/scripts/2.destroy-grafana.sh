#!/bin/bash
set -e

# Script para destruir completamente o Grafana

echo "🗑️ Destruindo Grafana..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Removendo Ingress ========"
kubectl delete -f ./k8s/apps/grafana/grafana-ingress.yaml --ignore-not-found

echo "======== [2/8] Removendo Certificate ========"
kubectl delete -f ./k8s/apps/grafana/grafana-certificate.yaml --ignore-not-found

echo "======== [3/8] Removendo HPA ========"
kubectl delete -f ./k8s/apps/grafana/grafana-hpa.yaml --ignore-not-found

echo "======== [4/8] Removendo Deployment ========"
kubectl delete -f ./k8s/apps/grafana/grafana-deployment.yaml --ignore-not-found

echo "======== [5/8] Removendo Service ========"
kubectl delete -f ./k8s/apps/grafana/grafana-service.yaml --ignore-not-found

echo "======== [6/8] Removendo PVCs e Secrets ========"
kubectl delete -f ./k8s/apps/grafana/grafana-pvc.yaml --ignore-not-found
kubectl delete -f ./k8s/apps/grafana/grafana-secret-db.yaml --ignore-not-found

echo "======== [7/8] Removendo Namespace (e todos os recursos) ========"
kubectl delete namespace grafana --ignore-not-found

echo "======== [8/8] Removendo entrada do /etc/hosts ========"
GRAFANA_DOMAIN="grafana.local.127.0.0.1.nip.io"
if grep -q "$GRAFANA_DOMAIN" /etc/hosts; then
    sudo sed -i "/$GRAFANA_DOMAIN/d" /etc/hosts
    echo "[OK] Entrada $GRAFANA_DOMAIN removida do /etc/hosts"
fi

echo ""
echo "🎉 Grafana removido completamente!"
echo "📝 Nota: O database 'grafana' no PostgreSQL não foi removido"
echo "   Para remover: kubectl exec -n postgres postgres-0 -- psql -U postgres -c 'DROP DATABASE grafana;'"
echo "   Para remover usuário: kubectl exec -n postgres postgres-0 -- psql -U postgres -c 'DROP USER grafana;'"