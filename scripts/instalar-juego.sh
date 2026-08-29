#!/usr/bin/env bash
# Despliega el juego SIN ejecutar el instalador de EA.
#
# El DVD guarda el juego en 0compressed.zip y 1compressed.zip, que son ZIP estandar.
# Extraerlos deja lo mismo que dejaria el instalador, sin depender de que su interfaz
# funcione bajo Wine. A cambio, el registro no se crea solo: de eso va configurar.sh.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

ISO="$DESCARGAS/carbon.iso"
TMP="$DESCARGAS/dvd"

log "=== desplegar el juego ==="
verificar_tamano "$ISO" 3847290880 "imagen del DVD"

# El ISO es UDF, no ISO9660; 7z lo abre igual. Ojo: la vista que expone 7z usa los
# nombres en minusculas, distintos de los que muestran otras herramientas.
mkdir -p "$TMP" "$JUEGO/juego"
for z in 0compressed.zip 1compressed.zip; do
  [ -f "$TMP/$z" ] || {
    log "   extrayendo $z de la imagen"
    7z e -y -o"$TMP" "$ISO" "$z" >>"$BITACORA" 2>&1 || abortar "no se pudo sacar $z"
  }
  log "   desplegando $z"
  unzip -o -q "$TMP/$z" -d "$JUEGO/juego" || aviso "avisos al desplegar $z"
done

log "   copiando los sueltos del disco"
7z e -y -o"$JUEGO/juego" "$ISO" \
   "nfsc.exe" "EAInstall.dll" "msvcp71.dll" "msvcr71.dll" \
   "00000000.256" "NFS_icon.ico" "eauninstall.exe" >>"$BITACORA" 2>&1

log "=== inventario ==="
for d in CARS MOVIES SOUND TRACKS GLOBAL FRONTEND LANGUAGES NIS SUBTITLES; do
  [ -d "$JUEGO/juego/$d" ] \
    && log "   $d: $(find "$JUEGO/juego/$d" -xdev -type f | wc -l) ficheros" \
    || abortar "falta la carpeta $d"
done
log "   total: $(du -shx "$JUEGO/juego" | cut -f1)"

[ -f "$JUEGO/juego/LANGUAGES/Spanish_Global.bin" ] || abortar "falta Spanish_Global.bin"
log "   espanol presente ($(ls "$JUEGO/juego/LANGUAGES" | grep -c _Global) idiomas en total)"
[ -n "$(ejecutable)" ] || abortar "no aparecio el ejecutable"
log "   ejecutable: $(basename "$(ejecutable)") ($(stat -c%s "$(ejecutable)") bytes)"

log "=== juego desplegado ==="
