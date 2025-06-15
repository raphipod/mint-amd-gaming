#!/bin/bash
set -e

### === CONFIGURATION ===
MESA_SOURCE="kisak"  # Default: kisak

### === FUNCTIONS ===

check_xanmod() {
  uname -r | grep -qi xanmod
}

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
          echo "Not a valid Mesa-Source: $1"
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

install_xanmod() {
  echo ">>> Installing XanMod-Kernel (stable/main)..."
  apt install -y gnupg ca-certificates
  wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -vo /etc/apt/keyrings/xanmod-archive-keyring.gpg
  echo 'deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
  apt update
  apt install -y linux-xanmod-x64v3
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
    echo ">>> AsyncFlipSecondaries active because of multiple monitors."
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

install_xanmod

if ! check_xanmod_active; then
  echo ">>> XanMod-Kernel is not active. Installing..."
  install_xanmod_kernel
  echo ">>> XanMod-Kernel is installed. Please reboot and then restart this script."
  exit 0
else
  echo ">>> XanMod-Kernel is active – continuing with config."
fi

install_mesa

if is_x11_active; then
  echo ">>> X-Server / X11 recognized – AMDGPU X11-Configuration is applied."
  configure_amdgpu_x11
else
  echo ">>> Wayland recognized or no active X-Server – AMDGPU X11-Configuration will be skipped."
fi

echo "=== Setup done! Please reboot again to apply changes. ==="
