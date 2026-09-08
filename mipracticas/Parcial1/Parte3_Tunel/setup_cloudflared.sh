#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  setup_cloudflared.sh — Instalación de cloudflared
#  Parcial 1 · Servicios Telemáticos 2026-02
#  Ejecutado por Vagrant durante el provisioning de parcial_master
# ══════════════════════════════════════════════════════════════════════════
set -euo pipefail

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 3] CLOUDFLARED — Instalación"
echo "════════════════════════════════════════════"

# ── Detectar arquitectura ─────────────────────────────────────────────────
ARCH=$(dpkg --print-architecture)
echo "[1/3] Arquitectura detectada: ${ARCH}"

# ── Descargar cloudflared ─────────────────────────────────────────────────
echo "[2/3] Descargando cloudflared (última versión)..."
DOWNLOAD_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb"

wget -q --show-progress -O /tmp/cloudflared.deb "${DOWNLOAD_URL}" || {
    echo "ERROR: No se pudo descargar cloudflared desde GitHub."
    echo "Asegúrese de que la VM tiene acceso a Internet."
    exit 1
}

# ── Instalar cloudflared ──────────────────────────────────────────────────
echo "[3/3] Instalando cloudflared..."
dpkg -i /tmp/cloudflared.deb
rm -f /tmp/cloudflared.deb

echo ""
echo "════════════════════════════════════════════"
echo " cloudflared instalado:"
cloudflared --version
echo ""
echo " Para iniciar el túnel (ejecutar manualmente):"
echo "   vagrant ssh parcial_master"
echo "   bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh"
echo ""
echo " El túnel es temporal (trycloudflare.com)"
echo " No requiere cuenta de Cloudflare"
echo "════════════════════════════════════════════"
echo ""
