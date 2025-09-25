#!/bin/bash

# Script de destruição da infraestrutura base
# Destroi: cluster k3d, PostgreSQL, cert-manager
# Isso automaticamente remove todos os PVCs e bases de dados

echo "🗑️ Destruindo infraestrutura base..."

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
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml --ignore-not-found

echo "======== [3/3] Removendo cluster k3d ========"
# Isso remove automaticamente todos os PVCs e dados
k3d cluster delete k3d-cluster

echo "🎉 Infraestrutura base removida completamente!"
echo "📝 Todos os PVCs e dados foram removidos junto com o cluster"