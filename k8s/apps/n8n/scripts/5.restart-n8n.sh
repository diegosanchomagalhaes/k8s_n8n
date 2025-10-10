#!/bin/bash
set -e

# Script para restart/recriar o n8n mantendo dados

echo "🔄 Reiniciando n8n..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/3] Parando n8n (mantendo dados) ========"
kubectl delete deployment n8n -n n8n --ignore-not-found
kubectl delete pod -l app=n8n -n n8n --ignore-not-found

echo "======== [2/3] Aguardando pods terminarem ========"
kubectl wait --for=delete pod -l app=n8n -n n8n --timeout=120s 2>/dev/null || true

echo "======== [3/3] Recriando n8n ========"
kubectl apply -f ./k8s/apps/n8n/n8n-deployment.yaml

echo "[INFO] Aguardando n8n ficar pronto..."
kubectl rollout status deployment/n8n -n n8n

echo ""
echo "🎉 n8n reiniciado com sucesso!"
echo "🌐 Acesse: https://n8n.local.127.0.0.1.nip.io:8443"
echo "💾 Todos os dados e configurações foram preservados"

# Mostrar status
echo ""
echo "📋 Status dos pods:"
kubectl get pods -n n8n -l app=n8n

echo ""
echo "🌐 Status do serviço:"
kubectl get svc -n n8n n8n