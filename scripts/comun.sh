#!/usr/bin/env bash
# Funciones y rutas compartidas por los guiones del instalador.

JUEGO="${NFSC_DESTINO:-/opt/games/Need For Speed X Carbon}"
DESCARGAS="${NFSC_DESCARGAS:-/var/tmp/nfsc-descargas}"
PREFIJO="$JUEGO/prefix"
INI="$JUEGO/juego/scripts/NFSCarbon.WidescreenFix.ini"
AJUSTES="$JUEGO/juego/save/NFS Carbon/Settings.ini"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BITACORA="${NFSC_BITACORA:-/var/tmp/nfsc-instalacion.log}"

log(){ echo "$(date +%H:%M:%S) $*" | tee -a "$BITACORA"; }
aviso(){ echo "$(date +%H:%M:%S) AVISO: $*" | tee -a "$BITACORA" >&2; }
abortar(){ echo "$(date +%H:%M:%S) ERROR: $*" | tee -a "$BITACORA" >&2; exit 1; }

verificar_tamano(){
  local ruta="$1" esperado="$2" nombre="${3:-$(basename "$1")}"
  [ -f "$ruta" ] || abortar "falta $nombre"
  local real; real=$(stat -c%s "$ruta")
  [ "$real" = "$esperado" ] || abortar "$nombre mide $real y deberia medir $esperado"
  log "   ok $nombre ($real bytes)"
}

# El ejecutable cambia de mayusculas segun quien lo escriba: el disco trae nfsc.exe
# y el parche 1.4 lo deja como NFSC.exe. Buscarlo sin distinguir evita sustos.
ejecutable(){ ls "$JUEGO/juego"/[Nn][Ff][Ss][Cc].exe 2>/dev/null | head -1; }

# Devuelve 0 si el ejecutable lleva las secciones de SafeDisc.
tiene_safedisc(){
  python3 - "$1" <<'PY'
import struct, sys
d = open(sys.argv[1], 'rb').read()
pe = struct.unpack('<I', d[0x3c:0x40])[0]
n = struct.unpack('<H', d[pe+6:pe+8])[0]
o = struct.unpack('<H', d[pe+20:pe+22])[0]
off = pe + 24 + o
sec = [d[off+i*40:off+i*40+8].rstrip(b'\x00') for i in range(n)]
sys.exit(0 if any(s.startswith(b'stxt') for s in sec) else 1)
PY
}

# Reescribe claves de un .ini en binario: el modo texto destruiria los CRLF que los
# complementos de Windows necesitan.
reescribir_ini(){
  local ruta="$1"; shift
  python3 - "$ruta" "$@" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1]); d = p.read_bytes()
for par in sys.argv[2:]:
    patron, nuevo = par.split('=>', 1)
    d, n = re.subn(patron.encode(), nuevo.encode(), d, flags=re.M)
    print(f"   {'ok ' if n else 'NO '} {nuevo}")
p.write_bytes(d)
PY
}

export WINEPREFIX="$PREFIJO"
export WINEDEBUG="${WINEDEBUG:--all}"
