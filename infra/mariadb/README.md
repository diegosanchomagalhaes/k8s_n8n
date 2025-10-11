# MariaDB Infrastructure

MariaDB database server para suporte ao GLPI no ambiente Kubernetes.

## 🎯 **Configuração Atual**

- **Versão**: MariaDB 12.0.2
- **Namespace**: `mariadb`
- **Persistência**: hostPath `/home/dsm/cluster/mariadb/`
- **fsGroup**: 999 (compatível com systemd-coredump)
- **Porta Externa**: 30306 (NodePort)
- **Database**: `glpi` (criada automaticamente)
- **Usuário GLPI**: Credenciais específicas em secret

## 🏗️ **Arquitetura**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   GLPI Pods     │────│  MariaDB Service │────│  MariaDB StatefulSet│
│  (fsGroup:1000) │    │   (Port: 3306)   │    │   (fsGroup: 999)    │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                          │
                                                ┌─────────────────────┐
                                                │  PVC (hostPath)     │
                                                │ /home/dsm/cluster/  │
                                                │     mariadb/        │
                                                └─────────────────────┘
```

## 📋 Arquivos Disponíveis

### **Principais:**

- `mariadb-deployment.yaml` - StatefulSet, Service e Namespace completo
- `mariadb-secret-admin.yaml` - Credenciais administrativas
- `mariadb-pv-hostpath.yaml` - PersistentVolume com hostPath
- `mariadb-pvc.yaml` - PersistentVolumeClaim

### **Templates:**

- `mariadb-secret-admin.yaml.template` - Template para credenciais
- `mariadb-pv-hostpath.yaml.template` - Template para PV

### **Alternative Storage:**

- `mariadb-pv.yaml` - PVC com local-path storage class

## 🚀 Deploy Manual

```bash
# 1. Criar namespace e componentes principais
kubectl apply -f mariadb-deployment.yaml

# 2. Aplicar PersistentVolume
kubectl apply -f mariadb-pv-hostpath.yaml

# 3. Aplicar PersistentVolumeClaim
kubectl apply -f mariadb-pvc.yaml

# 4. Aplicar credenciais
kubectl apply -f mariadb-secret-admin.yaml

# 5. Aguardar MariaDB ficar pronto
kubectl rollout status statefulset/mariadb -n mariadb
```

## 🔧 Scripts Automatizados

```bash
# Criar MariaDB (usa os scripts da infra)
./infra/scripts/16.create-mariadb.sh

# Remover MariaDB
./infra/scripts/17.delete-mariadb.sh
```

## 🔐 **Permissões e Segurança**

### **Configuração de Permissões**

```bash
# Verificar permissões da pasta MariaDB
ls -la /home/dsm/cluster/mariadb/

# Deve mostrar:
# drwxr-xr-x systemd-coredump ssh_keys /home/dsm/cluster/mariadb/
```

### **Correção Manual (se necessário)**

```bash
# Criar pasta com permissões corretas
sudo mkdir -p /home/dsm/cluster/mariadb

# Definir proprietário para fsGroup 999
sudo chown 999:999 /home/dsm/cluster/mariadb

# Permissões de leitura/escrita
sudo chmod 755 /home/dsm/cluster/mariadb
```

### **Credenciais Gerenciadas**

- **Admin**: `mariadb-admin-secret` (root/admin access)
- **GLPI**: `glpi-mariadb-secret` (user específico GLPI)
- **Templates**: Arquivos `.template` para configuração segura

> ⚠️ **IMPORTANTE**: fsGroup 999 deve ter permissões de escrita na pasta de dados!

## 📊 Configuração

### **Namespace:** `mariadb`

### **Service:** `mariadb.mariadb.svc.cluster.local:3306`

### **Imagem:** `mariadb:12.0.2` (versão estável mais recente)

### **Persistência:** `/mnt/cluster/mariadb` (hostPath)

### **Credenciais (mariadb-secret-admin):**

- **MYSQL_ROOT_PASSWORD:** mariadb_admin
- **MYSQL_DATABASE:** mariadb
- **MYSQL_USER:** mariadb_admin
- **MYSQL_PASSWORD:** mariadb_admin

## 🔗 Integração com GLPI

O GLPI deve usar estas variáveis de ambiente:

```yaml
- name: GLPI_DB_ENGINE
  value: "mysql"
- name: GLPI_DB_HOST
  value: "mariadb.mariadb.svc.cluster.local"
- name: GLPI_DB_PORT
  value: "3306"
- name: GLPI_DB_NAME
  value: "glpi" # Database criada automaticamente
```

## 💾 Persistência

### **Dados armazenados em:**

- Host: `/home/dsm/cluster/mariadb/`
- Container: `/var/lib/mysql`

### **Databases criadas:**

- `mariadb` - Database administrativa
- `glpi` - Database principal para GLPI (criada pelo init container do GLPI)

## 🛠️ Troubleshooting

### **Verificar status:**

```bash
kubectl get pods -n mariadb
kubectl logs -f statefulset/mariadb -n mariadb
```

### **Acessar MariaDB:**

```bash
kubectl exec -it mariadb-0 -n mariadb -- mysql -u root -p
# Password: mariadb_admin
```

### **Testar conectividade do GLPI:**

```bash
kubectl run test-mysql --rm -it --image=mariadb:12.0.2 -- mysql -h mariadb.mariadb.svc.cluster.local -u mariadb -p
```

## 🔄 Compatibilidade

- **GLPI:** ✅ Suporte oficial MySQL/MariaDB
- **PostgreSQL:** ❌ GLPI não suporta oficialmente
- **k3d:** ✅ Persistência com hostPath
- **Storage:** ✅ hostpath-storage e local-path
