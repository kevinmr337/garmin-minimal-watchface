#!/usr/bin/env bash
set -euo pipefail

# === RUTAS (configurables vía variables de entorno) ===
# CIQ_SDK_BIN: carpeta 'bin' del Connect IQ SDK (contiene monkeyc/monkeydo/connectiq)
# CIQ_DEV_KEY: ruta a tu developer_key
# CIQ_DEVICE:  id de dispositivo o alias del simulador (por defecto: venu3)
UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
if [ "$UNAME_S" = "Darwin" ]; then
  DEFAULT_SDK_BIN="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/current/bin"
  DEFAULT_DEVICES_DIR="$HOME/Library/Application Support/Garmin/ConnectIQ/Devices"
else
  DEFAULT_SDK_BIN="$HOME/connectiq-sdk/bin"
  DEFAULT_DEVICES_DIR="$HOME/.Garmin/ConnectIQ/Devices"
fi

SDK_BIN="${CIQ_SDK_BIN:-$DEFAULT_SDK_BIN}"
DEVICES_DIR="${CIQ_DEVICES_DIR:-$DEFAULT_DEVICES_DIR}"
DEVICE="${CIQ_DEVICE:-venu3}"
SIM="$DEVICES_DIR/$DEVICE.sim"

# === ARCHIVOS DEL PROYECTO ===
JUNGLE="monkey.jungle"
KEY="${CIQ_DEV_KEY:-}"
OUT_DIR="build"
OUT_PRG="$OUT_DIR/face.prg"

# === PREV ===
mkdir -p "$OUT_DIR"

if [ -z "$KEY" ] || [ ! -f "$KEY" ]; then
  echo "❌ No se encontró la developer key. Define CIQ_DEV_KEY apuntando a tu developer_key."
  echo "   Genera una con: \"$SDK_BIN/monkeyc\" --generate-key <ruta-clave>"
  exit 1
fi

if [ ! -f "$JUNGLE" ]; then
  echo "❌ No se encontró $JUNGLE en el directorio actual."
  exit 1
fi

if [ ! -x "$SDK_BIN/monkeyc" ]; then
  echo "❌ No se encontró monkeyc en $SDK_BIN. Define CIQ_SDK_BIN apuntando al 'bin' de tu Connect IQ SDK."
  exit 1
fi

if [ ! -f "$SIM" ]; then
  echo "⚠️  No se encontró $SIM. Intentaré lanzar por alias '$DEVICE'."
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
if ! pgrep -f "connectiq" >/dev/null 2>&1; then
  if [ "$UNAME_S" = "Darwin" ] && [ -d "$SDK_BIN/ConnectIQ.app" ]; then
    open -a "$SDK_BIN/ConnectIQ.app" || "$SDK_BIN/connectiq" &
  else
    "$SDK_BIN/connectiq" >/dev/null 2>&1 &
  fi
  sleep 1
fi

# === EJECUTAR EN EMULADOR ===
if [ "$USE_ALIAS" -eq 1 ]; then
  echo "➡️  Lanzando en emulador con alias: $DEVICE"
  "$SDK_BIN/monkeydo" "$OUT_PRG" "$DEVICE"
else
  echo "➡️  Lanzando en emulador con perfil: $SIM"
  "$SDK_BIN/monkeydo" "$OUT_PRG" "$SIM"
fi