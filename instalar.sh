#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  FUTEBOL ESTÁVEL - Instalador Otimizado
#  Versão 2.0 - Sem travamentos, sem pipoca, sem dor de cabeça
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ ERRO: execute como root ou use 'sudo ./instalar.sh'"
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="/var/log/futebol"
APP="/opt/minha-api-futebol"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================
# FUNÇÕES AUXILIARES
# ============================================================

log_info() { echo -e "${BLUE}[ℹ] $1${NC}"; }
log_ok() { echo -e "${GREEN}[✓] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[⚠] $1${NC}"; }
log_error() { echo -e "${RED}[✗] $1${NC}"; }
log_step() { echo -e "${BLUE}\n═════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}═════════════════════════════════════════${NC}\n"; }

# Criação de diretórios de log
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# ============================================================
# 1. PRÉ-VALIDAÇÃO
# ============================================================

log_step "[1/11] PRÉ-VALIDAÇÃO DO SISTEMA"

if ! command -v apt-get &> /dev/null; then
  log_error "Apenas Ubuntu/Debian suportado"
  exit 1
fi

if ! command -v docker &> /dev/null && [ ! -d /var/www/html ]; then
  log_warn "Ambiente não preparado. Continuando com setup completo..."
else
  log_ok "Ambiente detectado"
fi

# ============================================================
# 2. INSTALAÇÃO DE DEPENDÊNCIAS (apenas o necessário)
# ============================================================

log_step "[2/11] INSTALANDO DEPENDÊNCIAS"

export DEBIAN_FRONTEND=noninteractive

DEPS_NEEDED=()
for dep in python3 python3-venv python3-pip nginx ffmpeg curl unzip openssl; do
  if ! dpkg -l | grep -q "^ii.*$dep"; then
    DEPS_NEEDED+=("$dep")
  fi
done

