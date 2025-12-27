#!/bin/bash
# Script para entender cómo VSCode se comunica a través del display

echo "=== Información del Display ==="
echo "DISPLAY: $DISPLAY"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo ""

echo "=== Sockets X11 ==="
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "No hay sockets X11"
echo ""

echo "=== Runtime WSLg ==="
ls -la /mnt/wslg/ 2>/dev/null || echo "No hay runtime WSLg"
echo ""

echo "=== Sockets VSCode en /tmp ==="
ls -la /tmp/vscode-* 2>/dev/null || echo "No hay sockets VSCode en /tmp"
echo ""

echo "=== Runtime dir (si existe) ==="
if [ -n "$XDG_RUNTIME_DIR" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
    echo "Contenido de $XDG_RUNTIME_DIR:"
    ls -la "$XDG_RUNTIME_DIR" | grep -i vscode || echo "No hay archivos VSCode"
fi
echo ""

echo "=== Ventanas X11 activas ==="
if command -v xdotool &> /dev/null; then
    xdotool search --name "Visual Studio Code" 2>/dev/null || echo "No hay ventanas VSCode"
else
    echo "xdotool no disponible"
fi
echo ""

echo "=== Procesos code/electron ==="
ps aux | grep -E "(code|electron)" | grep -v grep || echo "No hay procesos code"
echo ""

echo "=== Variables de entorno VSCode ==="
env | grep -i vscode || echo "No hay variables VSCode"
