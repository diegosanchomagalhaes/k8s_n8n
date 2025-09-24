#!/bin/bash
set -e

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/4] Removendo n8n ========"
kubectl delete namespace n8n --ignore-not-found

echo "======== [2/4] Removendo PostgreSQL ========"
kubectl delete -f infra/postgres/postgres.yaml --ignore-not-found
kubectl delete -f infra/postgres/postgres-secret-admin.yaml --ignore-not-found
kubectl delete -f infra/postgres/postgres-pv.yaml --ignore-not-found

echo "======== [3/4] Removendo cert-manager ========"
kubectl delete -f infra/cert-manager/cluster-issuer-selfsigned.yaml --ignore-not-found
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml --ignore-not-found

echo "======== [4/4] Removendo cluster k3d ========"
k3d cluster delete k3d-cluster

echo "======== Infraestrutura removida com sucesso! ========"