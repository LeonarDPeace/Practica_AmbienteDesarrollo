# Revision del parcial frente al enunciado y la rubrica

Fecha de revision: 2026-09-08

Este documento contrasta el PDF del Primer Parcial con los archivos realmente
presentes en `mipracticas/Parcial1`. La sustentacion es presencial y en vivo;
un archivo Markdown no reemplaza las pruebas que el docente solicite ejecutar.

## Resumen ejecutivo

La infraestructura es reproducible y cubre buena parte del flujo: Vagrant,
BIND9 maestro/esclavo, TSIG, Apache, compresion y Quick Tunnel de cloudflared.
Sin embargo, **no se puede afirmar que cumple a la perfeccion todavia**. Los
puntos de mayor riesgo son:

- faltan registros AAAA exigidos para varios nombres;
- no hay evidencia documentada de IXFR, sincronizacion automatica y continuidad
  despues de apagar el maestro;
- Parte 2 tiene mediciones de tamano/tiempo, pero no ratios completos ni CPU;
- faltan las demostraciones de navegador y Wireshark;
- la pagina personalizada conserva placeholders de nombre y codigo;
- debe declararse el uso de asistentes de IA y el grupo debe poder explicar cada
  linea.

Estados usados: **Cumple**, **Parcial** y **Pendiente**.

## Parte 1 — DNS (2.0 puntos)

| Criterio de la rubrica | Estado | Evidencia o pendiente |
|---|---|---|
| Maestro con zona directa: A, AAAA, CNAME, MX, NS y SOA | Parcial | Existen SOA, NS, A, CNAME y MX. La zona solo tiene AAAA para `ns1`; faltan AAAA para `www`, `mail`, `ns2` y no existe un registro `www` AAAA directo. |
| Resolucion inversa PTR | Cumple en archivos | `50.168.192.zone` contiene PTR para `.10` y `.11`; debe demostrarse con `dig` en vivo. |
| NOTIFY, AXFR/IXFR y sincronizacion automatica | Parcial | `notify yes`, `also-notify` y configuracion slave existen. Falta evidencia de IXFR y de modificar serial en maestro para observar actualizacion automatica. |
| Transferencia TSIG y bloqueo AXFR no autorizado | Parcial | `allow-transfer` exige `transfer-key`. Deben ejecutarse AXFR sin clave y con clave, mostrando resultados y logs. |
| Hardening: recursion no, allow-query y RRL | Parcial | `recursion no`, `allow-recursion none` y RRL existen. `allow-query { any; }` no es una restriccion a redes previstas; debe justificarse o limitarse a las redes del laboratorio. |
| Auditoria queries/transfers/security | Cumple en configuracion | `named_logging.conf` separa categorias y archivos; falta mostrar entradas generadas durante las pruebas. |
| Continuidad con maestro apagado | Pendiente de evidencia | El slave esta configurado, pero hay que apuntar un cliente al slave, detener BIND9/VM1 y repetir consultas directas e inversas. |

### Correcciones/pruebas prioritarias de Parte 1

1. Decidir direcciones IPv6 de laboratorio y agregar AAAA validos para `www`,
   `mail`, `ns1` y `ns2`; no usar `::1` para representar todos los servicios.
2. Modificar un registro y aumentar el serial `YYYYMMDDNN`; comprobar el nuevo
   SOA en el esclavo y revisar `xfer-in`, `xfer-out` y `notify`.
3. Ejecutar transferencia AXFR autorizada y no autorizada, y guardar la salida
   que se mostrara en la sustentacion.
4. Verificar desde el esclavo que `dig @192.168.50.11 google.com +short` no
   resuelve por recursion.
5. Revisar si el requisito de `allow-query` permite la red del laboratorio y
   documentar la decision.

## Parte 2 — Apache y compresion (2.0 puntos)

| Criterio de la rubrica | Estado | Evidencia o pendiente |
|---|---|---|
| Apache, mod_deflate y DNS local | Parcial | Apache/VirtualHost estan automatizados y existe DNS para el dominio. Debe validarse que el servicio este activo y que `parcial.empresa.local` resuelva durante la demo. |
| Gzip niveles 1/6/9 con mediciones | Cumple en script | `medir_compresion.sh` cambia la directiva y mide bytes/tiempo. No mide CPU de forma directa. |
| Brotli calidades 5/11 | Cumple en script | El script cambia `BrotliCompressionQuality` y mide bytes/tiempo. Falta registrar costo de CPU. |
| Tipos de archivo y exclusion de binarios | Parcial | Hay HTML, CSS, JS, JSON, SVG, texto, JPG y MP4. Falta `feed.xml`, y CSS/JS/HTML minificado y no minificado no aparecen como pares comparables. |
| Curl, navegador y Wireshark en vivo | Parcial | Hay comandos curl y script de medicion. Falta documentar/realizar evidencia DevTools Network y captura Wireshark. |
| Tabla con ratio, ahorro, tiempo/CPU | Parcial | La tabla contiene bytes, tiempos y algunos ahorros, pero no ratio por algoritmo/nivel ni CPU; el ahorro no esta completo para todas las combinaciones. |
| Analisis critico sustentado con datos | Parcial | `ANALISIS_CRITICO.md` analiza conceptos, pero no responde con todas las mediciones de Parte 2. `tabla_comparativa.md` incluye conclusiones que deben validarse con datos reales. |

