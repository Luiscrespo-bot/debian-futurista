#!/usr/bin/env bash
# Debian Futurista - instalador de XFCE con tema oscuro, dock y compositor.
# Instalación: curl -fsSL https://raw.githubusercontent.com/Luiscrespo-bot/debian-futurista/main/personalizar.sh | sudo bash
set -Eeuo pipefail

LOG="/var/log/debian-futurista-install.log"
exec > >(tee -a "$LOG") 2>&1

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta este instalador como administrador: sudo bash personalizar.sh"
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "No se pudo identificar la distribución."
  exit 1
fi
. /etc/os-release
if [[ "\${ID:-}" != "debian" ]]; then
  echo "Este instalador está preparado para Debian. Detectado: \${PRETTY_NAME:-desconocido}"
  exit 1
fi

TARGET_USER="\${SUDO_USER:-}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "Por seguridad, inicia sesión con un usuario normal y ejecuta este script con sudo."
  exit 1
fi
TARGET_GROUP="$(id -gn "$TARGET_USER")"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
  echo "No se pudo localizar la carpeta personal de $TARGET_USER."
  exit 1
fi

echo "=================================================="
echo "             DEBIAN FUTURISTA"
echo "=================================================="
echo "Usuario: $TARGET_USER"
echo "Registro: $LOG"
echo
echo "Instalará XFCE, LightDM, Plank, Picom, temas e iconos."
echo "Necesita Internet y puede descargar varios cientos de MB."
echo "Guarda tu trabajo antes de continuar."
echo

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  xorg dbus-x11 xfce4 xfce4-goodies \
  lightdm lightdm-gtk-greeter \
  network-manager network-manager-gnome \
  plank picom \
  arc-theme papirus-icon-theme \
  fonts-cascadia-code fonts-jetbrains-mono \
  adwaita-icon-theme-full \
  firefox-esr \
  alsa-utils pavucontrol \
  policykit-1-gnome \
  xfce4-terminal thunar thunar-archive-plugin \
  gvfs gvfs-backends file-roller \
  curl ca-certificates

if command -v debconf-set-selections >/dev/null 2>&1; then
  echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections
fi
dpkg-reconfigure -f noninteractive lightdm || true

USER_CONFIG="$TARGET_HOME/.config"
AUTOSTART="$USER_CONFIG/autostart"
LOCAL_BIN="$TARGET_HOME/.local/bin"
mkdir -p "$AUTOSTART" "$USER_CONFIG/gtk-3.0" "$USER_CONFIG/picom" "$LOCAL_BIN"

cat > "$USER_CONFIG/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Cantarell 10
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
EOF

cat > "$USER_CONFIG/picom/picom.conf" <<'EOF'
backend = "glx";
vsync = true;
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.30;
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
inactive-opacity = 0.96;
EOF

cat > "$LOCAL_BIN/aplicar-debian-futurista" <<'EOF'
#!/usr/bin/env bash
set -u
command -v xfconf-query >/dev/null 2>&1 || exit 0

xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "Arc-Dark" 2>/dev/null || \
  xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "Papirus-Dark" 2>/dev/null || \
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "Cantarell 10" 2>/dev/null || \
  xfconf-query -c xsettings -p /Gtk/FontName -s "Cantarell 10" 2>/dev/null || true

pgrep -x picom >/dev/null 2>&1 || (picom --config "$HOME/.config/picom/picom.conf" >/dev/null 2>&1 &)
pgrep -x plank >/dev/null 2>&1 || (plank >/dev/null 2>&1 &)
EOF
chmod 755 "$LOCAL_BIN/aplicar-debian-futurista"

cat > "$AUTOSTART/debian-futurista.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Debian Futurista
Comment=Aplica el tema oscuro, el dock y el compositor
Exec=$LOCAL_BIN/aplicar-debian-futurista
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOF

chown -R "$TARGET_USER:$TARGET_GROUP" \
  "$USER_CONFIG/gtk-3.0" "$USER_CONFIG/picom" "$AUTOSTART/debian-futurista.desktop" "$LOCAL_BIN"

systemctl enable NetworkManager.service || true
systemctl enable lightdm.service
systemctl set-default graphical.target

echo
echo "=================================================="
echo "Instalación completada."
echo "XFCE y la personalización se aplicarán al iniciar sesión."
echo "El registro está en: $LOG"
echo
echo "El equipo se reiniciará en 30 segundos."
echo "Para cancelar el reinicio, pulsa Ctrl+C ahora."
echo "=================================================="

for seconds in $(seq 30 -1 1); do
  printf "\rReinicio en %2d segundos... " "$seconds"
  sleep 1
done
echo
systemctl reboot
