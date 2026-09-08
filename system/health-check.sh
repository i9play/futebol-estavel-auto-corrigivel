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

echo "📊 SERVIÇOS CRÍTICOS:"
check_service "API Local" "minha-api-futebol.service" && API_OK=1
check_service "Sync API-FOOTBALL" "sync-api-football.timer" && SYNC_OK=1
check_service "Stream Jogos" "jogos-dia-stream.service" && STREAM_OK=1
check_service "Stream Gols" "placares-stream.service" && STREAM_OK=1
check_service "Nginx" "nginx.service" && NGINX_OK=1

echo ""
echo "🌐 URLs DE ACESSO:"
IP=$(hostname -I | awk '{print $1}')
echo "  Jogos: http://$IP/jogos_dia.html"
echo "  Gols:  http://$IP/placar.html"
echo "  API:   http://$IP:5000/api/hoje"
echo "  HLS Jogos: http://$IP/hls/jogosdia.m3u8"
echo "  HLS Gols:  http://$IP/hls/placares.m3u8"

echo ""
echo "💾 ESPAÇO EM DISCO:"
df -h /var/www/html | tail -1 | awk '{print "  Uso: " $3 " / " $2}'
echo ""

echo "📝 ÚLTIMOS ERROS (se houver):"
ERRO_API=$(journalctl -u minha-api-futebol.service -p err -n 1 --no-pager 2>/dev/null || echo "Nenhum")
echo "  API: $ERRO_API"

echo ""
if [ $API_OK -eq 1 ] && [ $STREAM_OK -eq 1 ] && [ $NGINX_OK -eq 1 ]; then
  echo "╔════════════════════════════════════════════╗"
  echo "║  ✓ TUDO FUNCIONANDO PERFEITAMENTE!         ║"
  echo "╚════════════════════════════════════════════╝"
  exit 0
else
  echo "╔════════════════════════════════════════════╗"
  echo "║  ⚠️  ALGUNS SERVIÇOS COM PROBLEMA            ║"
  echo "║  Use: sudo ./system/diagnostico.sh          ║"
  echo "╚════════════════════════════════════════════╝"
  exit 1
fi
