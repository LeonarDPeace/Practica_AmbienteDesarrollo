# GUÍA EXHAUSTIVA DE SUSTENTACIÓN EN VIVO: PRÁCTICA 1 - SERVIDOR FTP (VSFTPD)

**Estudiante:** Eduard Criollo Yule  
**Asignatura:** Ambiente de Desarrollo / Servicios Telemáticos  
**Profesor Evaluador:** Prof. Oscar Mondragón  
**Repositorio:** `Practica_AmbienteDesarrollo`  
**Directorio de Trabajo:** `mipracticas/Practica1`  

---

## 1. Preparación del Entorno antes de la Sustentación

Antes de iniciar la evaluación con el profesor, asegúrate de tener abiertas las siguientes **5 consolas/herramientas** distribuidas en tu pantalla:

```
+-----------------------------------------------------------------------------------+
|                            MAPA DE CONSOLAS EN PANTALLA                           |
+-----------------------------------------------------------------------------------+
| [CONSOLA 1: HOST WINDOWS]       | [CONSOLA 2: VM SERVIDOR (SSH)]                  |
| CMD / PowerShell                | vagrant@servidor:~$ (IP: 192.168.50.3)          |
| Ruta: .../Practica_AmbienteDes...| Uso: Configuración vsftpd, permisos, usuarios   |
+---------------------------------+-------------------------------------------------+
| [CONSOLA 3: VM CLIENTE (SSH)]   | [HERRAMIENTA 4: FILEZILLA GUI]                  |
| vagrant@cliente:~$ (192.168.50.2)| Host: 192.168.50.3 | User: vagrant | Port: 21   |
| Uso: Cliente interactivo `ftp`  | Uso: Subida y descarga visual de archivos       |
+---------------------------------+-------------------------------------------------+
| [HERRAMIENTA 5: WIRESHARK PACKET SNIFFER]                                         |
| Interfaz: Ethernet 3 (VirtualBox Host-Only: 192.168.50.1)                         |
| Filtro de visualización: `ftp || ftp-data`                                       |
+-----------------------------------------------------------------------------------+
```

---

## 2. Guión Paso a Paso de Exposición en Vivo (Puntos 1 al 11)

### Punto 1: Tipos de Usuarios en FTP (Teoría Fundamental)
* **Consola a Usar:** Presentación Oral sin comando.
* **Qué Exponer al Profesor:**
  > *"Profesor Mondragón, el servicio FTP clasifica a los usuarios en tres categorías: los **anónimos**, que se mapean al usuario `ftp` del SO para descargas públicas masivas sin clave; los **reales**, que corresponden a cuentas locales con shell y su propio directorio `/home` en `/etc/passwd`; y los **invitados**, que son usuarios virtuales autenticados en bases de datos externas pero mapeados a una cuenta restringida única del sistema sin shell interactivo."*

---

### Punto 2: Habilitación de Escritura (`write_enable=YES`)
* **Consola a Usar:** `[CONSOLA 2: VM SERVIDOR]`
* **Comando a Mostrar/Ejecutar:**
  ```bash
  grep -N "^write_enable" /etc/vsftpd.conf
  ```
* **Qué Exponer al Profesor:**
  > *"Para permitir cualquier modificación en el servidor remoto como subir archivos (`STOR`), borrar (`DELE`) o crear carpetas (`MKD`), es indispensable activar `write_enable=YES` en `/etc/vsftpd.conf`. Sin esta directiva, vsftpd opera en modo de solo lectura."*
* **Evidencia Asociada:** `01_config_write_enable.png`

---

### Punto 3: Creación de Usuarios Reales y Verificación de Servicio
* **Consolas a Usar:** `[CONSOLA 2: VM SERVIDOR]` $\rightarrow$ `[CONSOLA 3: VM CLIENTE]`
* **Comandos en Vivo:**
  * En **Servidor:**
    ```bash
    sudo systemctl status vsftpd
    id usuario_real
    ```
  * En **Cliente:**
    ```bash
    ftp 192.168.50.3
    # Login: usuario_real | Clave: [tu_clave]
    ftp> pwd
    ```
* **Qué Exponer al Profesor:**
  > *"Creamos el usuario de sistema `usuario_real` con `sudo adduser`. Al verificar con `systemctl status vsftpd` confirmamos que el demonio está activo. Luego, nos conectamos vía FTP desde la VM cliente e invocamos `pwd`. El servidor retorna `/home/usuario_real`, demostrando que los usuarios reales inician por defecto en su directorio home de Linux."*
