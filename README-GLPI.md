# GLPI - Sistema de Gestão de Inventário e Central de Atendimento

## 📋 Visão Geral

Este diretório contém a configuração completa do GLPI (Gestionnaire libre de parc informatique) executando no Kubernetes com:

- **Versão**: 11.0.1
- **Base de Dados**: MariaDB 12.0.2 (suporte oficial GLPI)
- **Cache**: Redis 8.2.3 (database 2, compartilhado)
- **Persistência**: hostPath (dados preservados)
- **SSL/TLS**: Certificados automáticos via cert-manager
- **Monitoramento**: Probes de health check
- **Escalabilidade**: HPA configurado
- **fsGroup**: 1000 (compatível com user `dsm`)
- **Permissões**: Configuradas para escrita em `/home/dsm/cluster/applications/glpi/`

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────────┐
│   Ingress       │────│    GLPI      │────│    MariaDB 12.0.2   │
│  (HTTPS/TLS)    │    │   Service    │    │   (fsGroup: 999)    │
│ glpi.brioit.    │    │ (fsGroup:    │    │   Database: glpi    │
│   local:8443    │    │   1000)      │    │   Port: 30306       │
└─────────────────┘    └──────────────┘    └─────────────────────┘
                              │
                       ┌──────────────────┐
                       │  Redis 8.2.3     │
                       │  Database: 2      │
                       │  (Cache/Sessions) │
                       └──────────────────┘
                              │
                    ┌─────────────────────────┐
                    │   Persistent Storage    │
                    │ /home/dsm/cluster/      │
                    │  applications/glpi/     │
                    │  ├── data/ (app files)  │
                    │  ├── config/ (configs)  │
                    │  └── files/ (uploads)   │
                    └─────────────────────────┘
```

## 📁 Estrutura de Arquivos

```
glpi/
├── glpi-namespace.yaml           # Namespace do GLPI
├── glpi-secret-db.yaml          # Credenciais de banco (MariaDB + Redis)
├── glpi-secret-db.yaml.template # Template das credenciais
├── glpi-pv-hostpath.yaml        # Persistent Volumes (hostPath)
├── glpi-pv-hostpath.yaml.template # Template dos PVs
├── glpi-pvc.yaml                # Persistent Volume Claims
├── glpi-deployment.yaml         # Deployment principal
├── glpi-service.yaml            # Service (ClusterIP)
├── glpi-hpa.yaml                # Horizontal Pod Autoscaler
├── glpi-certificate.yaml        # Certificado TLS
├── glpi-ingress.yaml            # Ingress (acesso externo)
├── scripts/                     # Scripts de gerenciamento
│   ├── 1.deploy-glpi.sh        # Deploy completo
│   ├── 2.destroy-glpi.sh       # Destruir recursos
│   ├── 3.start-glpi.sh         # Iniciar GLPI parado
│   ├── 4.drop-database-glpi.sh # Remover banco de dados
│   ├── 5.restart-glpi.sh       # Reiniciar pods
│   └── 6.delete-volumes-glpi.sh # Remover volumes (CUIDADO!)
└── README.md                    # Esta documentação
```

## 🚀 Deploy Rápido

### Pré-requisitos

1. **Infraestrutura básica rodando:**

   ```bash
   cd ../../../../infra/scripts
   ./10.start-infra.sh
   ```

2. **Verificar dependências:**
   ```bash
   kubectl get pods -n postgres -l app=postgres
   kubectl get pods -n redis -l app=redis
   ```

### Deploy do GLPI

```bash
# Ir para o diretório de scripts
cd scripts/

# Deploy completo
# O script automaticamente:
# 1. Cria a database 'glpi' no MariaDB (se não existir)
# 2. Concede permissões ao usuário 'mariadb'
# 3. Faz deploy de todos os recursos (PV, PVC, Deployment, Service, Ingress, HPA)
./1.deploy-glpi.sh
```

**🔧 Novidade:** O script de deploy agora cria automaticamente a database e permissões **antes** do deployment, seguindo o padrão do Grafana. O init container no deployment serve como backup/redundância.

## 🔧 Gerenciamento

### Scripts Disponíveis

```bash
# Configurar hosts (executado automaticamente no deploy)
./0.setup-hosts-glpi.sh add

# Deploy completo (primeira vez)
./1.deploy-glpi.sh

# Destruir recursos (manter dados)
./2.destroy-glpi.sh

# Iniciar GLPI parado
./3.start-glpi.sh

# Reiniciar pods
./5.restart-glpi.sh

