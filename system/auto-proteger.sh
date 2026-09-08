#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/futebol/protecao.log"
mkdir -p /var/log/futebol

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando verificação de proteção" >> "$LOG"

# Função para reiniciar serviço com segurança
check_and_restart() {
  local svc=$1
  local max_attempts=3
  local attempt=0
  
  if ! systemctl is-active --quiet "$svc" 2>/dev/null; then
    while [ $attempt -lt $max_attempts ]; do
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $svc TRAVOU! Tentativa $((attempt+1))/$max_attempts" >> "$LOG"
      systemctl restart "$svc" 2>/dev/null || true
      sleep 3
      
      if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $svc RESTAURADO" >> "$LOG"
        return 0
      fi
      attempt=$((attempt+1))
    done
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ FALHA CRÍTICA: $svc não recupera" >> "$LOG"
    return 1
  fi
  return 0
done

# Verifica serviços críticos
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Verificando serviços..." >> "$LOG"
check_and_restart "minha-api-futebol.service"
check_and_restart "nginx.service"

# Limpa cache HLS se ficar muito grande (>2GB)
HLS_SIZE=$(du -sb /var/www/html/hls 2>/dev/null | cut -f1 || echo "0")
HLS_SIZE_GB=$((HLS_SIZE / 1073741824))

if [ "$HLS_SIZE_GB" -gt 2 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Limpando cache HLS (${HLS_SIZE_GB}GB)" >> "$LOG"
  find /var/www/html/hls -type f -mmin +30 -delete 2>/dev/null || true
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cache HLS limpo" >> "$LOG"
fi

# Verifica integridade de banco de dados
DB_PATH="/opt/minha-api-futebol/futebol.db"
if [ -f "$DB_PATH" ]; then
  if ! sqlite3 "$DB_PATH" "PRAGMA integrity_check;" 2>/dev/null | grep -q "^ok$"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  BD CORROMPIDO! Fazendo backup..." >> "$LOG"
    cp "$DB_PATH" "$DB_PATH.bak.$(date +%s)" 2>/dev/null || true
    rm -f "$DB_PATH"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BD resetado" >> "$LOG"
  fi
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Proteção verificada com sucesso" >> "$LOG"
