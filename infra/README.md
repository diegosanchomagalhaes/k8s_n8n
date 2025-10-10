# 🏗️ Infraestrutura - k3d + PostgreSQL + Redis + cert-manager

> Configuração de infraestrutura base com persistência hostPath real (PaaS-like behavior)

## 📁 Estrutura

```
infra/
├── k3d/
│   └── k3d-config.yaml          # Configuração do cluster k3d com volume bind
├── postgres/
│   ├── postgres-pv-hostpath.yaml   # PV hostPath (/home/dsm/cluster/postgresql/data)
│   ├── postgres-pvc.yaml           # PVC separado para PostgreSQL
│   ├── postgres-secret-admin.yaml  # Credenciais admin PostgreSQL
│   └── postgres.yaml               # StatefulSet + Service
├── redis/
│   ├── redis-pv-hostpath.yaml      # PV hostPath (/home/dsm/cluster/redis)
│   ├── redis-pvc.yaml              # PVC separado para Redis
│   ├── redis-secret.yaml           # Credenciais Redis
│   └── redis.yaml                  # Deployment + Service
├── scripts/
│   ├── 9.setup-directories.sh      # 📁 Criar estrutura /home/dsm/cluster/
│   ├── 10.create-postgres.sh       # 🐘 Deploy PostgreSQL com hostPath
│   ├── 11.create-redis.sh          # 🔴 Deploy Redis com hostPath
│   └── 2.destroy-infra.sh          # 🗑️ Destruir infraestrutura
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
├── postgresql/data/        # PostgreSQL 16 - Dados persistentes
├── redis/                  # Redis cache - AOF persistente
└── pvc/
    ├── n8n/               # n8n workflows
    └── grafana/           # Grafana dashboards
```

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
2. ✅ Configura estrutura de diretórios hostPath
3. ✅ Deploy PostgreSQL 16 com persistência hostPath (20Gi)
4. ✅ Deploy Redis 8.2.1 com persistência hostPath (5Gi)
5. ✅ Instala cert-manager v1.18.2
6. ✅ Configura ClusterIssuer para certificados self-signed
7. ✅ Verifica saúde de todos os componentes

**Portas mapeadas:**

- `8080:80` - HTTP (Traefik Ingress)
- `8443:443` - HTTPS (Traefik Ingress)
- `30432:30432` - PostgreSQL (NodePort)
- `6379` - Redis (ClusterIP)

### **🗑️ destroy-infra.sh - Limpeza Completa**

```bash
./infra/scripts/2.destroy-infra.sh
```

**O que faz:**

1. ✅ Remove cert-manager e todos os certificados
2. ✅ Remove PostgreSQL (StatefulSet + PVC + PV)
3. ✅ Remove Redis (Deployment + PVC + PV)
4. ✅ Destroi cluster k3d completo
5. ✅ **MANTÉM** dados em `/home/dsm/cluster/` (PaaS behavior)
6. ✅ Limpeza de volumes Docker

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

- **Versão**: v1.18.2
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
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml

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
