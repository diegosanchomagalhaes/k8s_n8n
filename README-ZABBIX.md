# Zabbix - Monitoramento de Infraestrutura e Aplicações

> 🛡️ **Monitoramento Empresarial**: Zabbix 7.4.5 com PostgreSQL, Redis cache, TLS automático e componentes completos para monitoramento avançado.

[![Zabbix](https://img.shields.io/badge/Zabbix-7.4.5-red)](https://www.zabbix.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-8.2.3-red)](https://redis.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.34.1-blue)](https://kubernetes.io/)
[![cert-manager](https://img.shields.io/badge/cert--manager-v1.19.0-green)](https://cert-manager.io/)

## 🎯 **Status Atual - Zabbix 7.4.5 Completo**

- ✅ **Zabbix Server 7.4.5**: Core de monitoramento com PostgreSQL (HPA 1-3 pods)
- ✅ **Zabbix Web Frontend**: Interface web com Nginx + PHP-FPM (HPA 1-3 pods)
- ✅ **Zabbix Proxy**: Monitoramento distribuído com MariaDB (HPA 1-3 pods)
- ✅ **Zabbix Agent2 (Deployment)**: Agente moderno na porta 10050 (HPA 1-3 pods)
- ✅ **Zabbix Agent Classic (Deployment)**: Agente legado na porta 10061 (HPA 1-3 pods)
- ✅ **Zabbix Java Gateway**: Monitoramento JMX de aplicações Java (HPA 1-3 pods)
- ✅ **Zabbix Web Service**: Geração de relatórios PDF e exportação (HPA 1-3 pods)
- ✅ **SNMP Traps**: Receptor de traps de dispositivos de rede (porta 162 UDP)
- ✅ **PostgreSQL Integration**: Database dedicado 'zabbix' (Server + Web)
- ✅ **MariaDB Integration**: Database dedicado 'zabbix_proxy' (Proxy)
- ✅ **Redis Cache**: DB4 exclusivo para cache (128M)
- ✅ **HTTPS/TLS**: Certificados automáticos via cert-manager
- ✅ **Auto-scaling**: 7 HPAs configurados (todos componentes exceto SNMP Traps)
- ✅ **hostPath Persistence**: Dados em `/home/dsm/cluster/pvc/zabbix/{server,web,proxy,snmptraps}`
- ✅ **Security**: Secrets, non-root user, resource limits

## 🌐 **Acesso**

| Serviço                  | URL/Endpoint                                          | Porta   | Credenciais                 | Status |
| ------------------------ | ----------------------------------------------------- | ------- | --------------------------- | ------ |
| **Zabbix Web**           | `https://zabbix.local.127.0.0.1.nip.io:8443`          | 8443    | Admin / zabbix              | ✅     |
| **Zabbix Server**        | `zabbix-server.zabbix.svc.cluster.local:10051`        | 10051   | (comunicação interna)       | ✅     |
| **Zabbix Proxy**         | `zabbix-proxy.zabbix.svc.cluster.local:10051`         | 10051   | (comunicação interna)       | ✅     |
| **Zabbix Agent2**        | `zabbix-agent2.zabbix.svc.cluster.local:10050`        | 10050   | (comunicação passiva/ativa) | ✅     |
| **Zabbix Agent Classic** | `zabbix-agent-classic.zabbix.svc.cluster.local:10061` | 10061   | (comunicação passiva/ativa) | ✅     |
| **SNMP Traps**           | `zabbix-snmptraps.zabbix.svc.cluster.local:162`       | 162 UDP | (receptor de traps SNMP)    | ✅     |
| **Database (Server)**    | `postgres.postgres.svc.cluster.local:5432`            | 5432    | (credenciais via secret)    | ✅     |
| **Database (Proxy)**     | `mariadb.mariadb.svc.cluster.local:3306`              | 3306    | root / mariadb_root         | ✅     |
| **Redis Cache**          | `redis.redis.svc.cluster.local:6379`                  | 6379    | DB4 (cache)                 | ✅     |
| **Java Gateway**         | `zabbix-java-gateway.zabbix.svc.cluster.local:10052`  | 10052   | (comunicação interna)       | ✅     |
| **Web Service**          | `zabbix-web-service.zabbix.svc.cluster.local:10053`   | 10053   | (comunicação interna)       | ✅     |

> ⚠️ **Porta 8443**: k3d mapeia `443→8443` para evitar privilégios root

### 🔐 **Credenciais de Acesso Padrão**

| Item                 | Valor                                                      | Observação                                                |
| -------------------- | ---------------------------------------------------------- | --------------------------------------------------------- |
| 🌐 **URL**           | `https://zabbix.local.127.0.0.1.nip.io:8443`               | Usar sempre HTTPS na porta 8443                           |
| 👤 **Usuário**       | `Admin`                                                    | **ATENÇÃO**: Inicial maiúsculo                            |
| 🔑 **Senha**         | `zabbix`                                                   | **⚠️ CRÍTICO**: Altere IMEDIATAMENTE após primeiro login! |
| 💾 **Database (PG)** | PostgreSQL 16 (`postgres.postgres.svc.cluster.local:5432`) | Database: `zabbix`, schema criado automaticamente         |
| 💾 **Database (MB)** | MariaDB 12.0.2 (`mariadb.mariadb.svc.cluster.local:3306`)  | Database: `zabbix_proxy` (utf8mb4_bin)                    |
| 🗄️ **Cache**         | Redis 8.2.3 (`redis.redis.svc.cluster.local:6379`)         | Database: DB4 (128M cache size)                           |
| 📊 **Timezone**      | `America/Sao_Paulo`                                        | Configurado no PHP                                        |

> 🔒 **ATENÇÃO DE SEGURANÇA CRÍTICA**:
>
> 1. ⚠️ **ALTERE A SENHA PADRÃO IMEDIATAMENTE!** A senha `zabbix` é conhecida publicamente
> 2. Configure autenticação de dois fatores (2FA) via integração LDAP/SAML se disponível
> 3. Crie usuários separados com permissões específicas (Admin, Super Admin, User)
> 4. Configure restrições de IP para usuários administrativos
> 5. Use senhas fortes (mínimo 16 caracteres com caracteres especiais)
> 6. Aceite o certificado self-signed no navegador
> 7. Configure auditoria de ações administrativas

## 📋 **Sumário**

- [Deploy Rápido](#-deploy-rápido)
- [Arquitetura](#-arquitetura)
- [Componentes](#-componentes)
- [Configuração](#-configuração)
- [Scripts Disponíveis](#-scripts-disponíveis)
- [Storage e Backup](#-storage-e-backup)
- [Troubleshooting](#-troubleshooting)
- [Segurança](#-segurança)
- [Monitoramento](#-monitoramento)

## 🚀 **Deploy Rápido**

### **⚡ Setup Completo**

```bash
# 🎯 OPÇÃO 1: Deploy completo (recomendado)
./k8s/apps/zabbix/scripts/3.start-zabbix.sh  # Verifica configurações e faz deploy

# 🎯 OPÇÃO 2: Deploy manual passo a passo
./infra/scripts/10.start-infra.sh            # 1. Infraestrutura base (PostgreSQL + Redis)
./k8s/apps/zabbix/scripts/1.deploy-zabbix.sh # 2. Zabbix completo com todos componentes
```

### **🌐 Acesso Imediato**

- **Zabbix Web**: https://zabbix.local.127.0.0.1.nip.io:8443
- **Login**: `Admin` / `zabbix` (**ALTERE IMEDIATAMENTE!**)

### **🔧 Configuração de HOSTS**

> ⚠️ **IMPORTANTE**: O domínio `zabbix.local.127.0.0.1.nip.io` usa resolução automática via nip.io, não necessitando configuração manual do `/etc/hosts`.

**Configuração Manual (opcional, se usar DNS customizado):**

```bash
# Adicionar ao /etc/hosts (Linux/WSL2)
echo "127.0.0.1 zabbix.local.127.0.0.1.nip.io" | sudo tee -a /etc/hosts

# Verificar se foi adicionado
grep "zabbix.local" /etc/hosts
```

**Para WSL2:**

- Acesse via Windows: `https://zabbix.local.127.0.0.1.nip.io:8443`
- **Porta 8443**: k3d mapeia `443→8443` para evitar privilégios root

**Remover entrada (se necessário):**

```bash
sudo sed -i "/zabbix.local.127.0.0.1.nip.io/d" /etc/hosts
```

---

## 🏗 **Arquitetura**

### **📦 Stack Completo**

```
Zabbix Stack Empresarial
├── 🛡️ Zabbix Server          # Core de monitoramento (port 10051)
│   ├── PostgreSQL Backend    # Armazenamento de dados
│   ├── Redis Cache DB4      # Cache de valores e histórico (128M)
│   ├── Pollers/Trappers     # Coleta de métricas (5 pollers, 5 trappers)
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── 🌐 Zabbix Web Frontend    # Interface web Nginx+PHP (ports 8080/8443)
│   ├── PHP 8.2              # Processamento web
│   ├── PostgreSQL           # Mesmo banco do servidor
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── �️ Zabbix Proxy          # Monitoramento distribuído (port 10051)
│   ├── MariaDB Backend      # Database 'zabbix_proxy'
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── �📡 Zabbix Agent2          # Deployment escalável com HPA (port 10050)
│   ├── Active Checks        # Envio proativo de métricas
│   ├── Passive Checks       # Resposta a consultas do servidor
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── 📡 Zabbix Agent Classic   # Deployment escalável com HPA (port 10061)
│   ├── Active Checks        # Envio proativo de métricas
│   ├── Passive Checks       # Resposta a consultas do servidor
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── ☕ Java Gateway           # Monitoramento JMX (port 10052)
│   ├── JMX Polling          # Aplicações Java/J2EE
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── 📄 Web Service           # Relatórios e exportação (port 10053)
│   ├── PDF/Report Engine    # Geração de relatórios
│   └── HPA Auto-scaling     # 1-3 replicas (CPU 70%, Memory 80%)
├── 📡 SNMP Traps            # Receptor de traps (port 162/UDP)
│   └── Fixed Deployment     # 1 replica (sem HPA)
├── 🗄️ PostgreSQL Database    # Database 'zabbix' com schema completo
├── 💾 PVC Storage (7Gi)      # Dados persistentes (server 5Gi + web 2Gi)
├── 🔒 TLS Certificate        # HTTPS automático via cert-manager
└── 🌐 Nginx Ingress          # Roteamento HTTPS
```

### **🔗 Integração com Infraestrutura**

```
┌──────────────────────────────────────────────────────────────┐
│                        k3d Cluster                           │
├──────────────────────────────────────────────────────────────┤
│  Namespace: zabbix                                           │
│  ├── 🛡️ Zabbix Server (7.4.5) - Deployment                  │
│  │   └── PVC: zabbix-server-pvc (5Gi) - /var/lib/zabbix    │
│  ├── 🌐 Zabbix Web (7.4.5) - Deployment + HPA (1-3)         │
│  │   └── PVC: zabbix-web-pvc (2Gi) - /usr/share/zabbix     │
│  ├── 📡 Zabbix Agent2 (7.4.5) - Deployment + HPA (1-3)      │
│  ├── 📡 Zabbix Agent Classic (7.4.5) - Deployment + HPA (1-3)│
│  ├── 🔀 Zabbix Proxy (7.4.5) - Deployment                   │
│  │   └── PVC: zabbix-proxy-pvc (3Gi) - /var/lib/zabbix     │
│  ├── 📶 SNMP Traps (7.4.5) - Deployment                     │
│  │   └── PVC: zabbix-snmptraps-pvc (1Gi) - /var/lib/zabbix │
│  ├── ☕ Java Gateway (7.4.5) - Deployment                    │
│  ├── 📄 Web Service (7.4.5) - Deployment                     │
│  └── 🔐 Secrets: DB credentials + Redis config              │
├──────────────────────────────────────────────────────────────┤
│  Namespace: postgres                                         │
│  └── 🗄️ PostgreSQL 16: Database 'zabbix'                    │
├──────────────────────────────────────────────────────────────┤
│  Namespace: redis                                            │
│  └── 💾 Redis 8.2.3: Database 4 (cache exclusivo)           │
├──────────────────────────────────────────────────────────────┤
│  Namespace: cert-manager                                     │
│  └── 🔒 TLS Certificate: zabbix.local.*                      │
└──────────────────────────────────────────────────────────────┘
```

### **🔄 Fluxo de Dados**

```
┌─────────────┐      10051      ┌──────────────┐      SQL       ┌──────────────┐
│ Zabbix      │◄────────────────►│ Zabbix       │◄──────────────►│ PostgreSQL   │
│ Agent2      │   Metrics        │ Server       │   Write/Read   │ Database     │
│ (HPA 1-3)   │                  │ (Core)       │                │ 'zabbix'     │
└─────────────┘                  └──────────────┘                └──────────────┘
                                        │  ▲                             │
                                        │  │ Cache                       │
                                        ▼  │                             │
                                 ┌──────────────┐                        │
                                 │ Redis DB4    │                        │
                                 │ (128M cache) │                        │
                                 └──────────────┘                        │
                                                                          │
┌─────────────┐      HTTPS      ┌──────────────┐      SQL               │
│ Browser     │◄────────────────►│ Zabbix Web   │◄──────────────────────┘
│ (User)      │   443→8443       │ Frontend     │   Read/Write
└─────────────┘                  └──────────────┘
                                        │
                                        │ 10053
                                        ▼
                                 ┌──────────────┐
                                 │ Web Service  │
                                 │ (Reports)    │
                                 └──────────────┘

┌─────────────┐      10052      ┌──────────────┐
│ Java Apps   │◄────────────────►│ Java Gateway │
│ (JMX)       │   JMX Polling    │ (Optional)   │
└─────────────┘                  └──────────────┘
```

## 🧩 **Componentes**

### **1. Zabbix Server (Core)**

**Função**: Motor principal de monitoramento, coleta, processamento e alertas.

**Características**:

- Image: `zabbix/zabbix-server-pgsql:ubuntu-7.4.5`
- Port: 10051 (Zabbix trapper protocol)
- Database: PostgreSQL com schema completo auto-criado
- Cache: Redis DB4 para otimização de performance
- Resources: 512Mi/500m (requests), 2Gi/2000m (limits)
- Storage: 5Gi PVC para logs, SNMP MIBs, bibliotecas

**Configurações Principais**:

```yaml
Pollers: 5 # Processos de coleta de dados
Trappers: 5 # Processos para receber dados ativos
Pingers: 1 # ICMP monitoring
Cache Size: 128M # Cache principal
History Cache: 64M # Cache de histórico
Trend Cache: 16M # Cache de tendências
Value Cache: 64M # Cache de valores
```

**Volumes**:

- `/var/lib/zabbix/snmptraps`: Traps SNMP
- `/var/lib/zabbix/mibs`: MIBs SNMP customizadas
- `/var/lib/zabbix`: Dados gerais

### **2. Zabbix Web Frontend**

**Função**: Interface web para configuração, visualização e gerenciamento.

**Características**:

- Image: `zabbix/zabbix-web-nginx-pgsql:ubuntu-7.4.5`
- Ports: 8080 (HTTP), 8443 (HTTPS)
- Web Server: Nginx
- PHP: 8.2 (memory_limit=256M, max_execution_time=600s)
- Database: Compartilhado com o servidor (PostgreSQL)
- Resources: 256Mi/250m (requests), 512Mi/500m (limits)
- Auto-scaling: HPA 1-3 replicas (70% CPU, 80% RAM)
- Storage: 2Gi PVC para módulos e plugins

**PHP Tuning**:

```yaml
Timezone: America/Sao_Paulo
Memory Limit: 256M
Upload Max: 16M
Execution Time: 600s (10 minutos)
```

### **3. Zabbix Agent2 (Deployment + HPA)**

**Função**: Coleta de métricas dos hosts monitorados.

**Características**:

- Image: `zabbix/zabbix-agent2:ubuntu-7.4.5`
- Port: 10050 (agent protocol)
- Mode: Active + Passive checks
- Deployment: Escalável com HPA (1-3 pods)
- Auto-scaling: CPU 70% / Memory 80%
- Privilege: Necessita acesso privilegiado ao host
- Resources: 64Mi/100m (requests), 128Mi/200m (limits)

**Volumes Montados do Host**:

- `/host/proc`: Informações de processos
- `/host/sys`: Estatísticas do sistema
- `/host/root`: Filesystem completo (read-only)

### **4. Java Gateway (Opcional)**

**Função**: Monitoramento de aplicações Java via JMX.

**Características**:

- Image: `zabbix/zabbix-java-gateway:ubuntu-7.4.5`
- Port: 10052 (JMX gateway)
- Pollers: 5 threads JMX
- Resources: 256Mi/250m (requests), 512Mi/500m (limits)

**Uso**: Configure no Zabbix Server: JavaGateway=zabbix-java-gateway.zabbix.svc.cluster.local

### **5. Web Service (Relatórios)**

**Função**: Geração de relatórios, gráficos e exportação de dados.

**Características**:

- Image: `zabbix/zabbix-web-service:ubuntu-7.4.5`
- Port: 10053 (web service)
- Resources: 128Mi/100m (requests), 256Mi/200m (limits)
- Security: Non-root user (1997:1995)

## ⚙️ **Configuração**

### **🗄️ Database & Cache**

**PostgreSQL:**

- **Database**: `zabbix`
- **User**: `postgres` (admin credentials via secret)
- **Host**: `postgres.postgres.svc.cluster.local:5432`
- **Schema**: Auto-criado pelo Zabbix Server na primeira inicialização
- **SSL**: Disabled (internal cluster communication)
- **Connection Pool**: Gerenciado pelo Zabbix Server

**Redis Cache (Database 4):**

- **Host**: `redis.redis.svc.cluster.local:6379`
- **Database**: `4` (DB4 exclusively for Zabbix)
- **Purpose**: Cache de valores, histórico e configurações
- **Size**: 128M cache size configurado
- **Connection**: `redis://redis.redis.svc.cluster.local:6379/4`

> 📝 **Redis Database Allocation**: Zabbix utiliza **Redis DB4** exclusivamente. Outros apps: n8n=DB0, Grafana=DB1, GLPI=DB2, Prometheus=DB3.

### **🔐 Secrets e Credenciais**

Todas as credenciais são gerenciadas via Kubernetes Secret: `zabbix-db-secret`

**Variáveis Principais**:

```yaml
# PostgreSQL
DB_SERVER_HOST: postgres.postgres.svc.cluster.local
DB_SERVER_PORT: "5432"
POSTGRES_USER: postgres
POSTGRES_PASSWORD: <senha_segura>
POSTGRES_DB: zabbix

# Redis Cache
ZBX_CACHESIZE: "128M"
ZBX_HISTORYCACHESIZE: "64M"
ZBX_HISTORYINDEXCACHESIZE: "32M"
ZBX_TRENDCACHESIZE: "16M"
ZBX_VALUECACHESIZE: "64M"

# Zabbix Server Tuning
ZBX_STARTPOLLERS: "5"
ZBX_STARTTRAPPERS: "5"
ZBX_STARTPINGERS: "1"
ZBX_TIMEOUT: "10"
```

### **🏗️ Resources**

```yaml
Zabbix Server:
  Requests: 512Mi RAM, 500m CPU
  Limits: 2Gi RAM, 2000m CPU
  Storage: 5Gi PVC

Zabbix Web:
  Requests: 256Mi RAM, 250m CPU
  Limits: 512Mi RAM, 500m CPU
  Storage: 2Gi PVC
  HPA: 1-3 replicas (70% CPU, 80% RAM)

Zabbix Agent2:
  Requests: 64Mi RAM, 100m CPU
  Limits: 128Mi RAM, 200m CPU
  Deployment: Escalável (HPA 1-3 pods)
  Auto-scaling: CPU 70%, Memory 80%

Zabbix Agent Classic:
  Requests: 64Mi RAM, 100m CPU
  Limits: 128Mi RAM, 200m CPU
  Deployment: Escalável (HPA 1-3 pods)
  Auto-scaling: CPU 70%, Memory 80%

Java Gateway:
  Requests: 256Mi RAM, 250m CPU
  Limits: 512Mi RAM, 500m CPU

Web Service:
  Requests: 128Mi RAM, 100m CPU
  Limits: 256Mi RAM, 200m CPU
```

## 🛠️ **Scripts Disponíveis**

### **📁 Estrutura**

```
k8s/apps/zabbix/
├── scripts/
│   ├── 0.setup-hosts-zabbix.sh       # 🌐 Configuração de hosts (nip.io)
│   ├── 1.deploy-zabbix.sh            # 🚀 Deploy completo (todos componentes)
│   ├── 2.destroy-zabbix.sh           # 🗑️ Remoção completa (mantém dados)
│   ├── 3.start-zabbix.sh             # ▶️ Iniciar (verifica configs)
│   ├── 4.drop-database-zabbix.sh     # 🗄️ Limpar database PostgreSQL
│   ├── 5.restart-zabbix.sh           # 🔄 Restart (preserva dados)
│   └── 6.delete-volumes-zabbix.sh    # 💾 Remove volumes hostPath
├── zabbix-*.yaml                     # 📄 Manifests Kubernetes
└── README-ZABBIX.md                  # 📚 Esta documentação
```

### **🎯 Comandos Principais**

```bash
# ▶️ Iniciar Zabbix (verifica configurações)
./k8s/apps/zabbix/scripts/3.start-zabbix.sh

# 🚀 Deploy completo (nova instalação)
./k8s/apps/zabbix/scripts/1.deploy-zabbix.sh

# 🔄 Restart (preserva dados e configurações)
./k8s/apps/zabbix/scripts/5.restart-zabbix.sh

# 🗑️ Remoção completa (mantém database e volumes)
./k8s/apps/zabbix/scripts/2.destroy-zabbix.sh

# 🗄️ Limpar database (⚠️ remove TODOS os dados)
./k8s/apps/zabbix/scripts/4.drop-database-zabbix.sh

# 💾 Remover volumes hostPath (⚠️ remove arquivos locais)
./k8s/apps/zabbix/scripts/6.delete-volumes-zabbix.sh
```

### **📋 Fluxo de Operações**

```bash
# Setup inicial
1. ./infra/scripts/10.start-infra.sh  # Iniciar PostgreSQL + Redis
2. cp zabbix-secret-db.yaml.template zabbix-secret-db.yaml
3. # Editar zabbix-secret-db.yaml (substituir CHANGE_ME)
4. ./3.start-zabbix.sh                # Deploy completo

# Manutenção
./5.restart-zabbix.sh                 # Restart sem perder dados

# Reset completo
./2.destroy-zabbix.sh                 # Remove aplicação
./4.drop-database-zabbix.sh           # Limpa database
./6.delete-volumes-zabbix.sh          # Remove volumes
./1.deploy-zabbix.sh                  # Reinstala do zero
```

## 💾 **Storage e Backup**

### **📂 Persistent Volumes**

**Zabbix Server PVC (5Gi)**:

- `/var/lib/zabbix/snmptraps`: SNMP traps recebidos
- `/var/lib/zabbix/mibs`: MIB files customizadas
- `/var/lib/zabbix`: Dados gerais do servidor
- **hostPath**: `/home/dsm/cluster/pvc/zabbix/server/`

**Zabbix Web PVC (2Gi)**:

- `/usr/share/zabbix/modules`: Módulos web customizados
- **hostPath**: `/home/dsm/cluster/pvc/zabbix/web/`

### **🔄 Backup Strategy**

#### **1. Database Backup (Principal)**

```bash
# Backup completo da database (configurações + histórico)
kubectl exec -n postgres postgres-0 -- pg_dump -U postgres zabbix > zabbix-backup-$(date +%Y%m%d).sql

# Backup comprimido
kubectl exec -n postgres postgres-0 -- pg_dump -U postgres zabbix | gzip > zabbix-backup-$(date +%Y%m%d).sql.gz

# Restore database
kubectl exec -n postgres postgres-0 -- psql -U postgres zabbix < zabbix-backup-20250603.sql
```

#### **2. Volumes Backup**

```bash
# Backup dos volumes hostPath (logs, MIBs, módulos)
sudo tar -czf zabbix-volumes-backup-$(date +%Y%m%d).tar.gz \
  /home/dsm/cluster/pvc/zabbix/

# Restore volumes
sudo tar -xzf zabbix-volumes-backup-20250603.tar.gz -C /
```

#### **3. Configuração Backup (via API)**

```bash
# Export de todos os templates via API
curl -X POST https://zabbix.local.127.0.0.1.nip.io:8443/api_jsonrpc.php \
  -H "Content-Type: application/json-rpc" \
  -d '{"jsonrpc":"2.0","method":"configuration.export","params":{"options":{"templates":[]},"format":"xml"},"id":1,"auth":"<token>"}' \
  > zabbix-templates-$(date +%Y%m%d).xml
```

### **📊 Retenção de Dados**

Configure na interface web: Administration → General → Housekeeping

**Recomendações**:

- **History**: 90 dias (dados brutos)
- **Trends**: 365 dias (dados agregados)
- **Events**: 90 dias
- **Alerts**: 365 dias
- **Audit**: 365 dias

## 🔧 **Troubleshooting**

### **🔍 Status e Logs**

```bash
# Status geral de todos os componentes
kubectl get all -n zabbix

# Logs do Zabbix Server
kubectl logs -n zabbix -l app=zabbix,component=server -f

# Logs do Zabbix Web
kubectl logs -n zabbix -l app=zabbix,component=web -f

# Logs dos Agents (todos os pods)
kubectl logs -n zabbix -l app=zabbix,component=agent2 -f --max-log-requests=10
kubectl logs -n zabbix -l app=zabbix,component=agent-classic -f --max-log-requests=10

# Status do database
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "\l" | grep zabbix

# Conectar ao database
kubectl exec -it -n postgres postgres-0 -- psql -U postgres -d zabbix

# Verificar conexão Redis
kubectl exec -n redis redis-0 -- redis-cli -n 4 INFO keyspace
```

### **⚠️ Problemas Comuns**

#### **1. Erro: "Cannot connect to database"**

```bash
# Verificar se PostgreSQL está rodando
kubectl get pods -n postgres

# Verificar credenciais no secret
kubectl get secret zabbix-db-secret -n zabbix -o yaml

# Testar conexão manual
kubectl exec -n postgres postgres-0 -- psql -U postgres -d zabbix -c "SELECT version();"
```

#### **2. Web Frontend não carrega**

```bash
# Verificar se Zabbix Server está pronto
kubectl get pods -n zabbix -l component=server

# Verificar logs do web frontend
kubectl logs -n zabbix -l component=web --tail=100

# Verificar ingress
kubectl get ingress -n zabbix
kubectl describe ingress zabbix-ingress -n zabbix

# Testar acesso interno
kubectl exec -n zabbix deployment/zabbix-web -- curl -I localhost:8080
```

#### **3. Agents não aparecem**

```bash
# Verificar Deployments e HPA dos agents
kubectl get deployment,hpa -n zabbix | grep agent

# Verificar logs dos agents
kubectl logs -n zabbix -l component=agent2 --tail=50
kubectl logs -n zabbix -l component=agent-classic --tail=50

# Verificar conectividade agent → server
kubectl exec -n zabbix deployment/zabbix-agent2 -- nc -zv zabbix-server 10051
kubectl exec -n zabbix deployment/zabbix-agent-classic -- nc -zv zabbix-server 10051

# Configurar host no Zabbix Web:
# Configuration → Hosts → Create Host
# - Host name: <pod_name>
# - Agent2 interface: zabbix-agent2.zabbix.svc.cluster.local:10050
# - Agent Classic interface: zabbix-agent-classic.zabbix.svc.cluster.local:10061
```

#### **4. Performance lenta**

```bash
# Verificar uso de recursos
kubectl top pods -n zabbix

# Verificar cache Redis
kubectl exec -n redis redis-0 -- redis-cli -n 4 INFO stats

# Aumentar cache sizes no secret e reiniciar:
kubectl edit secret zabbix-db-secret -n zabbix
kubectl rollout restart deployment/zabbix-server -n zabbix

# Verificar housekeeping (limpeza automática)
# Web UI: Administration → General → Housekeeping
```

#### **5. TLS Certificate issues**

```bash
# Verificar certificado
kubectl get certificate -n zabbix
kubectl describe certificate zabbix-tls-secret -n zabbix

# Forçar renovação
kubectl delete certificate zabbix-tls-secret -n zabbix
kubectl apply -f ./k8s/apps/zabbix/zabbix-certificate.yaml

# Verificar cert-manager
kubectl logs -n cert-manager -l app=cert-manager -f
```

### **📊 Health Checks**

```bash
# Script de verificação completa
kubectl get pods -n zabbix && \
kubectl get svc -n zabbix && \
kubectl get ingress -n zabbix && \
kubectl exec -n postgres postgres-0 -- psql -U postgres -d zabbix -c "SELECT version();" && \
kubectl exec -n redis redis-0 -- redis-cli -n 4 PING && \
echo "✅ Todos os componentes OK"
```

## 🔒 **Segurança**

### **🛡️ Checklist de Segurança**

- ✅ **Credenciais**: Alteradas do padrão (Admin/zabbix)
- ✅ **TLS/HTTPS**: Habilitado com certificados automáticos
- ✅ **Secrets**: Credenciais em Kubernetes Secrets (não em plaintext)
- ✅ **Non-root**: Containers rodando com UID 1997 (user zabbix)
- ✅ **Network Policies**: Isolamento de namespace (opcional)
- ✅ **Resource Limits**: Prevenção de resource exhaustion
- ✅ **RBAC**: Permissões mínimas necessárias
- ✅ **Audit**: Logs de auditoria habilitados

### **🔐 Hardening Recommendations**

```bash
# 1. Alterar senha padrão (CRÍTICO!)
# Web UI → Administration → Users → Admin → Password

# 2. Configurar autenticação avançada
# Web UI → Administration → Authentication → HTTP/LDAP/SAML

# 3. Restringir acesso administrativo por IP
# Web UI → Administration → Users → Admin → Frontend access

# 4. Habilitar auditoria completa
# Web UI → Administration → Audit log → Configure

# 5. Configurar auto-logout
# Web UI → Administration → General → GUI → Sign-out time: 15m

# 6. Desabilitar guest access
# Web UI → Administration → Users → guest → Disabled

# 7. Configure alertas de segurança
# Triggers para: failed logins, config changes, new admin users
```

## 📊 **Monitoramento**

### **🎯 Primeiros Passos Após Deploy**

1. **Acesse o Zabbix**: https://zabbix.local.127.0.0.1.nip.io:8443
2. **Login**: Admin / zabbix
3. **ALTERE A SENHA** imediatamente!
4. **Configure hosts**:
   - Configuration → Hosts → Create Host
   - Adicione os nós Kubernetes
   - Template: Linux by Zabbix agent
5. **Adicione templates**:
   - PostgreSQL by Zabbix agent
   - Redis by Zabbix agent
   - Nginx by Zabbix agent
6. **Configure actions**:
   - Configuration → Actions → Create action
   - Email, Telegram, Slack notifications
7. **Crie dashboards**:
   - Monitoring → Dashboard → Create dashboard
   - Adicione gráficos, mapas, problemas

### **📈 Templates Recomendados**

- **Linux by Zabbix agent**: Monitoramento de SO
- **PostgreSQL by Zabbix agent**: Database metrics
- **Redis by Zabbix agent**: Cache monitoring
- **Nginx by Zabbix agent**: Web server metrics
- **Kubernetes cluster by HTTP**: Cluster K8s
- **Docker by Zabbix agent**: Container stats

### **🔔 Alertas Importantes**

Configure triggers para:

- CPU usage > 80%
- Memory usage > 90%
- Disk space < 10%
- Service down
- Database connections > 80%
- Cache hit ratio < 70%
- Failed login attempts > 5

---

## 📚 **Documentação Adicional**

- 🌐 **Zabbix Documentation**: https://www.zabbix.com/documentation/7.4/en
- 📖 **PostgreSQL Integration**: https://www.zabbix.com/documentation/7.4/en/manual/installation/install_from_packages/postgresql
- 🐳 **Official Docker Images**: https://hub.docker.com/u/zabbix
- ☸️ **Kubernetes Helm Charts**: https://github.com/zabbix-community/helm-zabbix
- 🔧 **Zabbix API**: https://www.zabbix.com/documentation/7.4/en/manual/api

---

## 🎉 **Conclusão**

Você agora tem um **Zabbix 7.4.5 completo e empresarial** rodando em Kubernetes com:

✅ **Alta Disponibilidade**: Auto-scaling, health checks, restart automático  
✅ **Performance**: Redis cache, tuning PostgreSQL, resource limits otimizados  
✅ **Segurança**: TLS automático, secrets gerenciados, non-root containers  
✅ **Observabilidade**: Logs centralizados, métricas expostas, auditoria  
✅ **Backup**: Estratégia completa de backup database + volumes  
✅ **Escalabilidade**: HPA para Web, Agent2 e Agent Classic (1-3 pods cada)  
✅ **Componentes Completos**: Server, Web, Agent2, Agent Classic, Proxy, SNMP Traps, Java Gateway, Web Service

**Próximos Passos**:

1. Configure hosts e templates
2. Crie dashboards personalizados
3. Configure notificações (email, Slack, Telegram)
4. Implemente estratégia de backup automatizada
5. Configure integração com Grafana (opcional)

---

📝 **Documentação criada em**: 03/06/2025  
🔄 **Última atualização**: 03/06/2025  
✨ **Versão do Zabbix**: 7.4.5  
🏗️ **Arquitetura**: Kubernetes k3d com PostgreSQL 16 + Redis 8.2.3
