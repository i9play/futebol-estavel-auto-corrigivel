#!/usr/bin/env bash

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║    📊 MONITORAMENTO EM TEMPO REAL            ║"
echo "║    Pressione Ctrl+C para sair              ║"
echo "╚════════════════════════════════════════════╝"
echo ""

while true; do
  clear
  echo "╔════════════════════════════════════════════╗"
  echo "║    FUTEBOL ESTÁVEL - STATUS LIVE            ║"
  echo "║    Atualizado: $(date '+%H:%M:%S')                         ║"
  echo "╚════════════════════════════════════════════╝"
  echo ""
  
  echo "🟢 SERVIÇOS:"
  systemctl is-active --quiet minha-api-futebol.service && echo "  ✓ API" || echo "  ✗ API"
  systemctl is-active --quiet nginx.service && echo "  ✓ Nginx" || echo "  ✗ Nginx"
  
  echo ""
  echo "💾 MEMÓRIA:"
  free -h | awk 'NR==2 {print "  Total: " $2 " | Usado: " $3 " | Livre: " $7}'
  
  echo ""
  echo "📊 CPU:"
  echo "  $(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1%/' | awk '{print "Ocioso: " $1}')"
  
  echo ""
  echo "📁 HLS Cache:"
  if [ -d /var/www/html/hls ]; then
    SIZE=$(du -sh /var/www/html/hls | cut -f1)
    COUNT=$(find /var/www/html/hls -type f 2>/dev/null | wc -l)
    echo "  $SIZE ($COUNT arquivos)"
  fi
  
  echo ""
  echo "📝 ÚLTIMAS ATIVIDADES:"
  echo "  API: $(journalctl -u minha-api-futebol.service -n 1 --no-pager 2>/dev/null | tail -1 | cut -c 1-60)"
  
  echo ""
  echo "⏳ Próxima atualização em 5s... (Ctrl+C para sair)"
  sleep 5
done
