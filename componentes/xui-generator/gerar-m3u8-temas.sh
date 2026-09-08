#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# GERADOR INTEGRADO DE M3U8 + XUI ONE THEMES
# Cria extensões prontas para XUI One Live
# ============================================================

LOG_DIR="/var/log/futebol"
HLS_DIR="/var/www/html/hls"
XUI_DIR="/var/www/html/xui-themes"
API_URL="http://localhost:5000"

mkdir -p "$LOG_DIR" "$HLS_DIR" "$XUI_DIR"

log_ok() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $1" >> "$LOG_DIR/m3u8-generator.log"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ $1" >> "$LOG_DIR/m3u8-generator.log"; }

# ============================================================
# 1. GOLS AO VIVO - gols_ao_vivo.m3u8
# ============================================================

generar_gols_m3u8() {
  cat > "$HLS_DIR/gols_ao_vivo.m3u8" << 'M3U8'
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:2
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-PLAYLIST-TYPE:EVENT
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-STREAM-INF:BANDWIDTH=1500000,RESOLUTION=1280x720,CODECS="avc1.42e01e,mp4a.40.2"
rtmp://localhost:8080/live/gols
#EXTINF:2.0,
segment_gol_00.ts
#EXTINF:2.0,
segment_gol_01.ts
#EXTINF:2.0,
segment_gol_02.ts
#EXTINF:2.0,
segment_gol_03.ts
#EXTINF:2.0,
segment_gol_04.ts
#EXTINF:2.0,
segment_gol_05.ts
#EXTINF:2.0,
segment_gol_06.ts
#EXTINF:2.0,
segment_gol_07.ts
#EXTINF:2.0,
segment_gol_08.ts
#EXTINF:2.0,
segment_gol_09.ts
#EXT-X-ENDLIST
M3U8
  
  log_ok "gols_ao_vivo.m3u8 criado"
}

# ============================================================
# 2. PONTUAÇÃO - pontuacao.m3u8
# ============================================================

generar_pontuacao_m3u8() {
  cat > "$HLS_DIR/pontuacao.m3u8" << 'M3U8'
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:5
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-PLAYLIST-TYPE:EVENT
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1920x1080,CODECS="avc1.42e01e,mp4a.40.2"
rtmp://localhost:8080/live/pontuacao
#EXTINF:5.0,
segment_placar_00.ts
#EXTINF:5.0,
segment_placar_01.ts
#EXTINF:5.0,
segment_placar_02.ts
#EXTINF:5.0,
segment_placar_03.ts
#EXTINF:5.0,
segment_placar_04.ts
#EXTINF:5.0,
segment_placar_05.ts
#EXTINF:5.0,
segment_placar_06.ts
#EXTINF:5.0,
segment_placar_07.ts
#EXTINF:5.0,
segment_placar_08.ts
#EXTINF:5.0,
segment_placar_09.ts
#EXTINF:5.0,
segment_placar_10.ts
#EXTINF:5.0,
segment_placar_11.ts
#EXT-X-ENDLIST
M3U8
  
  log_ok "pontuacao.m3u8 criado"
}

# ============================================================
# 3. MMA - mma.m3u8
# ============================================================

generar_mma_m3u8() {
  cat > "$HLS_DIR/mma.m3u8" << 'M3U8'
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-PLAYLIST-TYPE:EVENT
#EXT-X-INDEPENDENT-SEGMENTS
#EXT-X-STREAM-INF:BANDWIDTH=3000000,RESOLUTION=1920x1080,CODECS="avc1.42e01e,mp4a.40.2"
rtmp://localhost:8080/live/mma
#EXTINF:10.0,
segment_mma_00.ts
#EXTINF:10.0,
segment_mma_01.ts
#EXTINF:10.0,
segment_mma_02.ts
#EXTINF:10.0,
segment_mma_03.ts
#EXTINF:10.0,
segment_mma_04.ts
#EXTINF:10.0,
segment_mma_05.ts
#EXTINF:10.0,
segment_mma_06.ts
#EXTINF:10.0,
segment_mma_07.ts
#EXTINF:10.0,
segment_mma_08.ts
#EXTINF:10.0,
segment_mma_09.ts
#EXTINF:10.0,
segment_mma_10.ts
#EXTINF:10.0,
segment_mma_11.ts
#EXTINF:10.0,
segment_mma_12.ts
#EXTINF:10.0,
segment_mma_13.ts
#EXTINF:10.0,
segment_mma_14.ts
#EXTINF:10.0,
segment_mma_15.ts
#EXTINF:10.0,
segment_mma_16.ts
#EXTINF:10.0,
segment_mma_17.ts
#EXTINF:10.0,
segment_mma_18.ts
#EXTINF:10.0,
segment_mma_19.ts
#EXT-X-ENDLIST
M3U8
  
  log_ok "mma.m3u8 criado"
}

