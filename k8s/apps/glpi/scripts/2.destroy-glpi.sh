#!/bin/bash
set -e

echo "======== Destruindo recursos do GLPI ========"
echo ""

echo "[1/6] Removendo Ingress e HPA..."
kubectl delete -f ./k8s/apps/glpi/glpi-ingress.yaml --ignore-not-found=true
kubectl delete -f ./k8s/apps/glpi/glpi-hpa.yaml --ignore-not-found=true

echo "[2/6] Removendo Service..."
kubectl delete -f ./k8s/apps/glpi/glpi-service.yaml --ignore-not-found=true

echo "[3/6] Removendo Deployment..."
kubectl delete -f ./k8s/apps/glpi/glpi-deployment.yaml --ignore-not-found=true

echo "[4/6] Removendo Certificate..."
kubectl delete -f ./k8s/apps/glpi/glpi-certificate.yaml --ignore-not-found=true

echo "[5/6] Removendo PVCs (Persistent Volume Claims)..."
kubectl delete -f ./k8s/apps/glpi/glpi-pvc.yaml --ignore-not-found=true

echo "[6/6] Removendo Secret..."
kubectl delete -f ./k8s/apps/glpi/glpi-secret-db.yaml --ignore-not-found=true

echo ""
echo "⚠️  ATENÇÃO: PVs (Persistent Volumes) mantidos para preservar dados"
echo "⚠️  Para remover PVs também, execute: ./6.delete-volumes-glpi.sh"
echo ""
echo "🗑️  GLPI destruído com sucesso!"
echo ""
echo "📋 Verificando recursos restantes:"
kubectl get all -n glpi 2>/dev/null || echo "   → Namespace limpo"