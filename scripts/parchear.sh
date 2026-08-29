#!/usr/bin/env bash
# Aplica el parche 1.4, deja el ejecutable sin SafeDisc y coloca los complementos.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

log "=== parches ==="
mkdir -p "$JUEGO/respaldos"

# 1. Parche oficial 1.4. Arregla, entre otras cosas, el cierre justo despues del
#    logotipo de EA en Windows Vista y posteriores, que es lo que Wine emula.
#    Es un RTPatch y acepta /S para no abrir interfaz. OJO: renombra el ejecutable
#    de nfsc.exe a NFSC.exe, asi que despues hay que buscarlo sin distinguir mayusculas.
if [ ! -f "$JUEGO/respaldos/nfsc.exe.original" ]; then
  cp -p "$(ejecutable)" "$JUEGO/respaldos/nfsc.exe.original"
fi
mkdir -p "$DESCARGAS/p14"
unzip -o -q "$DESCARGAS/patch14.zip" -d "$DESCARGAS/p14" || abortar "no se pudo abrir el parche"
log "   aplicando el parche 1.4"
( cd "$DESCARGAS/p14" && timeout 180 wine patch_1.2_1.3_1.4.exe /S >>"$BITACORA" 2>&1 ) || true
sleep 2
[ -n "$(ejecutable)" ] || abortar "el parche dejo el juego sin ejecutable"
log "   tras el parche: $(basename "$(ejecutable)") ($(stat -c%s "$(ejecutable)") bytes)"

# 2. El parche oficial NO quita SafeDisc: comprobado, las secciones stxt774 y
#    stxt371 siguen ahi. Wine no implementa el controlador secdrv que necesita.
if tiene_safedisc "$(ejecutable)"; then
  log "   sigue con SafeDisc; se sustituye por el limpio"
  mv -n "$(ejecutable)" "$JUEGO/respaldos/$(basename "$(ejecutable)").1.4-con-safedisc"
  unzip -o -q "$DESCARGAS/nocd.zip" -d "$JUEGO/juego" || abortar "no se pudo extraer el limpio"
else
  log "   el ejecutable ya venia limpio"
fi
verificar_tamano "$(ejecutable)" 7217152 "ejecutable sin SafeDisc"
tiene_safedisc "$(ejecutable)" && abortar "el ejecutable SIGUE con SafeDisc"
log "   sin SafeDisc, confirmado leyendo las secciones PE"

# 3. Un solo cargador. El Widescreen Fix y ExOpts traen cada uno su dinput8.dll;
#    poner los dos rompe la carga. Se usa el del Widescreen Fix.
log "   Widescreen Fix de ThirteenAG"
unzip -o -q "$DESCARGAS/widescreen.zip" -d "$JUEGO/juego" || abortar "fallo el parche panoramico"

log "   Extra Options (solo el .asi, no su cargador)"
TMP="$DESCARGAS/exopts-tmp"; mkdir -p "$TMP"
unzip -o -q "$DESCARGAS/exopts.zip" -d "$TMP" || abortar "fallo Extra Options"
cp -p "$TMP/Main Files/scripts/NFSCExtraOptions.asi"         "$JUEGO/juego/scripts/"
cp -p "$TMP/Main Files/scripts/NFSCExtraOptionsSettings.ini" "$JUEGO/juego/scripts/"
cp -p "$TMP/Read Me.txt" "$JUEGO/juego/scripts/ExOpts-LEEME.txt" 2>/dev/null
rm -rf "${TMP:?ruta vacia}"

# msvcp71, msvcr71 y EAInstall son del propio juego y deben quedarse; solo se cuenta
# que no haya un segundo cargador.
N=$(find "$JUEGO/juego" -xdev -maxdepth 1 -iname 'dinput*.dll' | wc -l)
[ "$N" = 1 ] || abortar "hay $N cargadores dinput y debe haber 1"
log "   un solo cargador: dinput8.dll"
for a in NFSCarbon.WidescreenFix.asi NFSCExtraOptions.asi; do
  [ -f "$JUEGO/juego/scripts/$a" ] || abortar "falta $a"
done
log "   los dos complementos en scripts/"
log "=== parches aplicados ==="
