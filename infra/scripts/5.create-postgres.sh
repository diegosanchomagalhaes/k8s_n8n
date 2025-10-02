#!/bin/bash
set -e

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Criando PostgreSQL na infra ========"

echo "[1/4] Criando namespace postgres..."
kubectl apply -f infra/postgres/postgres.yaml

echo "[2/4] Aplicando PV/PVC..."
kubectl apply -f infra/postgres/postgres-pv.yaml

echo "[3/4] Aplicando Secret admin..."
kubectl apply -f infra/postgres/postgres-secret-admin.yaml

echo "[4/4] Aguardando PostgreSQL ficar pronto..."
kubectl rollout status statefulset/postgres -n postgres

echo "======== PostgreSQL pronto no namespace postgres ========"
echo "Host interno: postgres.postgres.svc.cluster.local:5432"