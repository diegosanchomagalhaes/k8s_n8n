#!/bin/bash

# Script de destruição da infraestrutura base
# Destroi: cluster k3d, PostgreSQL, cert-manager
# MANTÉM: Dados persistentes em hostPath (PostgreSQL, Redis, PVCs)

echo "🗑️ Destruindo infraestrutura base (mantendo dados persistentes)..."

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/3] Removendo PostgreSQL ========"
kubectl delete -f infra/postgres/postgres.yaml --ignore-not-found
kubectl delete -f infra/postgres/postgres-secret-admin.yaml --ignore-not-found
kubectl delete -f infra/postgres/postgres-pv.yaml --ignore-not-found

echo "======== [2/3] Removendo cert-manager ========"
# Remover ClusterIssuer primeiro
kubectl delete -f infra/cert-manager/cluster-issuer-selfsigned.yaml --ignore-not-found
# Remover namespace cert-manager (isso remove tudo dentro)
kubectl delete namespace cert-manager --ignore-not-found
# Remover CRDs e recursos globais do cert-manager
echo "🗑️  Removendo cert-manager..."
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml --ignore-not-found

echo "======== [3/3] Removendo cluster k3d ========"
# Remove o cluster mas dados hostPath são preservados
k3d cluster delete k3d-cluster

echo ""
echo "🎉 Infraestrutura base removida!"
echo "💾 DADOS PRESERVADOS em:"
echo "   📁 /home/dsm/cluster/postgresql (dados PostgreSQL)"
echo "   � /home/dsm/cluster/redis (dados Redis)" 
echo "   📁 /home/dsm/cluster/pvc/n8n (dados n8n)"
echo "   📁 /home/dsm/cluster/pvc/grafana (dados Grafana)"
echo ""
echo "💡 Para iniciar novamente:"
echo "   ./infra/scripts/10.start-infra.sh"
echo ""