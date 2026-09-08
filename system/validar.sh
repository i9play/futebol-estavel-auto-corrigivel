#!/usr/bin/env bash

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║    ✓ VALIDANDO INTEGRIDADE DO SISTEMA      ║"
echo "╚════════════════════════════════════════════╝"
echo ""

ERROS=0

echo "1. Verificando diretórios..."
for dir in /var/www/html/hls /var/log/futebol /opt/minha-api-futebol; do
  if [ -d "$dir" ]; then
    echo "   ✓ $dir"
  else
    echo "   ✗ $dir (CRIANDO...)"
    mkdir -p "$dir"
    chmod 755 "$dir"
  fi
done

echo ""
echo "2. Verificando arquivos críticos..."
for file in /opt/minha-api-futebol/app.py /opt/minha-api-futebol/.env; do
  if [ -f "$file" ]; then
    echo "   ✓ $file"
  else
    echo "   ✗ $file (FALTANDO!)"
    ERROS=$((ERROS+1))
  fi
done

echo ""
echo "3. Verificando banco de dados..."
DB="/opt/minha-api-futebol/futebol.db"
if [ -f "$DB" ]; then
  if sqlite3 "$DB" "PRAGMA integrity_check;" 2>/dev/null | grep -q "^ok$"; then
    echo "   ✓ BD íntegro ($(du -h $DB | cut -f1))"
  else
    echo "   ✗ BD CORROMPIDO! Fazendo backup..."
    cp "$DB" "$DB.bak.$(date +%s)"
    rm -f "$DB"
    echo "   ✓ BD resetado"
  fi
else
  echo "   ℹ BD não existe ainda (será criado automaticamente)"
fi

echo ""
echo "4. Verificando permissões..."
chown -R www-data:www-data /var/www/html 2>/dev/null || true
chmod 755 /var/www/html/hls 2>/dev/null || true
chmod 600 /opt/minha-api-futebol/.env 2>/dev/null || true
echo "   ✓ Permissões ajustadas"

echo ""
echo "5. Verificando serviços..."
for svc in minha-api-futebol.service nginx.service; do
  if systemctl is-enabled "$svc" 2>/dev/null | grep -q enabled; then
    echo "   ✓ $svc (habilitado)"
  else
    echo "   ⚠️  $svc (NÃO habilitado - habilitando...)"
    systemctl enable "$svc" 2>/dev/null || true
  fi
done

echo ""
echo "╔════════════════════════════════════════════╗"
if [ $ERROS -eq 0 ]; then
  echo "║    ✓ SISTEMA VÁLIDO E ÍNTEGRO              ║"
else
  echo "║    ⚠️  ENCONTRADOS $ERROS PROBLEMAS           ║"
fi
echo "╚════════════════════════════════════════════╝"
echo ""
