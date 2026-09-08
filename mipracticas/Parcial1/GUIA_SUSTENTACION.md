# Guia de sustentacion en vivo

## Objetivo

Esta guia convierte el enunciado del PDF en una secuencia de demostracion. La
sustentacion es en vivo: los archivos Markdown sirven como apoyo, pero no
reemplazan ejecutar los comandos ni mostrar los resultados en las VMs.

## Preparacion antes de la sustentacion

Desde PowerShell, en `mipracticas/Parcial1`:

```powershell
vagrant validate
vagrant up parcial_master
vagrant up parcial_slave
```

Comprobar que ambos equipos estan activos:

```powershell
vagrant status
```

Abrir tres terminales:

| Terminal | Uso |
|---|---|
| 1 | `vagrant ssh parcial_master`: DNS maestro, Apache y cloudflared. |
| 2 | `vagrant ssh parcial_slave`: DNS esclavo y continuidad. |
| 3 | PowerShell del host: navegador, curl, Wireshark y comandos Vagrant. |

Antes de iniciar, completar una tabla con resultados reales en
`Parte2_Apache/tabla_comparativa.md`. No inventar tiempos, CPU ni tamaños.

## Parte 1 — DNS maestro/esclavo (2.0 puntos)

### 1. Sintaxis y zonas

En la terminal del maestro:

```bash
sudo named-checkconf
sudo named-checkzone empresa.local /etc/bind/zones/empresa.local.zone
sudo named-checkzone 50.168.192.in-addr.arpa /etc/bind/zones/50.168.192.zone
sudo systemctl is-active named
```

Resultado esperado: los tres chequeos indican `OK` y el servicio aparece
`active`.

### 2. Registros directos, IPv6 e inversos

```bash
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

Resultado esperado: aparecen SOA, dos NS, A/AAAA, CNAME, MX y PTR.

### 3. AXFR autorizado y rechazado

Mostrar primero el rechazo sin clave:

```bash
dig @192.168.50.10 empresa.local AXFR +tcp
```

Resultado esperado: `Transfer failed`, `REFUSED` o `NOTAUTH`; nunca debe
entregarse la zona completa.

Mostrar después la transferencia autorizada:

```bash
sudo dig @192.168.50.10 empresa.local AXFR -k /etc/bind/tsig.key +tcp
sudo dig @192.168.50.10 50.168.192.in-addr.arpa AXFR -k /etc/bind/tsig.key +tcp
```

Resultado esperado: aparecen los registros de la zona y la consulta termina
con `status: NOERROR`.

### 4. NOTIFY, IXFR y sincronizacion automatica

En el maestro mostrar el serial actual:

```bash
dig @192.168.50.10 empresa.local SOA +short
dig @192.168.50.11 empresa.local SOA +short
sudo tail -n 30 /var/log/named/transfers.log
```

Para una demostracion controlada, editar temporalmente la zona del maestro,
agregar un registro A de prueba y aumentar el serial respetando
`AAAAMMDDNN`. Validar y recargar:

```bash
sudo named-checkzone empresa.local /etc/bind/zones/empresa.local.zone
sudo rndc reload empresa.local
dig @192.168.50.10 empresa.local SOA +short
```

En la terminal del esclavo comprobar que el nuevo serial llega sin reiniciar
manualmente el esclavo:

```bash
dig @192.168.50.11 empresa.local SOA +short
sudo tail -n 30 /var/log/named/transfers.log
```

Explicar: la primera copia normalmente usa AXFR; después de un cambio el
maestro conserva diferencias con `ixfr-from-differences yes` y el esclavo puede
recibir IXFR. El log y el cambio de serial son la evidencia; el nombre exacto
de la categoria puede variar según la version de BIND.

### 5. Hardening y auditoria

```bash
dig @192.168.50.10 google.com A +short
sudo grep -E 'recursion|allow-query|rate-limit' /etc/bind/named.conf.options
sudo tail -n 20 /var/log/named/queries.log
sudo tail -n 20 /var/log/named/transfers.log
sudo tail -n 20 /var/log/named/security.log
```

Resultado esperado: `google.com` no se resuelve por recursion y los tres logs
muestran consultas, transferencias/rechazos y eventos de seguridad.

### 6. Continuidad con maestro apagado

Antes de apagarlo, comprobar desde el esclavo:

```bash
dig @192.168.50.11 www.empresa.local A +short
dig @192.168.50.11 -x 192.168.50.10 +short
```

Apagar solo el servicio del maestro:

```bash
sudo systemctl stop named
```

Repetir contra el esclavo:

```bash
dig @192.168.50.11 www.empresa.local A +short
dig @192.168.50.11 -x 192.168.50.10 +short
```

Resultado esperado: el esclavo sigue respondiendo con la zona almacenada hasta
que expire el `expire` del SOA. Restaurar al terminar:

```bash
sudo systemctl start named
```

## Parte 2 — Apache y compresion (2.0 puntos)

### 1. Servicio, VirtualHost y archivos

En el maestro:

```bash
sudo systemctl is-active apache2
sudo apache2ctl configtest
sudo apache2ctl -S
ss -ltnp | grep ':80'
curl -H 'Host: parcial.empresa.local' http://192.168.50.10/
```

Comprobar recursos exigidos:

```bash
for recurso in index.html index_grande.html styles.css styles.min.css app.js app.min.js data.json image.svg feed.xml texto_grande.txt foto.jpg video_sample.mp4; do
  printf '%-24s ' "$recurso"
  curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' "http://192.168.50.10/$recurso"
