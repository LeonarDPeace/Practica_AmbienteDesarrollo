#!/bin/bash
# Verificaciones reproducibles para la sustentacion de Parte 1.
set -euo pipefail

MASTER="192.168.50.10"
SLAVE="192.168.50.11"
ZONE="empresa.local"
REVERSE_ZONE="50.168.192.in-addr.arpa"
KEY="/etc/bind/tsig.key"

if [ "${EUID}" -ne 0 ]; then
    echo "Ejecute como root: sudo bash verificar_dns_parcial.sh"
    exit 1
fi

named-checkconf
named-checkzone "${ZONE}" /etc/bind/zones/empresa.local.zone
named-checkzone "${REVERSE_ZONE}" /etc/bind/zones/50.168.192.zone

echo "== Resolucion directa e IPv6 en maestro =="
dig @"${MASTER}" www."${ZONE}" A +short
dig @"${MASTER}" www."${ZONE}" AAAA +short
dig @"${MASTER}" mail."${ZONE}" AAAA +short
dig @"${MASTER}" ns1."${ZONE}" AAAA +short
dig @"${MASTER}" ns2."${ZONE}" AAAA +short

echo "== Resolucion inversa en maestro y esclavo =="
dig @"${MASTER}" -x "${MASTER}" +short
dig @"${SLAVE}" -x "${MASTER}" +short

echo "== AXFR sin TSIG: debe fallar =="
if dig @"${MASTER}" "${ZONE}" AXFR +tcp 2>&1 | grep -qE "Transfer failed|REFUSED|NOTAUTH"; then
    echo "OK: AXFR no autenticado rechazado"
else
    echo "ERROR: revisar que AXFR sin TSIG sea rechazado"
    exit 1
fi

echo "== AXFR con TSIG: debe responder =="
dig @"${MASTER}" "${ZONE}" AXFR -k "${KEY}" +tcp >/tmp/axfr-authenticated.out

echo "== Recursion: debe estar deshabilitada =="
if dig @"${MASTER}" google.com A +short | grep -q .; then
    echo "ERROR: el servidor resolvio un dominio externo"
    exit 1
fi
echo "OK: no hubo respuesta recursiva para google.com"

echo "== SOA maestro/esclavo =="
dig @"${MASTER}" "${ZONE}" SOA +short
dig @"${SLAVE}" "${ZONE}" SOA +short

echo "== Logs de auditoria =="
tail -n 10 /var/log/named/queries.log
tail -n 10 /var/log/named/transfers.log
tail -n 10 /var/log/named/security.log

echo "Prueba de continuidad: detenga named en el maestro y repita las consultas contra ${SLAVE}."
