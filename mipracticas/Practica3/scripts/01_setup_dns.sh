#!/bin/bash
# ==============================================================================
# Script 01: Configuración de Servidor DNS BIND9 para Práctica 3 (HTTP y Apache)
# ==============================================================================
set -e

echo "=== [1/4] Configurando Zona servicios.com ==="
cat << 'EOF' > /etc/bind/db.servicios.com
$TTL    604800
@       IN      SOA     ns1.servicios.com. admin.servicios.com. (
                              4         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.servicios.com.
ns1     IN      A       192.168.50.3
@       IN      A       192.168.50.3
servidor IN     A       192.168.50.3
www      IN     A       192.168.50.3
ftp      IN     A       192.168.50.3
cliente  IN     A       192.168.50.2
EOF

echo "=== [2/4] Configurando Zona miotrositio.com ==="
cat << 'EOF' > /etc/bind/db.miotrositio.com
$TTL    604800
@       IN      SOA     ns1.miotrositio.com. admin.miotrositio.com. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.miotrositio.com.
ns1     IN      A       192.168.50.3
@       IN      A       192.168.50.3
servidor IN     A       192.168.50.3
www      IN     A       192.168.50.3
EOF

echo "=== [3/4] Actualizando /etc/bind/named.conf.local ==="
cat << 'EOF' > /etc/bind/named.conf.local
// Zona 1: servicios.com
zone "servicios.com" {
    type master;
    file "/etc/bind/db.servicios.com";
};

// Zona 2: criollo.com
zone "criollo.com" {
    type master;
    file "/etc/bind/db.criollo.com";
};

// Zona 3: miotrositio.com
zone "miotrositio.com" {
    type master;
    file "/etc/bind/db.miotrositio.com";
};
EOF

echo "=== [4/4] Verificando Sintaxis y Reiniciando BIND9 ==="
named-checkconf
named-checkzone servicios.com /etc/bind/db.servicios.com
named-checkzone miotrositio.com /etc/bind/db.miotrositio.com
systemctl restart named

echo "=== DNS Configurado y Reiniciado Exitosamente ==="
named-checkzone servicios.com /etc/bind/db.servicios.com
named-checkzone miotrositio.com /etc/bind/db.miotrositio.com
