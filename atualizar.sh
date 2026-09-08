#!/usr/bin/env bash

# ============================================================
# SCRIPT DE ATUALIZAÇÃO - Futebol Estável
# Mantém tudo atualizado e seguro
# ============================================================

echo ""
echo "🔄 Atualizando Futebol Estável..."
echo ""

HERE="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="/var/log/futebol"

mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando atualização" >> "$LOG_DIR/atualizacao.log"

# Pull do repositório
echo "📦 Baixando atualizações..."
cd "$HERE"
git pull origin main --quiet

# Atualiza dependências
echo "📚 Atualizando dependências do sistema..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >> "$LOG_DIR/atualizacao.log" 2>&1
apt-get upgrade -y >> "$LOG_DIR/atualizacao.log" 2>&1

# Regenera M3U8 e Temas
echo "🎬 Regenerando M3U8 e Temas XUI One..."
bash "$HERE/componentes/xui-generator/gerar-m3u8-temas.sh" >> "$LOG_DIR/atualizacao.log" 2>&1

# Valida integridade
echo "✅ Validando integridade..."
bash "$HERE/system/validar.sh" >> "$LOG_DIR/atualizacao.log" 2>&1

# Reinicia serviços críticos
echo "🔄 Reiniciando serviços..."
systemctl restart nginx.service
systemctl restart minha-api-futebol.service
sleep 2

echo ""
echo "✅ Atualização Concluída!"
echo ""
echo "📊 Status:"
bash "$HERE/system/health-check.sh"
echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Atualização concluída com sucesso" >> "$LOG_DIR/atualizacao.log"
