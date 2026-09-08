# Análisis Crítico — Parcial 1 · Servicios Telemáticos 2026-02

---

## Punto 1: ¿Por qué TSIG es preferible a `allow-transfer` por IP para proteger las transferencias de zona DNS?

### Respuesta

La restricción por dirección IP (`allow-transfer { 192.168.50.11; };`) ofrece una seguridad
**superficial** porque trabaja a nivel de red y no realiza ninguna verificación criptográfica.
Sus vulnerabilidades principales son:

1. **IP Spoofing (falsificación de origen):** En UDP, un atacante puede enviar paquetes con la
   IP de origen falsificada. BIND9 respondería a quien falsifique la IP del esclavo legítimo.
   Si bien una transferencia AXFR completa requiere TCP (y el three-way handshake mitiga el
   spoofing puro), un atacante con posición en la red puede realizar ataques MITM.

2. **Sin integridad del mensaje:** Incluso si la IP es correcta, `allow-transfer` por IP no
   garantiza que el contenido del mensaje AXFR no haya sido manipulado en tránsito.

**TSIG (Transaction Signature — RFC 2845)** resuelve ambos problemas mediante:

- **Autenticación criptográfica HMAC-SHA256:** Cada mensaje DNS está firmado con la clave
  secreta compartida. Sin conocer la clave, es imposible generar una firma válida.
- **Protección de integridad:** La firma cubre el contenido completo del mensaje. Cualquier
  modificación en tránsito invalida la firma y BIND9 rechaza el mensaje.
- **Granularidad:** Se pueden asignar claves distintas a cada esclavo (`key slave1-key;` vs
  `key slave2-key;`), permitiendo revocar el acceso a un esclavo sin afectar a los demás.
- **Protección de replay:** TSIG incluye timestamp. Mensajes reproducidos después de 300
  segundos son rechazados automáticamente.

**Conclusión:** `allow-transfer` por IP es una lista de control de acceso a nivel de red;
TSIG es autenticación criptográfica a nivel de aplicación. En un entorno de producción,
se usan **ambos** en conjunto (defense-in-depth), pero TSIG es el control de seguridad principal.

---

## Punto 2: Diferencias entre AXFR e IXFR — ¿Cuándo conviene usar cada uno?

### AXFR — Full Zone Transfer (RFC 5936)

AXFR transfiere **la zona completa** desde el maestro al esclavo, independientemente de cuánto
haya cambiado desde la última sincronización.

**Características:**
- Requiere TCP (puede ser voluminoso)
- Simple de implementar: el esclavo descarta su copia y reemplaza con la recibida
- No requiere historial de cambios en el maestro
- Siempre funciona como fallback cuando IXFR falla

**Cuándo se usa AXFR:**
- Primera sincronización (el esclavo no tiene ninguna copia)
- El serial del esclavo está tan desactualizado que el maestro ya no tiene el historial intermedio
- Zonas pequeñas donde la eficiencia de IXFR no justifica la complejidad
- El maestro no está configurado para mantener historial de cambios

### IXFR — Incremental Zone Transfer (RFC 1995)

IXFR transfiere **solo los registros que cambiaron** entre el serial que el esclavo tiene y el
serial actual del maestro. El esclavo indica su serial actual en la solicitud.

**Características:**
- Puede usar UDP si el delta cabe en un paquete (512 B sin EDNS, o el tamaño máximo negociado)
- Usa TCP si el delta es grande
- El maestro debe mantener un historial de versiones de la zona (`ixfr-from-differences yes;`)
- Si el maestro no tiene historial suficiente, responde con AXFR completa (fallback automático)

**Cuándo se usa IXFR:**
- Zonas grandes (miles de registros) con cambios frecuentes pero pequeños
- Entornos con ancho de banda limitado entre maestro y esclavo
- Alta frecuencia de actualizaciones de zona

### Resumen comparativo

| Característica | AXFR | IXFR |
|---|---|---|
| Datos transferidos | Zona completa | Solo cambios (delta) |
| Protocolo | TCP siempre | UDP (pequeño) o TCP |
| Historial requerido | No | Sí |
| Complejidad | Baja | Media |
| Eficiencia en red | Baja | Alta |
| Fallback automático | — | Sí (→ AXFR) |

---

