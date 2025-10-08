#!/bin/bash

# Script de conveniência para inicializar infraestrutura + aplicações
# Para usar: ./start-all.sh [aplicacao]
# Exemplos:
#   ./start-all.sh          # Inicializa infra + todas as aplicações
#   ./start-all.sh n8n      # Inicializa infra + somente n8n
#   ./start-all.sh grafana  # Inicializa infra + somente grafana (futuro)

echo "🚀 Iniciando ambiente completo..."

# =================================================================
# 0. DEFINIR DIRETÓRIO BASE DO PROJETO
# =================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "📁 Diretório do projeto: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Parâmetro para aplicação específica
SPECIFIC_APP="$1"

# Lista de aplicações disponíveis
AVAILABLE_APPS=("n8n" "grafana")

# =================================================================
# FUNÇÃO: INICIAR UMA APLICAÇÃO
# =================================================================
start_single_app() {
    local app_name="$1"
    local app_script="$PROJECT_ROOT/k8s/apps/$app_name/scripts/3.start-$app_name.sh"
    
    if [ -f "$app_script" ]; then
        echo "🔄 Iniciando $app_name..."
        "$app_script"
        
        if [ $? -eq 0 ]; then
            echo "✅ $app_name iniciado com sucesso!"
        else
            echo "❌ Falha ao iniciar $app_name"
            return 1
        fi
    else
        echo "⚠️  Script não encontrado para $app_name: $app_script"
        return 1
    fi
}

# =================================================================
# 1. INICIAR INFRAESTRUTURA
# =================================================================
echo "🏗️ Passo 1: Infraestrutura base..."
"$PROJECT_ROOT/infra/scripts/10.start-infra.sh"

if [ $? -ne 0 ]; then
    echo "❌ Falha na inicialização da infraestrutura"
    exit 1
fi

echo ""
echo "✅ Infraestrutura pronta!"
echo ""

# =================================================================
# 2. INICIAR APLICAÇÕES
# =================================================================
if [ -n "$SPECIFIC_APP" ]; then
    # Verificar se a aplicação específica existe na lista
    if [[ " ${AVAILABLE_APPS[@]} " =~ " ${SPECIFIC_APP} " ]]; then
        echo "📱 Passo 2: Aplicação específica ($SPECIFIC_APP)..."
        start_single_app "$SPECIFIC_APP"
    else
        echo "❌ Aplicação '$SPECIFIC_APP' não encontrada!"
        echo "📋 Aplicações disponíveis: ${AVAILABLE_APPS[*]}"
        exit 1
    fi
else
    # Iniciar todas as aplicações disponíveis
    echo "📱 Passo 2: Todas as aplicações..."
    for app in "${AVAILABLE_APPS[@]}"; do
        start_single_app "$app"
    done
fi

# =================================================================
# 3. RESUMO FINAL
# =================================================================
echo ""
echo "🎉 Ambiente completo pronto!"
echo ""
echo "📋 Componentes da infraestrutura:"
echo "   ✅ k3d cluster"
echo "   ✅ PostgreSQL"
echo "   ✅ Redis"
echo "   ✅ cert-manager"
echo ""
echo "📱 Aplicações ativas:"

# Verificar quais aplicações estão rodando
for app in "${AVAILABLE_APPS[@]}"; do
    if kubectl get pods -n "$app" 2>/dev/null | grep -q "Running"; then
        case "$app" in
            "n8n")
                echo "   ✅ n8n - https://n8n.local.127.0.0.1.nip.io:8443"
                ;;
            "grafana")
                echo "   ✅ grafana - https://grafana.local.127.0.0.1.nip.io:8443"
                ;;
            *)
                echo "   ✅ $app"
                ;;
        esac
    else
        echo "   ⏸️  $app (não rodando)"
    fi
done

echo ""
echo "💡 Para iniciar aplicações específicas:"
echo "   ./start-all.sh n8n      # Somente n8n"
echo "   ./start-all.sh grafana  # Somente grafana"
echo ""