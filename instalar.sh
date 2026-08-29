#!/usr/bin/env bash
# Need For Speed: Carbon (2006) en Linux, de principio a fin.
#
#   ./instalar.sh              instalacion completa
#   ./instalar.sh --comprobar  solo comprueba una instalacion ya hecha
#   ./instalar.sh --ayuda
#
# Variables que se pueden cambiar:
#   NFSC_DESTINO    donde instalar        (por defecto /opt/games/Need For Speed X Carbon)
#   NFSC_DESCARGAS  donde guardar el ISO  (por defecto /var/tmp/nfsc-descargas)
#   NFSC_CDKEY      clave de producto     (opcional: el juego arranca sin ella)
set -uo pipefail
cd "$(dirname "$0")"
source scripts/comun.sh

for a in "$@"; do case "$a" in
  --comprobar) exec bash scripts/comprobar.sh ;;
  --ayuda|-h)  sed -n '2,13p' "$0"; exit 0 ;;
  *) abortar "Opcion desconocida: $a. Use --ayuda." ;;
esac; done

: > "$BITACORA"
log "=== Need For Speed: Carbon ==="
log "    destino:   $JUEGO"
log "    descargas: $DESCARGAS"
log "    bitacora:  $BITACORA"

if [ -n "$(ejecutable 2>/dev/null)" ]; then
  echo
  echo "Ya hay una instalacion en $JUEGO"
  read -r -p "Continuar y sobrescribir? [s/N] " r
  case "$r" in [sS]*) : ;; *) abortar "cancelado por el usuario" ;; esac
fi

mkdir -p "$JUEGO" || abortar "no se puede escribir en $JUEGO. Pruebe:
   sudo mkdir -p '$JUEGO' && sudo chown \"\$USER\" '$JUEGO'
o instale en su carpeta personal:
   NFSC_DESTINO=\"\$HOME/Juegos/Carbon\" ./instalar.sh"

bash scripts/dependencias.sh   || abortar "fallo la comprobacion de dependencias"
bash scripts/descargar.sh      || abortar "fallaron las descargas"
bash scripts/instalar-juego.sh || abortar "fallo el despliegue del juego"
bash scripts/parchear.sh       || abortar "fallaron los parches"
bash scripts/configurar.sh     || abortar "fallo la configuracion"

install -m 755 scripts/jugar.sh "$JUEGO/jugar.sh"
# OJO: NO tocar ShowSubs. Su documentacion dice "German, French, Spanish, all have
# subtitles. Why not English?": esa opcion es SOLO para anadir subtitulos al ingles.
# En espanol el juego ya los trae de serie.
bash scripts/crear-lanzador.sh || aviso "no se pudo crear la entrada del menu"

echo
bash scripts/comprobar.sh
EST=$?

echo
log "=== listo ==="
echo "Para jugar:"
echo "   \"$JUEGO/jugar.sh\""
echo "o busque \"Need For Speed: Carbono\" en el menu de aplicaciones."
echo
echo "Opciones del lanzador: --sinintro  --ventana  --fps  --sinsync  --registro"
exit $EST
