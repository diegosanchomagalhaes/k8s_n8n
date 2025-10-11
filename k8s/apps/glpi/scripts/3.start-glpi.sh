#!/bin/bash
set -e

echo "======== Iniciando GLPI (pods parados) ========"

# Verificar se o deployment existe
if ! kubectl get deployment glpi -n glpi &>/dev/null; then
    echo "❌ Deployment do GLPI não encontrado"
    echo "📝 Execute primeiro: ./1.deploy-glpi.sh"
    exit 1
fi

# Verificar se está parado (0 réplicas)
CURRENT_REPLICAS=$(kubectl get deployment glpi -n glpi -o jsonpath='{.spec.replicas}')

if [ "$CURRENT_REPLICAS" -gt 0 ]; then
    echo "✅ GLPI já está rodando com $CURRENT_REPLICAS réplica(s)"
else
    echo "🚀 Iniciando GLPI..."
    kubectl scale deployment glpi --replicas=1 -n glpi
    
    echo "⏳ Aguardando pods ficarem prontos..."
    kubectl wait --for=condition=ready pod -l app=glpi -n glpi --timeout=300s
fi

echo ""
echo "📋 Status do GLPI:"
kubectl get pods -n glpi -l app=glpi
echo ""
echo "🌐 GLPI disponível em:"
echo "   → https://glpi.local.127.0.0.1.nip.io"
echo ""
echo "✅ GLPI iniciado com sucesso!"