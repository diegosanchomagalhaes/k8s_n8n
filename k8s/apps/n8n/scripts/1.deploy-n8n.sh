#!/bin/bash
set -e

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/8] Criando namespace do n8n ========"
kubectl apply -f ./k8s/apps/n8n/n8n-namespace.yaml

echo "======== [2/8] Criando PVC para persistência ========"
kubectl apply -f ./k8s/apps/n8n/n8n-pvc.yaml

echo "======== [3/8] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/n8n/n8n-secret-db.yaml

echo "======== [4/8] Criando Deployment ========"
kubectl apply -f ./k8s/apps/n8n/n8n-deployment.yaml

echo "======== [5/8] Criando Service ========"
kubectl apply -f ./k8s/apps/n8n/n8n-service.yaml

echo "======== [6/8] Criando HPA (Horizontal Pod Autoscaler) ========"
kubectl apply -f ./k8s/apps/n8n/n8n-hpa.yaml

echo "======== [7/8] Criando Certificate ========"
kubectl apply -f ./k8s/apps/n8n/n8n-certificate.yaml

echo "======== [8/8] Criando Ingress ========"
kubectl apply -f ./k8s/apps/n8n/n8n-ingress.yaml

echo "[INFO] Aguardando n8n ficar pronto..."
kubectl rollout status deployment/n8n -n n8n

echo "======== n8n implantado com sucesso ========"
echo "Acesse: https://n8n.local.127.0.0.1.nip.io"