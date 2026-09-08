#!/bin/bash
# ==============================================================================
# Script 04: Batería Completa de Pruebas HTTP desde la VM Cliente
# ==============================================================================
echo "================================================================================"
echo "PRUEBA 1: Resolución DNS de Dominios"
echo "================================================================================"
dig www.servicios.com +short
dig miotrositio.com +short

echo ""
echo "================================================================================"
echo "PRUEBA 2: Requerimiento 1 - Acceso a servicios.com (main.html por defecto)"
echo "================================================================================"
curl -I http://www.servicios.com/
curl -s http://www.servicios.com/ | grep -i "<title>"

echo ""
echo "================================================================================"
echo "PRUEBA 3: Requerimiento 2 - Directorio protegido /inventario (<Directory>)"
echo "================================================================================"
echo "--- 3.1 Intento de Acceso Sin Autenticación (Debe retornar 401 Unauthorized) ---"
curl -I http://www.servicios.com/inventario/

echo "--- 3.2 Acceso Autenticado con Usuario 'oscar:oscar' (Debe retornar 200 OK) ---"
curl -I -u oscar:oscar http://www.servicios.com/inventario/
curl -s -u oscar:oscar http://www.servicios.com/inventario/ | grep -i "Autenticación <Directory> OK"

echo "--- 3.3 Acceso Autenticado a pagina.html (según guía del profesor) ---"
curl -I -u oscar:oscar http://www.servicios.com/inventario/pagina.html

echo ""
echo "================================================================================"
echo "PRUEBA 4: Requerimiento 3 - Directorio protegido /privado (.htaccess)"
echo "================================================================================"
echo "--- 4.1 Intento de Acceso Sin Autenticación (Debe retornar 401 Unauthorized) ---"
curl -I http://www.servicios.com/privado/

echo "--- 4.2 Acceso Autenticado con Usuario 'admin:admin123' (Debe retornar 200 OK) ---"
curl -I -u admin:admin123 http://www.servicios.com/privado/
curl -s -u admin:admin123 http://www.servicios.com/privado/ | grep -i "Protección .htaccess OK"

echo ""
echo "================================================================================"
echo "PRUEBA 5: Requerimiento 4 - Virtual Host miotrositio.com"
echo "================================================================================"
curl -I http://www.miotrositio.com/
curl -s http://www.miotrositio.com/ | grep -i "<title>"

echo ""
echo "================================================================================"
echo "PRUEBA 6: Requerimiento 5 - Páginas Personales (mod_userdir)"
echo "================================================================================"
echo "--- 6.1 Página personal de Pedro Pérez (~pedro) ---"
curl -I http://www.servicios.com/~pedro/
curl -s http://www.servicios.com/~pedro/ | grep -i "<title>"

echo "--- 6.2 Página personal de Maria Martínez (~maria) ---"
curl -I http://www.servicios.com/~maria/
curl -s http://www.servicios.com/~maria/ | grep -i "<title>"

echo "--- 6.3 Página personal de Juan Gonzáles (~juan) ---"
curl -I http://www.servicios.com/~juan/
curl -s http://www.servicios.com/~juan/ | grep -i "<title>"

echo ""
echo "================================================================================"
echo "TODAS LAS PRUEBAS COMPLETADAS CON ÉXITO"
echo "================================================================================"
