#!/bin/bash
# ==============================================================================
# Script 02: Configuración Completa de Apache2, VirtualHosts, Control de Acceso y mod_userdir
# ==============================================================================
set -e

echo "=== [1/8] Instalando Apache2 y Utilidades ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y apache2 apache2-utils

echo "=== [2/8] Habilitando Módulos de Apache ==="
a2enmod rewrite
a2enmod auth_basic
a2enmod authz_user
a2enmod userdir
a2enmod headers

echo "=== [3/8] Creando Estructura de Directorios ==="
mkdir -p /var/www/servicios.com/html/inventario
mkdir -p /var/www/servicios.com/html/privado
mkdir -p /var/www/miotrositio.com/html

echo "=== [4/8] Creando Páginas Web HTML5 ==="

# 1. Página principal de servicios.com (main.html)
cat << 'EOF' > /var/www/servicios.com/html/main.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Servicios Corporativos S.A. - Inicio</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --bg: #0f172a;
            --card-bg: rgba(30, 41, 59, 0.85);
            --text: #f8fafc;
            --text-muted: #94a3b8;
            --accent: #38bdf8;
            --border: rgba(255, 255, 255, 0.1);
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', system-ui, -apple-system, sans-serif; }
        body { background: linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%); color: var(--text); min-height: 100vh; display: flex; flex-direction: column; }
        header { background: rgba(15, 23, 42, 0.8); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border); padding: 1.2rem 2rem; display: flex; justify-content: space-between; align-items: center; position: sticky; top: 0; z-index: 10; }
        .logo { font-size: 1.5rem; font-weight: 800; color: #fff; display: flex; align-items: center; gap: 0.6rem; }
        .logo span { color: var(--accent); }
        nav a { color: var(--text-muted); text-decoration: none; margin-left: 1.5rem; font-weight: 500; transition: color 0.2s; }
        nav a:hover { color: var(--accent); }
        .hero { flex: 1; display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center; padding: 4rem 2rem; }
        .badge { background: rgba(56, 189, 248, 0.15); color: var(--accent); border: 1px solid rgba(56, 189, 248, 0.3); padding: 0.4rem 1rem; border-radius: 9999px; font-size: 0.85rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1.5rem; }
        h1 { font-size: 3.2rem; font-weight: 800; line-height: 1.2; margin-bottom: 1.2rem; background: linear-gradient(to right, #ffffff, #94a3b8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        p.subtitle { font-size: 1.25rem; color: var(--text-muted); max-width: 650px; margin-bottom: 2.5rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; width: 100%; max-width: 1000px; margin-top: 1rem; }
        .card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 1rem; padding: 1.8rem; text-align: left; transition: transform 0.2s, border-color 0.2s; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.3); backdrop-filter: blur(8px); }
        .card:hover { transform: translateY(-4px); border-color: var(--accent); }
        .card h3 { font-size: 1.2rem; margin-bottom: 0.6rem; color: #fff; }
        .card p { font-size: 0.95rem; color: var(--text-muted); margin-bottom: 1.2rem; line-height: 1.5; }
        .btn { display: inline-block; background: var(--primary); color: #fff; padding: 0.6rem 1.2rem; border-radius: 0.5rem; text-decoration: none; font-weight: 600; font-size: 0.9rem; transition: background 0.2s; }
        .btn:hover { background: var(--primary-dark); }
        footer { border-top: 1px solid var(--border); padding: 1.5rem; text-align: center; color: var(--text-muted); font-size: 0.9rem; }
    </style>
</head>
<body>
    <header>
        <div class="logo">⚡ Servicios<span>.com</span></div>
        <nav>
            <a href="/">Inicio (main.html)</a>
            <a href="/inventario/">Inventario (&lt;Directory&gt;)</a>
            <a href="/privado/">Privado (.htaccess)</a>
            <a href="http://www.miotrositio.com">Otro Sitio Web</a>
        </nav>
    </header>
    <main class="hero">
        <div class="badge">Servidor Web Apache 2.4 - Ubuntu 22.04 LTS</div>
        <h1>Portal Principal Corporativo</h1>
        <p class="subtitle">Bienvenido a la plataforma web oficial de <strong>servicios.com</strong>. Servidor de alta disponibilidad y gestión segura de contenidos.</p>
        <div class="grid">
            <div class="card">
                <h3>📦 Gestión de Inventario</h3>
                <p>Módulo de acceso restringido para control de existencias. Protegido mediante directivas <code>&lt;Directory&gt;</code> en Apache.</p>
                <a href="/inventario/" class="btn">Acceder a Inventario &rarr;</a>
            </div>
            <div class="card">
                <h3>🔒 Auditoría y Privado</h3>
                <p>Zona administrativa y confidencial controlada a través de directivas distribuidas <code>.htaccess</code>.</p>
                <a href="/privado/" class="btn">Acceder a Privado &rarr;</a>
            </div>
            <div class="card">
                <h3>👥 Páginas de Empleados</h3>
                <p>Espacios personales de publicación habilitados mediante el módulo <code>mod_userdir</code> para el equipo.</p>
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    <a href="/~pedro/" class="btn" style="background: #334155;">Pedro</a>
                    <a href="/~maria/" class="btn" style="background: #334155;">Maria</a>
                    <a href="/~juan/" class="btn" style="background: #334155;">Juan</a>
                </div>
            </div>
        </div>
    </main>
    <footer>
        <p>&copy; 2026 Servicios.com - Práctica 3: Servidor HTTP Apache y Control de Acceso</p>
    </footer>
</body>
</html>
EOF

# 2. Página del directorio protegido /inventario (Requerimiento 2: <Directory>)
cat << 'EOF' > /var/www/servicios.com/html/inventario/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Inventario Corporativo - Acceso Restringido</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', system-ui, sans-serif; }
        body { background: #0b132b; color: #e0e1dd; padding: 2rem; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
        .container { max-width: 800px; width: 100%; background: #1c2541; padding: 2.5rem; border-radius: 12px; border: 1px solid #3a506b; box-shadow: 0 15px 30px rgba(0,0,0,0.5); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #48cae4; padding-bottom: 1rem; margin-bottom: 1.5rem; }
        h1 { color: #48cae4; font-size: 1.8rem; }
        .badge { background: #06d6a0; color: #0b132b; font-weight: 700; padding: 0.3rem 0.8rem; border-radius: 6px; font-size: 0.85rem; }
        table { width: 100%; border-collapse: collapse; margin-top: 1.5rem; }
        th, td { text-align: left; padding: 0.8rem; border-bottom: 1px solid #3a506b; font-size: 0.95rem; }
        th { background: #0b132b; color: #48cae4; }
        .alert { background: rgba(72, 202, 228, 0.1); border-left: 4px solid #48cae4; padding: 1rem; margin-bottom: 1.5rem; font-size: 0.9rem; }
        a.back { color: #48cae4; text-decoration: none; display: inline-block; margin-top: 1.5rem; font-weight: 600; }
        a.back:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📦 Módulo de Inventario</h1>
            <span class="badge">Autenticación &lt;Directory&gt; OK</span>
        </div>
        <div class="alert">
            <strong>Acceso Autorizado:</strong> Has ingresado exitosamente a la zona restringida de inventario validada por directivas de bloque <code>&lt;Directory&gt;</code> en <code>servicios.com.conf</code>.
        </div>
        <table>
            <thead>
                <tr>
                    <th>Código</th>
                    <th>Descripción de Activo</th>
                    <th>Stock</th>
                    <th>Ubicación</th>
                    <th>Estado</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>SRV-001</td>
                    <td>Servidor Dell PowerEdge R640</td>
                    <td>4</td>
                    <td>Rack A-01</td>
                    <td><span style="color: #06d6a0;">Operativo</span></td>
                </tr>
                <tr>
                    <td>SWT-002</td>
                    <td>Switch Cisco Catalyst 2960-X</td>
                    <td>8</td>
                    <td>Rack A-02</td>
                    <td><span style="color: #06d6a0;">Operativo</span></td>
                </tr>
                <tr>
                    <td>RTR-003</td>
                    <td>Router Cisco ISR 4331</td>
                    <td>2</td>
                    <td>Rack B-01</td>
                    <td><span style="color: #06d6a0;">Operativo</span></td>
                </tr>
                <tr>
                    <td>AP-004</td>
                    <td>Access Point Ubiquiti UniFi 6 Pro</td>
                    <td>15</td>
                    <td>Almacén 2</td>
                    <td><span style="color: #ffd166;">En Reserva</span></td>
                </tr>
            </tbody>
        </table>
        <a href="/" class="back">&larr; Volver al Portal Principal</a>
    </div>
</body>
</html>
EOF

# También creamos pagina.html en inventario para compatibilidad con la guía
cp /var/www/servicios.com/html/inventario/index.html /var/www/servicios.com/html/inventario/pagina.html

# 3. Página del directorio protegido /privado (Requerimiento 3: .htaccess)
cat << 'EOF' > /var/www/servicios.com/html/privado/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Área Confidencial - .htaccess</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', system-ui, sans-serif; }
        body { background: #1a1a2e; color: #eaeaea; padding: 2rem; display: flex; flex-direction: column; align-items: center; min-height: 100vh; }
        .container { max-width: 800px; width: 100%; background: #16213e; padding: 2.5rem; border-radius: 12px; border: 1px solid #0f3460; box-shadow: 0 15px 30px rgba(0,0,0,0.5); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #e94560; padding-bottom: 1rem; margin-bottom: 1.5rem; }
        h1 { color: #e94560; font-size: 1.8rem; }
        .badge { background: #e94560; color: #fff; font-weight: 700; padding: 0.3rem 0.8rem; border-radius: 6px; font-size: 0.85rem; }
        .alert { background: rgba(233, 69, 96, 0.1); border-left: 4px solid #e94560; padding: 1rem; margin-bottom: 1.5rem; font-size: 0.95rem; line-height: 1.5; }
        ul { margin-left: 1.5rem; margin-bottom: 1.5rem; line-height: 1.8; color: #cbd5e1; }
        a.back { color: #e94560; text-decoration: none; display: inline-block; font-weight: 600; }
        a.back:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 Área de Auditoría Confidencial</h1>
            <span class="badge">Protección .htaccess OK</span>
        </div>
        <div class="alert">
            <strong>Zona de Acceso Restringido Descentralizado:</strong> Este directorio está protegido mediante el archivo distribuido <code>.htaccess</code> y la directiva <code>AllowOverride AuthConfig</code> en Apache.
        </div>
        <h3 style="margin-bottom: 0.8rem; color: #fff;">Registros de Seguridad y Auditoría</h3>
        <ul>
            <li><strong>Políticas de Seguridad:</strong> HTTP Basic Authentication activo (RFC 7617).</li>
            <li><strong>Archivo de contraseñas:</strong> <code>/etc/apache2/.htpasswd_htaccess</code></li>
            <li><strong>Mecanismo:</strong> Descentralizado vía <code>.htaccess</code> en la carpeta raíz del recurso.</li>
            <li><strong>Nivel de Cifrado de Claves:</strong> Cifrado APR1/MD5 / bcrypt nativo de Apache.</li>
        </ul>
        <a href="/" class="back">&larr; Volver al Portal Principal</a>
    </div>
</body>
</html>
EOF

# 4. Página del VirtualHost miotrositio.com (Requerimiento 4)
cat << 'EOF' > /var/www/miotrositio.com/html/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Bienvenida - miotrositio.com</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', system-ui, sans-serif; }
        body { background: linear-gradient(135deg, #064e3b 0%, #022c22 100%); color: #f0fdf4; min-height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center; padding: 2rem; }
        .card { background: rgba(6, 78, 59, 0.6); border: 1px solid rgba(52, 211, 153, 0.3); border-radius: 1.2rem; padding: 3rem 2.5rem; max-width: 650px; box-shadow: 0 20px 40px rgba(0,0,0,0.4); backdrop-filter: blur(12px); }
        .badge { background: #34d399; color: #022c22; padding: 0.4rem 1rem; border-radius: 9999px; font-weight: 700; font-size: 0.85rem; text-transform: uppercase; margin-bottom: 1.5rem; display: inline-block; }
        h1 { font-size: 2.5rem; font-weight: 800; margin-bottom: 1rem; color: #ffffff; }
        p { color: #a7f3d0; font-size: 1.15rem; line-height: 1.6; margin-bottom: 2rem; }
        .info-box { background: rgba(0,0,0,0.25); border-radius: 0.8rem; padding: 1.2rem; text-align: left; font-size: 0.95rem; color: #d1fae5; border-left: 4px solid #34d399; }
        a.link { color: #34d399; text-decoration: none; font-weight: 600; display: inline-block; margin-top: 1.5rem; }
        a.link:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="card">
        <span class="badge">VirtualHost Apache 2.4</span>
        <h1>¡Bienvenido a miotrositio.com!</h1>
        <p>Este es el segundo sitio web independiente alojado en el mismo servidor físico mediante la tecnología de <strong>Virtual Hosts basados en nombres (Name-Based Virtual Hosting)</strong>.</p>
        <div class="info-box">
            <strong>🌐 Dominio:</strong> www.miotrositio.com / miotrositio.com<br>
            <strong>📁 Raíz de Documentos:</strong> /var/www/miotrositio.com/html<br>
            <strong>⚙️ Servidor:</strong> Apache 2.4 en Ubuntu 22.04 LTS (192.168.50.3)
        </div>
        <a href="http://www.servicios.com" class="link">&larr; Ir al sitio principal servicios.com</a>
    </div>
</body>
</html>
EOF

echo "=== [5/8] Configurando Archivos de Contraseñas (htpasswd) ==="
# Usuarios para inventario (<Directory>): oscar:oscar y eduard:eduard123
htpasswd -b -c /etc/apache2/.htpasswd_inventario oscar oscar
htpasswd -b /etc/apache2/.htpasswd_inventario eduard eduard123

# Usuarios para privado (.htaccess): admin:admin123 y auditor:auditor123
htpasswd -b -c /etc/apache2/.htpasswd_htaccess admin admin123
htpasswd -b /etc/apache2/.htpasswd_htaccess auditor auditor123

chmod 644 /etc/apache2/.htpasswd_inventario
chmod 644 /etc/apache2/.htpasswd_htaccess

echo "=== [6/8] Creando Archivo .htaccess en /var/www/servicios.com/html/privado/.htaccess ==="
cat << 'EOF' > /var/www/servicios.com/html/privado/.htaccess
AuthType Basic
AuthName "Area Restringida via htaccess"
AuthUserFile /etc/apache2/.htpasswd_htaccess
Require valid-user
EOF

echo "=== [7/8] Configurando Virtual Hosts en Apache ==="

# VirtualHost para servicios.com
cat << 'EOF' > /etc/apache2/sites-available/servicios.com.conf
<VirtualHost *:80>
    ServerName servicios.com
    ServerAlias www.servicios.com

    ServerAdmin webmaster@servicios.com
    DocumentRoot /var/www/servicios.com/html

    # Requerimiento 1: Que al entrar al dominio aparezca main.html
    DirectoryIndex main.html index.html

    <Directory /var/www/servicios.com/html>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # Requerimiento 2: Directorio protegido con <Directory>
    <Directory "/var/www/servicios.com/html/inventario">
        AuthType Basic
        AuthName "Acceso Restringido - Inventario Corporativo"
        AuthUserFile /etc/apache2/.htpasswd_inventario
        Require valid-user
    </Directory>

    # Requerimiento 3: Directorio protegido mediante .htaccess
    <Directory "/var/www/servicios.com/html/privado">
        AllowOverride AuthConfig
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/servicios.com_error.log
    CustomLog ${APACHE_LOG_DIR}/servicios.com_access.log combined
</VirtualHost>
EOF

# VirtualHost para miotrositio.com (Requerimiento 4)
cat << 'EOF' > /etc/apache2/sites-available/miotrositio.com.conf
<VirtualHost *:80>
    ServerName miotrositio.com
    ServerAlias www.miotrositio.com

    ServerAdmin webmaster@miotrositio.com
    DocumentRoot /var/www/miotrositio.com/html

    DirectoryIndex index.html

    <Directory /var/www/miotrositio.com/html>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/miotrositio.com_error.log
    CustomLog ${APACHE_LOG_DIR}/miotrositio.com_access.log combined
</VirtualHost>
EOF

# Deshabilitar default y habilitar sitios nuevos
a2dissite 000-default.conf || true
a2ensite servicios.com.conf
a2ensite miotrositio.com.conf

echo "=== [8/8] Configurando Módulo userdir y Cuentas de Empleados (Requerimiento 5) ==="

# Función para crear usuario con public_html si no existe
setup_employee() {
    local username="$1"
    local fullname="$2"
    local role="$3"
    local color="$4"

    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        echo "$username:${username}123" | chpasswd
        echo "Usuario $username creado con éxito."
    fi

    # Asegurar permisos de navegación en el home
    chmod 755 "/home/$username"

    # Crear carpeta public_html
    mkdir -p "/home/$username/public_html"
    chmod 755 "/home/$username/public_html"

    # Crear página personal
    cat << EOF > "/home/$username/public_html/index.html"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Página Personal - $fullname</title>
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
        <div class="avatar">${username:0:1^^}</div>
        <h1>$fullname</h1>
        <div class="role">$role</div>
        <span class="badge">Apache mod_userdir: /~$username/</span>
        <p class="bio">Bienvenido a mi espacio web personal corporativo en <strong>Servicios.com</strong>. Esta página se sirve dinámicamente desde el directorio <code>~/public_html</code> de mi cuenta de usuario local.</p>
        <a href="http://www.servicios.com" class="footer-link">&larr; Regresar al Portal Principal de Servicios.com</a>
    </div>
</body>
</html>
EOF
    chown -R "$username:$username" "/home/$username/public_html"
    chmod 644 "/home/$username/public_html/index.html"
}

setup_employee "pedro" "Pedro Pérez" "Ingeniero de Infraestructura y Redes" "#2563eb"
setup_employee "maria" "Maria Martínez" "Líder de Desarrollo y Arquitectura Web" "#ec4899"
setup_employee "juan" "Juan Gonzáles" "Administrador de Base de Datos y Seguridad" "#10b981"

# Ajustar permisos globales para www-data
chown -R www-data:www-data /var/www/servicios.com
chown -R www-data:www-data /var/www/miotrositio.com
chmod -R 755 /var/www/servicios.com
chmod -R 755 /var/www/miotrositio.com

echo "=== Verificando Configuración de Apache ==="
apache2ctl configtest
systemctl restart apache2
systemctl status apache2 --no-pager

echo "=== ¡Configuración de Apache2 Completada con Éxito! ==="
