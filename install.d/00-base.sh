#!/bin/bash
set -e

echo "[*] Installing base dependencies..."

PACKAGES=(

)

sudo pacman -S --noconfirm --needed "${PACKAGES[@]}"