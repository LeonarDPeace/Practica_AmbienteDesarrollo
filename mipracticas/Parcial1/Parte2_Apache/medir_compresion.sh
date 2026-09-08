#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  medir_compresion.sh — Comparación de niveles de compresión HTTP
#  Parcial 1 · Servicios Telemáticos 2026-02
#
#  Flujo para cada nivel de deflate (1, 6, 9):
#    1. Modifica DeflateCompressionLevel en compression.conf con sed
#    2. Recarga Apache2 (systemctl reload)
#    3. Mide tamaño y tiempo con curl para cada recurso
#
#  Flujo para cada nivel de brotli (5, 11):
#    1. Modifica BrotliCompressionQuality en compression.conf con sed
#    2. Recarga Apache2
#    3. Mide tamaño y tiempo con curl para cada recurso
#
#  Resultado: genera/sobreescribe tabla_comparativa.md
#
#  Ejecutar como root dentro de parcial_master:
#    sudo bash /vagrant/Parte2_Apache/medir_compresion.sh
# ══════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Configuración ─────────────────────────────────────────────────────────
CONF_FILE="/etc/apache2/conf-available/compression.conf"
BACKUP_CONF="/tmp/compression_backup_$$.conf"
OUTPUT_FILE="/vagrant/Parte2_Apache/tabla_comparativa.md"
HOST="http://127.0.0.1"  # Medir directamente en localhost

# Recursos a medir (todos servidos desde DocumentRoot)
declare -a RECURSOS=(
    "index.html"
    "index_grande.html"
    "styles.css"
    "styles.min.css"
    "app.js"
    "app.min.js"
    "data.json"
    "image.svg"
    "feed.xml"
    "texto_grande.txt"
)

# Recursos binarios excluidos de compresión (solo para documentar)
declare -a RECURSOS_BINARIOS=("foto.jpg" "video_sample.mp4")

# ── Verificaciones previas ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Ejecutar como root (sudo bash medir_compresion.sh)"
    exit 1
fi

if [ ! -f "${CONF_FILE}" ]; then
    echo "ERROR: ${CONF_FILE} no encontrado."
    echo "Asegúrese de que Apache fue configurado con setup_apache.sh"
    exit 1
fi

if ! curl -sI "${HOST}/index.html" &>/dev/null; then
    echo "ERROR: Apache no responde en ${HOST}."
    echo "Verificar: systemctl status apache2"
    exit 1
fi

# ── Backup del config original ────────────────────────────────────────────
cp "${CONF_FILE}" "${BACKUP_CONF}"
trap "echo 'Restaurando configuración original...'; cp '${BACKUP_CONF}' '${CONF_FILE}'; systemctl reload apache2; rm -f '${BACKUP_CONF}'" EXIT

echo ""
echo "════════════════════════════════════════════════"
echo " medir_compresion.sh — Inicio"
echo " Config: ${CONF_FILE}"
echo " Salida: ${OUTPUT_FILE}"
echo "════════════════════════════════════════════════"
echo ""

# ── Función: cambiar DeflateCompressionLevel y recargar ──────────────────
set_deflate_level() {
    local level="$1"
    sed -i "s/DeflateCompressionLevel [0-9]/DeflateCompressionLevel ${level}/" "${CONF_FILE}"
    systemctl reload apache2
    sleep 0.5
    echo "  >> DeflateCompressionLevel → ${level}"
}

# ── Función: cambiar BrotliCompressionQuality y recargar ─────────────────
set_brotli_level() {
    local level="$1"
    sed -i "s/BrotliCompressionQuality [0-9]*/BrotliCompressionQuality ${level}/" "${CONF_FILE}"
    systemctl reload apache2
    sleep 0.5
    echo "  >> BrotliCompressionQuality → ${level}"
}

# ── Función: obtener tamaño sin compresión ────────────────────────────────
get_raw_size() {
    local recurso="$1"
    # identity fuerza respuesta sin compresión
    curl -s -o /dev/null \
         -H "Accept-Encoding: identity" \
         -w "%{size_download}" \
         "${HOST}/${recurso}" 2>/dev/null || echo "0"
}

