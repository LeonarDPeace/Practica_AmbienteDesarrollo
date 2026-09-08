# Parte 2 — Apache2 y compresion HTTP

## Funcion de esta carpeta

Esta carpeta implementa el servidor web de `parcial_master` y compara compresion
HTTP con `mod_deflate` (gzip) y `mod_brotli` (Brotli). El sitio publica recursos
textuales, datos JSON, SVG y binarios para observar cuando la compresion ayuda y
cuando debe excluirse.

## Archivos

| Archivo                                  | Funcion                                                                                                 |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `provision/setup_apache.sh`            | Instala Apache, habilita modulos, copia recursos, genera archivos de prueba y activa el VirtualHost.    |
| `provision/parcial.empresa.local.conf` | Define el VirtualHost, DocumentRoot, tipos MIME y logs propios.                                         |
| `provision/compression.conf`           | Configura`DeflateCompressionLevel`, `BrotliCompressionQuality`, tipos MIME y exclusion de binarios. |
| `medir_compresion.sh`                  | Mide tamanos, tiempo y CPU local de `curl` para gzip 1/6/9 y Brotli 5/11; genera la tabla de resultados. |
| `tabla_comparativa.md`                 | Registra los resultados obtenidos en una ejecucion del script y el analisis preliminar.                 |
| `recursos/`                            | Contiene HTML pequeno/grande, CSS/JS original y minificado, XML y SVG que se copian al DocumentRoot.    |

- Apache2 instalado en una VM y VirtualHost `parcial.empresa.local`.
- `mod_deflate` para HTML, CSS, JavaScript, JSON, XML, SVG y texto plano.
- `mod_brotli` para los mismos tipos de contenido.
- Niveles gzip 1, 6 y 9; calidades Brotli 5 y 11.
- Archivos generados en la VM: `index_grande.html`, `data.json`,
  `texto_grande.txt`, `foto.jpg` y `video_sample.mp4`.
- JPEG y MP4 excluidos porque ya usan compresion propia.

## Reproduccion

Desde el host:

```powershell
cd mipracticas/Parcial1
vagrant up parcial_master
vagrant ssh parcial_master
```

Dentro de `parcial_master`:

```bash
sudo apache2ctl configtest
sudo systemctl status apache2
curl -H "Host: parcial.empresa.local" http://192.168.50.10/
sudo bash /vagrant/Parte2_Apache/medir_compresion.sh
```

## Verificacion de cabeceras

```bash
curl -sI -H "Accept-Encoding: gzip" http://192.168.50.10/data.json \
  | grep -iE 'content-encoding|vary'

curl -sI -H "Accept-Encoding: br" http://192.168.50.10/data.json \
  | grep -iE 'content-encoding|vary'

curl -sI -H "Accept-Encoding: gzip" http://192.168.50.10/foto.jpg \
  | grep -i content-encoding
```

La primera y segunda consulta deben mostrar `Content-Encoding: gzip` y
`Content-Encoding: br`, respectivamente. La imagen debe permanecer sin
`Content-Encoding`.

## Evidencia en navegador y Wireshark

La demostracion detallada esta en el README principal del parcial, secciones
"Parte 2: Apache, navegador y Wireshark". En resumen, el navegador debe mostrar en
Network las cabeceras `Content-Encoding`/`Vary` y las columnas `Size` y
`Transferred`. Wireshark debe capturar el trafico HTTP local sobre la interfaz
VirtualBox Host-Only con `tcp port 80` (captura) o `http || tcp.port == 80`
(visualizacion). El trafico HTTPS de cloudflared no permite ver esas cabeceras
porque esta cifrado; ese trafico se valida con `curl` contra la URL publica.

## CPU y evidencia pendiente para la sustentacion

El script mide tamano transferido, tiempo de respuesta y tiempo de CPU local de
`curl` con `/usr/bin/time`. Es un indicador reproducible del costo de la
solicitud, pero no reemplaza un perfil directo del proceso Apache. La rubrica
tambien pide mostrar navegador y Wireshark. Antes de sustentar hay que:

1. repetir las mediciones en la VM que se demostrara;
2. completar ratio y ahorro por recurso en `tabla_comparativa.md`;
3. mostrar DevTools > Network con `Content-Encoding` y bytes transferidos;
4. capturar trafico con Wireshark usando un filtro HTTP apropiado;
5. conservar los resultados reales, sin inventar valores.

CSS y JavaScript tienen versiones originales y minificadas. `index_grande.html`
se genera durante el provisioning para cumplir el rango de tamano solicitado.