# Remover banco de dados (CUIDADO!)
./4.drop-database-glpi.sh

# Remover todos os dados (IRREVERSÍVEL!)
./6.delete-volumes-glpi.sh
```

### Comandos Úteis

```bash
# Status dos recursos
kubectl get all -n glpi

# Logs do GLPI
kubectl logs -f deployment/glpi -n glpi

# Acessar pod do GLPI
kubectl exec -it deployment/glpi -n glpi -- /bin/bash

# Verificar configuração do banco
kubectl exec -it deployment/glpi -n glpi -- env | grep GLPI_DB

# Verificar volumes
kubectl get pv | grep glpi
kubectl get pvc -n glpi
```

## 🌐 Acesso

### URLs de Acesso

- **Local**: https://glpi.local.127.0.0.1.nip.io

### Configuração Local

Já adicionado ao `/etc/hosts`:

```
127.0.0.1    glpi.local.127.0.0.1.nip.io
```

### 🔐 Credenciais de Acesso Padrão

GLPI fornece **4 perfis de usuário** diferentes para testes e configuração inicial:

| Perfil                 | Usuário     | Senha      | Descrição                          | Permissões                                       |
| ---------------------- | ----------- | ---------- | ---------------------------------- | ------------------------------------------------ |
| 🔵 **Super Admin**     | `glpi`      | `glpi`     | Administrador principal do sistema | Acesso total (configuração, usuários, entidades) |
| 🟢 **Admin (Técnico)** | `tech`      | `tech`     | Administrador técnico              | Gerenciar tickets, inventário, usuários          |
| 🟡 **Usuário Normal**  | `normal`    | `normal`   | Usuário padrão do sistema          | Criar/visualizar tickets próprios                |
| 🟠 **Post-only**       | `post-only` | `postonly` | Visualização limitada              | Apenas visualizar tickets                        |

#### 🌐 **URL de Acesso**

```
https://glpi.local.127.0.0.1.nip.io:8443
```

#### 💾 **Conexões Backend**

| Serviço         | Host                                     | Credenciais                                           | Database |
| --------------- | ---------------------------------------- | ----------------------------------------------------- | -------- |
| **MariaDB**     | `mariadb.mariadb.svc.cluster.local:3306` | `root` / `mariadb_root`                               | `glpi`   |
| **Redis Cache** | `redis.redis.svc.cluster.local:6379`     | Senha: `Redis_Shared_Cache_K8s_2024_9105092354952d9a` | DB2      |

> ⚠️ **RECOMENDAÇÃO DE SEGURANÇA CRÍTICA**:
>
> 1. **Altere TODAS as senhas padrão** imediatamente após primeiro acesso!
> 2. Desabilite ou remova usuários de teste que não serão utilizados
> 3. Configure políticas de senha forte no GLPI (Configuração → Geral → Autenticação)
> 4. Implemente autenticação LDAP/AD para ambientes corporativos
> 5. Revise permissões de cada perfil de acordo com suas necessidades
> 6. Aceite o certificado self-signed no navegador (porta 8443 obrigatória)

## 💾 Persistência de Dados

### Volumes Configurados

1. **glpi-data-pv** (5Gi): `/home/dsm/cluster/applications/glpi/data`
   - Dados da aplicação GLPI
2. **glpi-config-pv** (1Gi): `/home/dsm/cluster/applications/glpi/config`
   - Configurações personalizadas
3. **glpi-files-pv** (10Gi): `/home/dsm/cluster/applications/glpi/files`
   - Arquivos enviados, anexos, documentos

### Banco de Dados

**MariaDB 12.0.2:**

- **Database**: `glpi`
- **Host**: `mariadb.mariadb.svc.cluster.local`
- **Porta**: 3306
- **User**: `mariadb`
- **Compatibilidade**: Oficial GLPI MySQL/MariaDB

**Redis Cache (Database 2):**

- **Host**: `redis.redis.svc.cluster.local`
- **Porta**: 6379
- **Database**: `2` (DB2 exclusively for GLPI)
- **Purpose**: Cache de sessões, configurações e dados temporários
- **Variables**:
  - `GLPI_CACHE_REDIS_HOST`: redis.redis.svc.cluster.local
  - `GLPI_CACHE_REDIS_PORT`: 6379
  - `GLPI_CACHE_REDIS_DB`: 2

> 📝 **Redis Database**: GLPI utiliza **Redis DB2** exclusivamente para cache e sessões. Este database é separado dos outros aplicativos (n8n=DB0, Grafana=DB1, Prometheus=DB3).

## 🔐 **Permissões e Configuração**

### **fsGroup Configuration**

| Componente   | fsGroup | Proprietário                | Localização                            |
| ------------ | ------- | --------------------------- | -------------------------------------- |
| **GLPI Pod** | 1000    | `dsm:dsm`                   | `/home/dsm/cluster/applications/glpi/` |
| **MariaDB**  | 999     | `systemd-coredump:ssh_keys` | `/home/dsm/cluster/mariadb/`           |

### **Verificação de Permissões**

```bash
# Verificar permissões GLPI
ls -la /home/dsm/cluster/applications/glpi/
# Deve mostrar: drwxr-xr-x dsm dsm