## Punto 3: Comparación técnica entre `mod_deflate` (gzip) y `mod_brotli`

### mod_deflate — algoritmo gzip (DEFLATE)

El módulo `mod_deflate` de Apache implementa compresión usando el algoritmo **DEFLATE**,
que combina LZ77 (coincidencia de cadenas repetidas) con codificación Huffman.
La cabecera del stream identifica el formato como `gzip` (RFC 1952).

**Características:**
- **Soporte:** Universal. Todos los navegadores desde IE6+, curl, wget, y cualquier
  cliente HTTP lo soporta. El estándar de facto durante ~25 años.
- **Niveles de compresión:** 1–9 (1 = mínima CPU/máx. velocidad, 9 = máxima compresión/más CPU)
- **Ratio típico en texto:** 60–75% de reducción de tamaño
- **CPU:** Bajo en niveles 1-6; nivel 9 tiene rendimientos decrecientes con mucho más CPU
- **Latencia:** Muy baja, ideal para contenido dinámico en tiempo real

### mod_brotli — algoritmo Brotli

Brotli fue desarrollado por Google (2015, RFC 7932). Usa LZ77 + codificación Huffman de segundo
orden + **context modeling** (modela la probabilidad de bytes según el contexto previo).

**Características:**
- **Soporte:** Navegadores modernos: Chrome 50+, Firefox 44+, Edge 14+, Safari 11+.
  No soportado por IE, curl sin la biblioteca libbrotli, ni clientes HTTP básicos.
  Por eso Apache solo envía Brotli si el cliente incluye `br` en `Accept-Encoding`.
- **Niveles de compresión:** 0–11 (11 = máxima compresión, muy lento)
- **Ratio típico en texto:** 15–25% mejor que gzip al mismo nivel de CPU
- **CPU en niveles altos (11):** Significativamente más lento que gzip-9.
  **No recomendado para contenido dinámico**; ideal para archivos estáticos pre-comprimidos.
- **Nivel 5–6:** Balance óptimo calidad/CPU para contenido dinámico

### Comparativa directa

| Criterio | mod_deflate (gzip) | mod_brotli |
|---|---|---|
| Algoritmo | LZ77 + Huffman | LZ77 + Huffman + Context Modeling |
| Estándar | 1996 (RFC 1952) | 2015 (RFC 7932) |
| Soporte clientes | Universal | Navegadores modernos |
| Ratio de compresión | Moderado | 15-25% mejor |
| CPU (nivel equiv.) | Referencia | Similar (niveles bajos) |
| CPU (máx. nivel) | Moderado | Muy alto |
| Latencia dinámica | Muy baja | Baja (niveles ≤6) |
| Recomendación prod. | Nivel 6 (default) | Nivel 5 dinámico / 11 estático |

### Conclusión práctica

Para un servidor Apache sirviendo contenido mixto (estático + dinámico), la estrategia óptima
es **activar ambos módulos** y dejar que la negociación `Accept-Encoding` decida: los clientes
modernos (la mayoría) reciben Brotli con mejor compresión; los clientes legacy reciben gzip.

---

## Punto 4: ¿Cómo preserva un túnel inverso (cloudflared) las cabeceras HTTP como `Content-Encoding`?

### Arquitectura del túnel cloudflared

cloudflared implementa un **proxy inverso basado en conexión persistente saliente**.
A diferencia de un servidor expuesto directamente, el flujo es:

```
[Cliente externo]
      ↕ HTTPS (TLS 1.3)
[Cloudflare Edge — CDN]
      ↕ HTTP/2 encriptado (QUIC/TCP) — conexión saliente iniciada por cloudflared
[cloudflared daemon — parcial_master]
      ↕ HTTP/1.1 (localhost)
[Apache2 — puerto 80]
```

### Por qué se preservan las cabeceras

1. **Proxy transparente a nivel de capa 7:** cloudflared actúa como proxy de aplicación que
   retransmite la respuesta HTTP completa (status line + headers + body) sin interpretar
   ni modificar el cuerpo. El body comprimido (gzip o brotli) se trata como **bytes opacos**.

2. **Las cabeceras HTTP son texto ASCII plano:** cloudflared las lee del socket de Apache2,
   las incluye en la respuesta HTTP/2 hacia Cloudflare Edge, y el Edge las reenvía al cliente.
   No hay razón para eliminar `Content-Encoding`.