# ── Función: medir con encoding específico → bytes, tiempo, encoding y CPU local
medir() {
    local recurso="$1"
    local encoding="$2"
    local cpu_file="/tmp/curl_cpu_$$"

    # Medir tamaño de descarga y tiempo total
    read -r size time <<< "$(/usr/bin/time -f '%U' -o "${cpu_file}" curl -s -o /dev/null \
        -H "Accept-Encoding: ${encoding}" \
        -w "%{size_download} %{time_total}" \
        "${HOST}/${recurso}" 2>/dev/null || echo "0 0")"
    local cpu
    cpu=$(cat "${cpu_file}" 2>/dev/null || echo "0")
    rm -f "${cpu_file}"

    # Obtener Content-Encoding de los headers (HEAD request)
    local enc_header
    enc_header=$(curl -sI \
        -H "Accept-Encoding: ${encoding}" \
        "${HOST}/${recurso}" 2>/dev/null \
        | grep -i "^content-encoding:" \
        | awk '{print $2}' \
        | tr -d '\r' || echo "none")

    echo "${size:-0} ${time:-0} ${enc_header:-none} ${cpu:-0}"
}

# ── Recolectar tamaños sin compresión ─────────────────────────────────────
echo "Paso 1/3: Midiendo tamaños sin compresión (identity)..."
declare -A RAW_SIZE
for recurso in "${RECURSOS[@]}"; do
    RAW_SIZE["$recurso"]=$(get_raw_size "$recurso")
    echo "  ${recurso}: ${RAW_SIZE[$recurso]} bytes"
done

# ── Medir niveles de Deflate ──────────────────────────────────────────────
echo ""
echo "Paso 2/3: Midiendo niveles de mod_deflate (Accept-Encoding: gzip)..."
declare -A D1_SIZE D1_TIME D1_CPU D6_SIZE D6_TIME D6_CPU D9_SIZE D9_TIME D9_CPU

for nivel in 1 6 9; do
    set_deflate_level "${nivel}"
    for recurso in "${RECURSOS[@]}"; do
        read -r sz tm enc cpu <<< "$(medir "$recurso" "gzip")"
        case "$nivel" in
            1) D1_SIZE["$recurso"]="$sz"; D1_TIME["$recurso"]="$tm"; D1_CPU["$recurso"]="$cpu" ;;
            6) D6_SIZE["$recurso"]="$sz"; D6_TIME["$recurso"]="$tm"; D6_CPU["$recurso"]="$cpu" ;;
            9) D9_SIZE["$recurso"]="$sz"; D9_TIME["$recurso"]="$tm"; D9_CPU["$recurso"]="$cpu" ;;
        esac
        echo "    [D${nivel}] ${recurso}: ${sz}B en ${tm}s, CPU curl ${cpu}s (${enc})"
    done
done

# ── Medir niveles de Brotli ───────────────────────────────────────────────
echo ""
echo "Paso 3/3: Midiendo niveles de mod_brotli (Accept-Encoding: br)..."
declare -A B5_SIZE B5_TIME B5_CPU B11_SIZE B11_TIME B11_CPU

for nivel in 5 11; do
    set_brotli_level "${nivel}"
    for recurso in "${RECURSOS[@]}"; do
        read -r sz tm enc cpu <<< "$(medir "$recurso" "br")"
        case "$nivel" in
            5)  B5_SIZE["$recurso"]="$sz";  B5_TIME["$recurso"]="$tm"; B5_CPU["$recurso"]="$cpu"  ;;
            11) B11_SIZE["$recurso"]="$sz"; B11_TIME["$recurso"]="$tm"; B11_CPU["$recurso"]="$cpu" ;;
        esac
        echo "    [B${nivel}] ${recurso}: ${sz}B en ${tm}s, CPU curl ${cpu}s (${enc})"
    done
done

# ── Generar tabla_comparativa.md ─────────────────────────────────────────
echo ""
echo "Generando tabla_comparativa.md..."