# ============================================================
# 4. TEMA XUI ONE PARA GOLS
# ============================================================

generar_tema_xui_gols() {
  cat > "$XUI_DIR/gols_ao_vivo.json" << 'THEME'
{
  "manifest_version": 2,
  "id": "gols-ao-vivo-theme",
  "name": "⚽ Gols Ao Vivo",
  "version": "2.0",
  "description": "Tema otimizado para transmissão de gols em tempo real com notificações",
  "author": "Futebol Estável",
  "icons": {
    "16": "assets/gols_16.png",
    "48": "assets/gols_48.png",
    "128": "assets/gols_128.png"
  },
  "theme": {
    "colors": {
      "primary": "#FF6B35",
      "secondary": "#004E89",
      "accent": "#FFA500",
      "background": "#0a0e27",
      "surface": "#141829",
      "text": "#FFFFFF",
      "text_secondary": "#B0B0B0"
    },
    "fonts": {
      "primary": "Roboto, sans-serif",
      "secondary": "Open Sans, sans-serif"
    }
  },
  "stream": {
    "url": "http://localhost/hls/gols_ao_vivo.m3u8",
    "type": "HLS",
    "protocol": "http",
    "buffer": 3000,
    "adaptive_bitrate": true,
    "quality_levels": [
      {"name": "Auto", "bitrate": "auto"},
      {"name": "SD", "bitrate": "500k"},
      {"name": "HD", "bitrate": "1500k"},
      {"name": "FHD", "bitrate": "3000k"}
    ]
  },
  "ui": {
    "layout": "fullscreen",
    "controls": {
      "play": true,
      "pause": true,
      "volume": true,
      "fullscreen": true,
      "quality": true,
      "captions": false
    },
    "overlay": {
      "enabled": true,
      "position": "top-right",
      "elements": [
        {
          "type": "score",
          "display": "team1 score team2",
          "font_size": 32,
          "background": "rgba(0,0,0,0.7)",
          "padding": "10px 20px",
          "border_radius": "8px"
        },
        {
          "type": "notification",
          "trigger": "gol",
          "animation": "slide-in",
          "duration": 5000,
          "sound": "gol_alert.mp3"
        },
        {
          "type": "timer",
          "display": "match_time",
          "format": "MM:SS"
        }
      ]
    },
    "menus": {
      "main": {
        "position": "left",
        "width": "250px",
        "items": [
          {"label": "Ao Vivo", "icon": "live"},
          {"label": "Gols", "icon": "goal"},
          {"label": "Próximos", "icon": "calendar"},
          {"label": "Configurações", "icon": "settings"}
        ]
      }
    }
  },
  "api": {
    "endpoints": [
      {
        "name": "live_data",
        "url": "http://localhost:5000/api/live",
        "method": "GET",
        "refresh_interval": 2000
      },
      {
        "name": "gols",
        "url": "http://localhost:5000/api/gols",
        "method": "GET",
        "refresh_interval": 1000
      }
    ]
  },
  "notifications": {
    "enabled": true,
    "types": [
      {
        "type": "gol",
        "title": "⚽ GOL!",
        "icon": "goal.png",
        "sound": "gol.mp3",
        "duration": 3000
      },
      {
        "type": "cartao_amarelo",
        "title": "🟨 Cartão Amarelo",
        "icon": "card_yellow.png",
        "duration": 2000
      },
      {
        "type": "cartao_vermelho",
        "title": "🟥 Cartão Vermelho",
        "icon": "card_red.png",
        "sound": "card.mp3",
        "duration": 2000
      }
    ]
  },
  "stats": {
    "enabled": true,
    "display_elements": [
      "possession",
      "shots",
      "shots_on_target",
      "fouls",
      "corner_kicks",
      "offsides"
    ]
  }
}
THEME
  
  log_ok "Tema XUI One para Gols criado"
}

# ============================================================
# 5. TEMA XUI ONE PARA PONTUAÇÃO
# ============================================================

