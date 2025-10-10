#!/bin/bash

# Script para deletar todos os volumes (PVs e PVCs) do n8n
# Usado quando é necessário recriar volumes com configurações diferentes

set -e

echo "🗑️ Deletando volumes do n8n..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}======== [1/4] Parando deployment n8n ========${NC}"
kubectl scale deployment n8n --replicas=0 -n n8n 2>/dev/null || echo "Deployment n8n não encontrado ou já parado"

echo -e "${YELLOW}======== [2/4] Deletando PVCs n8n ========${NC}"
kubectl delete pvc n8n-pvc -n n8n 2>/dev/null || echo "PVC n8n-pvc não encontrado"
kubectl delete pvc n8n-data-pvc -n n8n 2>/dev/null || echo "PVC n8n-data-pvc não encontrado"

echo -e "${YELLOW}======== [3/4] Deletando PVs n8n ========${NC}"
kubectl delete pv n8n-pv-hostpath 2>/dev/null || echo "PV n8n-pv-hostpath não encontrado"
kubectl delete pv n8n-data-pv-hostpath 2>/dev/null || echo "PV n8n-data-pv-hostpath não encontrado"

echo -e "${YELLOW}======== [4/4] Verificando limpeza ========${NC}"
echo "PVs restantes relacionados ao n8n:"
kubectl get pv | grep n8n || echo "Nenhum PV do n8n encontrado ✅"

echo "PVCs restantes no namespace n8n:"
kubectl get pvc -n n8n || echo "Nenhum PVC no namespace n8n ✅"

echo -e "${GREEN}🎉 Volumes do n8n deletados com sucesso!${NC}"
echo ""
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "1. Corrigir os caminhos nos arquivos n8n-pv-hostpath.yaml"
echo "2. Executar: ./k8s/apps/n8n/scripts/1.deploy-n8n.sh"
echo "3. Ou usar: ./k8s/apps/n8n/scripts/3.start-n8n.sh"