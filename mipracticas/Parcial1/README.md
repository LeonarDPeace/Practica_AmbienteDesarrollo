# Parcial 1 — Servicios Telemáticos 2026-02

> **Ejecutar todas las VMs desde este directorio:**
>
> ```powershell
> cd mipracticas/Parcial1
> vagrant up parcial_master
> vagrant up parcial_slave
> ```
>
> Para las prácticas anteriores usar el `Vagrantfile` en la **raíz** del repositorio.

---

## Topología de red

```
  Host (Windows — VirtualBox)
  ┌──────────────────────────────────────────────────────┐
  │  Red privada Host-Only: 192.168.50.0/24              │
  │                                                      │
  │  ┌─────────────────────────┐  ┌──────────────────┐  │
  │  │     parcial_master      │  │  parcial_slave   │  │
  │  │     192.168.50.10       │  │  192.168.50.11   │  │
  │  │  ─────────────────────  │  │  ─────────────── │  │
  │  │  ✦ BIND9 DNS Maestro    │  │  ✦ BIND9 Esclavo │  │
  │  │  ✦ Apache2 :80          │  │                  │  │
  │  │  ✦ cloudflared → :80    │  │                  │  │
  │  └──────────┬──────────────┘  └─────────┬────────┘  │
  │             │  AXFR/IXFR + TSIG         │           │
  │             └───────────────────────────┘           │
  └──────────────────────────────────────────────────────┘
                │ Túnel cloudflared
          ┌─────▼──────────────┐
          │  trycloudflare.com │  (URL pública temporal)
          └────────────────────┘
```

---

## Prerrequisitos

