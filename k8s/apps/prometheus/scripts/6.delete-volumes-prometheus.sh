#!/bin/bash

# Script para deletar todos os volumes (PVs e PVCs) do Prometheus
# Usado quando é necessário recriar volumes com configurações diferentes

set -e

echo "🗑️ Deletando volumes do Prometheus..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======== [1/4] Parando deployment Prometheus ========${NC}"
kubectl scale deployment prometheus --replicas=0 -n prometheus 2>/dev/null || echo "Deployment prometheus não encontrado ou já parado"

echo -e "${YELLOW}======== [2/4] Deletando PVCs Prometheus ========${NC}"
kubectl delete pvc prometheus-pvc -n prometheus 2>/dev/null || echo "PVC prometheus-pvc não encontrado"
kubectl delete pvc prometheus-config-pvc -n prometheus 2>/dev/null || echo "PVC prometheus-config-pvc não encontrado"

echo -e "${YELLOW}======== [3/4] Deletando PVs Prometheus ========${NC}"
kubectl delete pv prometheus-pv-hostpath 2>/dev/null || echo "PV prometheus-pv-hostpath não encontrado"
kubectl delete pv prometheus-config-pv-hostpath 2>/dev/null || echo "PV prometheus-config-pv-hostpath não encontrado"

echo -e "${YELLOW}======== [4/4] Verificando limpeza ========${NC}"
echo "PVs restantes relacionados ao Prometheus:"
kubectl get pv | grep prometheus || echo "Nenhum PV do Prometheus encontrado ✅"

echo "PVCs restantes no namespace prometheus:"
kubectl get pvc -n prometheus || echo "Nenhum PVC no namespace prometheus ✅"

echo -e "${GREEN}🎉 Volumes do Prometheus deletados com sucesso!${NC}"
echo ""
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "1. Corrigir os caminhos nos arquivos prometheus-pv-hostpath.yaml"
echo "2. Executar: ./k8s/apps/prometheus/scripts/1.deploy-prometheus.sh"
echo "3. Ou usar: ./k8s/apps/prometheus/scripts/3.start-prometheus.sh"