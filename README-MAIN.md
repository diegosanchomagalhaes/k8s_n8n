# 🏗️ K8s n8n - Ambiente Kubernetes Completo

> 🚀 **Desenvolva Local, Deploy Global**: Ambiente de desenvolvimento Kubernetes completo com k3d, PostgreSQL persistente, n8n automação e sistema de backup profissional. **100% compatível com qualquer cluster Kubernetes de produção**!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![k3d](https://img.shields.io/badge/k3d-v5.6.0-blue)](https://k3d.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![n8n](https://img.shields.io/badge/n8n-1.112.4-orange)](https://n8n.io/)
[![Backup System](https://img.shields.io/badge/Backup-Automated-green)](./backup/README.md)

## 📋 Sumário

- [🎯 Início Rápido](#-início-rápido)
- [📂 Estrutura do Projeto](#-estrutura-do-projeto)
- [🏗️ Arquitetura](#️-arquitetura)
- [🗄️ Sistema de Backup](#️-sistema-de-backup)
- [📚 Documentação](#-documentação)
- [🛠️ Scripts Disponíveis](#️-scripts-disponíveis)
- [🔧 Configuração](#-configuração)
- [🚨 Troubleshooting](#-troubleshooting)
- [🎯 Produção](#-deploy-para-produção)

## 🎯 Início Rápido

### **⚡ Setup Completo em 3 Comandos**

```bash
# 1. Configurar credenciais
cp infra/postgres/postgres-secret-admin.yaml.template \
   infra/postgres/postgres-secret-admin.yaml
# Edite e defina sua senha PostgreSQL

# 2. Subir infraestrutura completa
./infra/scripts/10.start-infra.sh

# 3. Deploy n8n
./k8s/apps/n8n/scripts/1.deploy-n8n.sh
```

### **🌐 Acesso Rápido**

- **n8n**: https://n8n.local.127.0.0.1.nip.io
- **PostgreSQL**: localhost:30432

---

## 📂 Estrutura do Projeto

```
k8s_n8n/
├── infra/                      # 🏗️ Infraestrutura base
│   ├── scripts/                # Scripts de gerenciamento
│   │   ├── 9.setup-directories.sh    # Preparar estrutura
│   │   └── 10.start-infra.sh         # Subir tudo
│   ├── k3d/                    # Configuração do cluster
│   ├── postgres/               # PostgreSQL persistente
│   └── cert-manager/           # Certificados TLS
├── k8s/                        # 🚀 Aplicações Kubernetes
│   └── apps/
│       └── n8n/                # Automação n8n
│           ├── scripts/        # Deploy automático
│           └── *.yaml         # Manifests K8s
├── backup/                     # 🗄️ Sistema de Backup
│   ├── scripts/               # Scripts de backup/restore
│   ├── cronjobs/              # Backup automático
│   └── README.md              # Documentação backup
└── README*.md                 # 📚 Documentação modular
```

### **🎯 Estrutura de Dados Organizada**

```
/mnt/e/cluster/                 # 📂 Base organizada
├── postgresql/                 # 🗄️ Dados PostgreSQL
│   ├── n8n/                  # Database específico do n8n
│   ├── [outras-apps]/        # Futuras aplicações
│   └── backup/               # Backups de databases
├── pvc/                       # 📁 Volumes persistentes
│   ├── n8n/                 # Arquivos do n8n
│   ├── [outras-apps]/       # Futuras aplicações
│   └── backup/              # Backups de volumes
```

## 🏗️ Arquitetura

### **🔧 Componentes Principais**

| Componente       | Versão   | Função                   | Acesso     |
| ---------------- | -------- | ------------------------ | ---------- |
| **k3d**          | 5.6.0    | Cluster Kubernetes local | `kubectl`  |
| **PostgreSQL**   | 16       | Database persistente     | `:30432`   |
| **n8n**          | 1.112.4  | Automação workflows      | HTTPS      |
| **Traefik**      | Built-in | Ingress Controller       | HTTP/HTTPS |
| **cert-manager** | 1.13.1   | Certificados TLS         | -          |

### **🌐 Rede e Acesso**

```mermaid
graph TD
    A[🌐 localhost:8443] --> B[Traefik LoadBalancer]
    B --> C[n8n Service]
    C --> D[n8n Pod + PVC]
    D --> E[PostgreSQL:5432]

    F[🗄️ localhost:30432] --> E

    G[📂 /mnt/e/cluster] --> H[HostPath Volumes]
    H --> D
    H --> E
```

### **💾 Persistência de Dados**

- **PostgreSQL**: `hostPath:/mnt/e/cluster/postgresql`
- **n8n Files**: `hostPath:/mnt/e/cluster/pvc/n8n`
- **Backups DB**: `/mnt/e/cluster/postgresql/backup`
- **Backups PVC**: `/mnt/e/cluster/pvc/backup`

## 🗄️ Sistema de Backup

### **🚀 Backup Rápido**

```bash
# Backup completo do n8n
./backup/scripts/manage-backups.sh create n8n full

# Listar backups
./backup/scripts/manage-backups.sh list n8n

# Restaurar backup
./backup/scripts/manage-backups.sh restore n8n 20240924_143022
```

### **⏰ Backup Automático**

```bash
# Ativar backup diário às 02:00
./backup/scripts/manage-backups.sh schedule n8n

# Verificar status
./backup/scripts/manage-backups.sh status
```

### **📊 Tipos de Backup**

| Tipo    | Conteúdo         | Local                 | Uso               |
| ------- | ---------------- | --------------------- | ----------------- |
| `db`    | PostgreSQL dump  | `/postgresql/backup/` | Dados aplicação   |
| `files` | PVC tar.gz       | `/pvc/backup/`        | Arquivos, configs |
| `full`  | DB + Files + K8s | Ambos                 | Backup completo   |

**📖 [Documentação Completa de Backup](./backup/README.md)**

## 📚 Documentação

### **📋 READMEs Especializados**

| Arquivo                    | Conteúdo                          |
| -------------------------- | --------------------------------- |
| `README.md`                | 📖 **Este arquivo** - Visão geral |
| `README-SECURITY.md`       | 🔐 Configuração de segurança      |
| `README-INFRASTRUCTURE.md` | 🏗️ Detalhes da infraestrutura     |
| `README-DEPLOYMENT.md`     | 🚀 Guia de deployment             |
| `README-DEVELOPMENT.md`    | 👨‍💻 Guia para desenvolvedores      |
| `backup/README.md`         | 🗄️ Sistema de backup completo     |

## 🛠️ Scripts Disponíveis

### **🏗️ Infraestrutura**

```bash
./infra/scripts/9.setup-directories.sh   # Preparar estrutura
./infra/scripts/10.start-infra.sh        # Subir infraestrutura
./infra/scripts/2.destroy-infra.sh       # Destruir tudo
```

### **🚀 Aplicações**

```bash
./k8s/apps/n8n/scripts/1.deploy-n8n.sh  # Deploy n8n
./k8s/apps/n8n/scripts/2.delete-n8n.sh  # Remover n8n
```

### **🗄️ Backup**

```bash
./backup/scripts/manage-backups.sh       # Gerenciador principal
./backup/scripts/backup-app.sh           # Backup manual
./backup/scripts/restore-app.sh          # Restore manual
```

## 🔧 Configuração

### **1. 📋 Pré-requisitos**

- Docker
- k3d v5.6.0+
- kubectl

### **2. 🔐 Credenciais (OBRIGATÓRIO)**

```bash
# Copiar templates
cp infra/postgres/postgres-secret-admin.yaml.template \
   infra/postgres/postgres-secret-admin.yaml

cp k8s/apps/n8n/n8n-secret-db.yaml.template \
   k8s/apps/n8n/n8n-secret-db.yaml

# Editar e definir senhas
# Substituir: YOUR_POSTGRES_ADMIN_PASSWORD_HERE
```

### **3. 🚀 Execução**

```bash
# Setup completo
./infra/scripts/10.start-infra.sh
./k8s/apps/n8n/scripts/1.deploy-n8n.sh

# Verificar status
kubectl get pods -A
```

## 🚨 Troubleshooting

### **❌ Problemas Comuns**

#### **1. Cluster não sobe**

```bash
k3d cluster delete k3d-cluster
./infra/scripts/10.start-infra.sh
```

#### **2. Senha não configurada**

```bash
# Verificar se substituis a senha
grep "YOUR_POSTGRES" infra/postgres/postgres-secret-admin.yaml
```

#### **3. n8n não acessa banco**

```bash
# Verificar conectividade
kubectl exec -n n8n deployment/n8n -- nc -zv postgres.default.svc.cluster.local 5432
```

#### **4. Backup falha**

```bash
# Verificar permissões
ls -la /mnt/e/cluster/
./backup/scripts/manage-backups.sh status
```

### **🔍 Logs Úteis**

```bash
# Logs n8n
kubectl logs -n n8n deployment/n8n -f

# Logs PostgreSQL
kubectl logs -n default statefulset/postgres -f

# Status completo
kubectl get all -A
```

## 🎯 Deploy para Produção

### **☁️ Compatibilidade Cloud**

Este projeto é **100% compatível** com:

- **AKS** (Azure Kubernetes Service)
- **EKS** (Amazon Elastic Kubernetes Service)
- **GKE** (Google Kubernetes Engine)
- **Self-managed** Kubernetes

### **🔄 Path to Production**

```bash
# 1. Mesmo código, cluster diferente
kubectl config use-context production-cluster

# 2. Ajustar apenas storage classes
# local-path → azure-disk (AKS)
# local-path → gp2 (EKS)
# local-path → ssd (GKE)

# 3. Deploy idêntico
kubectl apply -f k8s/apps/n8n/
```

### **📋 Checklist de Produção**

- [ ] Trocar `manual` por storage class da cloud
- [ ] Configurar DNS real (não `.nip.io`)
- [ ] Certificados Let's Encrypt
- [ ] Backup para cloud storage
- [ ] Monitoring e alertas
- [ ] Resource limits adequados

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---

**🎯 Feito para desenvolvedores que querem simplicidade sem perder flexibilidade!**

**⭐ Se este projeto te ajudou, considera dar uma estrela!**
