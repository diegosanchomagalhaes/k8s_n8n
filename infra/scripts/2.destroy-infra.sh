#!/bin/bash

# Script de destruição da infraestrutura base
# Destroi: cluster k3d, PostgreSQL, cert-manager
# MANTÉM: Dados persistentes em hostPath (PostgreSQL, Redis, PVCs)

echo "🗑️ Destruindo infraestrutura base (mantendo dados persistentes)..."

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/4] Removendo aplicações (se ainda existirem) ========"
kubectl delete namespace n8n --ignore-not-found
kubectl delete namespace grafana --ignore-not-found

echo "======== [2/4] Removendo PostgreSQL ========"
kubectl delete -f infra/postgres/postgres.yaml --ignore-not-found
kubectl delete -f infra/postgres/postgres-secret-admin.yaml --ignore-not-found
echo "💾 MANTENDO: PVs e PVCs PostgreSQL (dados preservados)"

echo "======== [3/4] Removendo Redis ========"
kubectl delete -f infra/redis/redis.yaml --ignore-not-found
kubectl delete -f infra/redis/redis-secret.yaml --ignore-not-found
echo "💾 MANTENDO: PVs e PVCs Redis (dados preservados)"

echo "======== [4/4] Removendo cert-manager ========"
# Remover ClusterIssuer primeiro
kubectl delete -f infra/cert-manager/cluster-issuer-selfsigned.yaml --ignore-not-found
# Remover namespace cert-manager (isso remove tudo dentro)
kubectl delete namespace cert-manager --ignore-not-found
# Remover CRDs e recursos globais do cert-manager
echo "🗑️  Removendo cert-manager..."
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml --ignore-not-found

echo "======== [5/5] Removendo cluster k3d ========"
# Remove o cluster mas dados hostPath são preservados
k3d cluster delete k3d-cluster

echo ""
echo "🎉 Infraestrutura base removida!"
echo "💾 DADOS PRESERVADOS em:"
echo "   📁 /home/dsm/cluster/postgresql (databases: postgres, n8n, grafana)"
echo "   📁 /home/dsm/cluster/redis (cache: db0=n8n, db1=grafana)" 
echo "   📁 /home/dsm/cluster/applications/n8n/ (configurações e arquivos)"
echo "   📁 /home/dsm/cluster/applications/grafana/ (dados e logs)"
echo ""
echo "💡 Para recriar tudo:"
echo "   ./start-all.sh                    # Infraestrutura + aplicações"
echo "   ./infra/scripts/1.create-infra.sh # Somente infraestrutura"
echo ""