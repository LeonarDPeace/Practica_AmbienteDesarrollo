#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  setup_apache.sh — Provisioning Apache2 con compresión
#  Parcial 1 · Servicios Telemáticos 2026-02
#  VM: parcial_master  IP: 192.168.50.10
# ══════════════════════════════════════════════════════════════════════════
set -euo pipefail

RECURSOS_SRC="/vagrant/Parte2_Apache/recursos"
PROVISION_SRC="/vagrant/Parte2_Apache/provision"
WWW_DIR="/var/www/parcial"

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 2] APACHE2 + COMPRESIÓN — Inicio"
echo "════════════════════════════════════════════"

# ── 1. Instalar Apache2 y dependencias ───────────────────────────────────
echo "[1/9] Instalando Apache2, mod_brotli y curl..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y apache2 libapache2-mod-brotli curl python3

# ── 2. Habilitar módulos necesarios ─────────────────────────────────────
echo "[2/9] Habilitando módulos: deflate, brotli, headers, rewrite..."
a2enmod deflate brotli headers rewrite

# ── 3. Crear DocumentRoot ────────────────────────────────────────────────
echo "[3/9] Creando DocumentRoot ${WWW_DIR}..."
mkdir -p "${WWW_DIR}"
chown www-data:www-data "${WWW_DIR}"
chmod 755 "${WWW_DIR}"

# ── 4. Copiar recursos estáticos desde /vagrant ──────────────────────────
echo "[4/9] Copiando recursos web estáticos..."
cp "${RECURSOS_SRC}/index.html"    "${WWW_DIR}/"
cp "${RECURSOS_SRC}/styles.css"    "${WWW_DIR}/"
cp "${RECURSOS_SRC}/styles.min.css" "${WWW_DIR}/"
cp "${RECURSOS_SRC}/app.js"        "${WWW_DIR}/"
cp "${RECURSOS_SRC}/app.min.js"    "${WWW_DIR}/"
cp "${RECURSOS_SRC}/image.svg"     "${WWW_DIR}/"
cp "${RECURSOS_SRC}/feed.xml"      "${WWW_DIR}/"

# Copiar página personalizada del túnel
cp "/vagrant/Parte3_Tunel/pagina_personalizada.html" "${WWW_DIR}/"

# ── 5. Generar archivos grandes para prueba de compresión ────────────────
echo "[5/9] Generando texto_grande.txt (>1 MB)..."
python3 - <<'PYEOF'
import random, string
lines = []
for i in range(18000):
    content = ''.join(random.choices(string.ascii_letters + string.digits + ' ,.;:-_', k=75))
    lines.append(f"Linea {i:06d}: {content}")
with open('/var/www/parcial/texto_grande.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
size = __import__('os').path.getsize('/var/www/parcial/texto_grande.txt')
print(f"  >> texto_grande.txt: {size:,} bytes ({size/1024/1024:.2f} MB)")
PYEOF

echo "[5/9] Generando index_grande.html (100-500 KB)..."
python3 - <<'PYEOF'
items = '\n'.join(f'<p>Registro de prueba de compresion HTML {i:05d}: Servicios Telematicos y redes tolerantes a fallos.</p>' for i in range(2600))
with open('/var/www/parcial/index_grande.html', 'w', encoding='utf-8') as f:
    f.write('<!doctype html><html lang="es"><head><meta charset="utf-8"><title>HTML grande</title></head><body>\n')
    f.write(items)
    f.write('\n</body></html>\n')
PYEOF

echo "[5/9] Generando data.json (>100 KB)..."
python3 - <<'PYEOF'
import json, random, string
data = []
words = ['servidor','cliente','red','protocolo','transferencia','zona','registro',
         'dominio','consulta','respuesta','cabecera','compresion','tunel','cifrado']
for i in range(2500):
    data.append({
        "id": i,
        "nombre": ''.join(random.choices(string.ascii_letters, k=15)),
        "descripcion": ' '.join(random.choices(words, k=8)),
        "valor": round(random.uniform(0, 9999.99), 4),
        "activo": random.choice([True, False]),
        "tags": random.choices(words, k=3),
        "timestamp": f"2026-09-08T{i%24:02d}:{i%60:02d}:{i%60:02d}Z"
    })
payload = {"total": len(data), "pagina": 1, "registros": data}
with open('/var/www/parcial/data.json', 'w', encoding='utf-8') as f:
    json.dump(payload, f, indent=2, ensure_ascii=False)
size = __import__('os').path.getsize('/var/www/parcial/data.json')
print(f"  >> data.json: {size:,} bytes ({size/1024:.1f} KB)")
PYEOF

echo "[5/9] Generando foto.jpg (binario dummy ~50 KB)..."
dd if=/dev/urandom bs=1024 count=50 2>/dev/null > "${WWW_DIR}/foto.jpg"

echo "[5/9] Generando video_sample.mp4 (binario dummy ~200 KB)..."
dd if=/dev/urandom bs=1024 count=200 2>/dev/null > "${WWW_DIR}/video_sample.mp4"

# ── 6. Configurar VirtualHost ────────────────────────────────────────────
echo "[6/9] Configurando VirtualHost parcial.empresa.local..."
cp "${PROVISION_SRC}/parcial.empresa.local.conf" /etc/apache2/sites-available/
a2ensite parcial.empresa.local.conf
a2dissite 000-default.conf 2>/dev/null || true

# ── 7. Configurar compresión ─────────────────────────────────────────────
echo "[7/9] Aplicando configuración de compresión..."
cp "${PROVISION_SRC}/compression.conf" /etc/apache2/conf-available/
a2enconf compression

# ── 8. Validar configuración ─────────────────────────────────────────────
echo "[8/9] Validando configuración Apache2..."
apache2ctl configtest

# ── 9. Iniciar Apache2 ───────────────────────────────────────────────────
echo "[9/9] Iniciando Apache2..."
systemctl enable apache2
systemctl restart apache2
sleep 2
systemctl status apache2 --no-pager | head -20

echo ""
echo "════════════════════════════════════════════"
echo " [FASE 2] APACHE2 — Completado"
echo " URL local: http://192.168.50.10"
echo " VirtualHost: parcial.empresa.local"
echo " DocumentRoot: ${WWW_DIR}"
echo ""
echo " Recursos disponibles:"
ls -lh "${WWW_DIR}/"
echo "════════════════════════════════════════════"
echo ""
echo "[DIAGNÓSTICO] Puertos y estado de escucha (puerto 80):"
ss -ltnp | grep ':80' || true
echo "[DIAGNÓSTICO] apache2ctl -S (vhosts y binding):"
apache2ctl -S || true
echo "[DIAGNÓSTICO] Últimas líneas del journal de apache2 (si existe):"
journalctl -u apache2 --no-pager -n 40 || true