done
```

### 2. Curl: identidad, gzip y Brotli

Usar el mismo recurso grande para que la diferencia sea visible:

```bash
URL='http://192.168.50.10/data.json'
curl -s -H 'Accept-Encoding: identity' -o /dev/null -w 'identity bytes=%{size_download} time=%{time_total}s\n' "$URL"
curl -s -H 'Accept-Encoding: gzip' -o /dev/null -w 'gzip bytes=%{size_download} time=%{time_total}s\n' "$URL"
curl -s -H 'Accept-Encoding: br' -o /dev/null -w 'brotli bytes=%{size_download} time=%{time_total}s\n' "$URL"

curl -sI -H 'Accept-Encoding: gzip' "$URL" | grep -iE 'HTTP/|content-encoding|vary'
curl -sI -H 'Accept-Encoding: br' "$URL" | grep -iE 'HTTP/|content-encoding|vary'
curl -sI -H 'Accept-Encoding: gzip' http://192.168.50.10/foto.jpg | grep -iE 'HTTP/|content-encoding|vary'
```

Resultado esperado: texto con `gzip` o `br`, `Vary: Accept-Encoding` y JPG/MP4
sin compresion adicional.

### 3. Medicion de niveles y tabla

```bash
sudo bash /vagrant/Parte2_Apache/medir_compresion.sh
```

Mostrar el archivo generado:

```bash
less /vagrant/Parte2_Apache/tabla_comparativa.md
```

Explicar las formulas:

- ratio = `tamano_comprimido / tamano_original`;
- ahorro = `(1 - ratio) * 100`;
- CPU registrada por el script = tiempo local de `curl` medido con
  `/usr/bin/time`; no presentarlo como perfil exclusivo de Apache.

La tabla debe mostrar para cada recurso: identity, gzip 1/6/9, Brotli 5/11,
tamano, ratio, ahorro, tiempo y CPU.

### 4. Navegador: DevTools Network

Desde el host Windows:

1. Abrir `http://192.168.50.10/` en Chrome o Edge.
2. Presionar `F12` y seleccionar **Network**.
3. Activar **Disable cache** y recargar con `Ctrl+R`.
4. Filtrar por `data.json`, `texto_grande.txt` o `index_grande.html`.
5. Seleccionar la solicitud y abrir **Headers**.
6. En **Response Headers**, mostrar `Content-Encoding: br` o `gzip` y
   `Vary: Accept-Encoding`.
7. Mostrar en la fila las columnas **Size** y **Transferred**.
8. Repetir con `foto.jpg` y explicar que no debe aparecer `Content-Encoding`.
9. Para forzar el algoritmo desde el navegador, usar la consola solo como
   apoyo; la prueba controlada de algoritmo es la ejecutada con `curl`.

La evidencia que se muestra en vivo es la solicitud, sus cabeceras y el tamaño
transferido; una captura puede conservarse como apoyo, pero no reemplaza la
demostracion.

### 5. Wireshark: captura del trafico HTTP local

La captura debe hacerse contra el acceso local por HTTP, no contra la URL
HTTPS de Cloudflare, porque HTTPS cifra las cabeceras y el contenido ante
Wireshark.

Preparacion en Windows:

1. Instalar Wireshark y abrirlo como administrador.
2. Identificar la interfaz **VirtualBox Host-Only Network** conectada a la red
   `192.168.50.0/24`.
4. Iniciar captura en esa interfaz.
5. Para un filtro de **captura** usar:

```text
tcp port 80
```

Para un filtro de **visualizacion** usar:

```text
http || tcp.port == 80
```

6. En el navegador abrir `http://192.168.50.10/data.json` y recargar sin cache.
7. Volver a Wireshark y localizar la conversacion TCP entre el host y
   `192.168.50.10:80`.
8. Seleccionar un paquete y usar **Follow > TCP Stream**.
9. Mostrar que la respuesta contiene `Content-Encoding: gzip` o `br`,
   `Vary: Accept-Encoding` y el cuerpo transferido comprimido.
