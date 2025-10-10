#!/bin/bash
set -e

# Script para restart/recriar o Grafana mantendo dados

echo "🔄 Reiniciando Grafana..."

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/3] Parando Grafana (mantendo dados) ========"
kubectl delete deployment grafana -n grafana --ignore-not-found
kubectl delete pod -l app=grafana -n grafana --ignore-not-found

echo "======== [2/3] Aguardando pods terminarem ========"
kubectl wait --for=delete pod -l app=grafana -n grafana --timeout=120s 2>/dev/null || true

echo "======== [3/3] Recriando Grafana ========"
kubectl apply -f ./k8s/apps/grafana/grafana-deployment.yaml

echo "[INFO] Aguardando Grafana ficar pronto..."
kubectl rollout status deployment/grafana -n grafana

echo ""
echo "🎉 Grafana reiniciado com sucesso!"
echo "📊 Acesse: https://grafana.local.127.0.0.1.nip.io:8443"
echo "💾 Todos os dados e configurações foram preservados"

# Mostrar status
echo ""
echo "📋 Status dos pods:"
kubectl get pods -n grafana -l app=grafana

echo ""
echo "🌐 Status do serviço:"
kubectl get svc -n grafana grafana