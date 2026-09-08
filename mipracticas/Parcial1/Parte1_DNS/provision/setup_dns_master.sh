#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  setup_dns_master.sh — Provisioning DNS Maestro BIND9
#  Parcial 1 · Servicios Telemáticos 2026-02
#  VM: parcial_master  IP: 192.168.50.10
# ══════════════════════════════════════════════════════════════════════════
# Este script es ejecutado por Vagrant durante "vagrant up parcial_master"
# La carpeta /vagrant dentro de la VM apunta a mipracticas/Parcial1/ en el host.
# ══════════════════════════════════════════════════════════════════════════
set -euo pipefail

PROVISION_DIR="/vagrant/Parte1_DNS/provision"

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 1] DNS MAESTRO — Inicio"
echo "════════════════════════════════════════════"

# ── 1. Actualizar repositorios e instalar BIND9 ───────────────────────────
echo "[1/9] Instalando BIND9..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y bind9 bind9utils bind9-doc dnsutils

# ── 2. Crear directorios necesarios ─────────────────────────────────────
echo "[2/9] Creando directorios..."
mkdir -p /var/log/named
mkdir -p /etc/bind/zones
chown -R bind:bind /var/log/named
chmod 755 /var/log/named

# ── 3. Generar clave TSIG hmac-sha256 ───────────────────────────────────
echo "[3/9] Generando clave TSIG hmac-sha256 (transfer-key)..."
# Genera la clave y la escribe en formato BIND9 key{}
tsig-keygen -a hmac-sha256 transfer-key > /etc/bind/tsig.key
chown root:bind /etc/bind/tsig.key
chmod 640 /etc/bind/tsig.key

# Compartir la clave con el esclavo a través de la carpeta compartida
# (el slave leerá /vagrant/Parte1_DNS/provision/tsig.key)
cp /etc/bind/tsig.key "${PROVISION_DIR}/tsig.key"
echo "    >> Clave TSIG generada y copiada a ${PROVISION_DIR}/tsig.key"

# ── 4. Copiar configuración de opciones ─────────────────────────────────
echo "[4/9] Aplicando named.conf.options (recursion no, RRL)..."
cp "${PROVISION_DIR}/master_named.conf.options" /etc/bind/named.conf.options

# ── 5. Copiar named.conf.local (zonas + logging include) ────────────────
echo "[5/9] Aplicando named.conf.local (zonas empresa.local e inversa)..."
cp "${PROVISION_DIR}/master_named.conf.local" /etc/bind/named.conf.local

# ── 6. Copiar configuración de logging ──────────────────────────────────
echo "[6/9] Copiando named_logging.conf..."
cp "${PROVISION_DIR}/named_logging.conf" /etc/bind/named_logging.conf
chown root:bind /etc/bind/named_logging.conf
chmod 640 /etc/bind/named_logging.conf

# ── 7. Copiar archivos de zona ───────────────────────────────────────────
echo "[7/9] Copiando zona directa empresa.local y zona inversa..."
cp "${PROVISION_DIR}/empresa.local.zone" /etc/bind/zones/
cp "${PROVISION_DIR}/50.168.192.zone"    /etc/bind/zones/
chown bind:bind /etc/bind/zones/*.zone
chmod 640 /etc/bind/zones/*.zone

# ── 8. Validar configuración ─────────────────────────────────────────────
echo "[8/9] Validando configuración BIND9..."
named-checkconf
named-checkzone empresa.local /etc/bind/zones/empresa.local.zone
named-checkzone 50.168.192.in-addr.arpa /etc/bind/zones/50.168.192.zone

# ── 9. Habilitar e iniciar BIND9 ─────────────────────────────────────────
echo "[9/9] Iniciando named..."
usermod -aG bind vagrant || true
systemctl daemon-reload
systemctl enable named
systemctl restart named
sleep 2
systemctl status named --no-pager

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 1] DNS MAESTRO — Completado"
echo " IP: 192.168.50.10"
echo " Zona: empresa.local (maestro)"
echo " Logs: /var/log/named/{queries,transfers,security}.log"
echo "════════════════════════════════════════════"
echo ""
