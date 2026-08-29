#!/usr/bin/env bash
# Need For Speed: Carbon (2006) sobre Wine 11.
# Uso: jugar.sh [--sinintro] [--ventana] [--sinsync] [--fps] [--registro] [--ayuda]
set -uo pipefail
J="/opt/games/Need For Speed X Carbon"
export WINEPREFIX="$J/prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
# dinput8 nativo carga los complementos. msvcp71/msvcr71 y EAInstall son las que el
# propio juego trae; forzar las nativas evita que Wine sustituya por las suyas.
export WINEDLLOVERRIDES="mscoree,mshtml=;winemenubuilder.exe=;dinput8,msvcp71,msvcr71,EAInstall=n,b"
INI="$J/juego/scripts/NFSCarbon.WidescreenFix.ini"
TRAZA="$J/traza-wine.log"

fallo(){ kdialog --title "Carbon" --error "$1" 2>/dev/null || echo "ERROR: $1" >&2; exit 1; }

SININTRO=0; VENTANA=0; SINSYNC=0; FPS=0; TRAZAR=0
for a in "$@"; do case "$a" in
  --sinintro) SININTRO=1 ;;
  --ventana)  VENTANA=1 ;;
  --sinsync)  SINSYNC=1 ;;
  --fps)      FPS=1 ;;
  --registro) TRAZAR=1 ;;
  --ayuda|-h) sed -n '2,3p' "$0"; exit 0 ;;
  *) fallo "Opcion desconocida: $a. Use --ayuda." ;;
esac; done

EXE=$(ls "$J/juego"/[Nn][Ff][Ss][Cc].exe 2>/dev/null | head -1)
[ -n "$EXE" ] || fallo "Falta NFSC.exe en $J/juego"
[ -f "$INI" ] || fallo "Falta $INI"

RESTAURAR=0
if [ "$SININTRO" = 1 ] || [ "$VENTANA" = 1 ]; then
  [ -e "$INI.bak" ] && fallo "Existe $INI.bak de una ejecucion anterior. Revise y restaurelo."
  if cp -p "$INI" "$INI.bak"; then
    RESTAURAR=1
    trap 'if [ "$RESTAURAR" = 1 ] && [ -f "$INI.bak" ]; then mv -f "$INI.bak" "$INI"; fi' EXIT INT TERM
    [ "$SININTRO" = 1 ] && sed -i 's/^SkipIntro = 0/SkipIntro = 1/' "$INI"
    [ "$VENTANA"  = 1 ] && sed -i 's/^WindowedMode = 4/WindowedMode = 2/' "$INI"
  else
    fallo "No se pudo respaldar $INI; no se modifica nada."
  fi
fi

[ "$FPS" = 1 ] && { export MANGOHUD=1; export MANGOHUD_CONFIG="fps,frametime,cpu_stats,gpu_stats"; }
[ "$TRAZAR" = 1 ] && export WINEDEBUG=+file

cd "$J/juego" || fallo "No se pudo entrar a $J/juego"
MOTOR=(wine "$(basename "$EXE")")
[ "$FPS" = 1 ] && command -v mangohud >/dev/null && MOTOR=(mangohud wine "$(basename "$EXE")")
if [ "$SINSYNC" = 1 ] && command -v bwrap >/dev/null; then
  MOTOR=(bwrap --dev-bind / / --bind /dev/null /dev/ntsync -- "${MOTOR[@]}")
fi
if command -v systemd-run >/dev/null && [ -z "${NFSC_SIN_SCOPE:-}" ]; then
  MOTOR=(systemd-run --user --scope -q --slice=app.slice --unit="nfsc-$$" -- "${MOTOR[@]}")
fi

# Nada de 'exec' si hay que restaurar: exec reemplaza el proceso y el trap EXIT
# no se dispara nunca, dejando el .ini alterado para siempre.
if [ "$TRAZAR" = 1 ]; then
  "${MOTOR[@]}" 2> >(tee "$TRAZA" >&2)
elif [ "$RESTAURAR" = 1 ]; then
  "${MOTOR[@]}"
else
  exec "${MOTOR[@]}"
fi
