#!/bin/bash
set -e

### === CONFIGURATION ===
MESA_SOURCE="kisak"  # Standard: kisak

### === FUNCTIONS ===

print_usage() {
  echo "Usage: sudo $0 [--mesa oibaf|kisak]"
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mesa)
        shift
        if [[ "$1" == "oibaf" || "$1" == "kisak" ]]; then
          MESA_SOURCE="$1"
        else
          echo "Not a valid MESA-Source: $1"
          print_usage
        fi
        ;;
      -*|--*)
        echo "Unknown option: $1"
        print_usage
        ;;
    esac
    shift
  done
}

is_x11_active() {
  if [ -n "$DISPLAY" ] && xrandr &> /dev/null; then
    return 0  # X11
  else
    return 1  # probably Wayland
  fi
}

install_mesa() {
  case "$MESA_SOURCE" in
    oibaf)
      echo ">>> Adding Oibaf PPA (Mesa)..."
      add-apt-repository -y ppa:oibaf/graphics-drivers
      ;;
    kisak)
      echo ">>> Adding Kisak PPA (Mesa)..."
      add-apt-repository -y ppa:kisak/kisak-mesa
      ;;
  esac
  apt update
  apt full-upgrade -y
}

configure_amdgpu_x11() {
  echo ">>> Checking active monitors on X11..."
  ACTIVE_MONITORS=$(xrandr --listmonitors | grep -c "^ ")
  echo "Active monitors: $ACTIVE_MONITORS"

  echo ">>> Create X11-Configuration for AMDGPU..."
  mkdir -p /etc/X11/xorg.conf.d
  XORG_FILE="/etc/X11/xorg.conf.d/10-amdgpu.conf"

  cat > "$XORG_FILE" <<EOF
Section "Device"
    Identifier  "AMD Graphics"
    Driver      "amdgpu"
    Option      "TearFree" "true"
    Option      "VariableRefresh" "true"
EOF

  if [ "$ACTIVE_MONITORS" -gt 1 ]; then
    echo '    Option      "AsyncFlipSecondaries" "true"' >> "$XORG_FILE"
    echo ">>> AsyncFlipSecondaries aktiviert wegen Mehrschirmbetrieb."
  fi

  echo "EndSection" >> "$XORG_FILE"
}

### === MAIN FUNCTIONS ===

if [ "$EUID" -ne 0 ]; then
  echo "Please execute as root (sudo $0)"
  exit 1
fi

parse_args "$@"

echo "=== Linux Mint Gaming Setup (Mesa: $MESA_SOURCE) ==="

install_mesa

if is_x11_active; then
  echo ">>> X-Server / X11 recognized – AMDGPU X11-Configuration is applied."
  configure_amdgpu_x11
else
  echo ">>> Wayland recognized or no active X-Server – AMDGPU-Konfiguration will be skipped."
fi

echo "=== Setup done! Please reboot to apply changes. ==="
