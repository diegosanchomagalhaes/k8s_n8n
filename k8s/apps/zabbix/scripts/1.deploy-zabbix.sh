#!/bin/bash
set -e

# Ir para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

echo "======== [1/20] Criando namespace do Zabbix ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-namespace.yaml

echo "======== [2/20] Criando Secret de conexão com o banco ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-secret-db.yaml

echo "======== [3/20] Criando PVs Zabbix (Persistent Volumes) ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-pv-hostpath.yaml

echo "======== [4/20] Criando PVCs Zabbix (Persistent Volume Claims) ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-pvc.yaml

echo "======== [5/20] Verificando dependências (PostgreSQL, MariaDB e Redis) ========"
echo "  → Verificando PostgreSQL..."
if ! kubectl get pods -n postgres -l app=postgres 2>/dev/null | grep -q "Running"; then
    echo "❌ PostgreSQL não está rodando no namespace 'postgres'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ PostgreSQL OK"

echo "  → Verificando MariaDB..."
if ! kubectl get pods -n mariadb -l app=mariadb 2>/dev/null | grep -q "Running"; then
    echo "❌ MariaDB não está rodando no namespace 'mariadb'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ MariaDB OK"

echo "  → Verificando Redis..."
if ! kubectl get pods -n redis -l app=redis 2>/dev/null | grep -q "Running"; then
    echo "❌ Redis não está rodando no namespace 'redis'"
    echo "📝 Execute: cd infra/scripts && ./10.start-infra.sh"
    exit 1
fi
echo "  ✅ Redis OK"

echo "======== [6/20] Criando database 'zabbix' no PostgreSQL ========"
# Criar database zabbix se não existir
kubectl exec -n postgres postgres-0 -- psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'zabbix'" | grep -q 1 || \
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE zabbix;"
echo "  ✅ Database 'zabbix' criado no PostgreSQL"

echo "======== [7/20] Criando database 'zabbix_proxy' no MariaDB ========"
# Criar database zabbix_proxy se não existir
kubectl exec -n mariadb mariadb-0 -- mariadb -u root -pmariadb_root -e "CREATE DATABASE IF NOT EXISTS zabbix_proxy CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;" || true
echo "  ✅ Database 'zabbix_proxy' criado no MariaDB"

echo "======== [8/20] Criando TLS Certificate ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-certificate.yaml

echo "======== [9/20] Criando Deployment Zabbix Server ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-server-deployment.yaml

echo "======== [10/20] Criando Deployment Zabbix Web ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-web-deployment.yaml

echo "======== [11/20] Criando Services Zabbix ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-service.yaml

echo "======== [12/20] Aguardando Zabbix Server inicializar ========"
kubectl rollout status deployment/zabbix-server -n zabbix --timeout=300s

echo "======== [13/20] Criando Ingress Zabbix ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-ingress.yaml

echo "======== [14/20] Criando HPAs Zabbix (7 componentes) ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-server-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-proxy-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent2-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent-classic-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-java-gateway-hpa.yaml
kubectl apply -f ./k8s/apps/zabbix/zabbix-web-service-hpa.yaml

echo "======== [15/20] Criando Zabbix Agent2 Deployment ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent2-deployment.yaml

echo "======== [16/20] Criando Zabbix Agent Classic Deployment ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-agent-classic-deployment.yaml

echo "======== [17/20] Criando Zabbix Java Gateway ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-java-gateway-deployment.yaml

echo "======== [18/20] Criando Zabbix Web Service ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-web-service-deployment.yaml

echo "======== [19/20] Criando Zabbix Proxy ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-proxy-deployment.yaml

echo "======== [20/20] Criando Zabbix SNMP Traps ========"
kubectl apply -f ./k8s/apps/zabbix/zabbix-snmptraps-deployment.yaml

echo ""
echo "✅ Deploy concluído!"
echo "📊 Aguardando pods ficarem prontos..."

kubectl wait --for=condition=ready pod -l app=zabbix -n zabbix --timeout=300s || true

echo ""
echo "🎉 Zabbix 7.4.5 implantado com sucesso!"
echo ""
echo "📋 Informações de Acesso:"
echo "   🌐 URL: https://zabbix.local.127.0.0.1.nip.io:8443"
echo "   👤 Usuário: Admin"
echo "   🔑 Senha: zabbix"
echo "   ⚠️  IMPORTANTE: Altere a senha padrão após primeiro login!"
echo ""
echo "🗄️  Banco de dados:"
echo "   PostgreSQL - Database: zabbix (Server, Web)"
echo "   MariaDB - Database: zabbix_proxy (Proxy)"
echo ""
echo "💾 Cache Redis:"
echo "   Host: redis.redis.svc.cluster.local:6379"
echo "   DB: 4"
echo ""
echo "📊 Componentes implantados (9):"
echo "   ✅ Zabbix Server (PostgreSQL) - HPA 1-3 pods"
echo "   ✅ Zabbix Web (Nginx + PHP-FPM) - HPA 1-3 pods"
echo "   ✅ Zabbix Proxy (MariaDB) - HPA 1-3 pods"
echo "   ✅ Zabbix Agent2 (porta 10050) - HPA 1-3 pods"
echo "   ✅ Zabbix Agent Classic (porta 10061) - HPA 1-3 pods"
echo "   ✅ Zabbix Java Gateway - HPA 1-3 pods"
echo "   ✅ Zabbix Web Service - HPA 1-3 pods"
echo "   ✅ Zabbix SNMP Traps"
echo ""
echo "⚡ Auto-scaling habilitado:"
echo "   🔄 7 HPAs configurados (todos exceto SNMP Traps)"
echo "   📈 Escala: CPU > 70% ou Memória > 80%"
echo "   📉 Reduz: Após 5min de baixa utilização"
echo ""
echo "📊 Status dos componentes:"
kubectl get pods -n zabbix
echo ""
echo "🌐 Status dos services:"
kubectl get svc -n zabbix
