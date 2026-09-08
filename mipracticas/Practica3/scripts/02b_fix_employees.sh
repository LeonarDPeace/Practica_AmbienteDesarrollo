#!/bin/bash
# ==============================================================================
# Script 02b: Arreglo - Crear Páginas de Empleados y Finalizar Configuración Apache
# ==============================================================================
set -e

setup_employee() {
    local username="$1"
    local fullname="$2"
    local role="$3"
    local color="$4"
    local initial="$5"

    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        echo "$username:${username}123" | chpasswd
        echo "Usuario $username creado con éxito."
    else
        echo "Usuario $username ya existe."
    fi

    chmod 755 "/home/$username"
    mkdir -p "/home/$username/public_html"
    chmod 755 "/home/$username/public_html"

    cat > "/home/$username/public_html/index.html" << HTMLEOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pagina Personal - $fullname</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', system-ui, sans-serif; }
        body { background: #0f172a; color: #e2e8f0; min-height: 100vh; display: flex; justify-content: center; align-items: center; padding: 2rem; }
        .card { background: #1e293b; border-radius: 1.5rem; padding: 2.5rem; max-width: 550px; width: 100%; border: 1px solid #334155; box-shadow: 0 20px 40px rgba(0,0,0,0.4); text-align: center; }
        .avatar { width: 90px; height: 90px; border-radius: 50%; background: $color; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 2.2rem; font-weight: 700; margin: 0 auto 1.5rem auto; box-shadow: 0 10px 20px rgba(0,0,0,0.3); }
        h1 { font-size: 1.8rem; color: #fff; margin-bottom: 0.3rem; }
        .role { color: #38bdf8; font-weight: 600; font-size: 1rem; margin-bottom: 1.5rem; }
        .bio { color: #94a3b8; font-size: 0.95rem; line-height: 1.6; margin-bottom: 2rem; }
        .badge { background: rgba(56, 189, 248, 0.1); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.3); padding: 0.3rem 0.8rem; border-radius: 6px; font-size: 0.85rem; display: inline-block; margin-bottom: 1.5rem; }
        .footer-link { color: #94a3b8; font-size: 0.85rem; text-decoration: none; display: inline-block; }
        .footer-link:hover { color: #fff; }
    </style>
</head>
<body>
    <div class="card">
        <div class="avatar">$initial</div>
        <h1>$fullname</h1>
        <div class="role">$role</div>
        <span class="badge">Apache mod_userdir: /~$username/</span>
        <p class="bio">Bienvenido a mi espacio web personal corporativo en <strong>Servicios.com</strong>. Esta pagina se sirve desde el directorio <code>~/public_html</code> de mi cuenta de usuario local en el servidor.</p>
        <a href="http://www.servicios.com" class="footer-link">&larr; Regresar al Portal Principal de Servicios.com</a>
    </div>
</body>
</html>
HTMLEOF
    chown -R "$username:$username" "/home/$username/public_html"
    chmod 644 "/home/$username/public_html/index.html"
    echo "Pagina de $fullname configurada correctamente."
}

echo "=== Configurando Empleados ==="
setup_employee "pedro" "Pedro Perez" "Ingeniero de Infraestructura y Redes" "#2563eb" "P"
setup_employee "maria" "Maria Martinez" "Lider de Desarrollo y Arquitectura Web" "#ec4899" "M"
setup_employee "juan" "Juan Gonzales" "Administrador de Base de Datos y Seguridad" "#10b981" "J"

echo "=== Verificando Configuracion de Apache ==="
apache2ctl configtest
systemctl restart apache2
systemctl status apache2 --no-pager

echo "=== Configuracion Completada Exitosamente ==="