* **Evidencias Asociadas:** `02_crear_usuario_real.png`, `03_servicio_vsftpd_activo.png`, `04_login_usuario_real_pwd.png`

---

### Punto 4: Transferencia Bidireccional de Archivos (`get` y `put`)
* **Consola a Usar:** `[CONSOLA 3: VM CLIENTE]`
* **Comandos en Vivo:**
  ```bash
  ftp> ls
  ftp> get servidor_file.txt
  ftp> put cliente_file.txt
  ftp> ls
  ```
* **Qué Exponer al Profesor:**
  > *"Probamos la transferencia de archivos cliente-servidor: `get` descarga el archivo desde el servidor remoto escribiendo en el sistema de archivos del cliente, y `put` transmite un archivo local hacia el servidor remoto mediante el comando interno `STOR`. Validamos ambos archivos con `ls`."*
* **Evidencias Asociadas:** `05_crear_archivo_servidor.png`, `06_crear_archivo_cliente.png`, `07_ftp_transferencia_archivos.png`

---

### Punto 5: Personalización del Mensaje de Bienvenida (`ftpd_banner`)
* **Consola a Usar:** `[CONSOLA 2: SERVIDOR]` $\rightarrow$ `[CONSOLA 3: CLIENTE]`
* **Comando/Configuración:**
  * En **Servidor:** `grep "ftpd_banner" /etc/vsftpd.conf`
  * En **Cliente:** `ftp 192.168.50.3`
* **Qué Exponer al Profesor:**
  > *"Configuramos `ftpd_banner=Bienvenido al Servidor FTP de Servicios Telematicos.` en `/etc/vsftpd.conf`. Al iniciar la sesión desde el cliente, el servidor envía el código `220` adjuntando nuestro texto personalizado antes de solicitar las credenciales."*
* **Evidencias Asociadas:** `08_config_editar_banner.png`, `09_config_ftpd_banner.png`, `10_verificacion_banner_bienvenida.png`

---

### Punto 6: Enjaulamiento de Usuarios Reales (*Chroot Jail*)
* **Consolas a Usar:** `[CONSOLA 2: SERVIDOR]` $\rightarrow$ `[CONSOLA 3: CLIENTE]`
* **Comandos en Vivo:**
  * En **Servidor:**
    ```bash
    grep -E "chroot_local_user|allow_writeable_chroot" /etc/vsftpd.conf
    ```
  * En **Cliente:**
    ```bash
    ftp 192.168.50.3
    # Login: usuario_real
    ftp> pwd
    ftp> cd ..
    ftp> pwd
    ```
* **Qué Exponer al Profesor:**
  > *"El enjaulamiento o `chroot` confina al usuario a su propio home para evitar que escale directorios. Con `chroot_local_user=YES` y `allow_writeable_chroot=YES`, al intentar ejecutar `cd ..` dentro de FTP, la raíz virtual `/` pasa a ser su propia carpeta personal. Si cambiamos `chroot_local_user` a `NO`, el usuario podría navegar libremente hasta la raíz real `/` del sistema operativo, leyendo carpetas sensibles como `/etc` o `/var`."*
* **Evidencias Asociadas:** `11_config_abrir_vsftpd_chroot.png` a `17_prueba_navegacion_chroot_list.png`

---

### Punto 7: Restricción de Usuarios Reales por Seguridad (`userlist`)
* **Consolas a Usar:** `[CONSOLA 2: SERVIDOR]` $\rightarrow$ `[CONSOLA 3: CLIENTE]`
* **Comandos en Vivo:**
  * En **Servidor:**
    ```bash
    grep -E "userlist_enable|userlist_deny" /etc/vsftpd.conf
    cat /etc/vsftpd.user_list
    ```
  * En **Cliente:**
    ```bash
    ftp 192.168.50.3
    # Login: usuario_real
    ```
* **Qué Exponer al Profesor:**
  > *"Por motivos de seguridad, para impedir que usuarios reales del SO ingresen por FTP, podemos usar `local_enable=NO` (bloqueo global) o implementar una lista de denegación con `userlist_enable=YES` y `userlist_deny=YES`. Al colocar a `usuario_real` en `/etc/vsftpd.user_list`, el servidor rechaza inmediatamente la conexión con `530 Permission denied`."*
* **Evidencias Asociadas:** `18_config_abrir_vsftpd_restriccion.png` a `24_verificacion_login_denegado.png`

---

