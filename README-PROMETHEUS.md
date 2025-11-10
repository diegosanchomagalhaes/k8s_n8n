# Prometheus - Sistema de Monitoramento e Alertas

> Documentação específica da aplicação Prometheus: deployment, configuração, uso e troubleshooting.

## 📋 Sumário

- [Visão Geral Prometheus](#-visão-geral-prometheus)
- [Arquitetura](#-arquitetura)
- [Configuração](#-configuração)
- [Deploy Prometheus](#-deploy-prometheus)
- [Acesso e Uso](#-acesso-e-uso)
- [Scaling e Performance](#-scaling-e-performance)
- [Backup e Restore](#-backup-e-restore)
- [Troubleshooting Prometheus](#-troubleshooting-prometheus)
- [Desenvolvimento Prometheus](#-desenvolvimento-prometheus)

## 🎯 Visão Geral Prometheus

**Prometheus** é um sistema de monitoramento e alerta de código aberto que coleta métricas de sistemas e aplicações através de HTTP polling.

### Características do Deploy

- **Versão**: Prometheus v3.7.3
- **Namespace**: `prometheus`
- **Banco de dados**: PostgreSQL (infraestrutura compartilhada)
- **Cache**: Redis 8.2.3 (database 3, para métricas)
- **Persistência**: hostPath em `/home/dsm/cluster/applications/prometheus/` (TRUE PaaS)
- **Acesso**: HTTPS via Ingress (porta 8443)
- **Scaling**: HPA (Horizontal Pod Autoscaler)
- **Certificados**: TLS via cert-manager
- **Volume Strategy**: Separated PV/PVC architecture
- **TSDB**: Time Series Database nativo com retenção de 30 dias

### 🔐 Acesso à Aplicação

| Item                | Valor                                                      | Observação                         |
| ------------------- | ---------------------------------------------------------- | ---------------------------------- |
| 🌐 **URL**          | `https://prometheus.local.127.0.0.1.nip.io:8443`           | Usar sempre HTTPS na porta 8443    |
| 👤 **Autenticação** | **🔓 SEM AUTENTICAÇÃO**                                    | Prometheus não possui login padrão |
| 🔑 **Senha**        | Não requerida                                              | Acesso direto pela URL             |
| 💾 **Database**     | PostgreSQL 16 (`postgres.postgres.svc.cluster.local:5432`) | Database: `prometheus`             |
| 🗄️ **Cache**        | Redis 8.2.3 (`redis.redis.svc.cluster.local:6379`)         | Database: DB3                      |
| 📊 **TSDB**         | `/prometheus` (volume persistente)                         | Time Series Database para métricas |

> ⚠️ **IMPORTANTE**:
>
> - Prometheus **NÃO possui autenticação nativa** por padrão
> - Para ambientes de produção, considere adicionar autenticação via:
>   - Reverse proxy (Nginx, Traefik) com Basic Auth
>   - OAuth2 Proxy para SSO
>   - Network Policies do Kubernetes para restringir acesso
> - A porta 8443 é necessária (k3d mapeia 443→8443)
> - Aceite o certificado self-signed no navegador
> - **NÃO exponha Prometheus diretamente na internet pública sem autenticação!**

## 🏗 Arquitetura

### Componentes Prometheus

```
k8s/apps/prometheus/
├── prometheus-namespace.yaml          # Namespace dedicado
├── prometheus-secret-db.yaml          # Credenciais completas (DB + Redis)
├── prometheus-secret-db.yaml.template # Template seguro
├── prometheus-deployment.yaml         # Deployment Prometheus v3.7.3
├── prometheus-service.yaml           # Service ClusterIP
├── prometheus-hpa.yaml               # Auto-scaling (CPU + Memória)
├── prometheus-certificate.yaml       # Certificado TLS automático
├── prometheus-ingress.yaml           # Ingress HTTPS
├── prometheus-pvc.yaml               # Persistent Volume Claims
├── prometheus-pv-hostpath.yaml       # Persistent Volumes (hostPath)
├── prometheus-pv-hostpath.yaml.template # Template PV
└── scripts/
    ├── 0.setup-hosts-prometheus.sh   # Configuração hosts automática
    ├── 1.deploy-prometheus.sh        # Deploy completo Prometheus
    ├── 2.destroy-prometheus.sh       # Remove Prometheus (mantém dados)
    ├── 3.start-prometheus.sh         # Inicia Prometheus
    ├── 4.drop-database-prometheus.sh # Limpa database PostgreSQL
    ├── 5.restart-prometheus.sh       # Reinicia pods mantendo dados
    └── 6.delete-volumes-prometheus.sh # Remove volumes (DESTRUTIVO)
```

### Fluxo de Dados

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────────┐
│   Ingress       │────│  Prometheus  │────│  PostgreSQL 16      │
│  (HTTPS/TLS)    │    │   Service    │    │   (fsGroup: 999)    │
│ prometheus.     │    │ (Port: 9090) │    │ Database: prometheus│
│   local:8443    │    │ (fsGroup:    │    │   Port: 30432       │
└─────────────────┘    │   65534)     │    └─────────────────────┘
                       └──────────────┘
                              │
                       ┌──────────────────┐
                       │  Redis 8.2.3     │
                       │  Database: 3      │
                       │  (Cache/Métricas) │
                       └──────────────────┘
                              │
                    ┌─────────────────────────┐
                    │   Persistent Storage    │
                    │ /home/dsm/cluster/      │
                    │  applications/          │
                    │   prometheus/           │
                    │  ├── data/ (TSDB)       │
                    │  └── config/ (configs)  │
                    └─────────────────────────┘
```

## ⚙️ Configuração

### 1. **Configurar Credenciais (OBRIGATÓRIO)**

```bash
# Copiar template de credenciais
cp k8s/apps/prometheus/prometheus-secret-db.yaml.template \
   k8s/apps/prometheus/prometheus-secret-db.yaml

# Editar credenciais reais
nano k8s/apps/prometheus/prometheus-secret-db.yaml
```

**Template do Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: prometheus-db-secret
  namespace: prometheus
type: Opaque
stringData:
  # PostgreSQL Configuration (shared infrastructure)
  DB_POSTGRESDB_HOST: postgres.postgres.svc.cluster.local
  DB_POSTGRESDB_PORT: "5432"
  DB_POSTGRESDB_DATABASE: prometheus
  DB_POSTGRESDB_USER: postgres
  DB_POSTGRESDB_PASSWORD: SUA_SENHA_POSTGRES_AQUI

  # Redis Cache Configuration (Database 3 - dedicated for Prometheus)
  REDIS_HOST: redis.redis.svc.cluster.local
  REDIS_PORT: "6379"
  REDIS_PASSWORD: SUA_SENHA_REDIS_AQUI
  REDIS_DB: "3" # DB3 exclusively for Prometheus metrics cache
```

> 📝 **Redis Database**: Prometheus utiliza **Redis DB3** exclusivamente para cache de métricas e queries. Este database é separado dos outros aplicativos (n8n=DB0, Grafana=DB1, GLPI=DB2).

### 2. **Configuração do Prometheus.yml**

O arquivo `prometheus.yml` é criado automaticamente pelo init container com:

- **Scraping Kubernetes**: API servers, nodes, pods, services
- **Auto-discovery**: Pods e services com annotations
- **Retention**: 30 dias de dados TSDB
- **Storage**: 15GB máximo de dados

### 3. **Configuração de Targets**

Para adicionar novos targets, edite a configuração em:

```bash
# Acessar o pod
kubectl exec -n prometheus -it prometheus-xxx -- sh

# Editar configuração
vi /etc/prometheus/prometheus.yml

# Reload configuração (via API)
curl -X POST http://localhost:9090/-/reload
```

## 🚀 Deploy Prometheus

### **Opção 1: Deploy Automático (Recomendado)**

```bash
# Deploy completo com verificações
./k8s/apps/prometheus/scripts/3.start-prometheus.sh
```

### **Opção 2: Deploy Manual**

```bash
# 1. Deploy passo a passo
./k8s/apps/prometheus/scripts/1.deploy-prometheus.sh

# 2. Configurar hosts (opcional)
./k8s/apps/prometheus/scripts/0.setup-hosts-prometheus.sh
```

### **Verificação do Deploy**

```bash
# Status dos pods
kubectl get pods -n prometheus

# Logs do Prometheus
kubectl logs -n prometheus -l app=prometheus -f

# Verificar ingress
kubectl get ingress -n prometheus

# Testar conectividade
curl -k https://prometheus.local.127.0.0.1.nip.io:8443/-/ready
```

## 🌐 Acesso e Uso

### **URLs de Acesso**

| Serviço           | URL                                                      | Descrição                      |
| ----------------- | -------------------------------------------------------- | ------------------------------ |
| **Prometheus UI** | https://prometheus.local.127.0.0.1.nip.io:8443           | Interface web principal        |
| **API**           | https://prometheus.local.127.0.0.1.nip.io:8443/api/v1/   | API para consultas             |
| **Metrics**       | https://prometheus.local.127.0.0.1.nip.io:8443/metrics   | Métricas do próprio Prometheus |
| **Health**        | https://prometheus.local.127.0.0.1.nip.io:8443/-/healthy | Health check                   |

### **Queries Úteis (PromQL)**

```promql
# CPU usage por pod
rate(container_cpu_usage_seconds_total[5m]) * 100

# Memória usage por namespace
sum(container_memory_usage_bytes) by (namespace)

# Pods por status
kube_pod_status_phase

# Requests HTTP rate
rate(prometheus_http_requests_total[5m])

# Storage usage
prometheus_tsdb_symbol_table_size_bytes / 1024 / 1024
```

### **Annotations para Auto-Discovery**

Para que o Prometheus colete métricas automaticamente:

```yaml
# Em pods
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"

# Em services
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

## 📊 Scaling e Performance

### **Horizontal Pod Autoscaler (HPA)**

```yaml
# Configuração atual
minReplicas: 1
maxReplicas: 2
CPU target: 80%
Memory target: 85%
```

### **Recursos Configurados**

```yaml
resources:
  requests:
    cpu: "200m"
    memory: "1Gi"
  limits:
    cpu: "2000m"
    memory: "4Gi"
```

### **Otimizações TSDB**

- **Retenção**: 30 dias
- **Tamanho máximo**: 15GB
- **Compactação**: Automática
- **Scrape interval**: 15s (global)

## 💾 Backup e Restore

### **Backup Automático**

```bash
# Backup manual dos dados TSDB
kubectl exec -n prometheus prometheus-xxx -- tar -czf /tmp/prometheus-backup.tar.gz /prometheus

# Copiar backup para host
kubectl cp prometheus/prometheus-xxx:/tmp/prometheus-backup.tar.gz ./prometheus-backup-$(date +%Y%m%d).tar.gz
```

### **Restore de Dados**

```bash
# 1. Parar Prometheus
kubectl scale deployment prometheus --replicas=0 -n prometheus

# 2. Restaurar dados
kubectl cp ./prometheus-backup.tar.gz prometheus/prometheus-xxx:/tmp/

# 3. Extrair no volume
kubectl exec -n prometheus prometheus-xxx -- tar -xzf /tmp/prometheus-backup.tar.gz -C /

# 4. Reiniciar
kubectl scale deployment prometheus --replicas=1 -n prometheus
```

## 🔧 Troubleshooting Prometheus

### **Problemas Comuns**

#### **1. Pod não inicia**

```bash
# Verificar logs
kubectl logs -n prometheus -l app=prometheus

# Verificar permissões
kubectl exec -n prometheus prometheus-xxx -- ls -la /prometheus
```

#### **2. Targets down**

```bash
# Verificar targets na UI
# Status → Targets

# Verificar conectividade de rede
kubectl exec -n prometheus prometheus-xxx -- nslookup kubernetes.default
```

#### **3. Performance lenta**

```bash
# Verificar uso de recursos
kubectl top pods -n prometheus

# Verificar tamanho TSDB
kubectl exec -n prometheus prometheus-xxx -- du -sh /prometheus
```

#### **4. Configuração inválida**

```bash
# Validar configuração
kubectl exec -n prometheus prometheus-xxx -- promtool check config /etc/prometheus/prometheus.yml

# Reload configuração
kubectl exec -n prometheus prometheus-xxx -- curl -X POST http://localhost:9090/-/reload
```

### **Scripts de Manutenção**

```bash
# Reiniciar Prometheus mantendo dados
./k8s/apps/prometheus/scripts/5.restart-prometheus.sh

# Limpar database PostgreSQL
./k8s/apps/prometheus/scripts/4.drop-database-prometheus.sh

# Remover tudo (CUIDADO!)
./k8s/apps/prometheus/scripts/2.destroy-prometheus.sh
```

## 🔨 Desenvolvimento Prometheus

### **Desenvolvimento Local**

```bash
# Port-forward para desenvolvimento
kubectl port-forward -n prometheus svc/prometheus 9090:9090

# Acessar localmente
curl http://localhost:9090/api/v1/query?query=up
```

### **Customizar Configuração**

```bash
# 1. Editar configuração
kubectl exec -n prometheus -it prometheus-xxx -- vi /etc/prometheus/prometheus.yml

# 2. Validar configuração
kubectl exec -n prometheus prometheus-xxx -- promtool check config /etc/prometheus/prometheus.yml

# 3. Reload configuração
kubectl exec -n prometheus prometheus-xxx -- curl -X POST http://localhost:9090/-/reload
```

### **Adicionar Rules**

```yaml
# Criar arquivo de rules
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: prometheus
data:
  rules.yml: |
    groups:
      - name: example
        rules:
          - alert: HighErrorRate
            expr: rate(http_requests_total{status="500"}[5m]) > 0.1
```

## 📚 Recursos Adicionais

### **Documentação Oficial**

- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Kubernetes SD](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)

### **Integrações**

- **Grafana**: Conectar como data source
- **Alertmanager**: Para alertas avançados
- **Exporters**: Node exporter, kube-state-metrics

### **Monitoramento da Stack**

- **Prometheus**: Monitora toda a infraestrutura K8s
- **Grafana**: Visualização das métricas coletadas
- **N8N**: Workflows podem usar métricas Prometheus
- **GLPI**: Integrações via API para inventário

---

> 📊 **Prometheus v3.7.3** executando no cluster k3d local com integração completa Kubernetes e PostgreSQL para metadados.