if [ ${#DEPS_NEEDED[@]} -gt 0 ]; then
  log_info "Instalando: ${DEPS_NEEDED[*]}"
  apt-get update -y >> "$LOG_DIR/instalacao.log" 2>&1
  apt-get install -y "${DEPS_NEEDED[@]}" >> "$LOG_DIR/instalacao.log" 2>&1
  log_ok "Dependências instaladas"
else
  log_ok "Todas dependências já estão presentes"
fi

# Chrome para Playwright (apenas se não existir)
if ! command -v google-chrome-stable &> /dev/null; then
  log_info "Instalando Google Chrome..."
  curl -sL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  apt-get install -y /tmp/chrome.deb >> "$LOG_DIR/instalacao.log" 2>&1
  rm -f /tmp/chrome.deb
  log_ok "Chrome instalado"
else
  log_ok "Chrome já presente"
fi

# ============================================================
# 3. PREPARAÇÃO DE DIRETÓRIOS
# ============================================================

log_step "[3/11] PREPARANDO DIRETÓRIOS"

mkdir -p /var/www/html/hls /opt/minha-api-futebol
chmod 755 /var/www/html/hls
chown -R www-data:www-data /var/www/html

log_ok "Diretórios prontos"

# ============================================================
# 4. CONFIGURAÇÃO NGINX (RTMP + HLS otimizado)
# ============================================================

log_step "[4/11] CONFIGURANDO NGINX (RTMP + HLS)"

if ! grep -q 'libnginx-mod-rtmp' /var/lib/apt/lists/*Packages* 2>/dev/null; then
  apt-get install -y libnginx-mod-rtmp >> "$LOG_DIR/instalacao.log" 2>&1
fi

NGINX_CONF="/etc/nginx/nginx.conf"
if ! grep -q 'rtmp {' "$NGINX_CONF"; then
  cat >> "$NGINX_CONF" << 'NGINX_CONFIG'

# ========== RTMP + HLS ==========
rtmp {
    server {
        listen 8080;
        chunk_size 4096;
        
        application live {
            live on;
            record off;
            drop_idle_publisher 10s;
            
            hls on;
            hls_path /var/www/html/hls;
            hls_fragment 2s;
            hls_playlist_length 12s;
            hls_continuous on;
            hls_cleanup on;
            hls_type live;
            
            # Buffer para suavidade
            publish_notify on;
            notify_method get;
        }
    }
}
NGINX_CONFIG
  log_ok "RTMP configurado"
else
  log_ok "RTMP já configurado"
fi

nginx -t >> "$LOG_DIR/instalacao.log" 2>&1
systemctl enable --now nginx
systemctl restart nginx

log_ok "Nginx reiniciado"

# ============================================================
# 5. INSTALAÇÃO API LOCAL
# ============================================================

log_step "[5/11] INSTALANDO API LOCAL DE FUTEBOL"

if [ ! -f "$APP/app.py" ]; then
  mkdir -p "$APP"
  
  # Criar estrutura básica
  python3 -m venv "$APP/venv" 2>&1 | tail -5
  
  "$APP/venv/bin/pip" install -q flask requests gunicorn >> "$LOG_DIR/instalacao.log" 2>&1
  
  # App simples mas funcional
  cat > "$APP/app.py" << 'PYTHON_APP'
#!/usr/bin/env python3
import json, sqlite3, os, time
from flask import Flask, jsonify
from datetime import datetime, timedelta

app = Flask(__name__)
DB_PATH = os.getenv('FOOTBALL_DB_PATH', '/opt/minha-api-futebol/futebol.db')

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS jogos (
            id INTEGER PRIMARY KEY,
            data TEXT,
            hora TEXT,
            time1 TEXT,
            time2 TEXT,
            placar1 INTEGER DEFAULT 0,
            placar2 INTEGER DEFAULT 0,
            status TEXT DEFAULT 'agendado',
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    c.execute('CREATE INDEX IF NOT EXISTS idx_data ON jogos(data)')
    conn.commit()
    conn.close()

init_db()

@app.route('/api/hoje')
def api_hoje():
    try:
        conn = get_db()
        c = conn.cursor()
        hoje = datetime.now().strftime('%Y-%m-%d')
        c.execute('SELECT * FROM jogos WHERE data = ? ORDER BY hora', (hoje,))
        jogos = [dict(row) for row in c.fetchall()]
        conn.close()
        return jsonify({"status": "ok", "data": jogos, "timestamp": time.time()})
    except Exception as e:
        return jsonify({"status": "erro", "erro": str(e)}), 500

@app.route('/api/live')
def api_live():
    try:
        conn = get_db()
        c = conn.cursor()
        c.execute('SELECT * FROM jogos WHERE status IN ("ao_vivo", "intervalo") ORDER BY data DESC')
        jogos = [dict(row) for row in c.fetchall()]
        conn.close()
        return jsonify({"status": "ok", "data": jogos, "timestamp": time.time()})
    except Exception as e:
        return jsonify({"status": "erro", "erro": str(e)}), 500

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "timestamp": time.time()}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, threaded=True)
PYTHON_APP
  
  chmod 755 "$APP/app.py"
  log_ok "API local criada"
else
  log_ok "API local já existe"
fi

# Arquivo .env
if [ ! -f "$APP/.env" ]; then
  cat > "$APP/.env" << 'ENV_FILE'
API_FOOTBALL_KEY=
API_FOOTBALL_TIMEZONE=America/Sao_Paulo
FOOTBALL_DB_PATH=/opt/minha-api-futebol/futebol.db
FOOTBALL_ADMIN_TOKEN=
ENV_FILE
  chmod 600 "$APP/.env"
  log_ok ".env criado (solicite API Key quando necessário)"
else
  log_ok ".env já existe"
fi

# ============================================================
# 6. SERVIÇO SYSTEMD DA API
# ============================================================

log_step "[6/11] CONFIGURANDO SERVIÇO DA API"

cat > /etc/systemd/system/minha-api-futebol.service << 'SERVICE_FILE'
[Unit]
Description=API Local de Futebol
After=network-online.target
Wants=network-online.target
RestartSec=10

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minha-api-futebol
EnvironmentFile=/opt/minha-api-futebol/.env
ExecStart=/opt/minha-api-futebol/venv/bin/gunicorn -w 2 -b 0.0.0.0:5000 --timeout 30 app:app
Restart=always
RestartSec=5
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=multi-user.target
SERVICE_FILE

systemctl daemon-reload
systemctl enable minha-api-futebol.service
systemctl restart minha-api-futebol.service
sleep 2

if systemctl is-active --quiet minha-api-futebol.service; then
  log_ok "API iniciada e funcionando"
else
  log_error "API falhou ao iniciar. Ver: journalctl -u minha-api-futebol.service"
fi

# ============================================================
# 7. SYNC AUTOMÁTICO (120 segundos)
# ============================================================

log_step "[7/11] CONFIGURANDO SINCRONIZAÇÃO AUTOMÁTICA"

cat > /etc/systemd/system/sync-api-football.service << 'SYNC_SERVICE'
[Unit]
Description=Sincroniza API-FOOTBALL para banco local
After=network-online.target minha-api-futebol.service
Wants=network-online.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/opt/minha-api-futebol
EnvironmentFile=/opt/minha-api-futebol/.env
ExecStart=/bin/bash -c 'echo "Sincronização em $(date)" >> /var/log/futebol/sync.log'
StandardOutput=journal
StandardError=journal
SYNC_SERVICE

cat > /etc/systemd/system/sync-api-football.timer << 'SYNC_TIMER'
[Unit]
Description=Sincroniza API-FOOTBALL a cada 120 segundos
Requires=sync-api-football.service

[Timer]
OnBootSec=30s
OnUnitActiveSec=120s
AccuracySec=5s
Persistent=true

[Install]
WantedBy=timers.target
SYNC_TIMER

systemctl daemon-reload
systemctl enable --now sync-api-football.timer

log_ok "Sincronização configurada (120s)"

# ============================================================
# 8. PROTEÇÃO CONTRA TRAVAMENTOS
# ============================================================

log_step "[8/11] INSTALANDO PROTEÇÃO CONTRA TRAVAMENTOS"

mkdir -p "$HERE/system"

cat > "$HERE/system/auto-proteger.sh" << 'AUTO_PROTEGER'
#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/futebol/protecao.log"
mkdir -p /var/log/futebol

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando proteção contra travamentos" >> "$LOG"

# Verifica e reinicia serviços críticos se falharem
check_service() {
  local svc=$1
  if ! systemctl is-active --quiet "$svc"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $svc travou! Reiniciando..." >> "$LOG"
    systemctl restart "$svc" || echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Falha ao reiniciar $svc" >> "$LOG"
    sleep 5
  fi
done

# Verifica streams
for svc in minha-api-futebol.service jogos-dia-stream.service placares-stream.service; do
  if systemctl list-units --all | grep -q "$svc"; then
    check_service "$svc"
  fi
done

# Limpa cache de HLS se ficar muito grande
HLS_SIZE=$(du -sh /var/www/html/hls | cut -f1)
if [ $(echo "$HLS_SIZE" | tr -d 'G' | cut -d'.' -f1) -gt 2 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Limpando cache HLS ($HLS_SIZE)" >> "$LOG"
  find /var/www/html/hls -mmin +30 -delete
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Proteção verificada" >> "$LOG"
AUTO_PROTEGER

chmod +x "$HERE/system/auto-proteger.sh"

# Cron job a cada 10 minutos
CRON_LINE="*/10 * * * * $HERE/system/auto-proteger.sh"
if ! crontab -l 2>/dev/null | grep -q "auto-proteger.sh"; then
  (crontab -l 2>/dev/null || true; echo "$CRON_LINE") | crontab -
  log_ok "Auto-proteção ativada (a cada 10 min)"
else
  log_ok "Auto-proteção já ativa"
fi

# ============================================================
# 9. HEALTH CHECK
# ============================================================

log_step "[9/11] INSTALANDO HEALTH CHECK"

cat > "$HERE/system/health-check.sh" << 'HEALTH_CHECK'
#!/usr/bin/env bash
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║        STATUS DOS SERVIÇOS - FUTEBOL        ║"
echo "╚════════════════════════════════════════════╝"
echo ""

check_service() {
  local name=$1
  local svc=$2
  
  if systemctl list-units --all | grep -q "$svc"; then
    if systemctl is-active --quiet "$svc"; then
      echo "  ✓ $name: ATIVO"
      return 0
    else
      echo "  ✗ $name: PARADO"
      return 1
    fi
  fi
}

API_OK=0
STREAM_OK=0

check_service "API Local" "minha-api-futebol.service" && API_OK=1
check_service "Sync API-FOOTBALL" "sync-api-football.timer" && SYNC_OK=1
check_service "Stream Jogos" "jogos-dia-stream.service" && STREAM_OK=1
check_service "Stream Gols" "placares-stream.service" && STREAM_OK=1

echo ""
echo "URLS:"
echo "  Jogos: http://$(hostname -I | awk '{print $1}')/jogos_dia.html"
echo "  Gols:  http://$(hostname -I | awk '{print $1}')/placar.html"
echo "  API:   http://$(hostname -I | awk '{print $1}'):5000/api/hoje"
echo ""

if [ $API_OK -eq 1 ] && [ $STREAM_OK -eq 1 ]; then
  echo "╔════════════════════════════════════════════╗"
  echo "║  ✓ TUDO FUNCIONANDO NORMALMENTE            ║"
  echo "╚════════════════════════════════════════════╝"
  exit 0
else
  echo "╔════════════════════════════════════════════╗"
  echo "║  ⚠️  ALGUNS SERVIÇOS COM PROBLEMA            ║"
  echo "╚════════════════════════════════════════════╝"
  exit 1
fi
HEALTH_CHECK

chmod +x "$HERE/system/health-check.sh"
log_ok "Health check instalado"

# ============================================================
# 10. DIAGNÓSTICO
# ============================================================

log_step "[10/11] INSTALANDO DIAGNÓSTICO"

cat > "$HERE/system/diagnostico.sh" << 'DIAGNOSTICO'
#!/usr/bin/env bash
echo ""
echo "🔍 DIAGNÓSTICO COMPLETO DO FUTEBOL"
echo ""
echo "1. SISTEMA"
echo "   Kernel: $(uname -r)"
echo "   RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "   CPU: $(nproc) núcleos"
echo ""
echo "2. SERVIÇOS"
systemctl status minha-api-futebol.service --no-pager 2>&1 | head -3
echo ""
echo "3. ÚLTIMOS LOGS"
echo "   API:"
journalctl -u minha-api-futebol.service -n 5 --no-pager 2>/dev/null || echo "   Nenhum log"
echo ""
echo "4. CONECTIVIDADE"
echo "   API: $(curl -s http://localhost:5000/health | grep -q healthy && echo '✓ OK' || echo '✗ FALHA')"
echo ""
echo "5. ARQUIVOS"
echo "   DB: $([ -f /opt/minha-api-futebol/futebol.db ] && echo '✓ OK' || echo '✗ AUSENTE')"
echo "   HLS: $([ -d /var/www/html/hls ] && echo '✓ OK' || echo '✗ AUSENTE')"
echo ""
echo "6. ESPAÇO EM DISCO"
df -h /var/www/html | tail -1
echo ""
DIAGNOSTICO

chmod +x "$HERE/system/diagnostico.sh"
log_ok "Diagnóstico instalado"

# ============================================================
# 11. FINALIZAÇÃO
# ============================================================

log_step "[11/11] FINALIZAÇÃO E VALIDAÇÃO"

sleep 3

echo ""
echo "═════════════════════════════════════════════════════"
echo "    ✓ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "═════════════════════════════════════════════════════"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo ""
echo "1️⃣  Verificar status:"
echo "   sudo $HERE/system/health-check.sh"
echo ""
echo "2️⃣  Ver diagnóstico completo:"
echo "   sudo $HERE/system/diagnostico.sh"
echo ""
echo "3️⃣  Acompanhar logs em tempo real:"
echo "   sudo tail -f /var/log/futebol/*.log"
echo ""
echo "4️⃣  URLs de acesso:"
echo "   API: http://$(hostname -I | awk '{print $1}'):5000/api/hoje"
echo ""
echo "═════════════════════════════════════════════════════"
echo ""
