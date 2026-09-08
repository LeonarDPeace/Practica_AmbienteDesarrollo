#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  setup_dns_slave.sh — Provisioning DNS Esclavo BIND9
#  Parcial 1 · Servicios Telemáticos 2026-02
#  VM: parcial_slave  IP: 192.168.50.11
# ══════════════════════════════════════════════════════════════════════════
# IMPORTANTE: El maestro debe haberse provisionado PRIMERO para que
#             /vagrant/Parte1_DNS/provision/tsig.key exista.
#             Usar: vagrant up parcial_master && vagrant up parcial_slave
# ══════════════════════════════════════════════════════════════════════════
set -euo pipefail

PROVISION_DIR="/vagrant/Parte1_DNS/provision"
TSIG_KEY="${PROVISION_DIR}/tsig.key"

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 1] DNS ESCLAVO — Inicio"
echo "════════════════════════════════════════════"

# ── 1. Instalar BIND9 ────────────────────────────────────────────────────
echo "[1/8] Instalando BIND9..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y bind9 bind9utils bind9-doc dnsutils

# ── 2. Crear directorios necesarios ─────────────────────────────────────
echo "[2/8] Creando directorios..."
mkdir -p /var/log/named
mkdir -p /etc/bind/zones
chown -R bind:bind /var/log/named
chmod 755 /var/log/named

# ── 3. Instalar clave TSIG (generada por el maestro) ────────────────────
echo "[3/8] Copiando clave TSIG desde el maestro..."
if [ ! -f "${TSIG_KEY}" ]; then
    echo "ERROR: ${TSIG_KEY} no encontrado."
    echo "Asegúrese de haber provisionado parcial_master ANTES de parcial_slave."
    echo "Comando: vagrant provision parcial_master"
    exit 1
fi
cp "${TSIG_KEY}" /etc/bind/tsig.key
chown root:bind /etc/bind/tsig.key
chmod 640 /etc/bind/tsig.key
echo "    >> Clave TSIG instalada correctamente."

# ── 4. Copiar configuración de opciones ─────────────────────────────────
echo "[4/8] Aplicando named.conf.options (recursion no, RRL)..."
cp "${PROVISION_DIR}/slave_named.conf.options" /etc/bind/named.conf.options

# ── 5. Copiar named.conf.local ───────────────────────────────────────────
echo "[5/8] Aplicando named.conf.local (slave de empresa.local)..."
cp "${PROVISION_DIR}/slave_named.conf.local" /etc/bind/named.conf.local

# ── 6. Copiar configuración de logging ──────────────────────────────────
echo "[6/8] Copiando named_logging.conf..."
cp "${PROVISION_DIR}/named_logging.conf" /etc/bind/named_logging.conf
chown root:bind /etc/bind/named_logging.conf
chmod 640 /etc/bind/named_logging.conf

# ── 7. Validar configuración ─────────────────────────────────────────────
echo "[7/8] Validando configuración BIND9..."
named-checkconf

# ── 8. Habilitar e iniciar BIND9 ─────────────────────────────────────────
echo "[8/8] Iniciando bind9..."
systemctl enable bind9
systemctl restart bind9
sleep 2
systemctl status bind9 --no-pager

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 1] DNS ESCLAVO — Completado"
echo " IP: 192.168.50.11"
echo " Zona: empresa.local (slave — esperando AXFR del maestro)"
echo " Verificar transferencia:"
echo "   dig @192.168.50.11 empresa.local SOA"
echo "════════════════════════════════════════════"
echo ""
