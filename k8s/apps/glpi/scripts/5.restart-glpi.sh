#!/bin/bash
set -e

echo "======== Reiniciando GLPI ========"

# Verificar se o deployment existe
if ! kubectl get deployment glpi -n glpi &>/dev/null; then
    echo "❌ Deployment do GLPI não encontrado"
    echo "📝 Execute primeiro: ./1.deploy-glpi.sh"
    exit 1
fi

echo "🔄 Reiniciando deployment do GLPI..."
kubectl rollout restart deployment/glpi -n glpi

echo "⏳ Aguardando rollout completar..."
kubectl rollout status deployment/glpi -n glpi --timeout=300s

echo ""
echo "📋 Status dos pods após reinicialização:"
kubectl get pods -n glpi -l app=glpi

echo ""
echo "🌐 GLPI disponível em:"
echo "   → https://glpi.local.127.0.0.1.nip.io"
echo ""
echo "✅ GLPI reiniciado com sucesso!"