### Punto 8: Configuración de FTP Anónimo
* **Consolas a Usar:** `[CONSOLA 2: SERVIDOR]` $\rightarrow$ `[CONSOLA 3: CLIENTE]`
* **Comandos en Vivo:**
  * En **Servidor:**
    ```bash
    ls -ld /var/anonymous /var/anonymous/publico
    grep -E "anonymous_enable|anon_root|anon_upload_enable" /etc/vsftpd.conf
    ```
  * En **Cliente:**
    ```bash
    ftp 192.168.50.3
    # Name: anonymous | Password: (enter en blanco)
    ftp> cd publico
    ftp> get anonDescarga
    ftp> put cliente_file.txt
    ```
* **Qué Exponer al Profesor:**
  > *"Habilitamos `anonymous_enable=YES` definiendo la raíz personalizada `anon_root=/var/anonymous/`. Para cumplir las reglas de seguridad de vsftpd, la carpeta raíz `/var/anonymous` tiene permisos `555` (lectura/ejecución sin escritura), mientras que la subcarpeta `/var/anonymous/publico` tiene `777` con `anon_upload_enable=YES` para permitir subir archivos sin comprometer la seguridad del sistema."*
* **Evidencias Asociadas:** `25_crear_directorios_anonimos.png` a `30_prueba_ftp_anonimo_cliente.png`

---

### Punto 9: Cliente Gráfico FileZilla desde el Anfitrión Windows
* **Herramientas a Usar:** `[CONSOLA 1: HOST WINDOWS]` $\rightarrow$ `[HERRAMIENTA 4: FILEZILLA]`
* **Demostración en Vivo:**
  1. En CMD Windows: `ping 192.168.50.3` (demostrar conectividad desde la máquina real al servidor virtual).
  2. En FileZilla GUI: Mostrar conexión rápida a `192.168.50.3`, usuario `vagrant`, listar `/home/vagrant/mipracticas/Practica1` y arrastrar un archivo.
* **Qué Exponer al Profesor:**
  > *"Validamos la conectividad IP desde la máquina anfitriona hacia la interfaz VirtualBox Host-Only (`192.168.50.3`). Luego, mediante el cliente gráfico FileZilla, nos conectamos en el puerto 21 y realizamos transferencias de archivos por arrastrar y soltar."*
* **Evidencias Asociadas:** `31_ping_host_a_servidor.png` a `34_filezilla_descarga_archivo.png`

---

### Puntos 10 y 11: Captura con Wireshark y Análisis del Modo de Conexión
* **Herramienta a Usar:** `[HERRAMIENTA 5: WIRESHARK]`
* **Filtro Wireshark:** `ftp || ftp-data`
* **Demostración en Vivo:**
  1. Mostrar paquetes capturados en la interfaz `Ethernet 3` (`192.168.50.1`).
  2. Seleccionar un paquete de comando `USER` o `PASS` y mostrar en la sección *Follow TCP Stream* las credenciales visibles en texto claro.
  3. Mostrar la trama con la respuesta `229 Entering Extended Passive Mode (|||53514|)` y la posterior apertura del puerto 53514 para el canal de datos.
* **Evidencias Asociadas:** `35_host_ipconfig_interfaz.png`, `36_filezilla_trafico_wireshark.png`

---

## 3. Explicación Maestra: Modo Activo (PORT) vs Modo Pasivo (PASV/EPSV)

Si el Profesor Oscar Mondragón te pide explicar la diferencia de modos de conexión, responde con este diagrama y argumento:

### Tabla Comparativa de Arquitectura

| Característica | Modo Activo (PORT) | Modo Pasivo (PASV / EPSV) |
| :--- | :--- | :--- |
| **Comando del Cliente** | `PORT h1,h2,h3,h4,p1,p2` | `PASV` o `EPSV` |
| **Canal de Control (Puerto 21)** | Cliente (puerto $N$) $\rightarrow$ Servidor (Puerto 21) | Cliente (puerto $N$) $\rightarrow$ Servidor (Puerto 21) |
| **Origen del Canal de Datos** | **Servidor (Puerto 20)** $\rightarrow$ Cliente (Puerto $N+1$) | **Cliente (Puerto $N+1$)** $\rightarrow$ Servidor (Puerto $P > 1024$) |
| **Iniciador de Conexión de Datos**| El **Servidor** se conecta proactivamente al Cliente | El **Cliente** se conecta proactivamente al Servidor |
| **Problema con Firewalls / NAT** | **FALLA:** El firewall del cliente bloquea la conexión entrante desde el puerto 20 del servidor. | **FUNCIONA:** El firewall del cliente permite la conexión saliente hacia el puerto $P$ del servidor. |

