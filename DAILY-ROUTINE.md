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
- ✅ PostgreSQL funcionando (dados preservados)
- ✅ Redis funcionando (cache preservado)
- ✅ n8n funcionando (workflows preservados)
- ✅ Grafana funcionando (dashboards preservados)
- ✅ HTTPS/TLS configurado automaticamente

**⏱️ Tempo:** ~2-3 minutos

---

## 🎯 **URLs APÓS start-all.sh:**

- **n8n**: https://n8n.local.127.0.0.1.nip.io:8443
- **Grafana**: https://grafana.local.127.0.0.1.nip.io:8443 (admin/admin)

---

## 🆘 **COMANDOS ALTERNATIVOS (se necessário):**

### **Somente Infraestrutura:**

```bash
# Subir apenas PostgreSQL + Redis + cert-manager
./infra/scripts/10.start-infra.sh
```

### **Aplicações Individuais:**

```bash
# Subir apenas n8n
./start-all.sh n8n

# Subir apenas Grafana
./start-all.sh grafana
```

### **Teste de Persistência:**

```bash
# Testa destroy + recreate automaticamente
./infra/scripts/15.test-persistence.sh
```

### **Limpeza Completa (cuidado!):**

```bash
# Remove TODOS os dados persistentes (reset completo)
./infra/scripts/14.clean-cluster-data.sh
```

---

## 💡 **DICAS:**

1. **✅ Execute sempre** `2.destroy-infra.sh` antes de desligar
2. **✅ Execute sempre** `start-all.sh` ao ligar
3. **⚠️ NUNCA execute** `14.clean-cluster-data.sh` sem backup
4. **📱 Acesse URLs** somente após `start-all.sh` completar
5. **⏱️ Aguarde ~2min** para tudo ficar pronto

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