3. **`Vary: Accept-Encoding` es respetado:** Cloudflare Edge no recomprime la respuesta si ya
   viene con `Content-Encoding`. La presencia de esta cabecera + `Vary` le indica que la
   respuesta ya está comprimida y no debe tocarse.

4. **Sin decompresión intermedia:** cloudflared no tiene lógica de decompresión/recompresión.
   El dato viaja: `Apache (comprime) → cloudflared (transparente) → Cloudflare Edge (transparente) → Cliente (descomprime)`.

### Verificación

```bash
# La cabecera Content-Encoding gzip del servidor local...
curl -sI -H "Accept-Encoding: gzip" http://localhost/data.json | grep content-encoding
# content-encoding: gzip

# ...aparece idéntica a través del túnel público:
curl -sI -H "Accept-Encoding: gzip" https://TU-URL.trycloudflare.com/data.json | grep content-encoding
# content-encoding: gzip  ← preservada ✓
```

---

## Punto 5: Impacto del Rate-Limiting (RRL) en BIND9 como medida anti-amplificación DNS

### El problema: DNS Amplification Attack

Los servidores DNS autoritativos y recursivos abiertos son frecuentemente abusados en
ataques **DDoS de amplificación**, también llamados DNS Reflection/Amplification:

1. El atacante envía una consulta DNS pequeña (ej. 40 bytes) con la IP de origen falsificada
   apuntando a la **víctima**.
2. El servidor DNS responde con una respuesta grande (ej. `ANY` query → 3000 bytes) a la víctima.
3. El factor de amplificación puede llegar a **75x–100x** (40 B enviados → 4000 B hacia la víctima).
4. Con miles de servidores DNS como reflectores, el atacante puede generar tráfico masivo hacia
   la víctima con recursos mínimos.

### Solución: Response Rate Limiting (RRL)

RRL (implementado en BIND9 desde 9.10, RFC experimental) limita la velocidad a la que el servidor
envía **respuestas idénticas o similares** hacia la misma dirección IP de destino.

**Configuración del parcial:**
```
rate-limit {
    responses-per-second 10;  # Máx. 10 respuestas iguales/IP/ventana
    window               5;   # Ventana deslizante de 5 segundos
    slip                 2;   # Cada 2 descartadas, envía 1 truncada (TC=1)
};
```

**Mecanismo:**
- BIND9 mantiene una tabla hash de respuestas enviadas por IP/segundo.
- Si una IP supera el umbral → las respuestas siguientes se **descartan (DROP)** o se envían
  **truncadas** (flag TC=1).
- TC=1 fuerza al cliente legítimo a reintentar por TCP (mucho más difícil de falsificar).
- Un atacante con IP falsificada no puede recibir TCP → su amplificación falla.

### Impacto medido

| Escenario | Sin RRL | Con RRL (10 r/s) |
|---|---|---|
| Tráfico de amplificación | Ilimitado | Limitado a 10 resp/s por IP |
| Cliente legítimo (<10 q/s) | Normal | Normal (no afectado) |
| Cliente legítimo (>10 q/s) | Normal | Respuesta truncada → TCP retry |
| Resolvers recursivos | Posiblemente afectados | `exemp`-list puede excluirlos |

### `slip` y sus implicaciones

El parámetro `slip 2` es clave: en lugar de descartar todas las respuestas que exceden el límite,
**cada 2 respuestas descartadas, envía una truncada** (con bit TC=1, cuerpo vacío).

- **Para clientes legítimos:** Reciben el flag TC=1, reintentan por TCP y obtienen la respuesta completa.
- **Para atacantes con IP falsificada:** TCP es infactible → el intento de amplificación falla.
- **Sin slip (solo DROP):** Los clientes legítimos que superen el umbral reciben silencio total, lo que podría interpretarse como error de red.

### Trade-offs a considerar

- RRL puede afectar **resolvers recursivos** que centralizan consultas de miles de usuarios
  (parecen "un solo origen" desde el punto de vista de BIND9). Se pueden añadir a una
  `exemption-list` o aumentar el threshold.
- RRL **no protege** contra DoS directo con IP real no falsificada; es específico para amplificación.
- Complemento recomendado: `allow-recursion { none; };` para no ser un resolver abierto.
