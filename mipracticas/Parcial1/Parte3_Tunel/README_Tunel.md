# Parte 3 — Túnel Seguro con cloudflared

## ¿Qué hace este componente?

Expone el VirtualHost `parcial.empresa.local` (Apache2 en puerto 80)
hacia Internet a través de un **Quick Tunnel de Cloudflare**, sin necesidad
de cuenta ni configuración DNS adicional.

## Prerrequisitos

- `parcial_master` levantado y con Apache2 funcionando
- `cloudflared` instalado (el provisioning lo hace automáticamente)
- Acceso a Internet desde la VM

## Flujo del túnel

```
Browser (externo)
    ↓  HTTPS / TLS 1.3
Cloudflare Edge (CDN)
    ↓  HTTP/2 encriptado (QUIC)
cloudflared daemon (en parcial_master)
    ↓  HTTP/1.1
Apache2 → /var/www/parcial
```

**Importante:** cloudflared actúa como proxy transparente.
Las cabeceras `Content-Encoding: gzip` y `Content-Encoding: br`
generadas por Apache son retransmitidas intactas al cliente.

## Paso a paso

### 1. Verificar que Apache2 está activo
```bash
vagrant ssh parcial_master
systemctl status apache2
curl -sI http://localhost/index.html | grep -i content-encoding
```

### 2. Iniciar el túnel
```bash
# Dentro de parcial_master:
bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh
```
Esperar hasta ver una línea como:
```
 Your quick Tunnel has been created! Visit it at (it may take some time to be reachable):
 https://abc-def-123-xyz.trycloudflare.com
```

### 3. Verificar preservación de Content-Encoding

**Opción A — desde el host Windows:**
```powershell
curl -sI -H "Accept-Encoding: gzip" https://TU-URL.trycloudflare.com/data.json
curl -sI -H "Accept-Encoding: br"   https://TU-URL.trycloudflare.com/data.json
```

**Opción B — desde una terminal extra en parcial_master:**
```bash
# Segunda terminal (el túnel corre en la primera)
vagrant ssh parcial_master
bash /vagrant/Parte3_Tunel/verificar_encoding.sh https://TU-URL.trycloudflare.com
```

### 4. Resultado esperado

| Cabecera solicitada | Content-Encoding recibido | Preservado |
|---|---|---|
| `Accept-Encoding: gzip` | `gzip` | ✅ Sí |
| `Accept-Encoding: br`   | `br`   | ✅ Sí |
| Sin cabecera (binarios) | *(vacío)* | ✅ Correcto |

## Archivos

| Archivo | Descripción |
|---|---|
| `pagina_personalizada.html` | Página de identificación estudiantil |
| `setup_cloudflared.sh` | Instalación (llamado por Vagrant) |
| `iniciar_tunel_cloudflared.sh` | Inicia el Quick Tunnel |
| `verificar_encoding.sh` | Verifica Content-Encoding en el túnel |
