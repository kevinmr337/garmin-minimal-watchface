#!/usr/bin/env bash
set -euo pipefail

# === RUTAS (ajustadas a tu SDK) ===
SDK_BIN="/Users/kevinmendez/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.3.0-2025-09-22-5813687a0/bin"
DEVICES_DIR="$HOME/Library/Application Support/Garmin/ConnectIQ/Devices"
SIM="$DEVICES_DIR/venu3.sim"

# === ARCHIVOS DEL PROYECTO ===
JUNGLE="monkey.jungle"
KEY="/Users/kevinmendez/Documents/Keys/garmin/developer_key"
OUT_DIR="build"
OUT_PRG="$OUT_DIR/face.prg"

# === PREV ===
mkdir -p "$OUT_DIR"

if [ ! -f "$KEY" ]; then
  echo "❌ No se encontró $KEY. Genera tu llave de desarrollador (ver instrucciones abajo)."
  exit 1
fi

if [ ! -f "$JUNGLE" ]; then
  echo "❌ No se encontró $JUNGLE en el directorio actual."
  exit 1
fi

if [ ! -f "$SIM" ]; then
  echo "⚠️  No se encontró $SIM. Intentaré lanzar por alias 'venu3'."
  USE_ALIAS=1
else
  USE_ALIAS=0
fi

# === COMPILAR ===
"$SDK_BIN/monkeyc" \
  -o "$OUT_PRG" \
  -f "$JUNGLE" \
  -y "$KEY"

echo "✅ Compilado en $OUT_PRG"

# === ABRIR SIMULADOR (si no está abierto) ===
if ! pgrep -f "$SDK_BIN/connectiq" >/dev/null; then
  open -a "$SDK_BIN/ConnectIQ.app" || "$SDK_BIN/connectiq" || true
  sleep 1
fi

# === EJECUTAR EN EMULADOR ===
if [ "$USE_ALIAS" -eq 1 ]; then
  echo "➡️  Lanzando en emulador con alias: venu3"
  "$SDK_BIN/monkeydo" "$OUT_PRG" venu3
else
  echo "➡️  Lanzando en emulador con perfil: $SIM"
  "$SDK_BIN/monkeydo" "$OUT_PRG" "$SIM"
fi