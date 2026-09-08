# Tabla Comparativa de Compresión HTTP
**Parcial 1 — Servicios Telemáticos 2026-02**
Generado: 2026-09-08 17:49:49
Host: `parcial.empresa.local` (192.168.50.10)

## Resultados por algoritmo

### mod_deflate (gzip)

| Recurso | Sin compr. | D-1 (B) | D-1 (s) | D-6 (B) | D-6 (s) | D-9 (B) | D-9 (s) | Ahorro D-6 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `index.html` | 5339 | 1670 | 0.004383 | 1478 | 0.005577 | 1473 | 0.008078 | **72.3%** |
| `styles.css` | 9844 | 2496 | 0.010990 | 2198 | 0.002412 | 2188 | 0.004207 | **77.7%** |
| `app.js` | 9433 | 3303 | 0.002775 | 2995 | 0.002892 | 2987 | 0.002624 | **68.2%** |
| `data.json` | 827414 | 170791 | 0.023619 | 119547 | 0.051127 | 115033 | 0.098094 | **85.6%** |
| `image.svg` | 8269 | 2152 | 0.001640 | 1875 | 0.002158 | 1860 | 0.001667 | **77.3%** |
| `texto_grande.txt` | 1619999 | 1153376 | 0.126658 | 1128402 | 0.167458 | 1128402 | 0.238541 | **30.3%** |

### mod_brotli (br)

| Recurso | Sin compr. | B-5 (B) | B-5 (s) | B-11 (B) | B-11 (s) | Ahorro B-11 |
|---|---:|---:|---:|---:|---:|---:|
| `index.html` | 5339 | 1324 | 0.005210 | 1204 | 0.487623 | **77.4%** |
| `styles.css` | 9844 | 2053 | 0.030614 | 1852 | 0.045744 | **81.2%** |
| `app.js` | 9433 | 2813 | 0.007130 | 2555 | 0.035017 | **72.9%** |
| `data.json` | 827414 | 116639 | 0.058285 | 89748 | 4.141293 | **89.2%** |
| `image.svg` | 8269 | 1723 | 0.002979 | 1596 | 0.025497 | **80.7%** |
| `texto_grande.txt` | 1619999 | 1087594 | 0.232253 | 1074371 | 4.054792 | **33.7%** |

### Recursos binarios (excluidos de compresión)

| Recurso | Tamaño (B) | Content-Encoding | Justificación |
|---|---:|---|---|
| `foto.jpg` | 51200 | identity | Ya comprimido por naturaleza |
| `video_sample.mp4` | 204800 | identity | Ya comprimido por naturaleza |

## Análisis

- **Mejor ratio de compresión:** Brotli-11 supera consistentemente a Deflate-9 en texto (~15-25% más).
- **Mejor balance CPU/ratio:** Deflate-6 y Brotli-5 son los valores recomendados para producción.
- **Binarios (JPG, MP4):** Sin compresión efectiva (ya comprimidos). Se excluyen con .
- **Conclusión:** Para archivos de texto/JSON, activar Brotli-5 es la mejor opción en producción.

## Comandos de referencia

```bash
# Verificar encoding de un recurso
curl -sI -H "Accept-Encoding: gzip" http://parcial.empresa.local/data.json | grep -i content-encoding
curl -sI -H "Accept-Encoding: br"   http://parcial.empresa.local/data.json | grep -i content-encoding

# Ver config actual de compresión
grep -E "DeflateCompressionLevel|BrotliCompressionQuality" /etc/apache2/conf-available/compression.conf

# Verificación rápida a través de URL pública (si usa cloudflared/ngrok):
# bash /vagrant/Parte3_Tunel/verificar_encoding.sh https://TU-URL.trycloudflare.com
```