# Verificar permissões MariaDB
ls -la /home/dsm/cluster/mariadb/
# Deve mostrar: drwxr-xr-x systemd-coredump ssh_keys
```

### **Correção Manual (se necessário)**

```bash
# Corrigir permissões GLPI
sudo chown -R 1000:1000 /home/dsm/cluster/applications/glpi/
sudo chmod -R 755 /home/dsm/cluster/applications/glpi/

# Corrigir permissões MariaDB
sudo mkdir -p /home/dsm/cluster/mariadb
sudo chown 999:999 /home/dsm/cluster/mariadb
sudo chmod 755 /home/dsm/cluster/mariadb
```

## ⚡ Escalabilidade

### HPA Configurado

- **Min replicas**: 1
- **Max replicas**: 3
- **CPU target**: 70%
- **Memory target**: 80%

### Recursos por Pod

- **Requests**: 512Mi RAM, 250m CPU
- **Limits**: 2Gi RAM, 1000m CPU

## 🔒 Segurança

### TLS/SSL

- Certificados automáticos via cert-manager
- Let's Encrypt DNS-01 challenge
- Redirecionamento HTTP → HTTPS

### Configurações de Segurança

- Containers non-root (UID 1000)
- Security contexts configurados
- Network policies (se disponível)
- Headers de segurança via Traefik

## 📊 Monitoramento

### Health Checks

- **Readiness**: `/status.php` (30s delay, 10s interval)
- **Liveness**: `/status.php` (60s delay, 30s interval)

### Logs

```bash
# Logs em tempo real
kubectl logs -f deployment/glpi -n glpi

# Logs do init container
kubectl logs deployment/glpi -n glpi -c create-database

# Eventos do namespace
kubectl get events -n glpi --sort-by='.lastTimestamp'
```

## 🔄 Backup e Restore

### Backup do Banco

```bash
# Via script da infra
cd ../../../../backup/scripts
./1.backup-postgresql.sh
```

### Backup de Arquivos

```bash
# Backup dos volumes hostPath
sudo tar -czf glpi-backup-$(date +%Y%m%d).tar.gz /mnt/cluster/applications/glpi/
```

## 🐛 Troubleshooting

### Problemas Comuns

1. **Pod não inicia**

   ```bash
   kubectl describe pod -l app=glpi -n glpi
   ```

2. **Banco não conecta**

   ```bash
   kubectl logs deployment/glpi -n glpi -c create-database
   ```

3. **Volumes com erro de permissão**

   ```bash
   kubectl logs deployment/glpi -n glpi -c fix-permissions
   ```

4. **Certificado SSL não funciona**
   ```bash
   kubectl get certificate -n glpi
   kubectl describe certificate glpi-tls-cert -n glpi
   ```

### Reset Completo

```bash
# 1. Destruir tudo
./2.destroy-glpi.sh

# 2. Remover volumes (CUIDADO!)
./6.delete-volumes-glpi.sh

# 3. Deploy novamente
./1.deploy-glpi.sh
```

## 🏠 Gerenciamento de Hosts

O script `0.setup-hosts-glpi.sh` permite gerenciar a entrada DNS local:

```bash
# Adicionar entrada no /etc/hosts
./0.setup-hosts-glpi.sh add

# Remover entrada
./0.setup-hosts-glpi.sh remove

# Verificar status
./0.setup-hosts-glpi.sh check
```

## 📚 Documentação Adicional

- [GLPI Official Documentation](https://glpi-project.org/documentation/)
- [GLPI Docker Hub](https://hub.docker.com/r/glpi/glpi)
- [PostgreSQL Integration](https://glpi-project.org/documentation/installation/requirements.php)

## 🤝 Contribuição

Para contribuir com melhorias:

1. Teste mudanças em ambiente local
2. Documente alterações no README
3. Mantenha compatibilidade com scripts existentes
4. Siga padrões dos outros projetos (n8n, Grafana)
