#!/usr/bin/env bash
# Descarga la imagen del disco, los parches y los complementos.
#
# Aqui basta UN disco, a diferencia de Most Wanted: esta edicion trae dieciseis
# idiomas de texto, con Spanish_Global.bin y Mexican_Global.bin incluidos.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

mkdir -p "$DESCARGAS"
log "=== descargas en $DESCARGAS ==="

# aria2c con 16 conexiones: con una sola, archive.org da unos 0,2 MB/s y esto tarda
# horas; con 16 sube a 20-30 MB/s.
bajar(){
  local url="$1" salida="$2" tam="$3" nombre="$4"
  if [ -f "$DESCARGAS/$salida" ] && [ "$(stat -c%s "$DESCARGAS/$salida")" = "$tam" ]; then
    log "   ya estaba: $nombre"; return 0
  fi
  log "   bajando $nombre"
  aria2c -c -x16 -s16 -k1M --file-allocation=none --console-log-level=warn \
         --summary-interval=45 -d "$DESCARGAS" -o "$salida" "$url" \
    || abortar "fallo la descarga de $nombre"
  verificar_tamano "$DESCARGAS/$salida" "$tam" "$nombre"
}

# Publicacion: archive.org/details/need-for-speed-carbon_202510
# Trae el DVD original 1:1, el parche 1.4, el ejecutable sin CD y las claves.
IT=https://archive.org/download/need-for-speed-carbon_202510
bajar "$IT/Need%20For%20Speed%20Carbon.iso" "carbon.iso" 3847290880 "DVD de Carbon (3,6 GB)"

pequeno(){
  local url="$1" salida="$2" nombre="$3"
  [ -s "$DESCARGAS/$salida" ] && { log "   ya estaba: $nombre"; return 0; }
  log "   bajando $nombre"
  curl -sL --max-time 240 -o "$DESCARGAS/$salida" "$url" || abortar "fallo $nombre"
  [ -s "$DESCARGAS/$salida" ] || abortar "$nombre vino vacio"
  log "   ok $nombre ($(stat -c%s "$DESCARGAS/$salida") bytes)"
}
pequeno "$IT/Patch%201.4.zip"  "patch14.zip" "parche oficial 1.4"
pequeno "$IT/No-CD%20Fix.zip"  "nocd.zip"    "ejecutable sin SafeDisc"
pequeno "$IT/Serial%20keys.txt" "seriales.txt" "claves de producto"

GH=https://github.com
pequeno "$GH/ThirteenAG/WidescreenFixesPack/releases/download/nfsc/NFSCarbon.WidescreenFix.zip" \
        "widescreen.zip" "Widescreen Fix de ThirteenAG"
pequeno "$GH/ExOptsTeam/NFSCExOpts/releases/download/v3.0.1.1338/NFSC.ExOpts.v3.0.1.1338.zip" \
        "exopts.zip" "NFSC Extra Options"

log "=== descargas completas ==="
