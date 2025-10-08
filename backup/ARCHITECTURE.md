# 🏗️ Arquitetura de Backup Corrigida

## 📁 Estrutura de Diretórios

A arquitetura de backup foi reorganizada para usar os diretórios específicos criados no cluster k3d:

### 🗂️ No Host (fora do cluster)

```
/mnt/e/cluster/
├── postgresql/
│   └── backup/           # Backups do PostgreSQL
│       ├── n8n_db_TIMESTAMP.sql.gz
│       ├── n8n_configs_TIMESTAMP.tar.gz
│       └── ...
├── pvc/
│   └── backup/           # Backups dos PVCs/Files
│       ├── n8n_files_TIMESTAMP.tar.gz
│       └── ...
└── ...
```

### 🐳 Dentro do k3d

```
/mnt/host-cluster/        # Mount point dentro do k3d
├── postgresql/
│   └── backup/           # Mapeado para /mnt/e/cluster/postgresql/backup
├── pvc/
│   └── backup/           # Mapeado para /mnt/e/cluster/pvc/backup
└── ...
```

## 🔧 Scripts Atualizados

### 1. `manage-backups.sh`

- ✅ Variáveis atualizadas:
  - `POSTGRESQL_BACKUP_DIR="/mnt/host-cluster/postgresql/backup"`
  - `PVC_BACKUP_DIR="/mnt/host-cluster/pvc/backup"`
- ✅ Função `list_backups()` corrigida para buscar nos diretórios específicos
- ✅ Função `clean_backups()` atualizada para limpar ambos os locais

### 2. `backup-app.sh`

- ✅ Backups diretos para locais específicos:
  - `DB_BACKUP_FILE="$POSTGRESQL_BACKUP_DIR/${APP_NAME}_db_${TIMESTAMP}.sql.gz"`
  - `PVC_BACKUP_FILE="$PVC_BACKUP_DIR/${APP_NAME}_files_${TIMESTAMP}.tar.gz"`
- ✅ Configurações salvas no diretório PVC

### 3. `restore-app.sh`

- ✅ Verificação de arquivos nos locais corretos
- ✅ Restore específico por tipo (db/files/full)
- ✅ Paths corrigidos para nova estrutura

## 🎯 Tipos de Backup

### 🐘 PostgreSQL (`/postgresql/backup/`)

- **Arquivo**: `{app}_db_{timestamp}.sql.gz`
- **Conteúdo**: Dump completo do banco de dados
- **Comando**: `pg_dump` comprimido com gzip

### 📁 PVC/Files (`/pvc/backup/`)

- **Arquivo**: `{app}_files_{timestamp}.tar.gz`
- **Conteúdo**: Todos os arquivos do volume persistente
- **Comando**: `tar czf` via pod temporário

### ⚙️ Configurações (`/pvc/backup/`)

- **Arquivo**: `{app}_configs_{timestamp}.tar.gz`
- **Conteúdo**: Manifestos Kubernetes (deployment, services, ingress, etc.)
- **Local**: Salvo junto com backups de arquivos

## 📋 Comandos de Exemplo

```bash
# Listar backups disponíveis
./manage-backups.sh list n8n

# Criar backup completo
./manage-backups.sh create n8n full

# Criar backup apenas do banco
./manage-backups.sh create n8n db

# Criar backup apenas dos arquivos
./manage-backups.sh create n8n files

# Restaurar backup completo
./manage-backups.sh restore n8n 20240924_143022

# Limpar backups antigos (7 dias)
./manage-backups.sh clean n8n 7
```

## 🔄 Processo de Backup

### 1. **Backup do Banco**

```bash
kubectl exec postgres-0 -- pg_dump ... | gzip > /mnt/host-cluster/postgresql/backup/n8n_db_TIMESTAMP.sql.gz
```

### 2. **Backup dos Arquivos**

```bash
kubectl exec backup-pod -- tar czf - /data > /mnt/host-cluster/pvc/backup/n8n_files_TIMESTAMP.tar.gz
```

### 3. **Backup das Configurações**

```bash
kubectl get deployment,service,ingress... -o yaml | tar czf /mnt/host-cluster/pvc/backup/n8n_configs_TIMESTAMP.tar.gz
```

## ✅ Benefícios da Nova Arquitetura

1. **🎯 Separação Lógica**: Backups organizados por tipo de dados
2. **🔍 Busca Específica**: Fácil localização de backups por categoria
3. **🚀 Performance**: Operações paralelas em diferentes tipos
4. **📦 Manutenção**: Limpeza independente por categoria
5. **🔧 Flexibilidade**: Restore seletivo (db OU files OU completo)

## 🔒 Segurança

- ✅ Backups do PostgreSQL isolados
- ✅ Configurações Kubernetes sem secrets
- ✅ Paths absolutos e verificação de existência
- ✅ Validação antes de restore
