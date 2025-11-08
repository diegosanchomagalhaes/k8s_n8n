# 🗓️ ROTINA DIÁRIA - Comandos k8s Local

## 🌙 **AO DESLIGAR O LAPTOP (Noite)**

```bash
cd /home/dsm/brioit_local
./infra/scripts/2.destroy-infra.sh
```

**✅ Resultado:**

- ✅ Cluster k3d removido
- ✅ Recursos Kubernetes limpos
- ✅ RAM liberada
- ✅ **DADOS PRESERVADOS** em `/home/dsm/cluster/`

**⏱️ Tempo:** ~30 segundos

---

## 🌅 **AO LIGAR O LAPTOP (Manhã)**

```bash
cd /home/dsm/brioit_local
./start-all.sh
```

**✅ Resultado:**

- ✅ Cluster k3d recriado
- ✅ PostgreSQL funcionando (databases: n8n, grafana, prometheus)
- ✅ MariaDB funcionando (database: glpi)
- ✅ Redis funcionando (cache DB0-DB3 preservado)
- ✅ n8n funcionando (workflows preservados)
- ✅ Grafana funcionando (dashboards preservados)
- ✅ Prometheus funcionando (métricas preservadas)
- ✅ GLPI funcionando (dados preservados)
- ✅ HTTPS/TLS configurado automaticamente

**⏱️ Tempo:** ~5-6 minutos (4 aplicações completas)

---

## 🎯 **URLs APÓS start-all.sh:**

- **n8n**: https://n8n.local.127.0.0.1.nip.io:8443
- **Grafana**: https://grafana.local.127.0.0.1.nip.io:8443 (admin/Admin_Grafana_2025_K8s_10243769)
- **Prometheus**: https://prometheus.local.127.0.0.1.nip.io:8443
- **GLPI**: https://glpi.local.127.0.0.1.nip.io:8443

---

## 🆘 **COMANDOS ALTERNATIVOS (se necessário):**

### **Somente Infraestrutura:**

```bash
# Subir apenas PostgreSQL + MariaDB + Redis + cert-manager
./infra/scripts/10.start-infra.sh
```

### **Aplicações Individuais:**

```bash
# Subir apenas n8n
./start-all.sh n8n

# Subir apenas Grafana
./start-all.sh grafana

# Subir apenas Prometheus
./start-all.sh prometheus

# Subir apenas GLPI
./start-all.sh glpi
```

### **Teste de Persistência:**

```bash
# Testa destroy + recreate automaticamente
./infra/scripts/19.test-persistence.sh
```

### **Limpeza Completa (cuidado!):**

```bash
# Opção 1: Destruição completa automatizada (recomendado)
./infra/scripts/18.destroy-all.sh
# Drop databases → Destroy cluster → Clean filesystem

# Opção 2: Limpeza manual em 3 etapas
./infra/scripts/14.clean-cluster-data.sh  # Drop databases (cluster rodando)
./infra/scripts/2.destroy-infra.sh        # Destroy cluster
./infra/scripts/15.clean-cluster-pvc.sh   # Clean filesystem (cluster parado)
```

---

## 💡 **DICAS:**

1. **✅ Execute sempre** `2.destroy-infra.sh` antes de desligar
2. **✅ Execute sempre** `start-all.sh` ao ligar
3. **⚠️ NUNCA execute** `18.destroy-all.sh` sem backup (remove TODOS os dados)
4. **📱 Acesse URLs** somente após `start-all.sh` completar
5. **⏱️ Aguarde ~5-6min** para todas as 4 aplicações ficarem prontas
6. **🔐 Credenciais**: Verifique READMEs específicos de cada app
7. **🗄️ Databases**: PostgreSQL (n8n, grafana, prometheus) + MariaDB (glpi)
8. **💾 Redis**: DB0=n8n, DB1=grafana, DB2=glpi, DB3=prometheus

---

## 🎉 **RESULTADO:**

**Kubernetes local com persistência REAL!** 🚀

- Zero configuração diária
- Zero perda de dados
- Ambiente sempre consistente
- Performance otimizada (cluster limpo diariamente)

---

_Gerado em: $(date)_
_Versão: k8s_local com hostPath persistence_