### Explicación Verbal Recomendada
> *"Profesor, en el **Modo Activo**, el cliente le dice al servidor: 'Conéctate a mi puerto N+1 desde tu puerto 20'. Como esa conexión nace en el servidor e intenta entrar al cliente, la mayoría de firewalls residenciales o routers NAT en el cliente la bloquean por considerarla tráfico entrante no solicitado.*  
> *Por ello, en nuestra práctica FileZilla utilizó el **Modo Pasivo (EPSV)**. En este modo, el cliente envía `EPSV`, el servidor abre un puerto efímero de escucha (ej. 53514) y responde `229 Entering Extended Passive Mode`. Finalmente, es el cliente el que inicia la conexión saliente de datos hacia ese puerto del servidor. Como ambas conexiones (control y datos) son salientes desde el cliente, atraviesan los cortafuegos sin inconvenientes."*

---

## 4. Banco de Preguntas Desafiantes del Evaluador y Respuestas de Alto Nivel

### Pregunta 1: ¿Por qué el protocolo FTP requiere dos canales TCP independientes en lugar de uno solo?
* **Respuesta de Nivel Experto:**
  > *"FTP utiliza una arquitectura fuera de banda (*out-of-band*). El **canal de control** (puerto 21) se mantiene abierto durante toda la sesión exclusivamente para transmitir comandos y códigos de respuesta ASCII. El **canal de datos** se abre dinámicamente solo durante la transferencia de un archivo o listado de directorio y se cierra al finalizar. Esto permite enviar comandos de control (como abortar una transferencia `ABOR`) mientras un archivo pesado se está descargando en el canal de datos."*

### Pregunta 2: ¿Qué sucede si le asignamos permisos `777` al directorio raíz del chroot anónimo (`/var/anonymous/`) y por qué vsftpd arroja un error 500?
* **Respuesta de Nivel Experto:**
  > *"vsftpd incluye un mecanismo de defensa proactivo contra ataques de elevación de privilegios en entornos `chroot`. Si la raíz del enjaulamiento tiene permisos de escritura para el usuario de la sesión, un atacante podría sobrescribir librerías de sistema enjauladas o enlaces simbólicos. Por ello, si la raíz es escribible, vsftpd rechaza la conexión con error `500 OOPS: vsftpd: refusing to run with writable root inside chroot()`. La solución es mantener la raíz con permisos `555` y crear una subcarpeta (ej. `publico`) con permisos `777` o usar `allow_writeable_chroot=YES`."*

### Pregunta 3: ¿Cuál es la diferencia exacta en vsftpd entre tener `userlist_deny=YES` y `userlist_deny=NO`?
* **Respuesta de Nivel Experto:**
  > *"Con `userlist_deny=YES`, el archivo `/etc/vsftpd.user_list` actúa como una **Lista Negra (Blacklist)**: todos los usuarios ingresan excepto los que estén escritos en la lista. Si se cambia a `userlist_deny=NO`, el archivo se transforma en una **Lista Blanca (Whitelist)**: el acceso se deniega a todos los usuarios del sistema, excepto a aquellos expresamente incluidos en dicho archivo."*

### Pregunta 4: En Wireshark observamos la clave del usuario en texto claro. ¿Por qué ocurre esto y qué alternativa debe implementarse en producción?
* **Respuesta de Nivel Experto:**
  > *"Ocurre porque el protocolo FTP nativo (RFC 959) fue diseñado en 1985 sin mecanismos de cifrado en la capa de aplicación, transmitiendo los comandos `USER` y `PASS` en texto claro. En un entorno de producción real, esto se soluciona mediante **FTPS (FTP over TLS/SSL)** usando las directivas `ssl_enable=YES` en vsftpd para cifrar el túnel, o migrando directamente a **SFTP**, que corre sobre el subsistema de SSH en el puerto 22."*

### Pregunta 5: Si tuviéramos un firewall en el Servidor Ubuntu, ¿qué rango de puertos deberíamos abrir en `/etc/vsftpd.conf` para garantizar el Modo Pasivo?
* **Respuesta de Nivel Experto:**
  > *"Deberíamos restringir el rango de puertos pasivos en `/etc/vsftpd.conf` agregando directivas como `pasv_min_port=40000` y `pasv_max_port=40100`, y luego abrir en el firewall `ufw` el puerto de control `21/tcp` junto con el rango de puertos de datos `40000:40100/tcp`."*
