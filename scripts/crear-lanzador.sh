#!/usr/bin/env bash
# Crea la entrada del menu de escritorio, con icono y acciones.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/comun.sh"

APPS="$HOME/.local/share/applications"
ICONOS="$HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$APPS" "$ICONOS"

log "=== lanzador de escritorio ==="
if [ -f "$JUEGO/juego/NFS_icon.ico" ] && command -v magick >/dev/null; then
  magick "$JUEGO/juego/NFS_icon.ico" -alpha on "$HOME/.local/share/icons/nfsc-tmp.png" 2>/dev/null || true
  MEJOR=$(ls -S "$HOME/.local/share/icons/"nfsc-tmp*.png 2>/dev/null | head -1)
  [ -n "$MEJOR" ] && magick "$MEJOR" -resize 256x256 "$ICONOS/nfs-carbon.png" 2>/dev/null
  find "$HOME/.local/share/icons" -maxdepth 1 -name 'nfsc-tmp*.png' -delete
  log "   icono extraido del propio juego"
fi

# OJO: la ruta lleva espacios. Sin las comillas dobles, el Exec no arranca y el
# escritorio no da ningun aviso: simplemente no pasa nada al pulsar.
cat > "$APPS/nfs-carbon-be.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Need For Speed: Carbono
GenericName=Juego de carreras
Comment=Carbon (2006) en espanol, a 1080p, sobre Wine
Exec="$JUEGO/jugar.sh"
Path=$JUEGO
Icon=nfs-carbon
Terminal=false
Categories=Game;ActionGame;ArcadeGame;
Keywords=nfs;carreras;coches;wine;racing;
StartupNotify=true
StartupWMClass=nfsc.exe
Actions=SinIntro;Ventana;Fps;

[Desktop Action SinIntro]
Name=Saltar los videos de arranque
Exec="$JUEGO/jugar.sh" --sinintro

[Desktop Action Ventana]
Name=Abrir en ventana
Exec="$JUEGO/jugar.sh" --ventana

[Desktop Action Fps]
Name=Con contador de rendimiento
Exec="$JUEGO/jugar.sh" --fps
EOF

desktop-file-validate "$APPS/nfs-carbon-be.desktop" || aviso "el .desktop tiene avisos"
update-desktop-database "$APPS" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
kbuildsycoca6 --noincremental 2>/dev/null >/dev/null || true
log "   entrada creada en el menu"
