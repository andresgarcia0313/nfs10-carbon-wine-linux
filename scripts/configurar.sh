#!/usr/bin/env bash
# Crea el prefijo, el registro y la configuracion, y sube la calidad grafica.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

log "=== configuracion ==="
mkdir -p "$PREFIJO"
wineboot -u >>"$BITACORA" 2>&1
sleep 3
[ -d "$PREFIJO/drive_c" ] || abortar "no se creo el prefijo"
ln -sfn "$JUEGO/juego" "$PREFIJO/drive_c/NFSC"

# CUATRO ramas de registro. `strings NFSC.exe` revela que el juego busca tanto
# "Need for Speed Carbon" como "Need for Speed Carbono": ese es el titulo en
# espanol, y es la rama que usa cuando el idioma es el nuestro. Crear solo la
# inglesa deja al juego sin encontrar sus ajustes.
CLAVE="${NFSC_CDKEY:-INSERTYOURCDKEYHERE}"
log "   registro (las cuatro ramas, Carbon y Carbono)"
{
  echo 'Windows Registry Editor Version 5.00'; echo
  for base in 'Software' 'Software\Wow6432Node'; do
    for nom in 'Need for Speed Carbon' 'Need for Speed Carbono'; do
      echo "[HKEY_LOCAL_MACHINE\\$base\\Electronic Arts\\$nom]"
      echo '"Install Dir"="C:\\NFSC\\"'
      echo '"PATH"="C:\\NFSC\\"'
      echo '"Language"="Spanish"'
      echo '"VERSION"="1.4"'; echo
      echo "[HKEY_LOCAL_MACHINE\\$base\\Electronic Arts\\Electronic Arts\\$nom\\ergc]"
      echo "@=\"$CLAVE\""; echo
    done
  done
  echo '[HKEY_CURRENT_USER\Software\Wine\DllOverrides]'
  echo '"dinput8"="native,builtin"'
  echo '"winemenubuilder.exe"=""'
  echo '"mscoree"=""'
  echo '"mshtml"=""'
} > "$DESCARGAS/juego.reg"
wine regedit "$DESCARGAS/juego.reg" >>"$BITACORA" 2>&1
sleep 2

# Muchos equipos exponen ratones o teclados virtuales que Wine enumera como mandos.
# En NFS Underground eso hacia que el juego actuara como si se mantuviera ARRIBA.
log "   desactivando mandos fantasma"
{
  echo 'Windows Registry Editor Version 5.00'; echo
  echo '[HKEY_CURRENT_USER\Software\Wine\DirectInput\Joysticks]'
  for d in /dev/input/event*; do
    n=$(cat "/sys/class/input/$(basename "$d")/device/name" 2>/dev/null) || continue
    case "$n" in *fake*|*Fake*|*virtual*|*Virtual*|*ydotool*|*mouce*) printf '"%s"="disabled"\n' "$n";; esac
  done
} > "$DESCARGAS/joysticks.reg"
wine regedit "$DESCARGAS/joysticks.reg" >>"$BITACORA" 2>&1
sleep 2

log "   configuracion del parche panoramico"
cp -p "$REPO/config/NFSCarbon.WidescreenFix.ini" "$INI"

# Primer arranque corto: con WriteSettingsToFile = 1 el parche vuelca los ajustes a
# un fichero de texto. Sin este paso no existe el fichero que luego se sustituye.
log "   generando el fichero de ajustes (arranque corto)"
mkdir -p "$(dirname "$AJUSTES")"
( cd "$JUEGO/juego" && \
  WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=;dinput8,msvcp71,msvcr71,EAInstall=n,b" \
  timeout 60 wine "$(basename "$(ejecutable)")" >>"$BITACORA" 2>&1 ) || true
for p in $(pgrep -xi "nfsc.exe" 2>/dev/null); do kill -TERM "$p" 2>/dev/null; done
sleep 3
[ -f "$AJUSTES" ] || abortar "el parche no genero el fichero de ajustes"
cp -p "$AJUSTES" "$AJUSTES.bak-defecto"
cp -p "$REPO/config/Settings.ini" "$AJUSTES"
[ "$CLAVE" != "INSERTYOURCDKEYHERE" ] && \
  sed -i "s/^@=INSERTYOURCDKEYHERE/@=$CLAVE/" "$AJUSTES"
log "   ajustes aplicados (los de fabrica quedan en Settings.ini.bak-defecto)"

# Red de seguridad: si el complemento no cargara, el juego leeria el registro, y de
# fabrica lo deja todo al minimo.
log "   replicando la calidad en el registro"
{
  echo 'Windows Registry Editor Version 5.00'; echo
  for nom in 'Need for Speed Carbon' 'Need for Speed Carbono'; do
    echo "[HKEY_CURRENT_USER\\Software\\Electronic Arts\\$nom]"
    grep -aoE "^g_[A-Za-z]+=[0-9]+" "$AJUSTES" | tr -d '\r' | while IFS='=' read -r k v; do
      [ "$k" = "g_RacingResolution" ] && continue
      printf '"%s"=dword:%08x\n' "$k" "$v"
    done
    echo '"Language"="Spanish"'; echo
  done
} > "$DESCARGAS/graficos.reg"
wine regedit "$DESCARGAS/graficos.reg" >>"$BITACORA" 2>&1
sleep 2
log "=== configurado ==="
