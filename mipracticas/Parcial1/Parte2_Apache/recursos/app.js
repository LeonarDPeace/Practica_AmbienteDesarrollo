/**
 * app.js — Script JavaScript para Parcial 1 · Servicios Telemáticos 2026-02
 * Recurso de prueba para medición de compresión HTTP
 */

'use strict';

// ── Módulo: Información del sistema ──────────────────────────────────────
const SistemaInfo = {
    version: '1.0.0',
    parcial: 1,
    materia: 'Servicios Telemáticos',
    anio: 2026,
    semestre: '2026-02',

    getInfo() {
        return {
            version: this.version,
            parcial: this.parcial,
            materia: this.materia,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
        };
    },

    imprimirInfo() {
        console.table(this.getInfo());
    }
};

// ── Módulo: Medición de compresión ────────────────────────────────────────
const CompresionMonitor = {
    recursos: [
        { nombre: 'index.html',       tipo: 'HTML',  icono: '📄' },
        { nombre: 'styles.css',       tipo: 'CSS',   icono: '🎨' },
        { nombre: 'app.js',           tipo: 'JS',    icono: '⚙️' },
        { nombre: 'data.json',        tipo: 'JSON',  icono: '📊' },
        { nombre: 'image.svg',        tipo: 'SVG',   icono: '🖼️' },
        { nombre: 'texto_grande.txt', tipo: 'TXT',   icono: '📝' },
        { nombre: 'foto.jpg',         tipo: 'JPG',   icono: '🖼️' },
        { nombre: 'video_sample.mp4', tipo: 'MP4',   icono: '🎬' },
    ],

    async medirRecurso(nombre, encoding = 'gzip') {
        const inicio = performance.now();
        try {
            const resp = await fetch(`/${nombre}`, {
                headers: { 'Accept-Encoding': encoding }
            });
            const buffer = await resp.arrayBuffer();
            const fin = performance.now();
            const encodingRecibido = resp.headers.get('Content-Encoding') || 'ninguno';
            return {
                nombre,
                encoding: encodingRecibido,
                tamanio: buffer.byteLength,
                tiempo: Math.round(fin - inicio),
                status: resp.status
            };
        } catch (err) {
            return { nombre, error: err.message };
        }
    },

    async medirTodos() {
        console.group('📊 Medición de compresión desde el navegador');
        const resultados = [];
        for (const recurso of this.recursos) {
            const gzip   = await this.medirRecurso(recurso.nombre, 'gzip');
            const brotli = await this.medirRecurso(recurso.nombre, 'br');
            resultados.push({ recurso: recurso.nombre, gzip, brotli });
            console.log(`${recurso.icono} ${recurso.nombre}:`, { gzip, brotli });
        }
        console.groupEnd();
        return resultados;
    }
};

// ── Módulo: DNS Info ──────────────────────────────────────────────────────
const DNSInfo = {
    maestro: '192.168.50.10',
    esclavo: '192.168.50.11',
    zona:    'empresa.local',

    registros: [
        { tipo: 'NS',    nombre: '@',       valor: 'ns1.empresa.local.' },
        { tipo: 'NS',    nombre: '@',       valor: 'ns2.empresa.local.' },
        { tipo: 'A',     nombre: 'ns1',     valor: '192.168.50.10'      },
        { tipo: 'A',     nombre: 'ns2',     valor: '192.168.50.11'      },
        { tipo: 'A',     nombre: 'parcial', valor: '192.168.50.10'      },
        { tipo: 'CNAME', nombre: 'www',     valor: 'parcial'            },
        { tipo: 'MX',    nombre: '@',       valor: '10 mail'            },
        { tipo: 'AAAA',  nombre: 'ns1',     valor: '::1'                },
        { tipo: 'PTR',   nombre: '10',      valor: 'ns1.empresa.local.' },
        { tipo: 'PTR',   nombre: '11',      valor: 'ns2.empresa.local.' },
    ],

    imprimirZona() {
        console.group(`🌐 Zona DNS: ${this.zona}`);
        console.log(`Maestro: ${this.maestro} | Esclavo: ${this.esclavo}`);
        console.table(this.registros);
        console.groupEnd();
    }
};

