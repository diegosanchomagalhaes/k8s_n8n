#!/bin/bash
set -e

# Detectar diretório do projeto automaticamente
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== Criando PostgreSQL na infra ========"

echo "[1/3] Aplicando PV/PVC..."
kubectl apply -f infra/postgres/postgres-pv.yaml

echo "[2/3] Aplicando Secret admin..."
kubectl apply -f infra/postgres/postgres-secret-admin.yaml

echo "[3/3] Aplicando StatefulSet + Service..."
kubectl apply -f infra/postgres/postgres.yaml

echo "[INFO] Aguardando PostgreSQL ficar pronto..."
kubectl rollout status statefulset/postgres -n default

echo "======== PostgreSQL pronto no namespace default ========"
echo "Host interno: postgres.default.svc.cluster.local:5432"