generar_tema_xui_pontuacao() {
  cat > "$XUI_DIR/pontuacao.json" << 'THEME'
{
  "manifest_version": 2,
  "id": "pontuacao-theme",
  "name": "📊 Pontuação Ao Vivo",
  "version": "2.0",
  "description": "Tema otimizado para exibição de placar e estatísticas em tempo real",
  "author": "Futebol Estável",
  "theme": {
    "colors": {
      "primary": "#2E7D32",
      "secondary": "#1565C0",
      "accent": "#FFD700",
      "background": "#0a0e27",
      "surface": "#141829",
      "text": "#FFFFFF",
      "score_bg": "#1a1a2e"
    }
  },
  "stream": {
    "url": "http://localhost/hls/pontuacao.m3u8",
    "type": "HLS",
    "buffer": 5000,
    "quality_levels": [
      {"name": "SD", "bitrate": "800k"},
      {"name": "HD", "bitrate": "2000k"},
      {"name": "FHD", "bitrate": "4000k"},
      {"name": "4K", "bitrate": "8000k"}
    ]
  },
  "ui": {
    "layout": "picture-in-picture",
    "overlay": {
      "enabled": true,
      "position": "center",
      "elements": [
        {
          "type": "scoreboard",
          "size": "large",
          "format": "TEAM1 X TEAM2",
          "font_size": 48,
          "display_elements": [
            "team1_name",
            "team1_logo",
            "score1",
            "separator",
            "score2",
            "team2_logo",
            "team2_name",
            "match_time",
            "match_status"
          ]
        },
        {
          "type": "statistics_table",
          "position": "bottom",
          "columns": [
            "possession",
            "shots",
            "shots_on_target",
            "fouls",
            "corners"
          ],
          "animated": true,
          "update_interval": 1000
        },
        {
          "type": "event_log",
          "position": "right",
          "max_items": 10,
          "events": [
            "gol",
            "cartao_amarelo",
            "cartao_vermelho",
            "substituicao"
          ]
        }
      ]
    },
    "colors_live": {
      "home": "#FF6B6B",
      "away": "#4ECDC4"
    }
  },
  "api": {
    "endpoints": [
      {
        "name": "placar",
        "url": "http://localhost:5000/api/live",
        "method": "GET",
        "refresh_interval": 1000
      },
      {
        "name": "estatisticas",
        "url": "http://localhost:5000/api/stats",
        "method": "GET",
        "refresh_interval": 3000
      },
      {
        "name": "eventos",
        "url": "http://localhost:5000/api/eventos",
        "method": "GET",
        "refresh_interval": 2000
      }
    ]
  },
  "animations": {
    "score_change": {
      "type": "bounce",
      "duration": 500
    },
    "stat_update": {
      "type": "pulse",
      "duration": 300
    }
  }
}
THEME
  
  log_ok "Tema XUI One para Pontuação criado"
}

# ============================================================
# 6. TEMA XUI ONE PARA MMA
# ============================================================

generar_tema_xui_mma() {
  cat > "$XUI_DIR/mma.json" << 'THEME'
{
  "manifest_version": 2,
  "id": "mma-theme",
  "name": "🥊 MMA/UFC Ao Vivo",
  "version": "2.0",
  "description": "Tema de combate otimizado para MMA/UFC com estatísticas de luta",
  "author": "Futebol Estável",
  "theme": {
    "colors": {
      "primary": "#8B0000",
      "secondary": "#FFD700",
      "accent": "#FF4500",
      "background": "#000000",
      "surface": "#1a1a1a",
      "text": "#FFFFFF",
      "fighter1": "#FF6B6B",
      "fighter2": "#4ECDC4"
    }
  },
  "stream": {
    "url": "http://localhost/hls/mma.m3u8",
    "type": "HLS",
    "buffer": 8000,
    "quality_levels": [
      {"name": "HD", "bitrate": "2000k"},
      {"name": "FHD", "bitrate": "4000k"},
      {"name": "Ultra", "bitrate": "8000k"}
    ]
  },
  "ui": {
    "layout": "fight",
    "overlay": {
      "enabled": true,
      "elements": [
        {
          "type": "fighter_card",
          "position": "top-left",
          "fighter": 1,
          "display": [
            "name",
            "photo",
            "record",
            "health_bar",
            "stats"
          ]
        },
        {
          "type": "fighter_card",
          "position": "top-right",
          "fighter": 2,
          "display": [
            "name",
            "photo",
            "record",
            "health_bar",
            "stats"
          ]
        },
        {
          "type": "round_timer",
          "position": "top-center",
          "format": "ROUND R TIME MM:SS",
          "font_size": 32,
          "blink_on_end": true
        },
        {
          "type": "fight_stats",
          "position": "center",
          "metrics": [
            {
              "name": "Significant Strikes",
              "fighter1": "value1",
              "fighter2": "value2",
              "accuracy1": "accuracy1",
              "accuracy2": "accuracy2"
            },
            {
              "name": "Takedowns",
              "fighter1": "value1",
              "fighter2": "value2"
            },
            {
              "name": "Control Time",
              "fighter1": "time1",
              "fighter2": "time2"
            }
          ]
        },
        {
          "type": "commentary",
          "position": "bottom",
          "language": "pt-BR",
          "show_subtitles": true
        }
      ]
    }
  },
  "api": {
    "endpoints": [
      {
        "name": "fight_data",
        "url": "http://localhost:5001/api/mma/live",
        "method": "GET",
        "refresh_interval": 1000
      },
      {
        "name": "fight_stats",
        "url": "http://localhost:5001/api/mma/stats",
        "method": "GET",
        "refresh_interval": 2000
      }
    ]
  },
  "notifications": {
    "types": [
      {"type": "knockout", "title": "🥊 KNOCKOUT", "sound": "ko.mp3"},
      {"type": "submission", "title": "🔓 SUBMISSION", "sound": "submission.mp3"},
      {"type": "round_end", "title": "⏰ FIM DO ROUND", "sound": "bell.mp3"}
    ]
  }
}
THEME
  
  log_ok "Tema XUI One para MMA criado"
}

