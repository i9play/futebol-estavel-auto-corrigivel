# ⚡ Instalação Rápida - Futebol Estável

## 📋 Pré-requisitos

- Ubuntu/Debian 20.04 ou superior
- Acesso root (sudo)
- 5GB de espaço em disco
- Conexão de internet

## 🚀 Instalação em 4 Passos

### 1. Clone o repositório

```bash
cd /root
git clone https://github.com/i9play/futebol-estavel-auto-corrigivel.git
cd futebol-estavel-auto-corrigivel
```

### 2. Execute o instalador

```bash
chmod +x instalar.sh
sudo ./instalar.sh
```

> ⏱️ Tempo estimado: 3-4 minutos

### 3. Aguarde a conclusão

O script mostrará quando tudo está pronto. Você será solicitado a colar sua **API-FOOTBALL Key** (única vez).

### 4. Verifique o status

```bash
sudo ./system/health-check.sh
```

## 🔗 Acesso aos Serviços

```
Jogos de Amanhã:
  Web: http://SEU_IP/jogos_dia.html
  HLS: http://SEU_IP/hls/jogosdia.m3u8

Tabela de Gols:
  Web: http://SEU_IP/placar.html
  HLS: http://SEU_IP/hls/placares.m3u8

API Local:
  http://SEU_IP:5000/api/hoje
  http://SEU_IP:5000/api/live
```

Para descobrir seu IP:

```bash
hostname -I
```

## 🛠️ Comandos Essenciais

### Ver status de tudo

```bash
sudo ./system/health-check.sh
```

### Diagnosticar problema

```bash
sudo ./system/diagnostico.sh
```

### Acompanhar em tempo real

```bash
sudo ./system/monitorar.sh
```

### Ativar auto-proteção

```bash
sudo ./system/auto-proteger.sh
```

### Reiniciar tudo

```bash
sudo ./system/reiniciar-tudo.sh
```

### Reiniciar um serviço específico

```bash
sudo systemctl restart minha-api-futebol.service
```

## 🔍 Solução de Problemas

### Audio travando?

```bash
sudo ./system/auto-proteger.sh
```

### Vídeo com pipoca?

```bash
sudo systemctl restart nginx.service
```

### API não responde?

```bash
sudo systemctl restart minha-api-futebol.service
sudo ./system/diagnostico.sh
```

### Ver logs completos

```bash
sudo tail -f /var/log/futebol/*.log
```

## ✅ Sistema de Auto-Recuperação

O sistema **monitora continuamente** e se detectar um problema:

- ✅ Reinicia automaticamente a cada 10 minutos
- ✅ Limpa cache se ficar muito grande
- ✅ Valida integridade do banco de dados
- ✅ Registra todos os problemas em `/var/log/futebol/`

## 📊 Estrutura de Logs

```
/var/log/futebol/
├── instalacao.log      # Log da instalação
├── sync.log            # Sincronização
├── protecao.log        # Auto-proteção
└── api.log             # API Local
```

## 🎯 O Que Muda vs Versão Anterior

| Aspecto | Antes | Depois |
|---------|-------|--------|
| Tempo de Instalação | 10+ min | 3-4 min |
| Auto-Recuperação | ❌ Manual | ✅ Automática |
| Logs | 🔄 Desorganizados | 📁 Estruturados |
| Health Check | ❌ Nenhum | ✅ 24/7 |
| Buffer Áudio | 😢 Baixo | 😊 Alto |

## 📞 Precisa de Help?

1. **Primeiro**: `sudo ./system/diagnostico.sh`
2. **Depois**: Veja os logs: `sudo tail -f /var/log/futebol/protecao.log`
3. **Por último**: Reinicie: `sudo ./system/reiniciar-tudo.sh`

---

**Desenvolvido para ser ESTÁVEL, RÁPIDO e SEM DOR DE CABEÇA** 🎉
