# 🏗️ Infraestrutura - k3d + PostgreSQL + Redis + cert-manager

> Configuração de infraestrutura base com persistência hostPath real (PaaS-like behavior)

## 📁 Estrutura

```
infra/
├── k3d/
│   └── k3d-config.yaml              # Configuração do cluster k3d com volume bind
├── postgres/
│   ├── postgres-pv-hostpath.yaml   # PV hostPath (/home/dsm/cluster/postgresql/data)
│   ├── postgres-pvc.yaml           # PVC separado para PostgreSQL
│   ├── postgres-secret-admin.yaml  # Credenciais admin PostgreSQL
│   └── postgres.yaml               # StatefulSet + Service (N8N + Grafana)
├── mariadb/                         # 🆕 NOVO - MariaDB para GLPI
│   ├── mariadb-pv-hostpath.yaml    # PV hostPath (/home/dsm/cluster/mariadb/)
│   ├── mariadb-pvc.yaml            # PVC separado para MariaDB
│   ├── mariadb-secret-admin.yaml   # Credenciais admin MariaDB
│   └── mariadb-deployment.yaml     # StatefulSet + Service (GLPI)
├── redis/
│   ├── redis-pv-hostpath.yaml      # PV hostPath (/home/dsm/cluster/redis)
│   ├── redis-pvc.yaml              # PVC separado para Redis
│   ├── redis-secret.yaml           # Credenciais Redis (compartilhado)
│   └── redis.yaml                  # Deployment + Service
├── scripts/
│   ├── 9.setup-directories.sh      # 📁 Criar estrutura /home/dsm/cluster/
│   ├── 10.create-postgres.sh       # 🐘 Deploy PostgreSQL com hostPath
│   ├── 11.create-redis.sh          # 🔴 Deploy Redis com hostPath
│   ├── 16.create-mariadb.sh        # 🗄️ Deploy MariaDB com hostPath (NOVO)
│   ├── 17.delete-mariadb.sh        # 🗑️ Remover MariaDB (NOVO)
│   └── 2.destroy-infra.sh          # 🗑️ Destruir infraestrutura completa
└── README.md                       # Este arquivo
```

## 🎯 **Persistência hostPath - TRUE PaaS**

### **✅ Implementação Atual**

**Cluster com volume bind real:**

```bash
k3d cluster create --volume "/home/dsm/cluster:/home/dsm/cluster@all"
```

**Estrutura de persistência:**

```
/home/dsm/cluster/
├── postgresql/data/        # PostgreSQL 16 - N8N + Grafana databases
├── mariadb/               # MariaDB 12.0.2 - GLPI database
├── redis/                 # Redis cache - Compartilhado (DB 0,1,2)
├── applications/
│   ├── n8n/              # N8N workflows e configurações
│   ├── grafana/          # Grafana dashboards e plugins
│   └── glpi/             # GLPI dados, configs, uploads (NOVO)
└── pvc/                  # Volumes tradicionais (fallback)
```

## 🏗️ **Arquitetura Dual-Database**

### **📊 PostgreSQL 16** (Aplicações Avançadas)

- **N8N**: Workflows complexos, JSON fields, arrays
- **Grafana**: Dashboards, alertas, métricas time-series
- **Resources**: JSONB, extensões, performance otimizada
- **fsGroup**: 999 (postgres user)

### **🗄️ MariaDB 12.0.2** (Aplicações Tradicionais)

- **GLPI**: Compatibilidade oficial MySQL/MariaDB
- **Resources**: Transações ACID, relações tradicionais
- **fsGroup**: 999 (systemd-coredump)

### **⚡ Redis 8.2.2** (Cache Compartilhado)

- **Database 0**: N8N cache e sessões
- **Database 1**: Grafana cache
- **Database 2**: GLPI cache e sessões

### **🔄 Arquitetura PV/PVC Separada**

- **PV (Persistent Volume)**: Define **ONDE** os dados são armazenados no host
- **PVC (Persistent Volume Claim)**: Define **COMO** as aplicações requisitam storage
- **Benefício**: Separação clara entre infraestrutura e aplicação

## 🚀 Scripts Principais

### **🌟 start-infra.sh - Deploy Completo**

```bash
./infra/scripts/9.start-infra.sh
```

**O que faz:**