10. Repetir con `foto.jpg` para evidenciar que el binario no recibe la misma
   cabecera.
11. Detener la captura y guardar opcionalmente `evidencia_http.pcapng` fuera
    del repositorio si contiene datos que no deban publicarse.

Importante: si se captura la URL `https://...trycloudflare.com`, el filtro
`http` no mostrara las cabeceras porque el trafico va cifrado. Para Wireshark
se usa la IP local; para demostrar el tunel se usa `curl` y el navegador desde
la URL publica.

### 6. Analisis critico de Parte 2

Responder oralmente con los valores de la tabla:

1. cuanto mejora Brotli frente a gzip en HTML, CSS, JS, JSON, XML y texto;
2. cuanto se gana al pasar gzip 1 a 6 a 9 y Brotli 5 a 11, y donde aparecen
   rendimientos decrecientes;
3. por que JPG, PNG, MP4 y ZIP no deben comprimirse otra vez;
4. como cambia el balance CPU/ancho de banda con alta concurrencia;
5. cuando conviene Brotli 11 precomprimido y cuando compresion al vuelo en
   niveles moderados.

## Parte 3 — Tunel seguro (1.0 punto)

### 1. Iniciar cloudflared

En el maestro verificar Apache y arrancar un Quick Tunnel:

```bash
sudo ss -ltnp | grep ':80'
nohup bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh > /tmp/cloudflared.out 2>&1 &
sleep 5
grep -oE 'https://[^ ]+trycloudflare.com' /tmp/cloudflared.out | tail -1
```

Copiar la URL real. No usar `XXXX` ni `TU-URL`.

### 2. Acceso desde otra red

Desde un telefono con datos moviles, o un equipo conectado a otra red, abrir:

```text
https://URL-REAL.trycloudflare.com/pagina_personalizada.html
```

Mostrar nombre, codigos, fecha e identificador del despliegue. Esto es distinto
de probar desde la misma red local.

### 3. Compresion atravesando el tunel

Desde PowerShell, otra red o el maestro:

```powershell
curl.exe -sI -H "Accept-Encoding: br" https://URL-REAL.trycloudflare.com/data.json
curl.exe -sI -H "Accept-Encoding: gzip" https://URL-REAL.trycloudflare.com/data.json
```

O ejecutar el verificador completo:

```bash
bash /vagrant/Parte3_Tunel/verificar_encoding.sh https://URL-REAL.trycloudflare.com
```

Mostrar `Content-Encoding` y explicar que el tunel conserva la respuesta de
Apache. Detenerlo al concluir:

```bash
sudo pkill -f cloudflared
```

### 4. Seguridad que se debe explicar

- La URL publica expone el servidor mientras el proceso esta activo.
- Quick Tunnel no agrega autenticacion de usuario a la pagina.
- La URL es temporal y el plan/servicio puede tener limites.
- No deben exponerse datos sensibles.
- Mitigaciones: apagar el proceso al terminar, publicar solo datos de prueba,
  agregar autenticacion basica si el escenario lo permite y restringir el
  acceso por IP o una capa de autenticacion delante del servicio.

## Entregables que deben estar en GitHub

### General

- `Vagrantfile` reproducible y orden de provisioning.
- README general y comandos utilizados.
- Declaracion de uso de Gemini y Claude como asistencia.

### Parte 1

- `named.conf` o fragmentos equivalentes de opciones y zonas.
- Zona directa e inversa.
- Clave TSIG de laboratorio o mecanismo reproducible para generarla; nunca
  publicar una clave personal o reutilizada.
- Configuracion de `allow-transfer`, NOTIFY, IXFR, hardening y RRL.
- Configuracion de logging separado.
- Scripts de provisioning y verificacion.

### Parte 2

- VirtualHost Apache.
- Configuracion de `mod_deflate` y `mod_brotli`.
- Sitio y recursos HTML, CSS, JS, JSON, XML/SVG, texto y binarios.
- Script de medicion.
- Tabla por recurso con identity, tamanos, ratios, ahorro, tiempos y CPU.
- Analisis critico sustentado con los datos reales.

### Parte 3

- Pagina personalizada con nombre, codigo, fecha e identificador.
- Script de instalacion/inicio/verificacion de cloudflared.
- Comandos para URL publica, prueba desde otra red y parada segura.
- Analisis de riesgos y al menos dos mitigaciones.

## Criterio de cierre

El parcial esta listo para sustentarse cuando cada casilla del checklist de
`REVISION_RUBRICA.md` tenga una salida real observada en vivo. La existencia de
un script o de un archivo de configuracion demuestra reproducibilidad, pero no
por si sola el funcionamiento de la prueba.