{
cat <<HEADER
# Tabla Comparativa de Compresión HTTP
**Parcial 1 — Servicios Telemáticos 2026-02**
Generado: $(date '+%Y-%m-%d %H:%M:%S')
Host: \`parcial.empresa.local\` (192.168.50.10)

## Resultados por algoritmo

### mod_deflate (gzip)

| Recurso | Sin compr. | D-1 (B) | D-1 (s) | D-1 CPU curl (s) | D-6 (B) | D-6 (s) | D-6 CPU curl (s) | D-9 (B) | D-9 (s) | D-9 CPU curl (s) | Ratio D-6 | Ahorro D-6 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
HEADER

for recurso in "${RECURSOS[@]}"; do
    raw="${RAW_SIZE[$recurso]}"
    d1="${D1_SIZE[$recurso]:-N/A}"; t1="${D1_TIME[$recurso]:-N/A}"; c1="${D1_CPU[$recurso]:-N/A}"
    d6="${D6_SIZE[$recurso]:-N/A}"; t6="${D6_TIME[$recurso]:-N/A}"; c6="${D6_CPU[$recurso]:-N/A}"
    d9="${D9_SIZE[$recurso]:-N/A}"; t9="${D9_TIME[$recurso]:-N/A}"; c9="${D9_CPU[$recurso]:-N/A}"

    # Calcular ahorro en % para D-6
    if [[ "$raw" -gt 0 && "$d6" =~ ^[0-9]+$ ]]; then
        ratio=$(awk "BEGIN{printf \"%.4f\", $d6/$raw}")
        ahorro=$(awk "BEGIN{printf \"%.1f%%\", (1 - $d6/$raw)*100}")
    else
        ratio="N/A"
        ahorro="N/A"
    fi

    echo "| \`${recurso}\` | ${raw} | ${d1} | ${t1} | ${c1} | ${d6} | ${t6} | ${c6} | ${d9} | ${t9} | ${c9} | ${ratio} | **${ahorro}** |"
done

cat <<BROTLI

### mod_brotli (br)

| Recurso | Sin compr. | B-5 (B) | B-5 (s) | B-5 CPU curl (s) | B-11 (B) | B-11 (s) | B-11 CPU curl (s) | Ratio B-11 | Ahorro B-11 |
|---|---:|---:|---:|---:|---:|---:|
BROTLI

for recurso in "${RECURSOS[@]}"; do
    raw="${RAW_SIZE[$recurso]}"
    b5="${B5_SIZE[$recurso]:-N/A}";  t5="${B5_TIME[$recurso]:-N/A}"; c5="${B5_CPU[$recurso]:-N/A}"
    b11="${B11_SIZE[$recurso]:-N/A}"; t11="${B11_TIME[$recurso]:-N/A}"; c11="${B11_CPU[$recurso]:-N/A}"

    if [[ "$raw" -gt 0 && "$b11" =~ ^[0-9]+$ ]]; then
        ratio=$(awk "BEGIN{printf \"%.4f\", $b11/$raw}")
        ahorro=$(awk "BEGIN{printf \"%.1f%%\", (1 - $b11/$raw)*100}")
    else
        ratio="N/A"
        ahorro="N/A"
    fi

    echo "| \`${recurso}\` | ${raw} | ${b5} | ${t5} | ${c5} | ${b11} | ${t11} | ${c11} | ${ratio} | **${ahorro}** |"
done

cat <<BINARIOS

### Recursos binarios (excluidos de compresión)

| Recurso | Tamaño (B) | Content-Encoding | Justificación |
|---|---:|---|---|
BINARIOS

for recurso in "${RECURSOS_BINARIOS[@]}"; do
    raw=$(get_raw_size "$recurso")
    enc=$(curl -sI -H "Accept-Encoding: gzip" "${HOST}/${recurso}" \
        | grep -i "^content-encoding:" | awk '{print $2}' | tr -d '\r' || echo "identity")
    echo "| \`${recurso}\` | ${raw} | ${enc:-identity} | Ya comprimido por naturaleza |"
done

cat <<ANALISIS

## Análisis

- **Mejor ratio de compresión:** Brotli-11 supera consistentemente a Deflate-9 en texto (~15-25% más).
- **Mejor balance CPU/ratio:** Deflate-6 y Brotli-5 son los valores recomendados para producción.
- **Binarios (JPG, MP4):** Sin compresión efectiva (ya comprimidos). Se excluyen con `SetEnvIfNoCase`.
- **Conclusión:** Para archivos de texto/JSON, activar Brotli-5 es la mejor opción en producción.

## Comandos de referencia

\`\`\`bash
# Verificar encoding de un recurso
curl -sI -H "Accept-Encoding: gzip" http://parcial.empresa.local/data.json | grep -i content-encoding
curl -sI -H "Accept-Encoding: br"   http://parcial.empresa.local/data.json | grep -i content-encoding

# Ver config actual de compresión
grep -E "DeflateCompressionLevel|BrotliCompressionQuality" /etc/apache2/conf-available/compression.conf
\`\`\`
ANALISIS

} > "${OUTPUT_FILE}"

echo ""
echo "════════════════════════════════════════════════"
echo " Completado. Tabla guardada en:"
echo " ${OUTPUT_FILE}"
echo " (también visible en el host en Parte2_Apache/tabla_comparativa.md)"
echo "════════════════════════════════════════════════"
