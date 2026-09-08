#!/bin/bash
# ==============================================================================
# Script 03: Configuración de Cliente DNS en la VM cliente (192.168.50.2)
# ==============================================================================
set -e

echo "=== Configurando DNS en el Cliente ==="
# Configurar DNS de resolución
sudo bash -c 'echo "nameserver 192.168.50.3" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'

echo "=== Verificando Resolución DNS desde el Cliente ==="
dig @192.168.50.3 www.servicios.com +short
dig @192.168.50.3 servicios.com +short
dig @192.168.50.3 www.miotrositio.com +short

echo "=== DNS en Cliente OK ==="