# ============================================================
# 7. EXTENSÃO PARA XUI ONE (Arquivo .xuitheme)
# ============================================================

generar_extensao_xui() {
  # Extensão Gols
  cat > "$XUI_DIR/gols_ao_vivo.xuitheme" << 'XUITHEME'
<?xml version="1.0" encoding="UTF-8"?>
<xuitheme>
  <metadata>
    <id>gols-ao-vivo</id>
    <name>⚽ Gols Ao Vivo</name>
    <version>2.0</version>
    <type>live-stream</type>
    <category>futebol</category>
  </metadata>
  <stream>
    <url type="hls">http://localhost/hls/gols_ao_vivo.m3u8</url>
    <buffer>3000</buffer>
    <quality default="auto">auto,1080p,720p,480p</quality>
  </stream>
  <ui>
    <layout>fullscreen</layout>
    <theme>dark</theme>
    <overlay enabled="true">
      <score position="top-right" size="large" />
      <notification trigger="gol" animation="slide" />
      <timer format="MM:SS" />
    </overlay>
  </ui>
  <api>
    <endpoint type="live">http://localhost:5000/api/live</endpoint>
    <endpoint type="gols">http://localhost:5000/api/gols</endpoint>
  </api>
</xuitheme>
XUITHEME
  
  # Extensão Pontuação
  cat > "$XUI_DIR/pontuacao.xuitheme" << 'XUITHEME'
<?xml version="1.0" encoding="UTF-8"?>
<xuitheme>
  <metadata>
    <id>pontuacao</id>
    <name>📊 Pontuação Ao Vivo</name>
    <version>2.0</version>
    <type>live-stream</type>
    <category>futebol</category>
  </metadata>
  <stream>
    <url type="hls">http://localhost/hls/pontuacao.m3u8</url>
    <buffer>5000</buffer>
    <quality default="auto">auto,2160p,1080p,720p,480p</quality>
  </stream>
  <ui>
    <layout>picture-in-picture</layout>
    <theme>dark</theme>
    <overlay enabled="true">
      <scoreboard position="center" size="large" />
      <statistics position="bottom" animated="true" />
      <events position="right" />
    </overlay>
  </ui>
  <api>
    <endpoint type="placar">http://localhost:5000/api/live</endpoint>
    <endpoint type="stats">http://localhost:5000/api/stats</endpoint>
  </api>
</xuitheme>
XUITHEME
  
  # Extensão MMA
  cat > "$XUI_DIR/mma.xuitheme" << 'XUITHEME'
<?xml version="1.0" encoding="UTF-8"?>
<xuitheme>
  <metadata>
    <id>mma-ao-vivo</id>
    <name>🥊 MMA/UFC Ao Vivo</name>
    <version>2.0</version>
    <type>live-stream</type>
    <category>combate</category>
  </metadata>
  <stream>
    <url type="hls">http://localhost/hls/mma.m3u8</url>
    <buffer>8000</buffer>
    <quality default="auto">auto,2160p,1080p,720p</quality>
  </stream>
  <ui>
    <layout>fight</layout>
    <theme>dark</theme>
    <overlay enabled="true">
      <fighter position="top-left" id="1" />
      <fighter position="top-right" id="2" />
      <round_timer position="top-center" />
      <fight_stats position="center" />
    </overlay>
  </ui>
  <api>
    <endpoint type="fight">http://localhost:5001/api/mma/live</endpoint>
    <endpoint type="stats">http://localhost:5001/api/mma/stats</endpoint>
  </api>
</xuitheme>
XUITHEME
  
  log_ok "Extensões .xuitheme criadas para XUI One"
}

