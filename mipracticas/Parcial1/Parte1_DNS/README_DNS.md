# Parte 1 — DNS BIND9 Maestro/Esclavo con TSIG

## Topología

```
192.168.50.10  parcial_master  →  DNS Maestro + Apache2 + cloudflared
192.168.50.11  parcial_slave   →  DNS Esclavo
```

## Zona DNS

| Registro | Tipo | Valor |
|---|---|---|
| empresa.local | SOA | ns1.empresa.local. (serial 2026090801) |
| empresa.local | NS | ns1.empresa.local. |
| empresa.local | NS | ns2.empresa.local. |
| ns1.empresa.local | A | 192.168.50.10 |
| ns2.empresa.local | A | 192.168.50.11 |
| parcial.empresa.local | A | 192.168.50.10 |
| www.empresa.local | A / AAAA | 192.168.50.10 / 2001:db8:50::80 |
| ftp.empresa.local | CNAME | www.empresa.local |
| empresa.local | MX | 10 mail.empresa.local |
| mail.empresa.local | AAAA | 2001:db8:50::25 |
| ns1.empresa.local | AAAA | 2001:db8:50::10 |
| ns2.empresa.local | AAAA | 2001:db8:50::11 |
| 10.50.168.192.in-addr.arpa | PTR | ns1.empresa.local |
| 11.50.168.192.in-addr.arpa | PTR | ns2.empresa.local |

## Hardening aplicado

- `recursion no;` — servidor autoritativo puro (no es resolver)
- `allow-transfer { none; };` — transferencias bloqueadas globalmente
- `allow-transfer { key transfer-key; };` — solo con TSIG por zona
- RRL: 10 resp/s, ventana 5 s, slip 2 (TCP fallback)

## Verificación

```bash
# Desde la VM parcial_master (o desde el host si está enrutado):

# 1. Comprobar SOA del maestro
dig @192.168.50.10 empresa.local SOA +short

# 2. Comprobar SOA del esclavo (sincronizado vía AXFR)
dig @192.168.50.11 empresa.local SOA +short

# 3. Resolución directa (A y CNAME)
dig @192.168.50.10 parcial.empresa.local A +short
dig @192.168.50.10 www.empresa.local CNAME +short
dig @192.168.50.10 www.empresa.local AAAA +short
dig @192.168.50.10 mail.empresa.local AAAA +short
dig @192.168.50.10 ns1.empresa.local AAAA +short
dig @192.168.50.10 ns2.empresa.local AAAA +short

# 4. Resolución inversa (PTR)
dig @192.168.50.10 -x 192.168.50.10 +short

# 5. Demostración de seguridad TSIG:
# 5a. Transferencia SIN clave TSIG (debe ser RECHAZADA - Transfer failed):
dig @192.168.50.10 empresa.local AXFR

# 5b. Transferencia CON clave TSIG (exitosa - NOERROR, usar sudo para leer tsig.key):
sudo dig @192.168.50.10 empresa.local AXFR -k /etc/bind/tsig.key

# 6. Ver logs de auditoría dedicados:
sudo tail -n 20 /var/log/named/transfers.log
sudo tail -n 20 /var/log/named/security.log
sudo tail -n 20 /var/log/named/queries.log

# 7. Secuencia automatizada de validacion (incluye AXFR y recursion):
sudo bash /vagrant/Parte1_DNS/provision/verificar_dns_parcial.sh
```

## Archivos creados

| Archivo | Descripción |
|---|---|
| `provision/master_named.conf.options` | Opciones BIND9 maestro |
| `provision/master_named.conf.local` | Zonas y TSIG maestro |
| `provision/slave_named.conf.options` | Opciones BIND9 esclavo |
| `provision/slave_named.conf.local` | Zonas slave y TSIG esclavo |
| `provision/empresa.local.zone` | Zona directa |
| `provision/50.168.192.zone` | Zona inversa |
| `provision/named_logging.conf` | Logging queries/transfers/security |
| `provision/setup_dns_master.sh` | Script provisioning maestro |
| `provision/setup_dns_slave.sh` | Script provisioning esclavo |
| `provision/tsig.key` | Clave TSIG generada (auto, no editar) |
