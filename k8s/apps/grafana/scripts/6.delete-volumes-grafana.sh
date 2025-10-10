#!/bin/bash

# Script para deletar todos os volumes (PVs e PVCs) do Grafana
# Usado quando é necessário recriar volumes com configurações diferentes

set -e

echo "🗑️ Deletando volumes do Grafana..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======== [1/4] Parando deployment Grafana ========${NC}"
kubectl scale deployment grafana --replicas=0 -n grafana 2>/dev/null || echo "Deployment grafana não encontrado ou já parado"

echo -e "${YELLOW}======== [2/4] Deletando PVCs Grafana ========${NC}"
kubectl delete pvc grafana-pvc -n grafana 2>/dev/null || echo "PVC grafana-pvc não encontrado"
kubectl delete pvc grafana-data-pvc -n grafana 2>/dev/null || echo "PVC grafana-data-pvc não encontrado"

echo -e "${YELLOW}======== [3/4] Deletando PVs Grafana ========${NC}"
kubectl delete pv grafana-pv-hostpath 2>/dev/null || echo "PV grafana-pv-hostpath não encontrado"
kubectl delete pv grafana-data-pv-hostpath 2>/dev/null || echo "PV grafana-data-pv-hostpath não encontrado"

echo -e "${YELLOW}======== [4/4] Verificando limpeza ========${NC}"
echo "PVs restantes relacionados ao Grafana:"
kubectl get pv | grep grafana || echo "Nenhum PV do Grafana encontrado ✅"

echo "PVCs restantes no namespace grafana:"
kubectl get pvc -n grafana || echo "Nenhum PVC no namespace grafana ✅"

echo -e "${GREEN}🎉 Volumes do Grafana deletados com sucesso!${NC}"
echo ""
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "1. Corrigir os caminhos nos arquivos grafana-pv-hostpath.yaml"
echo "2. Executar: ./k8s/apps/grafana/scripts/1.deploy-grafana.sh"
echo "3. Ou usar: ./k8s/apps/grafana/scripts/3.start-grafana.sh"