// ── Módulo: UI Helpers ────────────────────────────────────────────────────
const UI = {
    mostrarFechaActual() {
        const elementos = document.querySelectorAll('[data-fecha-actual]');
        const ahora = new Date().toLocaleString('es-CO', {
            timeZone: 'America/Bogota',
            dateStyle: 'full',
            timeStyle: 'medium'
        });
        elementos.forEach(el => { el.textContent = ahora; });
    },

    resaltarRecursoActivo() {
        const ruta = window.location.pathname.split('/').pop() || 'index.html';
        document.querySelectorAll('.recurso-item').forEach(el => {
            const nombre = el.querySelector('.nombre');
            if (nombre && nombre.textContent === ruta) {
                el.style.borderColor = 'var(--color-accent)';
                el.style.background  = 'rgba(56, 189, 248, 0.12)';
            }
        });
    },

    agregarIndicadorCompresion() {
        const header = document.querySelector('.site-header .subtitle');
        if (!header) return;
        const badge = document.createElement('span');
        badge.style.cssText = `
            display: inline-block; margin-left: 1rem;
            background: rgba(25, 135, 84, 0.2); color: #6ee7b7;
            font-size: 0.75rem; font-weight: 600; letter-spacing: 0.06em;
            padding: 0.2rem 0.6rem; border-radius: 999px;
            border: 1px solid rgba(110, 231, 183, 0.3); text-transform: uppercase;
        `;
        badge.textContent = '⚡ Compresión activa';
        header.appendChild(badge);
    }
};

// ── Módulo: Estadísticas de rendimiento ──────────────────────────────────
const Rendimiento = {
    obtener() {
        if (!window.performance || !window.performance.timing) return null;
        const t = window.performance.timing;
        return {
            domContentLoaded: t.domContentLoadedEventEnd - t.navigationStart,
            loadCompleto:      t.loadEventEnd - t.navigationStart,
            ttfb:              t.responseStart - t.requestStart,
            dns:               t.domainLookupEnd - t.domainLookupStart,
        };
    },

    imprimir() {
        const stats = this.obtener();
        if (stats) {
            console.group('⚡ Métricas de rendimiento');
            console.table(stats);
            console.groupEnd();
        }
    }
};

// ── Utilidades generales ──────────────────────────────────────────────────
const Utils = {
    formatearBytes(bytes, decimales = 2) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const unidades = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return `${parseFloat((bytes / Math.pow(k, i)).toFixed(decimales))} ${unidades[i]}`;
    },

    formatearTiempo(ms) {
        if (ms < 1000) return `${ms} ms`;
        return `${(ms / 1000).toFixed(2)} s`;
    },

    debounce(fn, espera = 300) {
        let timer;
        return (...args) => {
            clearTimeout(timer);
            timer = setTimeout(() => fn(...args), espera);
        };
    },

    throttle(fn, limite = 100) {
        let enEspera = false;
        return (...args) => {
            if (!enEspera) {
                fn(...args);
                enEspera = true;
                setTimeout(() => { enEspera = false; }, limite);
            }
        };
    }
};

// ── Configuración de compresión esperada ──────────────────────────────────
const CONFIG_COMPRESION = {
    deflate: {
        niveles: [1, 6, 9],
        descripcion: 'mod_deflate (gzip)',
        algoritmo: 'DEFLATE (LZ77 + Huffman coding)',
        soporte: 'Universal — todos los navegadores'
    },
    brotli: {
        niveles: [5, 11],
        descripcion: 'mod_brotli (br)',
        algoritmo: 'Brotli (LZ77 + Huffman + context modeling)',
        soporte: 'Navegadores modernos (Chrome 50+, Firefox 44+)'
    }
};

// ── Inicialización ────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    SistemaInfo.imprimirInfo();
    DNSInfo.imprimirZona();
    UI.mostrarFechaActual();
    UI.resaltarRecursoActivo();
    UI.agregarIndicadorCompresion();

    window.addEventListener('load', () => {
        Rendimiento.imprimir();
    });

    // Exponer en consola para experimentación
    window._parcial = {
        sistema:    SistemaInfo,
        compresion: CompresionMonitor,
        dns:        DNSInfo,
        config:     CONFIG_COMPRESION,
        utils:      Utils,
    };

    console.log(
        '%c Parcial 1 — Servicios Telemáticos 2026 ',
        'background:#0d6efd;color:#fff;font-size:14px;font-weight:bold;padding:4px 8px;border-radius:4px'
    );
    console.log('Ejecuta window._parcial.compresion.medirTodos() para medir desde el navegador.');
});
