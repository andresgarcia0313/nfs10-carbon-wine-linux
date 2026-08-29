#!/usr/bin/env bash
# Comprueba (y ofrece instalar) lo que hace falta antes de empezar.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

log "=== dependencias ==="

FALTAN=()
for h in wine aria2c 7z unzip curl python3; do
  command -v "$h" >/dev/null || FALTAN+=("$h")
done
command -v mangohud >/dev/null || aviso "sin mangohud: la opcion --fps del lanzador no medira nada"
command -v bwrap    >/dev/null || aviso "sin bubblewrap: la opcion --sinsync no podra ocultar /dev/ntsync"

if [ ${#FALTAN[@]} -gt 0 ]; then
  echo
  echo "Faltan estas herramientas: ${FALTAN[*]}"
  echo "En Debian, Ubuntu o Kubuntu:"
  echo "   sudo apt install wine aria2 p7zip-full unzip curl python3 mangohud bubblewrap"
  echo "En Arch:"
  echo "   sudo pacman -S wine aria2 p7zip unzip curl python mangohud bubblewrap"
  abortar "instale lo que falta y vuelva a ejecutar"
fi

VER=$(wine --version 2>/dev/null | sed 's/^wine-//')
log "   wine $VER"
case "$VER" in
  1[0-9].*|[2-9][0-9].*) : ;;
  9.*) aviso "wine $VER es anterior a la 10; el juego deberia ir igual, pero no esta probado" ;;
  *)   aviso "no se pudo interpretar la version de wine ($VER)" ;;
esac

# Wine 11 ya no permite prefijos de 32 bits: se usa uno de 64 con WoW64, que ejecuta
# el speed.exe de 32 bits sin problema.
log "   se creara un prefijo de 64 bits con WoW64 (Wine 11 ya no admite prefijos win32)"

LIBRE=$(df -Pk "$(dirname "$JUEGO")" | awk 'NR==2{print int($4/1048576)}')
log "   espacio libre en el destino: ${LIBRE} GB"
[ "${LIBRE:-0}" -ge 12 ] || abortar "hacen falta al menos 12 GB libres (imagenes + juego). Hay ${LIBRE} GB"

LIBRE_D=$(df -Pk "$(dirname "$DESCARGAS")" | awk 'NR==2{print int($4/1048576)}')
[ "${LIBRE_D:-0}" -ge 6 ] || abortar "hacen falta al menos 6 GB libres para las descargas en $DESCARGAS"

log "   todo en orden"
