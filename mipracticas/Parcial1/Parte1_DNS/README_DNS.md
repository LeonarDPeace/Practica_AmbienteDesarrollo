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
| www.empresa.local | CNAME | parcial.empresa.local |
| empresa.local | MX | 10 mail.empresa.local |
| ns1.empresa.local | AAAA | ::1 |
| 10.50.168.192.in-addr.arpa | PTR | ns1.empresa.local |
| 11.50.168.192.in-addr.arpa | PTR | ns2.empresa.local |

## Hardening aplicado

- `recursion no;` — servidor autoritativo puro (no es resolver)
- `allow-transfer { none; };` — transferencias bloqueadas globalmente
- `allow-transfer { key transfer-key; };` — solo con TSIG por zona
- RRL: 10 resp/s, ventana 5 s, slip 2 (TCP fallback)

## Verificación

```bash
# Desde el host (ajustar según tu red) o desde la VM maestro:

# 1. Comprobar SOA del maestro
dig @192.168.50.10 empresa.local SOA

# 2. Comprobar SOA del esclavo (debe coincidir con maestro)
dig @192.168.50.11 empresa.local SOA

# 3. Resolución directa
dig @192.168.50.10 parcial.empresa.local A
dig @192.168.50.10 www.empresa.local CNAME

# 4. Resolución inversa
dig @192.168.50.10 -x 192.168.50.10

# 5. Verificar transferencia de zona con TSIG
#    (ejecutar dentro de parcial_master como root)
dig @192.168.50.10 empresa.local AXFR -k /etc/bind/tsig.key

# 6. Ver logs de transferencia
tail -f /var/log/named/transfers.log

# 7. Ver logs de seguridad (RRL, TSIG)
tail -f /var/log/named/security.log
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
