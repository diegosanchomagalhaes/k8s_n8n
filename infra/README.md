# 🏗️ Infraestrutura - k3d + PostgreSQL + cert-manager

> Configuração de infraestrutura base para desenvolvimento local com k3d

## 📁 Estrutura

```
infra/
├── k3d/
│   └── k3d-config.yaml          # Configuração do cluster k3d
├── postgres/
│   ├── postgres-pv.yaml         # Persistent Volume (20Gi)
│   ├── postgres-secret-admin.yaml # Credenciais admin PostgreSQL
│   └── postgres.yaml            # StatefulSet + Service
├── scripts/
│   ├── 9.start-infra.sh         # 🚀 Deploy infraestrutura completa
│   └── 2.destroy-infra.sh       # 🗑️ Destruir infraestrutura
└── README.md                    # Este arquivo
```

## 🚀 Scripts Principais

### **🌟 start-infra.sh - Deploy Completo**

```bash
./infra/scripts/9.start-infra.sh
```

**O que faz:**

1. ✅ Cria cluster k3d com configuração personalizada
2. ✅ Deploy PostgreSQL 16 com volume persistente (20Gi)
3. ✅ Instala cert-manager v1.18.2
4. ✅ Configura ClusterIssuer para certificados self-signed
5. ✅ Verifica saúde de todos os componentes

**Portas mapeadas:**

- `8080:80` - HTTP (Traefik Ingress)
- `8443:443` - HTTPS (Traefik Ingress)
- `30432:30432` - PostgreSQL (NodePort)

### **🗑️ destroy-infra.sh - Limpeza Completa**

```bash
./infra/scripts/2.destroy-infra.sh
```

**O que faz:**

1. ✅ Remove cert-manager
2. ✅ Remove PostgreSQL (StatefulSet + PVC)
3. ✅ Destroi cluster k3d completo
4. ✅ Limpeza de volumes Docker

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
