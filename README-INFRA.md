# Infraestrutura K3D Local

> Documentação da infraestrutura base: k3d, PostgreSQL, cert-manager e networking.

## 📋 Sumário

- [Visão Geral da Infraestrutura](#-visão-geral-da-infraestrutura)
- [Componentes](#-componentes)
- [Scripts de Infraestrutura](#-scripts-de-infraestrutura)
- [Configuração k3d](#-configuração-k3d)
- [PostgreSQL](#-postgresql)
- [cert-manager](#-cert-manager)
- [Storage Persistente](#-storage-persistente)
- [Networking](#-networking)
- [Monitoramento](#-monitoramento)
- [Troubleshooting Infraestrutura](#-troubleshooting-infraestrutura)

## 🏗 Visão Geral da Infraestrutura

A infraestrutura base é composta por:

- **k3d**: Cluster Kubernetes local leve
- **PostgreSQL**: Banco de dados persistente (StatefulSet)
- **Traefik**: Ingress controller (padrão do k3d)
- **cert-manager**: Gerenciamento de certificados TLS self-signed
- **Storage persistente**: Volumes montados em SSD NVMe

## 🧩 Componentes

### 🐳 k3d Cluster

- **Nome**: `k3d-cluster`
- **Configuração**: 1 server + 2 agents
- **Portas expostas**:
  - `8080:80` (HTTP)
  - `8443:443` (HTTPS)
- **Volume persistente**: `/mnt/e/postgresql:/mnt/host-k8s`

### 🐘 PostgreSQL

- **Versão**: PostgreSQL 16
- **Namespace**: `default`
- **Service**: `postgres.default.svc.cluster.local:5432`
- **Tipo**: StatefulSet com PersistentVolume
- **Dados**: `/mnt/e/postgresql/data`
- **Recursos**:
  - CPU: 100m (request) / 500m (limit)
  - Memória: 256Mi (request) / 1Gi (limit)

### 🔐 cert-manager

- **Namespace**: `cert-manager`
- **Issuer**: `k3d-selfsigned` (ClusterIssuer)
- **Função**: Geração automática de certificados TLS para desenvolvimento

### 🌐 Traefik (Ingress)

- **Namespace**: `kube-system`
- **Tipo**: LoadBalancer (padrão k3d)
- **Função**: Roteamento HTTP/HTTPS e terminação TLS

## 📜 Scripts de Infraestrutura

### Scripts Principais (`infra/scripts/`)

| Script                     | Descrição                    | Componentes                     |
| -------------------------- | ---------------------------- | ------------------------------- |
| `1.create-infra.sh`        | **Setup completo**           | k3d + PostgreSQL + cert-manager |
| `2.destroy-infra.sh`       | **Destruir tudo**            | Remove cluster e dados          |
| `3.create-cluster.sh`      | Criar apenas cluster         | k3d cluster                     |
| `4.delete-cluster.sh`      | Deletar cluster              | Remove k3d                      |
| `5.create-postgres.sh`     | PostgreSQL apenas            | StatefulSet + PV                |
| `6.delete-postgres.sh`     | Remover PostgreSQL           | Cleanup DB                      |
| `7.create-cert-manager.sh` | cert-manager apenas          | TLS management                  |
| `8.delete-cert-manager.sh` | Remover cert-manager         | Remove certificates             |
| `9.start-n8n.sh`           | **Inicialização automática** | Detecta e executa necessário    |

### Uso dos Scripts

```bash
# Setup completo (primeira vez)
./infra/scripts/1.create-infra.sh

# Uso diário (detecta automaticamente o que fazer)
./infra/scripts/9.start-n8n.sh

# Limpeza completa
./infra/scripts/2.destroy-infra.sh
```

## ⚙️ Configuração k3d

### Arquivo de Configuração

**Localização**: `infra/k3d/k3d-config.yaml`

```yaml
apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: k3d-cluster
servers: 1
agents: 2
ports:
  - port: 8080:80
    nodeFilters:
      - loadbalancer
  - port: 8443:443
    nodeFilters:
      - loadbalancer
volumes:
  - volume: /mnt/e/postgresql:/mnt/host-k8s
    nodeFilters:
      - server:0
      - agent:*
options:
  k3d:
    wait: true
    timeout: "60s"
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:*
  kubeconfig:
    updateDefaultKubeconfig: true
    switchCurrentContext: true
```

### Características do Cluster

- **Alta disponibilidade local**: 3 nodes (1 server + 2 agents)
- **Load balancer integrado**: Traefik automático
- **Volume compartilhado**: SSD NVMe para performance
- **Networking**: Bridge network com port forwarding

## 🐘 PostgreSQL

### Estrutura de Arquivos

```
infra/postgres/
├── postgres-pv.yaml              # PersistentVolume
├── postgres-secret-admin.yaml    # Credenciais (não commitado)
├── postgres-secret-admin.yaml.template  # Template seguro
└── postgres.yaml                 # StatefulSet + Service
```

### Configuração do StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      containers:
        - name: postgres
          image: postgres:16
          envFrom:
            - secretRef:
                name: postgres-admin-secret
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
```

### Storage Persistente

- **Tipo**: hostPath (desenvolvimento)
- **Localização Host**: `/mnt/e/postgresql/data`
- **Localização Container**: `/var/lib/postgresql/data`
- **Tamanho**: 10Gi (configurável)

### Credenciais

**Template** (`postgres-secret-admin.yaml.template`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-admin-secret
type: Opaque
stringData:
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: YOUR_POSTGRES_ADMIN_PASSWORD_HERE
  POSTGRES_DB: postgres
```

## 🔐 cert-manager

### Instalação

```bash
# Aplicar manifests
kubectl apply -f infra/cert-manager/cert-manager-namespace.yaml
kubectl apply -f infra/cert-manager/cluster-issuer-selfsigned.yaml
```

### ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: k3d-selfsigned
spec:
  selfSigned: {}
```

### Uso em Aplicações

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: app-tls
  namespace: app-namespace
spec:
  secretName: app-tls-secret
  issuerRef:
    name: k3d-selfsigned
    kind: ClusterIssuer
  dnsNames:
    - app.local.127.0.0.1.nip.io
```

## 💾 Storage Persistente

### Configuração de Volumes

**PersistentVolume** (`postgres-pv.yaml`):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/host-k8s/postgresql/data
  persistentVolumeReclaimPolicy: Retain
```

### Backup e Restore

```bash
# Backup do banco
kubectl exec statefulset/postgres -- pg_dump -U postgres postgres > backup.sql

# Restore do banco
kubectl exec -i statefulset/postgres -- psql -U postgres postgres < backup.sql

# Backup de dados (filesystem)
sudo cp -r /mnt/e/postgresql/data /backup/postgresql-$(date +%Y%m%d)
```

## 🌐 Networking

### Configuração de Rede

- **CNI**: Flannel (padrão k3d)
- **Service Network**: 10.43.0.0/16
- **Pod Network**: 10.42.0.0/16
- **DNS**: CoreDNS integrado

### Acesso Externo

```bash
# Port forwarding para desenvolvimento
kubectl port-forward svc/postgres 5432:5432

# Ingress via Traefik
# HTTP: http://localhost:8080
# HTTPS: https://localhost:8443
```

### DNS Interno

```yaml
# Serviços acessíveis internamente:
postgres.default.svc.cluster.local:5432
n8n.n8n.svc.cluster.local:5678
```

## 📊 Monitoramento

### Comandos Úteis

```bash
# Status geral do cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Status da infraestrutura
kubectl get statefulset postgres
kubectl get pv,pvc
kubectl get certificates --all-namespaces

# Logs da infraestrutura
kubectl logs statefulset/postgres
kubectl logs -n cert-manager deployment/cert-manager

# Recursos e performance
kubectl top nodes
kubectl top pods --all-namespaces
```

### Health Checks

```bash
# Verificar PostgreSQL
kubectl exec -it postgres-0 -- pg_isready -U postgres

# Verificar cert-manager
kubectl get certificaterequests --all-namespaces

# Verificar conectividade
kubectl run test-pod --image=postgres:16 --rm -it -- psql -h postgres.default.svc.cluster.local -U postgres
```

## 🔧 Troubleshooting Infraestrutura

### Problemas de Cluster

#### k3d não inicia

```bash
# Verificar Docker
docker ps

# Limpar e recriar
./infra/scripts/4.delete-cluster.sh
./infra/scripts/3.create-cluster.sh

# Verificar logs
docker logs k3d-k3d-cluster-server-0
```

#### Nodes não ficam Ready

```bash
# Verificar status dos nodes
kubectl get nodes -o wide

# Verificar eventos
kubectl get events --sort-by='.lastTimestamp'

# Reiniciar cluster
k3d cluster stop k3d-cluster
k3d cluster start k3d-cluster
```

### Problemas PostgreSQL

#### Pod não inicia

```bash
# Verificar status do pod
kubectl describe pod postgres-0

# Verificar logs
kubectl logs postgres-0

# Verificar volume
ls -la /mnt/e/postgresql/data/
sudo chown -R 999:999 /mnt/e/postgresql/data/
```

#### Conexão recusada

```bash
# Verificar service
kubectl get svc postgres

# Testar conectividade interna
kubectl run test-client --image=postgres:16 --rm -it -- bash
psql -h postgres.default.svc.cluster.local -U postgres

# Port forward para teste
kubectl port-forward svc/postgres 5432:5432
```

### Problemas cert-manager

#### Certificados não são criados

```bash
# Verificar cert-manager
kubectl get pods -n cert-manager

# Verificar CertificateRequest
kubectl get certificaterequests --all-namespaces

# Verificar eventos
kubectl describe certificate -n namespace nome-cert
```

### Problemas de Storage

#### Volume não monta

```bash
# Verificar PV/PVC
kubectl get pv,pvc

# Verificar permissões
ls -la /mnt/e/postgresql/
sudo mkdir -p /mnt/e/postgresql/data
sudo chown -R 999:999 /mnt/e/postgresql/
```

#### Performance lenta

```bash
# Verificar I/O do disco
iostat -x 1

# Mover para SSD se estiver em HDD
sudo mkdir -p /mnt/nvme/postgresql
sudo chown -R 999:999 /mnt/nvme/postgresql
# Atualizar k3d-config.yaml e recriar cluster
```

---

**Infraestrutura K3D Local** - Base para Ambiente de Desenvolvimento Kubernetes  
_Última atualização: setembro 2025_
