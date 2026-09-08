# Tabla Comparativa de Compresión HTTP
**Parcial 1 — Servicios Telemáticos 2026-02**

> [!NOTE]
> Esta es la plantilla inicial. Para generar la tabla con datos reales,
> ejecutar **dentro de `parcial_master`** como root:
> ```bash
> sudo bash /vagrant/Parte2_Apache/medir_compresion.sh
> ```
> El script sobreescribirá este archivo con los resultados reales.

## Plantilla de resultados (completar manualmente si no se usa el script)

### mod_deflate (gzip)

| Recurso | Sin compr. | D-1 (B) | D-1 (s) | D-6 (B) | D-6 (s) | D-9 (B) | D-9 (s) | Ahorro D-6 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `index.html`       | — | — | — | — | — | — | — | — |
| `styles.css`       | — | — | — | — | — | — | — | — |
| `app.js`           | — | — | — | — | — | — | — | — |
| `data.json`        | — | — | — | — | — | — | — | — |
| `image.svg`        | — | — | — | — | — | — | — | — |
| `texto_grande.txt` | — | — | — | — | — | — | — | — |

### mod_brotli (br)

| Recurso | Sin compr. | B-5 (B) | B-5 (s) | B-11 (B) | B-11 (s) | Ahorro B-11 |
|---|---:|---:|---:|---:|---:|---:|
| `index.html`       | — | — | — | — | — | — |
| `styles.css`       | — | — | — | — | — | — |
| `app.js`           | — | — | — | — | — | — |
| `data.json`        | — | — | — | — | — | — |
| `image.svg`        | — | — | — | — | — | — |
| `texto_grande.txt` | — | — | — | — | — | — |

### Recursos binarios (excluidos de compresión)

| Recurso | Tamaño (B) | Content-Encoding | Justificación |
|---|---:|---|---|
| `foto.jpg`          | — | identity | Ya comprimido (JPEG) |
| `video_sample.mp4`  | — | identity | Ya comprimido (MP4)  |

## Comandos de verificación manual

```bash
# En parcial_master como root:

# Cambiar nivel deflate a 1 y medir
sed -i 's/DeflateCompressionLevel [0-9]/DeflateCompressionLevel 1/' /etc/apache2/conf-available/compression.conf
systemctl reload apache2
curl -so /dev/null -H "Accept-Encoding: gzip" -w "Size: %{size_download}B  Time: %{time_total}s\n" http://127.0.0.1/data.json

# Cambiar a nivel 6
sed -i 's/DeflateCompressionLevel [0-9]/DeflateCompressionLevel 6/' /etc/apache2/conf-available/compression.conf
systemctl reload apache2
curl -so /dev/null -H "Accept-Encoding: gzip" -w "Size: %{size_download}B  Time: %{time_total}s\n" http://127.0.0.1/data.json

# Medir con brotli nivel 11
sed -i 's/BrotliCompressionQuality [0-9]*/BrotliCompressionQuality 11/' /etc/apache2/conf-available/compression.conf
systemctl reload apache2
curl -so /dev/null -H "Accept-Encoding: br" -w "Size: %{size_download}B  Time: %{time_total}s\n" http://127.0.0.1/data.json

# Ver Content-Encoding en header
curl -sI -H "Accept-Encoding: gzip" http://127.0.0.1/index.html | grep -i content-encoding
curl -sI -H "Accept-Encoding: br"   http://127.0.0.1/index.html | grep -i content-encoding
```
