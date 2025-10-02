#!/bin/bash
set -e

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Removendo Ingress ========"
kubectl delete -f ./k8s/apps/n8n/n8n-ingress.yaml --ignore-not-found

echo "======== Removendo Certificate ========"
kubectl delete -f ./k8s/apps/n8n/n8n-certificate.yaml --ignore-not-found

echo "======== Removendo HPA ========"
kubectl delete -f ./k8s/apps/n8n/n8n-hpa.yaml --ignore-not-found

echo "======== Removendo Service ========"
kubectl delete -f ./k8s/apps/n8n/n8n-service.yaml --ignore-not-found

echo "======== Removendo Deployment n8n ========"
kubectl delete -f ./k8s/apps/n8n/n8n-deployment.yaml --ignore-not-found

echo "======== Redis e PostgreSQL mantidos (shared infrastructure) ========"
echo "  ℹ️ Redis e PostgreSQL não são removidos pois são recursos compartilhados"
echo "  📝 Para remover: cd infra/scripts && ./2.destroy-infra.sh"

echo "======== Removendo PVCs n8n ========"
kubectl delete -f ./k8s/apps/n8n/n8n-pvc.yaml --ignore-not-found

echo "======== Removendo Secret n8n ========"
kubectl delete -f ./k8s/apps/n8n/n8n-secret-db.yaml --ignore-not-found

echo "======== Removendo PVC ========"
kubectl delete -f ./k8s/apps/n8n/n8n-pvc.yaml --ignore-not-found

echo "======== Removendo Namespace ========"
kubectl delete -f ./k8s/apps/n8n/n8n-namespace.yaml --ignore-not-found

echo "======== n8n removido ========"