### Sobre el MD faltante de Parte 2

Si: faltaba una guia tecnica especifica. `Parte2_Apache/tabla_comparativa.md`
es un resultado de medicion, no un manual de reproduccion. Se agrego
`Parte2_Apache/README_APACHE.md` con funciones de archivos, comandos, criterios
cubiertos y pendientes de sustentacion.

### Correcciones/pruebas prioritarias de Parte 2

1. Completar ratio = comprimido/original y ahorro = `(1 - ratio) * 100` para
   cada recurso y combinacion.
2. Medir CPU o explicar una metodologia reproducible (por ejemplo `time`/`/usr/bin/time`
   en varias repeticiones), separando tiempo de red de costo de compresion.
3. Agregar recursos faltantes (`feed.xml` y una version minificada/no minificada
   cuando el requisito se vaya a demostrar literalmente).
4. Mostrar DevTools > Network y una captura de Wireshark durante la sustentacion.
5. No afirmar que Brotli es “15-25% mejor” sin relacionarlo con los resultados
   concretos de la tabla.

## Parte 3 — Tunel (1.0 punto)

| Criterio de la rubrica | Estado | Evidencia o pendiente |
|---|---|---|
| Tunel activo y URL publica | Cumple en automatizacion | `setup_cloudflared.sh` instala y `iniciar_tunel_cloudflared.sh` inicia Quick Tunnel; la URL solo existe mientras el proceso esta activo. |
| Pagina personalizada desde otra red | Parcial | La pagina existe y se copia al DocumentRoot, pero conserva `Eduardo [Apellido]` y `XXXXXXXX`; deben sustituirse por datos reales antes de sustentar. Tambien debe probarse desde datos moviles u otra red. |
| Compresion a traves del tunel | Parcial | `verificar_encoding.sh` automatiza la comprobacion. Falta ejecutar con una URL real y mostrar `Content-Encoding` gzip/br. |
| Analisis de seguridad y dos mitigaciones | Parcial | El PDF exige argumentacion oral; la documentacion debe mencionar exposicion publica, ausencia de autenticacion, apagar el tunel y al menos otra mitigacion concreta. |

## Reproducibilidad y entregables

| Requisito general | Estado | Observacion |
|---|---|---|
| Vagrantfile y provisioning | Cumple | El `Vagrantfile` define ambas VMs y ejecuta provisioning en orden. |
| Configuraciones y scripts en GitHub | Cumple en estructura | Estan organizados por parte; hay que revisar que no se suban secretos reales. |
| Comandos utilizados | Cumple parcialmente | Estan en los README, pero se deben ejecutar en la misma secuencia durante la sustentacion. |
| Integridad academica | Pendiente de declaracion | Se agrega una nota de uso de Gemini y Claude como asistencia; el grupo debe revisar y comprender el codigo. |

## Checklist de sustentacion

- [ ] Cada integrante puede explicar DNS, Apache y tunel.
- [ ] `named-checkconf` y `named-checkzone` sin errores.
- [ ] AXFR sin TSIG rechazado y AXFR con TSIG exitoso.
- [ ] Actualizacion automatica del serial maestro al esclavo.
- [ ] Consulta directa e inversa con el maestro apagado.
- [ ] Logs `queries`, `transfers` y `security` visibles.
- [ ] Gzip 1/6/9 y Brotli 5/11 demostrados.
- [ ] Tabla con bytes, ratio, ahorro y tiempo/CPU completa.
- [ ] DevTools Network y Wireshark mostrados.
- [ ] Pagina personalizada con nombre, codigo, fecha e identificador reales.
- [ ] Quick Tunnel activo, probado desde otra red y detenido al finalizar.
- [ ] URL real del tunel usada en todas las verificaciones; nunca `XXXX`.
- [ ] Declaracion de uso de IA leida y comprendida por el grupo.
