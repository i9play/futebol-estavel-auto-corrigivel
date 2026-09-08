#!/usr/bin/env bash

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║     🔍 DIAGNÓSTICO COMPLETO - FUTEBOL ESTÁVEL      ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  SISTEMA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "CPU: $(nproc) núcleos @ $(lscpu | grep 'CPU max MHz' | awk '{print $4}') MHz"
echo "RAM: $(free -h | awk '/^Mem:/ {print "Total: " $2 " | Livre: " $7}')"
echo "Uptime: $(uptime -p)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  SERVIÇOS E PORTAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "API Local (5000):"
if curl -s http://localhost:5000/health | grep -q "healthy"; then
  echo "  ✓ RESPONDENDO"
else
  echo "  ✗ NÃO RESPONDENDO - Ver: journalctl -u minha-api-futebol.service -n 10"
fi

echo "Nginx RTMP (8080):"
if netstat -tuln 2>/dev/null | grep -q :8080 || ss -tuln 2>/dev/null | grep -q :8080; then
  echo "  ✓ ESCUTANDO"
else
  echo "  ✗ NÃO ESCUTANDO - Reiniciar: sudo systemctl restart nginx"
fi

echo "Nginx HTTP (80/443):"
if systemctl is-active --quiet nginx; then
  echo "  ✓ ATIVO"
else
  echo "  ✗ PARADO"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  ARQUIVOS E DIRETÓRIOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Base de dados: $([ -f /opt/minha-api-futebol/futebol.db ] && echo '✓ EXISTS' || echo '✗ MISSING')"
if [ -f /opt/minha-api-futebol/futebol.db ]; then
  SIZE=$(du -h /opt/minha-api-futebol/futebol.db | cut -f1)
  echo "  Tamanho: $SIZE"
fi

echo "HLS Cache: $([ -d /var/www/html/hls ] && echo '✓ EXISTS' || echo '✗ MISSING')"
if [ -d /var/www/html/hls ]; then
  SIZE=$(du -sh /var/www/html/hls | cut -f1)
  COUNT=$(find /var/www/html/hls -type f 2>/dev/null | wc -l)
  echo "  Tamanho: $SIZE ($COUNT arquivos)"
fi

echo "Logs: $([ -d /var/log/futebol ] && echo '✓ EXISTS' || echo '✗ MISSING')"
if [ -d /var/log/futebol ]; then
  SIZE=$(du -sh /var/log/futebol | cut -f1)
  echo "  Tamanho: $SIZE"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  ESPAÇO EM DISCO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h / /var/www/html | awk 'NR==1 || /^\// {printf "  %-20s %10s %10s %10s %6s\n", $6, $2, $3, $4, $5}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  ÚLTIMAS 10 LINHAS DE LOGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🔴 Erros da API:"
journalctl -u minha-api-futebol.service -p err -n 5 --no-pager 2>/dev/null | sed 's/^/  /' || echo "  Nenhum erro registrado"

echo ""
echo "⚠️  Avisos:"
journalctl -u minha-api-futebol.service -p warning -n 3 --no-pager 2>/dev/null | sed 's/^/  /' || echo "  Nenhum aviso"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  CONECTIVIDADE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Verificando API-FOOTBALL..."
API_KEY=$(grep '^API_FOOTBALL_KEY=' /opt/minha-api-futebol/.env 2>/dev/null | cut -d'=' -f2 || echo "")
if [ -n "$API_KEY" ] && [ "$API_KEY" != "" ]; then
  echo "  ✓ Chave configurada"
else
  echo "  ⚠️  Chave NÃO configurada - Solicitar ao instalar"
fi

echo "Verificando conectividade com internet..."
if timeout 3 curl -s https://www.google.com > /dev/null 2>&1; then
  echo "  ✓ Internet OK"
else
  echo "  ✗ Sem internet"
fi
echo ""

echo "╔═══════════════════════════════════════════════════╗"
echo "║  Diagnóstico concluído!                            ║"
echo "║  Para mais ajuda, rode: sudo ./system/auto-proteger.sh ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
