# 💾 Persistência hostPath - TRUE PaaS Behavior

> ✅ **IMPLEMENTADO**: Todos os dados sobrevivem à destruição/recriação do cluster k3d (comportamento PaaS real).

## 🎯 **Status Atual - Implementação Completa**

### **✅ TRUE PaaS BEHAVIOR ATIVO**

- 🔴 Cluster pode ser **COMPLETAMENTE DESTRUÍDO** (`k3d cluster delete`)
- ✅ **TODOS os dados SOBREVIVEM** no host em `/home/dsm/cluster/`
- 🔄 **Recreação automática** recupera todos os dados
- 🌐 Comportamento **idêntico a um PaaS** (AWS, Azure, GCP)

### **🏗️ Configuração do Cluster**

```bash
# Cluster criado com volume bind real
k3d cluster create --volume "/home/dsm/cluster:/home/dsm/cluster@all"
```

### **📁 Estrutura de Persistência Atual**

```
/home/dsm/cluster/
├── postgresql/
│   └── data/              # PostgreSQL 16 - Bancos: n8n, grafana
├── redis/
│   └── appendonlydir/     # Redis AOF - Cache persistente
└── pvc/
    ├── n8n/               # n8n workflows e configurações
    └── grafana/           # Dashboards e configurações
```

## 🔄 **Validação de Persistência - TESTADO**

### **Todos os Serviços Validados**

| Serviço        | Status | Localização Host                    | Teste Executado          |
| -------------- | ------ | ----------------------------------- | ------------------------ |
| **PostgreSQL** | ✅     | `/home/dsm/cluster/postgresql/data` | ✅ Restart testado       |
| **Redis**      | ✅     | `/home/dsm/cluster/redis`           | ✅ **RECÉM VALIDADO**    |
| **n8n**        | ✅     | `/home/dsm/cluster/pvc/n8n`         | ✅ Workflows preservados |
| **Grafana**    | ✅     | `/home/dsm/cluster/pvc/grafana`     | ✅ Dashboards mantidos   |

### **🧪 Teste de Persistência Redis (Exemplo)**

```bash
# 1. Inserir dados no Redis
kubectl exec -n redis redis-xxx -- redis-cli set teste-persistencia "dados redis - $(date)"

# 2. Deletar pod para simular falha
kubectl delete pod -n redis redis-xxx

# 3. Verificar dados após restart
kubectl exec -n redis redis-yyy -- redis-cli get teste-persistencia
# Resultado: "dados redis - Wed Oct  8 10:07:24 PM -03 2025" ✅
    └── backup/             # Backups do Grafana
```

## 🔧 **Como Configurar**

### **Passo 1: Configurar Templates**

```bash
# Executar script que substitui [CLUSTER_BASE_PATH] pelo path real
./infra/scripts/13.configure-hostpath.sh
```

**O que faz:**

- Processa templates `*-pv-hostpath.yaml.template`
- Substitui `[CLUSTER_BASE_PATH]` por `/home/dsm/cluster`
- Gera arquivos `*-pv-hostpath.yaml` prontos para uso

### **Passo 2: Criar Estrutura de Diretórios**

```bash
# Criar todos os diretórios necessários
./infra/scripts/9.setup-directories.sh
```

**O que faz:**

- Cria estrutura completa em `/home/dsm/cluster/`
- Define permissões adequadas
- Prepara diretórios para todos os serviços

### **Passo 3: Deploy com Persistência**

```bash
# Deploy completo usando hostPath
./start-all.sh
```

## 📋 **Templates Disponíveis**

| Template                                             | Arquivo Gerado              | Serviço    |
| ---------------------------------------------------- | --------------------------- | ---------- |
| `infra/postgres/postgres-pv-hostpath.yaml.template`  | `postgres-pv-hostpath.yaml` | PostgreSQL |
| `infra/redis/redis-pv-hostpath.yaml.template`        | `redis-pv-hostpath.yaml`    | Redis      |
| `k8s/apps/n8n/n8n-pv-hostpath.yaml.template`         | `n8n-pv-hostpath.yaml`      | n8n        |
| `k8s/apps/grafana/grafana-pv-hostpath.yaml.template` | `grafana-pv-hostpath.yaml`  | Grafana    |

## 🔄 **Como Funciona**

### **PersistentVolume com hostPath**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv-hostpath
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: hostpath-storage
  hostPath:
    path: /home/dsm/cluster/postgresql/data
    type: DirectoryOrCreate
```

### **PersistentVolumeClaim com Seletor**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: postgres
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: hostpath-storage
  resources:
    requests:
      storage: 20Gi
  selector:
    matchLabels:
      storage-type: hostpath
```

## 📊 **Comparação: Padrão vs Persistente**

| Aspecto          | local-path (Padrão)             | hostPath (Recomendado)         |
| ---------------- | ------------------------------- | ------------------------------ |
| **Localização**  | `/var/lib/rancher/k3s/storage/` | `/home/dsm/cluster/`           |
| **Persistência** | ❌ Perdido ao destruir cluster  | ✅ Sobrevive à destruição      |
| **Backup**       | ❌ Difícil de acessar           | ✅ Fácil acesso via filesystem |
| **Configuração** | ✅ Automático                   | 🔧 Requer configuração         |
| **Performance**  | ✅ Otimizado k3d                | ✅ Performance similar         |

## 🧪 **Testando a Persistência**

### **Teste Automatizado**

```bash
# Script automático que testa persistência completa
./infra/scripts/15.test-persistence.sh
```

### **Teste Manual**

```bash
# 1. Deploy com dados
./start-all.sh

# 2. Criar dados de teste
kubectl exec -n postgres postgres-0 -- psql -U postgres -c "CREATE DATABASE teste;"

# 3. Destruir cluster (mantendo dados)
./infra/scripts/2.destroy-infra.sh

# 4. Verificar se dados persistem
ls -la /home/dsm/cluster/postgresql/data/

# 5. Recriar cluster
./start-all.sh

# 6. Verificar se dados voltaram
kubectl exec -n postgres postgres-0 -- psql -U postgres -l | grep teste
```

## 🎛️ **Personalização do Path**

### **Alterar Path Base**

1. **Editar script de configuração:**

   ```bash
   nano infra/scripts/13.configure-hostpath.sh
   # Alterar: CLUSTER_BASE_PATH="/seu/path/customizado"
   ```

2. **Executar configuração:**
   ```bash
   ./infra/scripts/13.configure-hostpath.sh
   ./infra/scripts/9.setup-directories.sh
   ```

### **Templates Manuais**

Para configuração manual, edite os templates substituindo:

- `[CLUSTER_BASE_PATH]` → Seu path desejado

## ⚠️ **Importantes**

1. **Permissões**: Certifique-se que o usuário tem acesso de escrita no path
2. **Espaço**: Monitore espaço disponível (PostgreSQL pode crescer significativamente)
3. **Backup**: Mesmo com persistência, mantenha backups regulares
4. **Segurança**: Path deve estar em local seguro e com permissões adequadas

## 🔧 **Troubleshooting**

### **PVC Pending**

```bash
# Verificar PVs disponíveis
kubectl get pv

# Verificar eventos do PVC
kubectl describe pvc postgres-pvc -n postgres
```

### **Dados Não Persistem**

1. Verificar se está usando storageClassName correto
2. Confirmar se diretórios foram criados
3. Validar permissões nos diretórios hostPath

### **Performance Issues**

1. Verificar I/O do disco onde está o hostPath
2. Considerar SSD para melhor performance
3. Monitorar uso de espaço
