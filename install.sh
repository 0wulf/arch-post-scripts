#!/bin/bash
set -e

# Load environment variables
source ./env.sh

INSTALL_DIR="./install.d"

if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: $INSTALL_DIR does not exist"
    exit 1
fi

echo "[*] Updating the system..."
sudo pacman -Syu --noconfirm

if [ "$#" -eq 0 ]; then
    echo "[*] Running all modules..."
    for script in "$INSTALL_DIR"/*.sh; do
        echo "[+] Running: $(basename "$script")"
        bash "$script"
    done
else
    echo "[*] Running selected modules: $*"
    for arg in "$@"; do
        for script in "$INSTALL_DIR"/*"$arg"*.sh; do
            echo "[+] Running: $(basename "$script")"
            bash "$script"
        done
    done
fi