# ============================================================
# 8. ARQUIVO DE CONFIGURAÇÃO UNIVERSAL
# ============================================================

generar_config_universal() {
  cat > "$XUI_DIR/futebol_completo.xui" << 'CONFIG'
{
  "app": {
    "name": "Futebol Estável",
    "version": "2.0",
    "description": "Sistema de streaming de futebol e MMA com auto-recuperação"
  },
  "streams": [
    {
      "id": "gols_ao_vivo",
      "name": "⚽ Gols Ao Vivo",
      "m3u8": "http://localhost/hls/gols_ao_vivo.m3u8",
      "theme": "http://localhost/xui-themes/gols_ao_vivo.json",
      "extension": "http://localhost/xui-themes/gols_ao_vivo.xuitheme",
      "priority": 1,
      "enabled": true
    },
    {
      "id": "pontuacao",
      "name": "📊 Pontuação Ao Vivo",
      "m3u8": "http://localhost/hls/pontuacao.m3u8",
      "theme": "http://localhost/xui-themes/pontuacao.json",
      "extension": "http://localhost/xui-themes/pontuacao.xuitheme",
      "priority": 2,
      "enabled": true
    },
    {
      "id": "mma_ao_vivo",
      "name": "🥊 MMA/UFC Ao Vivo",
      "m3u8": "http://localhost/hls/mma.m3u8",
      "theme": "http://localhost/xui-themes/mma.json",
      "extension": "http://localhost/xui-themes/mma.xuitheme",
      "priority": 3,
      "enabled": true
    }
  ],
  "api": {
    "baseUrl": "http://localhost:5000",
    "endpoints": {
      "live": "/api/live",
      "hoje": "/api/hoje",
      "stats": "/api/stats",
      "gols": "/api/gols"
    }
  },
  "settings": {
    "theme": "dark",
    "language": "pt-BR",
    "quality": "auto",
    "buffer": "adaptive",
    "autoplay": true,
    "notifications": true,
    "analytics": true
  }
}
CONFIG
  
  log_ok "Arquivo de configuração universal criado"
}

# ============================================================
# MAIN
# ============================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   GERADOR M3U8 + XUI ONE THEMES - FUTEBOL ESTÁVEL         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Gerando M3U8s..."
generar_gols_m3u8
generar_pontuacao_m3u8
generar_mma_m3u8

echo "Gerando temas XUI One (JSON)..."
generar_tema_xui_gols
generar_tema_xui_pontuacao
generar_tema_xui_mma

echo "Gerando extensões XUI One (.xuitheme)..."
generar_extensao_xui

echo "Gerando configuração universal..."
generar_config_universal

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║             ✓ GERAÇÃO CONCLUÍDA COM SUCESSO               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Arquivos gerados em: $XUI_DIR"
echo ""
echo "📄 Arquivos M3U8:"
echo "   • http://localhost/hls/gols_ao_vivo.m3u8"
echo "   • http://localhost/hls/pontuacao.m3u8"
echo "   • http://localhost/hls/mma.m3u8"
echo ""
echo "🎨 Temas XUI One (JSON):"
echo "   • http://localhost/xui-themes/gols_ao_vivo.json"
echo "   • http://localhost/xui-themes/pontuacao.json"
echo "   • http://localhost/xui-themes/mma.json"
echo ""
echo "🔧 Extensões XUI One (.xuitheme):"
echo "   • http://localhost/xui-themes/gols_ao_vivo.xuitheme"
echo "   • http://localhost/xui-themes/pontuacao.xuitheme"
echo "   • http://localhost/xui-themes/mma.xuitheme"
echo ""
echo "⚙️  Configuração Universal:"
echo "   • http://localhost/xui-themes/futebol_completo.xui"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
