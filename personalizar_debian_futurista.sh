#!/usr/bin/env bash
# Debian Futurista - instalador de escritorio XFCE
# Uso: sudo bash personalizar.sh
set -Eeuo pipefail

LOG="/var/log/debian-futurista-install.log"
exec > >(tee -a "$LOG") 2>&1

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta este archivo como administrador:"
  echo "  sudo bash $0"
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "No se pudo identificar la distribución."
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "debian" ]]; then
  echo "Este instalador está preparado para Debian. Detectado: ${PRETTY_NAME:-desconocido}"
  exit 1
fi

# Si se usa sudo, personaliza la cuenta que lanzó el comando.
TARGET_USER="${SUDO_USER:-}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "Por seguridad, inicia sesión con tu usuario normal y ejecuta:"
  echo "  sudo bash $0"
  exit 1
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
  echo "No se pudo localizar la carpeta personal de $TARGET_USER."
  exit 1
fi

echo "== Debian Futurista: instalación =="
echo "Usuario: $TARGET_USER"
echo "Registro: $LOG"
echo
echo "Se instalará XFCE, LightDM, un dock y temas oscuros."
echo "Esto requiere conexión a Internet y puede descargar varios cientos de MB."
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

# Selecciona LightDM como gestor gráfico si hay más de una opción.
if command -v dpkg-reconfigure >/dev/null 2>&1; then
  echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections
  dpkg-reconfigure -f noninteractive lightdm || true
fi

# Configuración que se aplica al iniciar sesión gráfica del usuario.
USER_CONFIG="$TARGET_HOME/.config"
AUTOSTART="$USER_CONFIG/autostart"
mkdir -p "$AUTOSTART" "$USER_CONFIG/gtk-3.0" "$USER_CONFIG/picom"

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
corner-radius = 10;
EOF

# Aplicador de ajustes: se ejecuta dentro de la sesión XFCE, cuando D-Bus está disponible.
cat > "$TARGET_HOME/.local/bin/aplicar-debian-futurista" <<'EOF'
#!/usr/bin/env bash
set -u
command -v xfconf-query >/dev/null 2>&1 || exit 0

# Apariencia oscura y tipografía.
xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "Arc-Dark" 2>/dev/null || \
  xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "Papirus-Dark" 2>/dev/null || \
  xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "Cantarell 10" 2>/dev/null || \
  xfconf-query -c xsettings -p /Gtk/FontName -s "Cantarell 10" 2>/dev/null || true

# Fondo azul noche uniforme.
for screen in 0; do
  xfconf-query -c xfce4-desktop -p "/backdrop/screen${screen}/monitor0/workspace0/color-style" -n -t int -s 0 2>/dev/null || true
  xfconf-query -c xfce4-desktop -p "/backdrop/screen${screen}/monitor0/workspace0/rgba1" -n \
    -t double -t double -t double -t double -s 0.025 -s 0.045 -s 0.09 -s 1 2>/dev/null || true
done

# Inicia el dock y el compositor si todavía no están activos.
pgrep -x picom >/dev/null 2>&1 || (picom --config "$HOME/.config/picom/picom.conf" >/dev/null 2>&1 &)
pgrep -x plank >/dev/null 2>&1 || (plank >/dev/null 2>&1 &)
EOF

mkdir -p "$TARGET_HOME/.local/bin"
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$TARGET_HOME/.local"
chmod 755 "$TARGET_HOME/.local/bin/aplicar-debian-futurista"

cat > "$AUTOSTART/debian-futurista.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Debian Futurista
Comment=Aplica el tema oscuro, el dock y el compositor
Exec=$TARGET_HOME/.local/bin/aplicar-debian-futurista
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOF

# Autostart para el dock y compositor se controla desde el aplicador.
chown -R "$TARGET_USER":"$(id -gn "$TARGET_USER")" "$USER_CONFIG"

# Habilita red y gestor de inicio gráfico.
systemctl enable NetworkManager.service || true
systemctl enable lightdm.service
systemctl set-default graphical.target

echo
echo "== Instalación terminada =="
echo "El escritorio XFCE y la personalización se aplicarán al iniciar sesión."
echo "Reinicia con: sudo reboot"
echo "Si aparece una pantalla de inicio de sesión, selecciona la sesión XFCE."
echo "Si algo falla, revisa: $LOG"
