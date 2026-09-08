#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║    🔄 REINICIANDO TODOS OS SERVIÇOS         ║"
echo "╚════════════════════════════════════════════╝"
echo ""

echo "Parando serviços..."
systemctl stop minha-api-futebol.service 2>/dev/null || true
systemctl stop nginx.service 2>/dev/null || true
sleep 2

echo "Limpando cache..."
rm -f /var/www/html/hls/*.m3u8 /var/www/html/hls/*.ts 2>/dev/null || true

echo "Iniciando serviços..."
systemctl start nginx.service
sleep 2
systemctl start minha-api-futebol.service
sleep 3

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║    ✓ TODOS OS SERVIÇOS REINICIADOS          ║"
echo "╚════════════════════════════════════════════╝"
echo ""

echo "Status:"
systemctl is-active --quiet minha-api-futebol.service && echo "  ✓ API" || echo "  ✗ API"
systemctl is-active --quiet nginx.service && echo "  ✓ Nginx" || echo "  ✗ Nginx"
echo ""
