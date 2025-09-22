# ==================================================================

# BrioIT Local - Configuração de Secrets

# ==================================================================

## 🔐 Configuração Necessária Após Clone

Após clonar este repositório, você precisa configurar as credenciais:

### 1. **PostgreSQL Admin Password**

Copie os templates e configure as senhas:

```bash
# 1. Copiar template do PostgreSQL
cp infra/postgres/postgres-secret-admin.yaml.template \
   infra/postgres/postgres-secret-admin.yaml

# 2. Editar e substituir YOUR_POSTGRES_ADMIN_PASSWORD_HERE
nano infra/postgres/postgres-secret-admin.yaml
```

### 2. **n8n Database Secret**

```bash
# 1. Copiar template do n8n
cp k8s/apps/n8n/n8n-secret-db.yaml.template \
   k8s/apps/n8n/n8n-secret-db.yaml

# 2. Editar e substituir YOUR_POSTGRES_ADMIN_PASSWORD_HERE
nano k8s/apps/n8n/n8n-secret-db.yaml
```

**⚠️ IMPORTANTE: Use a MESMA senha nos dois arquivos!**

**ℹ️ NOTA: Os templates usam o usuário padrão `postgres` do PostgreSQL para máxima compatibilidade.**

### 3. **Sugestão de Senha Segura**

```bash
# Gerar senha segura (exemplo):
openssl rand -base64 24
```

### 4. **Verificar Configuração**

```bash
# Verificar se os templates foram copiados
ls -la infra/postgres/postgres-secret-admin.yaml
ls -la k8s/apps/n8n/n8n-secret-db.yaml

# Verificar se as senhas foram substituídas
grep -v "YOUR_POSTGRES_ADMIN_PASSWORD_HERE" \
  infra/postgres/postgres-secret-admin.yaml \
  k8s/apps/n8n/n8n-secret-db.yaml
```

### 5. **Inicializar Ambiente**

Após configurar as senhas:

```bash
# Executar script de inicialização
./infra/scripts/9.start-n8n.sh
```

## 🚫 **O que NÃO commitar:**

- `postgres-secret-admin.yaml` (com senhas)
- `n8n-secret-db.yaml` (com senhas)
- Qualquer arquivo com credenciais reais

## ✅ **O que commitar:**

- `*.template` (templates sem senhas)
- Scripts de configuração
- Documentação
- Manifestos Kubernetes (sem secrets)

## 🔒 **Segurança:**

- **Nunca** commite senhas reais no Git
- **Sempre** use templates para repositórios públicos
- **Configure** `.gitignore` corretamente
- **Gere** senhas seguras para produção
