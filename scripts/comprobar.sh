#!/usr/bin/env bash
# Comprobacion posterior a la instalacion. Devuelve 1 si algo esta mal.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

FALLOS=0
ok(){   printf '  \033[32mok\033[0m   %s\n' "$1"; }
mal(){  printf '  \033[31mMAL\033[0m  %s\n' "$1"; FALLOS=$((FALLOS+1)); }
nota(){ printf '  \033[33mnota\033[0m %s\n' "$1"; }

echo "=== comprobacion de la instalacion ==="

EXE=$(ejecutable)
if [ -n "$EXE" ]; then
  T=$(stat -c%s "$EXE")
  [ "$T" = 7217152 ] && ok "ejecutable de 7.217.152 bytes" || mal "el ejecutable mide $T"
  tiene_safedisc "$EXE" && mal "el ejecutable LLEVA SafeDisc" || ok "sin SafeDisc"
else mal "no hay ejecutable"; fi

N=$(find "$JUEGO/juego" -xdev -maxdepth 1 -iname 'dinput*.dll' | wc -l)
[ "$N" = 1 ] && ok "un solo cargador de complementos" || mal "hay $N cargadores dinput"

for a in NFSCarbon.WidescreenFix.asi NFSCExtraOptions.asi; do
  [ -f "$JUEGO/juego/scripts/$a" ] && ok "complemento $a" || mal "falta $a"
done

[ -f "$JUEGO/juego/LANGUAGES/Spanish_Global.bin" ] && ok "textos en espanol" || mal "falta Spanish_Global.bin"
IDI=$(ls "$JUEGO/juego/LANGUAGES" 2>/dev/null | grep -c _Global)
[ "$IDI" -ge 16 ] && ok "$IDI idiomas instalados" || nota "solo $IDI idiomas"

grep -q "^Language=Spanish" "$AJUSTES" 2>/dev/null \
  && ok "idioma en el fichero de ajustes" || mal "el fichero de ajustes no dice Spanish"
grep -q "^Language = Spanish" "$INI" 2>/dev/null \
  && ok "idioma en el parche panoramico" || mal "el parche panoramico no dice Spanish"

# Las CUATRO ramas: en espanol el juego se llama "Carbono" y usa esa rama.
for n in 'Need for Speed Carbon' 'Need for Speed Carbono'; do
  wine reg query "HKLM\\Software\\Electronic Arts\\$n" /v Language 2>/dev/null | grep -q Spanish \
    && ok "registro: $n" || mal "falta o no esta en espanol la rama $n"
done

wine reg query 'HKCU\Software\Wine\DllOverrides' /v dinput8 2>/dev/null | grep -q native \
  && ok "dinput8 nativo tambien en el registro" \
  || mal "dinput8 solo en el lanzador: arrancar por otra via no cargaria los complementos"

grep -q "^SkipIntro = 0" "$INI" 2>/dev/null && ok "los videos de arranque se ven" \
  || nota "SkipIntro no esta en 0"
grep -q "^WindowedMode = 4" "$INI" 2>/dev/null && ok "pantalla completa sin bordes (lo que Wayland necesita)" \
  || nota "WindowedMode no esta en 4"
grep -q "^CrashFix = 1" "$INI" 2>/dev/null && ok "arreglo del cierre al cargar perfil" \
  || mal "CrashFix apagado: el juego se cerrara al cargar una partida"
grep -q "^ShowSubs = 1" "$JUEGO/juego/scripts/NFSCExtraOptionsSettings.ini" 2>/dev/null \
  && ok "subtitulos activados (asi las cinematicas se leen en espanol)" \
  || nota "subtitulos apagados: las cinematicas iran en ingles sin texto"

[ -L "$PREFIJO/drive_c/NFSC" ] && [ -d "$PREFIJO/drive_c/NFSC" ] \
  && ok "el prefijo ve el juego como C:\\NFSC" || mal "el enlace C:\\NFSC no resuelve"

[ -f "$JUEGO/juego/d3d9.dll" ] \
  && nota "hay un d3d9.dll (DXVK): en esta serie wined3d rindio mejor" \
  || ok "sin DXVK"

echo
if [ "$FALLOS" = 0 ]; then echo "Todo correcto."; else echo "$FALLOS comprobaciones fallaron."; fi
exit $([ "$FALLOS" = 0 ] && echo 0 || echo 1)
