#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  verificar_encoding.sh — Comprobación de Content-Encoding vía túnel
#  Parcial 1 · Servicios Telemáticos 2026-02
#
#  Verifica que cloudflared preserva la cabecera Content-Encoding
#  en las respuestas de Apache2.
#
#  Uso:
#    bash /vagrant/Parte3_Tunel/verificar_encoding.sh <URL_DEL_TUNEL>
#
#  Ejemplo:
#    bash /vagrant/Parte3_Tunel/verificar_encoding.sh \
#         https://abc-def-123.trycloudflare.com
#
#  Puede ejecutarse desde DENTRO o FUERA de la VM (con curl instalado).
# ══════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Validar argumento ─────────────────────────────────────────────────────
if [ -z "${1:-}" ]; then
    echo ""
    echo "Uso: bash verificar_encoding.sh <URL_DEL_TUNEL>"
    echo ""
    echo "Ejemplo:"
    echo "  bash verificar_encoding.sh https://abc-def-123.trycloudflare.com"
    echo ""
    echo "Obtén la URL ejecutando iniciar_tunel_cloudflared.sh en parcial_master."
    exit 1
fi

TUNEL_URL="${1%/}"  # Eliminar trailing slash si existe

# ── Recursos a verificar ──────────────────────────────────────────────────
declare -a RECURSOS=(
    "index.html"
    "styles.css"
    "app.js"
    "data.json"
    "image.svg"
    "texto_grande.txt"
    "pagina_personalizada.html"
    "foto.jpg"
    "video_sample.mp4"
)

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Verificación de Content-Encoding a través del túnel         ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  URL: %-55s║\n" "${TUNEL_URL}"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Verificar conectividad al túnel
echo -n "Verificando conectividad al túnel... "
if ! curl -sf --max-time 10 "${TUNEL_URL}/" &>/dev/null; then
    echo "FALLO"
    echo "ERROR: No se puede conectar a ${TUNEL_URL}"
    echo "Verificar que iniciar_tunel_cloudflared.sh esté corriendo en parcial_master."
    exit 1
fi
echo "OK ✓"
echo ""

# ── Función de medición ───────────────────────────────────────────────────
verificar_recurso() {
    local recurso="$1"
    local url="${TUNEL_URL}/${recurso}"

    # Medir con gzip
    local headers_gzip
    headers_gzip=$(curl -sI --max-time 15 \
        -H "Accept-Encoding: gzip, deflate" \
        "${url}" 2>/dev/null || echo "")

    local enc_gzip size_gzip
    enc_gzip=$(echo "$headers_gzip" | grep -i "^content-encoding:" | awk '{print $2}' | tr -d '\r' || echo "—")
    size_gzip=$(curl -so /dev/null --max-time 15 \
        -H "Accept-Encoding: gzip, deflate" \
        -w "%{size_download}" "${url}" 2>/dev/null || echo "?")

    # Medir con brotli
    local headers_br
    headers_br=$(curl -sI --max-time 15 \
        -H "Accept-Encoding: br" \
        "${url}" 2>/dev/null || echo "")

    local enc_br size_br
    enc_br=$(echo "$headers_br" | grep -i "^content-encoding:" | awk '{print $2}' | tr -d '\r' || echo "—")
    size_br=$(curl -so /dev/null --max-time 15 \
        -H "Accept-Encoding: br" \
        -w "%{size_download}" "${url}" 2>/dev/null || echo "?")

    printf "%-30s | gzip: %-8s (%s B) | brotli: %-8s (%s B)\n" \
        "${recurso}" \
        "${enc_gzip:-—}" "${size_gzip}" \
        "${enc_br:-—}" "${size_br}"
}

# ── Encabezado de tabla ───────────────────────────────────────────────────
printf "%-30s | %-20s | %-20s\n" "Recurso" "Accept-Encoding: gzip" "Accept-Encoding: br"
printf "%s\n" "$(printf '─%.0s' {1..80})"

# ── Verificar cada recurso ────────────────────────────────────────────────
for recurso in "${RECURSOS[@]}"; do
    verificar_recurso "${recurso}"
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo " Interpretación de resultados:"
echo "  content-encoding: gzip    → mod_deflate activo, preservado ✓"
echo "  content-encoding: br      → mod_brotli activo, preservado ✓"
echo "  (vacío / identity)        → binario excluido o sin compresión"
echo ""
echo " Si gzip/br aparecen → el túnel cloudflared preserva"
echo " correctamente las cabeceras Content-Encoding de Apache2."
echo "════════════════════════════════════════════════════════════════"
echo ""
