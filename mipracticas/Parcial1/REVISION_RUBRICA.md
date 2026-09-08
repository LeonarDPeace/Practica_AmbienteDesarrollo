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

- los registros AAAA ya fueron completados en la zona, pero deben validarse en vivo;
- la evidencia de IXFR, sincronizacion automatica y continuidad despues de
   apagar el maestro solo puede obtenerse ejecutando ambas VMs;
- Parte 2 ya tiene script para ratios, ahorro y CPU local de `curl`, pero falta
   regenerar la tabla con una ejecucion final;
- la demostracion de navegador y Wireshark ya esta documentada en
   `GUIA_SUSTENTACION.md`, pero debe hacerse en vivo;
- la pagina personalizada ya contiene los datos de ambos integrantes, pero debe
   demostrarse desde otra red;
- la declaracion de uso de asistentes ya esta escrita y el grupo debe poder
   explicar cada linea.

Estados usados: **Cumple**, **Parcial** y **Pendiente**.

## Parte 1 — DNS (2.0 puntos)

| Puntos | Criterio de la rubrica | Estado | Evidencia o pendiente |
|---:|---|---|---|
| 0.4 | Maestro con zona directa: A, AAAA, CNAME, MX, NS y SOA | Parcial | La zona incluye A/AAAA para `www`, `mail`, `ns1` y `ns2`, además de `ftp` como CNAME. Falta validar la respuesta en la VM. |
| 0.3 | Resolucion inversa PTR | Cumple en archivos | `50.168.192.zone` contiene PTR para `.10` y `.11`; debe demostrarse con `dig` en vivo. |
| 0.4 | NOTIFY, AXFR/IXFR y sincronizacion automatica | Parcial | `notify`, `also-notify`, `ixfr-from-differences` y slave existen. Falta cambiar serial y mostrar el nuevo SOA/log. |
| 0.3 | Transferencia TSIG y bloqueo AXFR no autorizado | Parcial | `allow-transfer` exige `transfer-key`; deben ejecutarse AXFR sin/con clave y mostrar logs. |
| 0.2 | Hardening: recursion no, allow-query y RRL | Cumple en configuracion | Restricciones configuradas; falta demostrar recursion denegada y consultas permitidas. |
| 0.2 | Auditoria queries/transfers/security | Cumple en configuracion | `named_logging.conf` separa categorias; falta mostrar entradas durante pruebas. |
| 0.2 | Continuidad con maestro apagado | Pendiente de evidencia | Detener el maestro y repetir consultas directas/inversas contra el esclavo. |

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

| Puntos | Criterio de la rubrica | Estado | Evidencia o pendiente |
|---:|---|---|---|
| 0.3 | Apache, mod_deflate y DNS local | Parcial | Automatizado; validar servicio y resolucion durante la demo. |
| 0.3 | Gzip niveles 1/6/9 con mediciones | Cumple en script | Cambia niveles y mide; ejecutar en la VM final. |
| 0.3 | Brotli calidades 5/11 | Cumple en script | Cambia calidades y mide; ejecutar en la VM final. |
| 0.3 | Tipos de archivo y exclusion de binarios | Cumple en archivos/provisioning | Corpus completo; ejecutar medicion final. |
| 0.3 | Curl, navegador y Wireshark en vivo | Parcial | La guia contiene pasos exactos; falta realizar la demostracion. |
| 0.2 | Tabla con ratio, ahorro, tiempo/CPU | Parcial | El script genera columnas; falta regenerar tabla final y explicar limite de CPU de `curl`. |
| 0.3 | Analisis critico sustentado con datos | Parcial | Debe responder los cinco puntos con los resultados finales. |

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

| Puntos | Criterio de la rubrica | Estado | Evidencia o pendiente |
|---:|---|---|---|
| 0.4 | Tunel activo y URL publica | Cumple en automatizacion | Quick Tunnel automatizado; mostrar salida y URL real. |
| 0.3 | Pagina personalizada desde otra red | Parcial | Pagina completa; falta abrirla desde datos moviles u otra red. |
| 0.1 | Compresion a traves del tunel | Parcial | Script listo; ejecutar con URL real y mostrar gzip/br. |
| 0.2 | Analisis de seguridad y dos mitigaciones | Parcial | Guia lista; argumentar riesgos y mitigaciones en vivo. |

## Reproducibilidad y entregables

| Requisito general | Estado | Observacion |
|---|---|---|
| Vagrantfile y provisioning | Cumple | El `Vagrantfile` define ambas VMs y ejecuta provisioning en orden. |
| Configuraciones y scripts en GitHub | Cumple en estructura | Estan organizados por parte; hay que revisar que no se suban secretos reales. |
| Comandos utilizados | Cumple parcialmente | Estan en los README, pero se deben ejecutar en la misma secuencia durante la sustentacion. |
| Integridad academica | Cumple en documentacion | La declaracion de uso de Gemini y Claude esta en `README.md` y `ANALISIS_CRITICO.md`; el grupo debe explicarla y comprender el codigo. |

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
- [ ] Wireshark capturando `tcp port 80` o visualizando `http || tcp.port == 80` en la interfaz VirtualBox Host-Only.
- [ ] DevTools Network mostrando `Content-Encoding`, `Vary`, `Size` y `Transferred`.
- [ ] Acceso a la pagina personalizada desde otra red, no solo desde la LAN.
- [ ] Pagina personalizada con nombre, codigo, fecha e identificador reales.
- [ ] Quick Tunnel activo, probado desde otra red y detenido al finalizar.
- [ ] URL real del tunel usada en todas las verificaciones; nunca `XXXX`.
- [ ] Declaracion de uso de IA leida y comprendida por el grupo.
