#!/usr/bin/env bash

# ============================================================
# INSTALL SCRIPT - XUI ONE M3U8 + THEMES
# ============================================================

echo "Instalando gerador de M3U8 + Temas XUI One..."

if [ -f "componentes/xui-generator/gerar-m3u8-temas.sh" ]; then
  chmod +x componentes/xui-generator/gerar-m3u8-temas.sh
  
  echo "Gerando todos os arquivos..."
  bash componentes/xui-generator/gerar-m3u8-temas.sh
  
  echo ""
  echo "✓ Instalação concluída!"
  echo ""
  echo "Próximas etapas:"
  echo "1. Abra seu XUI One"
  echo "2. Vá em: Configurações → Playlists → Adicionar Playlist"
  echo "3. Importe: http://localhost/xui-themes/futebol_completo.xui"
  echo "4. Ou adicione cada stream manualmente com os arquivos JSON"
else
  echo "Erro: Script não encontrado"
  exit 1
fi
