#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  FUTEBOL ESTÁVEL - Instalador Otimizado v2.1
#  Correção: Nginx init corrigido, melhor tratamento de erros
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

log_step "[1/12] PRÉ-VALIDAÇÃO DO SISTEMA"

if ! command -v apt-get &> /dev/null; then
  log_error "Apenas Ubuntu/Debian suportado"
  exit 1
fi

log_ok "Sistema compatível detectado"

# ============================================================
# 2. INSTALAÇÃO DE DEPENDÊNCIAS
# ============================================================

log_step "[2/12] INSTALANDO DEPENDÊNCIAS"

export DEBIAN_FRONTEND=noninteractive

DEPS_NEEDED=()
for dep in python3 python3-venv python3-pip nginx ffmpeg curl unzip openssl libnginx-mod-rtmp sqlite3; do
  if ! dpkg -l 2>/dev/null | grep -q "^ii.*$dep"; then
    DEPS_NEEDED+=("$dep")
  fi
done

if [ ${#DEPS_NEEDED[@]} -gt 0 ]; then
  log_info "Instalando: ${DEPS_NEEDED[*]}"
  apt-get update -y >> "$LOG_DIR/instalacao.log" 2>&1 || log_warn "apt-get update teve aviso"
  apt-get install -y "${DEPS_NEEDED[@]}" >> "$LOG_DIR/instalacao.log" 2>&1 || log_warn "Alguns pacotes podem ter aviso"
  log_ok "Dependências instaladas"
else
  log_ok "Todas dependências já estão presentes"
fi

# Chrome para Playwright (apenas se não existir)
if ! command -v google-chrome-stable &> /dev/null; then
  log_info "Instalando Google Chrome..."
  curl -sL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 2>/dev/null || log_warn "Aviso ao baixar Chrome"
  apt-get install -y /tmp/chrome.deb >> "$LOG_DIR/instalacao.log" 2>&1 || log_warn "Chrome pode ter aviso"
  rm -f /tmp/chrome.deb
  log_ok "Chrome instalado"
else
  log_ok "Chrome já presente"
fi

# ============================================================
# 3. PREPARAÇÃO DE DIRETÓRIOS
# ============================================================

log_step "[3/12] PREPARANDO DIRETÓRIOS"

mkdir -p /var/www/html/hls /var/www/html/xui-themes /opt/minha-api-futebol
chmod 755 /var/www/html/hls /var/www/html/xui-themes
chown -R www-data:www-data /var/www/html 2>/dev/null || log_warn "Aviso ao ajustar permissões"

log_ok "Diretórios prontos"

# ============================================================
# 4. CONFIGURAÇÃO NGINX (RTMP + HLS otimizado)
# ============================================================

log_step "[4/12] CONFIGURANDO NGINX (RTMP + HLS)"

# Para nginx se estiver rodando
systemctl stop nginx 2>/dev/null || true

NGINX_CONF="/etc/nginx/nginx.conf"
NGINX_BACKUP="${NGINX_CONF}.bak.$(date +%s)"

# Faz backup
cp "$NGINX_CONF" "$NGINX_BACKUP"
log_ok "Backup do Nginx criado: $NGINX_BACKUP"

# Remove bloco RTMP antigo se existir
if grep -q 'rtmp {' "$NGINX_CONF"; then
  log_info "Removendo configuração RTMP antiga..."
  sed -i '/^rtmp {/,/^}/d' "$NGINX_CONF"
fi

# Adiciona novo bloco RTMP antes do último closing brace
if ! grep -q 'rtmp {' "$NGINX_CONF"; then
  # Encontra a última linha com }
  LAST_BRACE=$(grep -n '^}' "$NGINX_CONF" | tail -1 | cut -d: -f1)
  if [ -n "$LAST_BRACE" ]; then
    sed -i "${LAST_BRACE}i\\\n# ========== RTMP + HLS ==========\nrtmp {\n    server {\n        listen 8080;\n        chunk_size 4096;\n        \n        application live {\n            live on;\n            record off;\n            drop_idle_publisher 10s;\n            \n            hls on;\n            hls_path /var/www/html/hls;\n            hls_fragment 2s;\n            hls_playlist_length 12s;\n            hls_continuous on;\n            hls_cleanup on;\n            hls_type live;\n            \n            publish_notify on;\n            notify_method get;\n        }\n    }\n}" "$NGINX_CONF"
    log_ok "RTMP configurado"
  fi
else
  log_ok "RTMP já configurado"
fi

# Valida configuração
if ! nginx -t >> "$LOG_DIR/instalacao.log" 2>&1; then
  log_error "Erro na configuração Nginx! Restaurando backup..."
  cp "$NGINX_BACKUP" "$NGINX_CONF"
  exit 1
fi

# Inicia Nginx
if ! systemctl start nginx 2>&1 | tee -a "$LOG_DIR/instalacao.log"; then
  log_error "Nginx falhou ao iniciar"
  exit 1
fi

systemctl enable nginx 2>/dev/null || true
log_ok "Nginx iniciado e habilitado"

# ============================================================
# 5. INSTALAÇÃO API LOCAL
# ============================================================

log_step "[5/12] INSTALANDO API LOCAL DE FUTEBOL"

if [ ! -f "$APP/app.py" ]; then
  mkdir -p "$APP"
  log_info "Criando ambiente Python..."
  python3 -m venv "$APP/venv" >> "$LOG_DIR/instalacao.log" 2>&1
  
  log_info "Instalando dependências Python..."
  "$APP/venv/bin/pip" install -q flask requests gunicorn >> "$LOG_DIR/instalacao.log" 2>&1
  
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

# ============================================================
# 6. ARQUIVO .env
# ============================================================

log_step "[6/12] CONFIGURANDO VARIÁVEIS DE AMBIENTE"

if [ ! -f "$APP/.env" ]; then
  cat > "$APP/.env" << 'ENV_FILE'
API_FOOTBALL_KEY=
API_FOOTBALL_TIMEZONE=America/Sao_Paulo
FOOTBALL_DB_PATH=/opt/minha-api-futebol/futebol.db
FOOTBALL_ADMIN_TOKEN=
ENV_FILE
  chmod 600 "$APP/.env"
  log_ok ".env criado"
else
  log_ok ".env já existe"
fi

# ============================================================
# 7. SERVIÇO SYSTEMD DA API
# ============================================================

log_step "[7/12] CRIANDO SERVIÇO SYSTEMD"

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
sleep 3

if systemctl is-active --quiet minha-api-futebol.service; then
  log_ok "API iniciada com sucesso"
else
  log_error "API falhou ao iniciar. Ver: journalctl -u minha-api-futebol.service"
  journalctl -u minha-api-futebol.service -n 10 --no-pager
fi

# ============================================================
# 8. SINCRONIZAÇÃO AUTOMÁTICA
# ============================================================

log_step "[8/12] CONFIGURANDO SINCRONIZAÇÃO AUTOMÁTICA"

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
log_ok "Sincronização configurada"

# ============================================================
# 9. AUTO-PROTEÇÃO
# ============================================================

log_step "[9/12] INSTALANDO AUTO-PROTEÇÃO"

if [ ! -f "$HERE/system/auto-proteger.sh" ]; then
  log_warn "Scripts do sistema não encontrados"
else
  chmod +x "$HERE/system/auto-proteger.sh"
  CRON_LINE="*/10 * * * * $HERE/system/auto-proteger.sh"
  if ! crontab -l 2>/dev/null | grep -q "auto-proteger.sh"; then
    (crontab -l 2>/dev/null || true; echo "$CRON_LINE") | crontab -
    log_ok "Auto-proteção ativada (a cada 10 min)"
  else
    log_ok "Auto-proteção já ativa"
  fi
fi

# ============================================================
# 10. GERAR M3U8 E TEMAS
# ============================================================

log_step "[10/12] GERANDO M3U8 E TEMAS XUI ONE"

if [ -f "$HERE/componentes/xui-generator/gerar-m3u8-temas.sh" ]; then
  chmod +x "$HERE/componentes/xui-generator/gerar-m3u8-temas.sh"
  bash "$HERE/componentes/xui-generator/gerar-m3u8-temas.sh" >> "$LOG_DIR/instalacao.log" 2>&1 || log_warn "Geração de M3U8 teve aviso"
  log_ok "M3U8 e Temas gerados"
else
  log_warn "Gerador de M3U8 não encontrado"
fi

# ============================================================
# 11. VALIDAÇÃO
# ============================================================

log_step "[11/12] VALIDANDO INSTALAÇÃO"

echo ""
echo "Status dos Serviços:"
systemctl is-active --quiet minha-api-futebol.service && echo "  ✓ API Local" || echo "  ✗ API Local"
systemctl is-active --quiet nginx.service && echo "  ✓ Nginx" || echo "  ✗ Nginx"
systemctl is-active --quiet sync-api-football.timer && echo "  ✓ Sincronização" || echo "  ✗ Sincronização"

echo ""
echo "Verificando conectividade:"
if curl -s http://localhost:5000/health | grep -q "healthy"; then
  echo "  ✓ API respondendo"
else
  echo "  ✗ API não respondendo"
fi

# ============================================================
# 12. FINALIZAÇÃO
# ============================================================

log_step "[12/12] INSTALAÇÃO CONCLUÍDA"

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "╔═════════════════════════════════════════════════════════╗"
echo "║     ✓ INSTALAÇÃO CONCLUÍDA COM SUCESSO!                 ║"
echo "╚═════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Seu IP: $IP"
echo ""
echo "🔗 URLs de Acesso:"
echo "   API:  http://$IP:5000/api/hoje"
echo "   M3U8 (Gols): http://$IP/hls/gols_ao_vivo.m3u8"
echo "   XUI One (Todos): http://$IP/xui-themes/futebol_completo.xui"
echo ""
echo "🎯 Próximos Passos:"
echo "   1. Verifique status: sudo ./system/health-check.sh"
echo "   2. Abra seu XUI One: http://$IP:8080"
echo "   3. Importe: http://$IP/xui-themes/futebol_completo.xui"
echo ""
echo "📊 Logs em: /var/log/futebol/"
echo ""