1. ✅ Cria cluster k3d com volume bind real (`/home/dsm/cluster:/home/dsm/cluster@all`)
2. ✅ Configura estrutura de diretórios hostPath com permissões corretas
3. ✅ Deploy PostgreSQL 16 com persistência hostPath (20Gi) - fsGroup: 999
4. ✅ Deploy MariaDB 12.0.2 com persistência hostPath (20Gi) - fsGroup: 999
5. ✅ Deploy Redis 8.2.2 com persistência hostPath (5Gi)
6. ✅ Instala cert-manager v1.19.0
7. ✅ Configura ClusterIssuer para certificados self-signed
8. ✅ Verifica saúde de todos os componentes e permissões

**Portas mapeadas:**

- `8080:80` - HTTP (Traefik Ingress)
- `8443:443` - HTTPS (Traefik Ingress)
- `30432:30432` - PostgreSQL (NodePort)
- `30306:30306` - MariaDB (NodePort)
- `6379` - Redis (ClusterIP)

### **🗑️ destroy-infra.sh - Limpeza Completa**

```bash
./infra/scripts/2.destroy-infra.sh
```

**O que faz:**

1. ✅ Remove cert-manager e todos os certificados
2. ✅ Remove PostgreSQL (StatefulSet + PVC + PV)
3. ✅ Remove MariaDB (StatefulSet + PVC + PV)
4. ✅ Remove Redis (Deployment + PVC + PV)
5. ✅ Destroi cluster k3d completo
6. ⚠️ **Dados preservados**: `/home/dsm/cluster/` mantido para reuso
7. ✅ Remove Redis (Deployment + PVC + PV)
8. ✅ Destroi cluster k3d completo
9. ✅ **MANTÉM** dados em `/home/dsm/cluster/` (PaaS behavior)
10. ✅ Limpeza de volumes Docker

## 🔧 Configurações Importantes

### **k3d Cluster**

```yaml
# /infra/k3d/k3d-config.yaml
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: k3d-cluster
servers: 1
agents: 2
ports:
  - port: 8080:80 # HTTP
  - port: 8443:443 # HTTPS (⚠️ Porta 8443 para evitar sudo)
  - port: 30432:30432 # PostgreSQL NodePort
```

### **PostgreSQL**

- **Versão**: PostgreSQL 16
- **Storage**: 20Gi PersistentVolume
- **Acesso**: `localhost:30432`
- **Credenciais**: Definidas em `postgres-secret-admin.yaml`

### **cert-manager**

- **Versão**: v1.19.0
- **ClusterIssuer**: `k3d-selfsigned` (certificados self-signed)
- **Namespace**: `cert-manager`

## 🔐 Configuração de Credenciais

**Antes do primeiro uso:**

```bash
# Copie o template (se não existir)
cp infra/postgres/postgres-secret-admin.yaml.template \
   infra/postgres/postgres-secret-admin.yaml

# Edite e configure sua senha
nano infra/postgres/postgres-secret-admin.yaml
```

## 📊 Verificação de Status

```bash
# Verificar cluster
k3d cluster list

# Verificar PostgreSQL
kubectl get statefulset postgres -o wide
kubectl get svc postgres

# Verificar cert-manager
kubectl get pods -n cert-manager
kubectl get clusterissuer

# Testar conexão PostgreSQL
psql -h localhost -p 30432 -U admin -d postgres
```

## 🚨 Solução de Problemas

### **Porta 8443 vs 443**

**Por que 8443?**

- Portas < 1024 requerem privilégios root
- k3d mapeia `443 (cluster) → 8443 (host)`
- Evita `sudo` para execução do Docker

### **PostgreSQL não conecta**

```bash
# Verificar se o pod está rodando
kubectl get pods | grep postgres

# Verificar logs
kubectl logs postgres-0

# Testar porta
netstat -tulpn | grep 30432
```

### **cert-manager com problemas**

```bash
# Reinstalar cert-manager
kubectl delete namespace cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.0/cert-manager.yaml

# Verificar ClusterIssuer
kubectl get clusterissuer k3d-selfsigned -o yaml
```

## 🎯 Próximos Passos

Após executar a infraestrutura, deploy as aplicações:

```bash
# Deploy n8n com HTTPS/TLS
./k8s/apps/n8n/scripts/1.deploy-n8n.sh
```

> **💡 Esta infraestrutura serve de base para qualquer aplicação k8s que você queira rodar localmente!**
