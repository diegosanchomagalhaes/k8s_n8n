# 🗄️ Sistema de Backup para Kubernetes com Persistência hostPath

Sistema completo de backup e restore para aplicações Kubernetes com **persistência real no host** e automação via CronJobs.

## 🎯 **Persistência hostPath vs Backup**

### **✅ Persistência Automática (Ativa)**

Com a implementação hostPath, os dados **já são persistentes** no host:

```
/home/dsm/cluster/
├── postgresql/data/     # PostgreSQL - Dados já persistem
├── redis/              # Redis AOF - Cache já persiste
└── pvc/
    ├── n8n/           # n8n workflows - Já persistem
    └── grafana/       # Grafana dashboards - Já persistem
```

**🔄 TRUE PaaS Behavior:**

- Cluster pode ser **destruído** e **recriado**
- **TODOS os dados sobrevivem** automaticamente
- **Zero perda de dados** durante manutenção

### **🗄️ Backup Adicional (Redundância)**

Os scripts de backup servem para:

- **📦 Redundância externa**: Backup fora do host
- **🔄 Migração**: Mover dados entre ambientes
- **📅 Versionamento**: Manter histórico de mudanças
- **☁️ Cloud Backup**: Upload para AWS S3, Azure Blob, etc.

## 📋 Estrutura

```
backup/
├── scripts/                         # 🗂️ Scripts organizados numericamente
│   ├── 1.backup-postgresql.sh       # Backup PostgreSQL
│   ├── 2.backup-applications.sh     # Backup aplicações (n8n, grafana)
│   ├── 3.backup-complete.sh         # Backup completo
│   ├── 4.restore-postgresql.sh      # Restore PostgreSQL
│   ├── 5.restore-applications.sh    # Restore aplicações
│   ├── 6.restore-complete.sh        # Restore completo
│   └── 7.manage-backups.sh          # 🎛️ Gerenciador central
├── cronjobs/
│   ├── backup-rbac.yaml             # Permissões para CronJobs
│   └── n8n-backup-cronjob.yaml     # Backup automático
└── backups/                         # 📁 Arquivos de backup
    ├── postgresql/
    └── applications/
        └── [timestamp]/   # Backups organizados por data
```

## 🚀 Uso Rápido

### Backup Manual

```bash
# Backup completo do n8n
./backup/scripts/7.manage-backups.sh create n8n full

# Apenas banco de dados
./backup/scripts/7.manage-backups.sh create n8n db

# Backup completo via script direto
./backup/scripts/3.backup-complete.sh
```

### Listar Backups

```bash
./backup/scripts/7.manage-backups.sh list n8n
```

### Restaurar Backup

```bash
./backup/scripts/7.manage-backups.sh restore n8n 20240924_143022
# ou direto:
./backup/scripts/5.restore-applications.sh n8n 20240924_143022 full
```

### Backup Automático

```bash
# Ativar backup diário às 02:00
./backup/scripts/manage-backups.sh schedule n8n

# Verificar status
./backup/scripts/manage-backups.sh status

# Desativar
./backup/scripts/manage-backups.sh unschedule n8n
```

## 📊 Tipos de Backup

| Tipo    | Conteúdo                        | Uso                     |
| ------- | ------------------------------- | ----------------------- |
| `db`    | Banco de dados PostgreSQL       | Dados aplicação         |
| `files` | Volumes persistentes (PVC)      | Arquivos, logs, configs |
| `full`  | Banco + Volumes + Manifests K8s | Backup completo         |

## ⚙️ Configuração Automática

### CronJob de Backup

- **Agendamento**: Diário às 02:00
- **Retenção**: Últimos 7 backups
- **Local**: `./backups/postgresql/` (diretório local)
- **Compressão**: Automática (gzip)

### Estrutura dos Backups

```
backups/n8n/20240924_143022/
├── n8n_database_20240924_143022.sql.gz
├── n8n_files_20240924_143022.tar.gz
├── n8n_configs_20240924_143022.tar.gz
└── backup_info.json
```

## 🔧 Configuração Avançada

### Adicionar Nova Aplicação

1. Editar `backup-app.sh` e adicionar configurações no `case` statement
2. Criar CronJob específico baseado em `n8n-backup-cronjob.yaml`
3. Atualizar `manage-backups.sh` se necessário

### Exemplo de Configuração:

```bash
"nova-app")
    NAMESPACE="nova-app"
    DB_HOST="postgres.default.svc.cluster.local"
    DB_NAME="nova_app_db"
    PVC_NAME="nova-app-data-pvc"
    DEPLOYMENT_NAME="nova-app"
    ;;
```

## 🛡️ Segurança

- **Secrets**: Não incluídos nos backups por segurança
- **Credenciais**: Obtidas dinamicamente do Kubernetes
- **Permissões**: RBAC mínimo necessário
- **Isolamento**: Cada app em namespace próprio

## 🚨 Recuperação de Desastres

### Restauração Completa

```bash
# 1. Subir infraestrutura
./infra/scripts/9.start-infra.sh

# 2. Deploy aplicação
./k8s/apps/n8n/scripts/1.deploy-n8n.sh

# 3. Restaurar dados
./backup/scripts/manage-backups.sh restore n8n [timestamp]
```

### Restauração Seletiva

```bash
# Apenas banco de dados
./backup/scripts/restore-app.sh n8n [timestamp] db

# Apenas arquivos
./backup/scripts/restore-app.sh n8n [timestamp] files
```

## 📈 Monitoramento

### Verificar Backups

```bash
# Status geral
./backup/scripts/manage-backups.sh status

# Logs do último backup automático
kubectl logs -n n8n -l job-name=[job-name]

# Verificar CronJob
kubectl describe cronjob n8n-backup -n n8n
```

### Limpeza Automática

```bash
# Limpar backups > 7 dias
./backup/scripts/manage-backups.sh clean n8n 7

# Limpar backups > 30 dias
./backup/scripts/manage-backups.sh clean n8n 30
```

## 🔍 Troubleshooting

### Problemas Comuns

1. **Pod de backup não inicia**

   ```bash
   kubectl describe pod backup-pod-n8n -n n8n
   ```

2. **Permissões negadas**

   ```bash
   kubectl apply -f backup/cronjobs/backup-rbac.yaml
   ```

3. **Espaço insuficiente**

   ```bash
   df -h ./backups/
   ./backup/scripts/manage-backups.sh clean n8n 3
   ```

4. **Backup corrompido**
   ```bash
   # Verificar integridade
   gunzip -t backup_file.sql.gz
   tar -tzf backup_file.tar.gz > /dev/null
   ```

## 📚 Logs e Auditoria

### Arquivos de Log

- Backup manual: Output direto no terminal
- Backup automático: `kubectl logs -n n8n [cronjob-pod]`
- Metadados: `backup_info.json` em cada backup

### Auditoria

```bash
# Verificar histórico de backups
find ./backup/backups -name "backup_info.json" -exec cat {} \;

# Verificar jobs executados
kubectl get jobs -n n8n | grep backup
```

## 🎯 Próximos Passos

1. **Backup Remoto**: Configurar sincronização com cloud storage
2. **Notificações**: Alertas por email/Slack em caso de falha
3. **Métricas**: Dashboard Grafana para monitoramento
4. **Teste Automático**: Validação automática dos backups
5. **Múltiplas Aplicações**: Expandir para outras apps (Grafana, etc.)

---

**💡 Dica**: Execute backups manuais antes de updates importantes!

**⚠️ Importante**: Sempre teste a restauração em ambiente de desenvolvimento primeiro!