| Herramienta | Versión mínima | Instalación                                |
| ----------- | ---------------- | ------------------------------------------- |
| VirtualBox  | 6.1+             | [virtualbox.org](https://www.virtualbox.org) |
| Vagrant     | 2.3+             | [vagrantup.com](https://www.vagrantup.com)   |
| Git         | 2.x              | incluido                                    |
| curl        | cualquiera       | para`verificar_encoding.sh` desde el host |

---

## Instrucciones de reproducción

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/CriolloYule/Practica_AmbienteDesarrollo.git
cd Practica_AmbienteDesarrollo/mipracticas/Parcial1
```

### Paso 2 — Levantar VM Maestro (DNS + Apache + cloudflared)

```bash
# Desde mipracticas/Parcial1/
vagrant up parcial_master
```

Este paso ejecuta en orden:

1. `Parte1_DNS/provision/setup_dns_master.sh` → BIND9 Maestro
2. `Parte2_Apache/provision/setup_apache.sh` → Apache2 + compresión
3. `Parte3_Tunel/setup_cloudflared.sh` → Instalación cloudflared

> ⏱️ Tiempo estimado: 5–10 minutos (incluye descarga de paquetes).

### Paso 3 — Levantar VM Esclavo (DNS Slave)

```bash
# DESPUÉS de que parcial_master esté completamente provisionado
vagrant up parcial_slave
```

> **¡Importante!** El esclavo lee la clave TSIG generada por el maestro
> desde la carpeta compartida. Debe levantarse después del maestro.

### Paso 4 — Verificar DNS

```bash
# SSH al maestro
vagrant ssh parcial_master

# 1. Verificar zona directa (maestro)
dig @192.168.50.10 empresa.local SOA +short
dig @192.168.50.10 parcial.empresa.local A +short
dig @192.168.50.10 ftp.empresa.local CNAME +short

# 2. Verificar resolución inversa (PTR)
dig @192.168.50.10 -x 192.168.50.10 +short

# 3. Verificar esclavo (sincronizado vía AXFR)
dig @192.168.50.11 empresa.local SOA +short

# 4. Demostración de seguridad TSIG:
# 4a. Transferencia SIN clave TSIG (debe ser RECHAZADA - Transfer failed):
dig @192.168.50.10 empresa.local AXFR

# 4b. Transferencia CON clave TSIG (exitosa - NOERROR):
sudo dig @192.168.50.10 empresa.local AXFR -k /etc/bind/tsig.key

# 5. Ver logs de auditoría dedicados:
sudo tail -n 20 /var/log/named/transfers.log
sudo tail -n 20 /var/log/named/queries.log
```

### Paso 5 — Verificar Apache y compresión

```bash
# Dentro de parcial_master:
# Acceso al VirtualHost
curl -H "Host: parcial.empresa.local" http://192.168.50.10/

# Verificar gzip
curl -sI -H "Accept-Encoding: gzip" http://192.168.50.10/data.json | grep -i content-encoding

# Verificar brotli
curl -sI -H "Accept-Encoding: br" http://192.168.50.10/data.json | grep -i content-encoding

# Ejecutar medición completa (genera tabla_comparativa.md)
sudo bash /vagrant/Parte2_Apache/medir_compresion.sh
```

### Paso 6 — Túnel cloudflared

```bash
# Verifique primero que Apache escucha en :80 (dentro de la VM):
sudo ss -ltnp | grep :80 || sudo apache2ctl -S

# Si cloudflared no fue instalado por el provisioning:
sudo bash /vagrant/Parte3_Tunel/setup_cloudflared.sh

# Dentro de parcial_master (terminal 1):
# Inicia el túnel y muestra la URL pública (bloquea la terminal — Ctrl+C para detener)

bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh

# Alternativa: ejecución en background (la URL se guarda en /tmp/cloudflared.out):
nohup bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh > /tmp/cloudflared.out 2>&1 &

# Esperar la URL real generada por Cloudflare (no usar XXXX como URL):
sleep 5
grep -oE 'https://[^ ]+trycloudflare.com' /tmp/cloudflared.out | tail -1

# Para detener el túnel en background:
# sudo pkill -f cloudflared

# Terminal 2 (o desde el host), sustituyendo URL_REAL por la URL mostrada:
bash /vagrant/Parte3_Tunel/verificar_encoding.sh URL_REAL
```

---

## Estructura de archivos

```
mipracticas/Parcial1/
├── Vagrantfile                      ← Entorno exclusivo del parcial
├── README.md                        ← Este archivo
├── ANALISIS_CRITICO.md              ← Respuestas a los 5 puntos teóricos
├── 2026-02_Primer_Parcial_ServiciosTelematicos.pdf
│
├── Parte1_DNS/
│   ├── provision/
│   │   ├── master_named.conf.options
│   │   ├── master_named.conf.local
│   │   ├── slave_named.conf.options
│   │   ├── slave_named.conf.local
│   │   ├── empresa.local.zone
│   │   ├── 50.168.192.zone
│   │   ├── named_logging.conf
│   │   ├── verificar_dns_parcial.sh
│   │   ├── setup_dns_master.sh
│   │   ├── setup_dns_slave.sh
│   │   └── tsig.key                 ← Auto-generado, NO editar
│   └── README_DNS.md
│
├── Parte2_Apache/
│   ├── provision/
│   │   ├── parcial.empresa.local.conf
│   │   ├── compression.conf
│   │   └── setup_apache.sh
│   ├── recursos/
│   │   ├── index.html
│   │   ├── index_grande.html       ← Generado en la VM (100-500 KB)
│   │   ├── styles.css
│   │   ├── styles.min.css
│   │   ├── app.js
│   │   ├── app.min.js
│   │   ├── feed.xml
│   │   └── image.svg
│   ├── medir_compresion.sh          ← Ejecutar como root en parcial_master
│   ├── README_APACHE.md              ← Guia tecnica y checklist de Parte 2
│   └── tabla_comparativa.md         ← Generada por medir_compresion.sh
│
└── Parte3_Tunel/
    ├── pagina_personalizada.html    ← Identidad e identificador del grupo
    ├── setup_cloudflared.sh         ← Llamado por Vagrant
    ├── iniciar_tunel_cloudflared.sh ← Ejecutar manualmente
    ├── verificar_encoding.sh        ← Verificar preservación de cabeceras
    └── README_Tunel.md
```

## Sustentación y entregables

La guía completa de demostración, la matriz de cumplimiento y el checklist
están integrados en este README. Un archivo de configuración o un script
demuestra reproducibilidad, pero la rúbrica también exige ejecutar y mostrar
las pruebas en vivo.

---

## Comandos rápidos de referencia

```bash
# ── Ciclo de vida Vagrant ─────────────────────────────────────────
vagrant up parcial_master          # Levantar maestro
vagrant up parcial_slave           # Levantar esclavo
vagrant ssh parcial_master         # SSH al maestro
vagrant ssh parcial_slave          # SSH al esclavo
vagrant halt                       # Apagar todas las VMs del parcial
vagrant destroy                    # Eliminar VMs (mantiene archivos)
vagrant provision parcial_master   # Re-ejecutar provisioning maestro

# ── DNS ───────────────────────────────────────────────────────────
named-checkconf                    # Validar config BIND9
named-checkzone empresa.local /etc/bind/zones/empresa.local.zone
systemctl restart bind9            # Reiniciar BIND9
rndc reload                        # Recargar zonas sin reiniciar

# ── Apache ────────────────────────────────────────────────────────
apache2ctl configtest              # Validar config Apache
systemctl reload apache2           # Recargar config sin bajar servicio
a2enmod brotli                     # Habilitar mod_brotli si falta

# ── cloudflared ───────────────────────────────────────────────────
cloudflared --version              # Verificar instalación
cloudflared tunnel --url http://localhost:80  # Inicio rápido manual
# Verificar compresión contra URL pública (ejemplo)
# bash /vagrant/Parte3_Tunel/verificar_encoding.sh https://TU-URL.trycloudflare.com
```

---

## Solución de problemas frecuentes

| Síntoma | Causa probable | Solución / comandos |
| --- | --- | --- |
| `setup_dns_slave.sh` falla con "tsig.key no encontrado" | Maestro no provisionado | `vagrant provision parcial_master` |
| Apache responde sin `Content-Encoding` | Módulo no habilitado | `sudo a2enmod deflate brotli && sudo systemctl reload apache2` |
| Brotli no funciona | `libapache2-mod-brotli` no instalado | `sudo apt install -y libapache2-mod-brotli && sudo a2enmod brotli` |
| `curl: (7) Failed to connect ... port 80` | Apache no iniciado o no escucha en :80 | `sudo systemctl status apache2` y `sudo ss -ltnp \| grep :80` |
| Apache falló durante el provisioning | Error de configuración o instalación | `sudo journalctl -u apache2 -n 50` y `vagrant provision parcial_master` |
| cloudflared no descarga / binario no encontrado | Sin Internet o provisioning incompleto | `sudo bash /vagrant/Parte3_Tunel/setup_cloudflared.sh` |
| Verificación del túnel falla | URL de ejemplo o túnel terminado | `cat /tmp/cloudflared.out`; usar URL real y `pgrep -af cloudflared` |
| Se iniciaron varios túneles | Se ejecutó `nohup` más de una vez | `sudo pkill -f cloudflared` y arrancar uno solo |
| `medir_compresion.sh` falla | No se ejecuta como root | `sudo bash /vagrant/Parte2_Apache/medir_compresion.sh` |
| Transferencia AXFR falla | `tsig.key` no coincide o permisos | Revisar `/etc/bind` y logs; reprovisionar maestro y luego esclavo |

---

## Integridad academica

Para la elaboracion del proyecto se utilizaron Gemini y Claude como asistencia
para revisar documentacion, proponer comandos, organizar explicaciones y
detectar inconsistencias. El grupo reviso el resultado y mantiene la
responsabilidad de comprender, verificar y sustentar cada linea de los archivos
entregados. La declaracion ampliada se encuentra en `ANALISIS_CRITICO.md`.

## Commits del parcial

| Commit   | Tipo               | Descripción                                                |
| -------- | ------------------ | ----------------------------------------------------------- |
| Commit 0 | `chore(repo)`    | Limpieza inicial — .gitignore + archivos pendientes        |
| Commit 1 | `feat(dns)`      | BIND9 maestro/esclavo, TSIG, zonas, hardening, logging      |
| Commit 2 | `feat(apache)`   | VirtualHost, mod_deflate, mod_brotli, medir_compresion.sh   |
| Commit 3 | `feat(tunel)`    | cloudflared, página identificación, verificar_encoding.sh |
| Commit 4 | `docs(parcial1)` | ANALISIS_CRITICO.md + README.md                             |

---

## Guía completa de sustentación en vivo

La sustentación es presencial y en vivo. Los archivos Markdown sirven como apoyo,
pero no reemplazan ejecutar los comandos ni mostrar los resultados.

### Preparación

Desde PowerShell, ubicado en `mipracticas/Parcial1`:

```powershell
vagrant validate
vagrant up parcial_master
vagrant up parcial_slave
vagrant status
```

Abrir tres terminales: maestro para DNS/Apache/cloudflared, esclavo para DNS y
continuidad, y host para navegador, curl y Wireshark. Antes de sustentar,
generar `Parte2_Apache/tabla_comparativa.md` con datos reales.

### Parte 1: DNS

#### Sintaxis y registros

```bash
sudo named-checkconf
sudo named-checkzone empresa.local /etc/bind/zones/empresa.local.zone
sudo named-checkzone 50.168.192.in-addr.arpa /etc/bind/zones/50.168.192.zone
sudo systemctl is-active named
dig @192.168.50.10 empresa.local SOA +short
dig @192.168.50.10 empresa.local NS +short
dig @192.168.50.10 www.empresa.local A +short
dig @192.168.50.10 www.empresa.local AAAA +short
dig @192.168.50.10 mail.empresa.local A +short
dig @192.168.50.10 mail.empresa.local AAAA +short
dig @192.168.50.10 ns1.empresa.local AAAA +short
dig @192.168.50.10 ns2.empresa.local AAAA +short
dig @192.168.50.10 ftp.empresa.local CNAME +short
dig @192.168.50.10 empresa.local MX +short
dig @192.168.50.10 -x 192.168.50.10 +short
dig @192.168.50.10 -x 192.168.50.11 +short
```

Resultado esperado: `OK`, servicio `active`, SOA, NS, A/AAAA, CNAME, MX y PTR.

#### AXFR, TSIG, NOTIFY e IXFR

```bash
# Sin clave: debe mostrar Transfer failed, REFUSED o NOTAUTH
dig @192.168.50.10 empresa.local AXFR +tcp

# Con clave: debe responder NOERROR y mostrar la zona
sudo dig @192.168.50.10 empresa.local AXFR -k /etc/bind/tsig.key +tcp
sudo dig @192.168.50.10 50.168.192.in-addr.arpa AXFR -k /etc/bind/tsig.key +tcp

# Serial y logs
dig @192.168.50.10 empresa.local SOA +short
dig @192.168.50.11 empresa.local SOA +short
sudo tail -n 30 /var/log/named/transfers.log
```

Editar temporalmente la zona en el maestro, agregar un registro de prueba,
incrementar el serial `AAAAMMDDNN`, validar y recargar:

```bash
sudo named-checkzone empresa.local /etc/bind/zones/empresa.local.zone
sudo rndc reload empresa.local
dig @192.168.50.11 empresa.local SOA +short
sudo tail -n 30 /var/log/named/transfers.log
```

Explicar que la primera sincronización normalmente usa AXFR y los cambios
posteriores pueden usar IXFR gracias a `ixfr-from-differences yes`.

#### Hardening, auditoría y continuidad

```bash
dig @192.168.50.10 google.com A +short
sudo grep -E 'recursion|allow-query|rate-limit' /etc/bind/named.conf.options
sudo tail -n 20 /var/log/named/queries.log
sudo tail -n 20 /var/log/named/transfers.log
sudo tail -n 20 /var/log/named/security.log

# Antes de detener el maestro
dig @192.168.50.11 www.empresa.local A +short
dig @192.168.50.11 -x 192.168.50.10 +short

# En parcial_master
sudo systemctl stop named

# En el esclavo: deben seguir respondiendo
dig @192.168.50.11 www.empresa.local A +short
dig @192.168.50.11 -x 192.168.50.10 +short

# Restaurar al finalizar
sudo systemctl start named
```

`google.com` no debe resolverse por recursión. El esclavo debe continuar
respondiendo mientras no expire el `expire` del SOA.

### Parte 2: Apache, navegador y Wireshark

#### Servicio, recursos y medición

```bash
sudo systemctl is-active apache2
sudo apache2ctl configtest
sudo apache2ctl -S
ss -ltnp | grep ':80'
curl -H 'Host: parcial.empresa.local' http://192.168.50.10/

for recurso in index.html index_grande.html styles.css styles.min.css app.js app.min.js data.json image.svg feed.xml texto_grande.txt foto.jpg video_sample.mp4; do
  printf '%-24s ' "$recurso"
  curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' "http://192.168.50.10/$recurso"
done

sudo bash /vagrant/Parte2_Apache/medir_compresion.sh
less /vagrant/Parte2_Apache/tabla_comparativa.md
```

Para comparar identity, gzip y Brotli:

```bash
URL='http://192.168.50.10/data.json'
curl -s -H 'Accept-Encoding: identity' -o /dev/null -w 'identity bytes=%{size_download} time=%{time_total}s\n' "$URL"
curl -s -H 'Accept-Encoding: gzip' -o /dev/null -w 'gzip bytes=%{size_download} time=%{time_total}s\n' "$URL"
curl -s -H 'Accept-Encoding: br' -o /dev/null -w 'brotli bytes=%{size_download} time=%{time_total}s\n' "$URL"
curl -sI -H 'Accept-Encoding: gzip' "$URL" | grep -iE 'HTTP/|content-encoding|vary'
curl -sI -H 'Accept-Encoding: br' "$URL" | grep -iE 'HTTP/|content-encoding|vary'
curl -sI -H 'Accept-Encoding: gzip' http://192.168.50.10/foto.jpg | grep -iE 'HTTP/|content-encoding|vary'
```

La tabla debe contener por recurso identity, gzip 1/6/9, Brotli 5/11, tamaño,
ratio, ahorro, tiempo y CPU. Ratio = comprimido/original; ahorro =
`(1 - ratio) * 100`. La CPU es tiempo local de `curl` medido con `/usr/bin/time`,
no un perfil exclusivo de Apache.

#### Navegador: DevTools Network

1. Abrir `http://192.168.50.10/` en Chrome o Edge.
2. Presionar `F12`, seleccionar **Network**, activar **Disable cache** y recargar.
3. Filtrar `data.json`, `texto_grande.txt` o `index_grande.html`.
4. Abrir la solicitud y mostrar **Headers > Response Headers**.
5. Mostrar `Content-Encoding: br` o `gzip` y `Vary: Accept-Encoding`.
6. Mostrar las columnas **Size** y **Transferred**.
7. Repetir con `foto.jpg` y explicar la exclusión de binarios.

La elección controlada del algoritmo se demuestra con `curl`; el navegador
demuestra las cabeceras y el tamaño transferido en vivo.

#### Wireshark: tráfico HTTP local

No capturar la URL HTTPS de Cloudflare para inspeccionar cabeceras: el tráfico
está cifrado. En Windows:

1. Instalar Wireshark y abrirlo como administrador.
2. Seleccionar **VirtualBox Host-Only Network** (`192.168.50.0/24`).
3. Usar filtro de captura `tcp port 80`.
4. Abrir `http://192.168.50.10/data.json` y recargar sin cache.
5. Usar filtro de visualización `http || tcp.port == 80`.
6. Localizar la conversación con `192.168.50.10:80` y usar **Follow > TCP Stream**.
7. Mostrar `Content-Encoding`, `Vary` y el cuerpo transferido.
8. Repetir con `foto.jpg` y detener la captura. Un `.pcapng` puede conservarse
   fuera del repositorio si contiene datos de prueba.

#### Análisis crítico de Parte 2

Responder usando los valores reales: mejora de Brotli frente a gzip, ganancia al
cambiar niveles, rendimientos decrecientes, comportamiento de JPG/PNG/MP4/ZIP,
balance CPU/ancho de banda con concurrencia y cuándo usar Brotli 11 precomprimido
frente a compresión al vuelo.

### Parte 3: túnel seguro

```bash
sudo ss -ltnp | grep ':80'
nohup bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh > /tmp/cloudflared.out 2>&1 &
sleep 5
grep -oE 'https://[^ ]+trycloudflare.com' /tmp/cloudflared.out | tail -1
```

Copiar la URL real. No usar `XXXX` ni `TU-URL`. Desde un teléfono con datos
móviles abrir `https://URL-REAL.trycloudflare.com/pagina_personalizada.html` y
mostrar nombres, códigos, fecha e identificador. Verificar compresión:

```powershell
curl.exe -sI -H "Accept-Encoding: br" https://URL-REAL.trycloudflare.com/data.json
curl.exe -sI -H "Accept-Encoding: gzip" https://URL-REAL.trycloudflare.com/data.json
```

También puede ejecutarse:

```bash
bash /vagrant/Parte3_Tunel/verificar_encoding.sh https://URL-REAL.trycloudflare.com
sudo pkill -f cloudflared
```

Explicar exposición pública, ausencia de autenticación, URL temporal y límites.
Mitigaciones: apagar el túnel, publicar solo datos de prueba, agregar
autenticación básica y restringir por IP o con otra capa de autenticación.

## Entregables requeridos en GitHub

- General: `Vagrantfile`, este README, comandos y declaración de uso de Gemini
  y Claude.
- Parte 1: configuraciones BIND, zonas directa/inversa, generación de TSIG,
  `allow-transfer`, NOTIFY, IXFR, hardening, RRL, logs y scripts.
- Parte 2: VirtualHost, `mod_deflate`, `mod_brotli`, HTML/CSS/JS/JSON/XML/SVG,
  texto, binarios, script, tabla completa y análisis crítico con datos reales.
- Parte 3: página personalizada, scripts cloudflared, URL pública, prueba desde
  otra red, verificación de compresión y análisis de riesgos/mitigaciones.

## Auditoría frente a la rúbrica

Estados: **Cumple en configuración**, **Parcial** y **Pendiente de evidencia**.
La existencia de un archivo no reemplaza la demostración en vivo.

### Parte 1: DNS — 2.0 puntos

| Puntos | Criterio | Estado |
|---:|---|---|
| 0.4 | Zona directa A/AAAA/CNAME/MX/NS/SOA | Configurada; validar en vivo. |
| 0.3 | Resolución inversa PTR | Configurada; demostrar con `dig`. |
| 0.4 | NOTIFY, AXFR/IXFR y sincronización | Configurada; cambiar serial y mostrar logs. |
| 0.3 | TSIG y bloqueo AXFR | Configurado; ejecutar sin/con clave. |
| 0.2 | Recursión, allow-query y RRL | Configurados; demostrar comportamiento. |
| 0.2 | Auditoría | Configurada; mostrar tres logs. |
| 0.2 | Continuidad | Pendiente hasta apagar maestro y consultar esclavo. |

### Parte 2: Apache — 2.0 puntos

| Puntos | Criterio | Estado |
|---:|---|---|
| 0.3 | Apache, mod_deflate y DNS local | Automatizado; validar en VM. |
| 0.3 | Gzip 1/6/9 | Script listo; ejecutar medición final. |
| 0.3 | Brotli 5/11 | Script listo; ejecutar medición final. |
| 0.3 | Tipos y exclusión de binarios | Corpus completo; demostrar cabeceras. |
| 0.3 | Curl, navegador y Wireshark | Pasos documentados; demostrar en vivo. |
| 0.2 | Tabla ratio/ahorro/tiempo/CPU | Regenerar tabla final. |
| 0.3 | Análisis con datos | Responder los cinco puntos. |

### Parte 3: túnel — 1.0 punto

| Puntos | Criterio | Estado |
|---:|---|---|
| 0.4 | Túnel activo y URL pública | Automatizado; mostrar URL real. |
| 0.3 | Página desde otra red | Completa; probar con datos móviles. |
| 0.1 | Compresión a través del túnel | Script listo; mostrar gzip/br. |
| 0.2 | Seguridad y mitigaciones | Explicar oralmente. |

## Checklist final de sustentación

- [ ] Ambos integrantes pueden explicar DNS, Apache y túnel.
- [ ] `named-checkconf` y `named-checkzone` sin errores.
- [ ] AXFR sin TSIG rechazado y AXFR con TSIG exitoso.
- [ ] Serial actualizado automáticamente en el esclavo.
- [ ] Consultas directas/inversas con maestro apagado.
- [ ] Logs `queries`, `transfers` y `security` visibles.
- [ ] Gzip 1/6/9 y Brotli 5/11 demostrados.
- [ ] Tabla con bytes, ratio, ahorro, tiempo y CPU completa.
- [ ] DevTools muestra `Content-Encoding`, `Vary`, `Size` y `Transferred`.
- [ ] Wireshark captura `tcp port 80` o visualiza `http || tcp.port == 80`.
- [ ] Página personalizada visible desde otra red.
- [ ] Quick Tunnel detenido al finalizar.
- [ ] Declaración de uso de IA comprendida por el grupo.

El parcial está listo para sustentarse cuando cada casilla tenga una salida real
observada en vivo.
