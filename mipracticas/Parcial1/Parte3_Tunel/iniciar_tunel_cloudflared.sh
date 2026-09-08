#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════
#  iniciar_tunel_cloudflared.sh — Túnel seguro hacia Apache2
#  Parcial 1 · Servicios Telemáticos 2026-02
#
#  Usa cloudflared Quick Tunnel (trycloudflare.com):
#    - NO requiere cuenta de Cloudflare
#    - URL pública temporal y aleatoria (válida mientras el proceso corra)
#    - Apunta al puerto 80 de Apache2 en localhost
#
#  Ejecutar DENTRO de parcial_master:
#    vagrant ssh parcial_master
#    bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh
# ══════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║     Túnel Cloudflare Quick (trycloudflare.com)       ║"
echo "║     Parcial 1 · Servicios Telemáticos 2026-02        ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Apuntando a: http://localhost:80 (Apache2)          ║"
echo "║  VirtualHost: parcial.empresa.local                  ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  La URL pública aparecerá en el output.              ║"
echo "║  Ejemplo: https://abc-def-123.trycloudflare.com      ║"
echo "║                                                      ║"
echo "║  COPIAR la URL y usar en verificar_encoding.sh:      ║"
echo "║  bash /vagrant/Parte3_Tunel/verificar_encoding.sh \  ║"
echo "║       https://TU-URL.trycloudflare.com               ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Ctrl+C para detener el túnel.                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

echo "NOTA: Si desea ejecutar el túnel en background (no interactivo), puede usar:\n  nohup bash /vagrant/Parte3_Tunel/iniciar_tunel_cloudflared.sh > /tmp/cloudflared.out 2>&1 &"
echo "Para detener un túnel en background: pkill -f cloudflared  (o kill <PID>)."
echo "Si ejecuta en background, consulte /tmp/cloudflared.out o /tmp/cloudflared.log para la URL pública."

# Verificar que cloudflared está instalado
if ! command -v cloudflared &>/dev/null; then
    echo "ERROR: cloudflared no está instalado."
    echo "Ejecutar: sudo bash /vagrant/Parte3_Tunel/setup_cloudflared.sh"
    exit 1
fi

# Verificar que Apache2 está corriendo
if ! curl -sf http://localhost:80/ &>/dev/null; then
    echo "ADVERTENCIA: Apache2 no responde en localhost:80."
    echo "Verificar: systemctl status apache2"
    echo "Continuando de todos modos..."
    echo ""
fi

# Iniciar túnel (bloquea el terminal — Ctrl+C para detener)
cloudflared tunnel --url http://localhost:80 \
    --no-autoupdate \
    2>&1 | tee /tmp/cloudflared.log
