#!/bin/bash
set -e

# Script para remoção da aplicação Grafana
# MANTÉM: Base de dados PostgreSQL, Redis e dados PVC em hostPath

echo "🗑️ Removendo aplicação Grafana (mantendo dados persistentes)..."

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

echo "======== [6/8] Removendo Secrets ========"
kubectl delete -f ./k8s/apps/grafana/grafana-secret-db.yaml --ignore-not-found

echo "======== MANTENDO PVCs Grafana (dados persistentes) ========"
echo "  💾 PVCs mantidos para preservar dados em hostPath"
echo "  📁 Dados em: /home/dsm/cluster/pvc/grafana"

echo "======== [7/8] Removendo Namespace (e todos os recursos) ========"
kubectl delete namespace grafana --ignore-not-found

echo "======== [8/8] Removendo entrada do /etc/hosts ========"
GRAFANA_DOMAIN="grafana.local.127.0.0.1.nip.io"
if grep -q "$GRAFANA_DOMAIN" /etc/hosts; then
    sudo sed -i "/$GRAFANA_DOMAIN/d" /etc/hosts
    echo "[OK] Entrada $GRAFANA_DOMAIN removida do /etc/hosts"
fi

echo ""
echo "🎉 Aplicação Grafana removida!"
echo "� DADOS PRESERVADOS:"
echo "   📁 Base de dados grafana no PostgreSQL"
echo "   📁 PVCs em: /home/dsm/cluster/pvc/grafana"
echo "   🔴 Redis (compartilhado) mantido"
echo ""
echo "💡 Para recriar a aplicação:"
echo "   ./k8s/apps/grafana/scripts/3.start-grafana.sh"
echo ""
echo "🗑️ Para limpeza COMPLETA da base de dados:"
echo "   ./k8s/apps/grafana/scripts/4.drop-database-grafana.sh"
echo ""