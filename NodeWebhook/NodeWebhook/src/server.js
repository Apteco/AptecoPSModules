// src/server.js
// Fastify 5 Webhook Receiver — Multi-Endpoint
//
// Routen-Schema:  POST /webhook/:endpoint/:key
//
// Absicherung pro Endpunkt (konfigurierbar in endpoints.yaml):
//   1. URL-Key          — :key in der URL (immer aktiv)
//   2. X-Api-Key Header — apiKey + apiKeyHeader (optional)
//   3. Bearer Token     — bearerToken im Authorization-Header (optional)
//   4. IP-Whitelist     — allowedIps (optional)

import 'dotenv/config';
import Fastify from 'fastify';
import { getDb, enqueue } from './db.js';
import { loadEndpoints } from './config.js';

const PORT        = parseInt(process.env.PORT         ?? '3000', 10);
const HOST        = process.env.HOST                   ?? '127.0.0.1';
const SQLITE_PATH = process.env.SQLITE_PATH            ?? './data/queue.db';
const YAML_PATH   = process.env.ENDPOINTS_YAML         ?? './endpoints.yaml';
const LOG_LEVEL   = process.env.LOG_LEVEL              ?? 'info';

// ------------------------------------------------------------
// Konfiguration laden
// ------------------------------------------------------------
const endpoints = loadEndpoints(YAML_PATH);

// ------------------------------------------------------------
// Fastify 5 Instanz
// pino-pretty nur wenn LOG_PRETTY=true in .env (+ npm install pino-pretty)
// ------------------------------------------------------------
const loggerConfig = { level: LOG_LEVEL };
if (process.env.LOG_PRETTY === 'true') {
  loggerConfig.transport = {
    target:  'pino-pretty',
    options: { translateTime: 'SYS:standard', ignore: 'pid,hostname' },
  };
}

const app = Fastify({
  logger:    loggerConfig,
  bodyLimit: 1_048_576,
});

// ------------------------------------------------------------
// DB-Initialisierung
// ------------------------------------------------------------
const db = getDb(SQLITE_PATH);

// ------------------------------------------------------------
// Health-Check (für IIS ARR Probe)
// ------------------------------------------------------------
app.get('/health', async (_req, reply) => {
  return reply.send({
    status:    'ok',
    ts:        new Date().toISOString(),
    endpoints: [...endpoints.keys()],
  });
});

// ------------------------------------------------------------
// Webhook-Endpunkt  POST /webhook/:endpoint/:key
// ------------------------------------------------------------
app.post('/webhook/:endpoint/:key', async (request, reply) => {
  const { endpoint: endpointName, key } = request.params;

  // 1. Endpunkt nachschlagen
  const cfg = endpoints.get(endpointName);
  if (!cfg) {
    request.log.warn({ endpointName }, 'Unbekannter Endpunkt');
    return reply.code(404).send({ error: 'Not found' });
  }

  // 2. URL-Key validieren
  if (!timingSafeEqual(key, cfg.key)) {
    request.log.warn({ endpointName, ip: request.ip }, 'Ungültiger URL-Key');
    return reply.code(401).send({ error: 'Unauthorized' });
  }

  // 3. X-Api-Key Header prüfen (falls konfiguriert)
  if (cfg.apiKey) {
    const incoming = request.headers[cfg.apiKeyHeader] ?? '';
    if (!timingSafeEqual(incoming, cfg.apiKey)) {
      request.log.warn({ endpointName, ip: request.ip, header: cfg.apiKeyHeader }, 'Ungültiger API-Key Header');
      return reply.code(401).send({ error: 'Unauthorized' });
    }
  }

  // 4. Bearer Token prüfen (falls konfiguriert)
  if (cfg.bearerToken) {
    const authHeader = request.headers['authorization'] ?? '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    if (!timingSafeEqual(token, cfg.bearerToken)) {
      request.log.warn({ endpointName, ip: request.ip }, 'Ungültiger Bearer Token');
      return reply.code(401).send({ error: 'Unauthorized' });
    }
  }

  // 5. IP-Whitelist prüfen (falls konfiguriert)
  if (cfg.allowedIps.length > 0) {
    const clientIp = request.ip;
    if (!cfg.allowedIps.includes(clientIp)) {
      request.log.warn({ endpointName, ip: clientIp }, 'IP nicht erlaubt');
      return reply.code(403).send({ error: 'Forbidden' });
    }
  }

  // 6. Header sammeln (Basis + endpunkt-spezifische)
  const baseHeaders = {
    'content-type':    request.headers['content-type'],
    'x-request-id':    request.headers['x-request-id'],
    'x-forwarded-for': request.headers['x-forwarded-for'],
    'user-agent':      request.headers['user-agent'],
  };
  const extraHeaders = Object.fromEntries(
    cfg.headers
      .filter(h => request.headers[h.toLowerCase()] !== undefined)
      .map(h => [h.toLowerCase(), request.headers[h.toLowerCase()]])
  );
  const safeHeaders = { ...baseHeaders, ...extraHeaders };

  // 7. Body normalisieren
  const payload = request.body ?? {};

  // 8. In SQLite speichern
  try {
    const id = enqueue(db, {
      endpoint: endpointName,
      sourceIp: request.ip,
      headers:  safeHeaders,
      payload,
    });

    request.log.info({ id, endpoint: endpointName, ip: request.ip }, 'Webhook enqueued');
    return reply.code(202).send({ queued: true, id, endpoint: endpointName });

  } catch (err) {
    request.log.error({ err, endpointName }, 'Fehler beim Speichern in SQLite');
    return reply.code(500).send({ error: 'Internal error' });
  }
});

// ------------------------------------------------------------
// Admin: Queue-Status aufgeschlüsselt nach Endpunkt
// ------------------------------------------------------------
app.get('/admin/queue-stats', async (_req, reply) => {
  const rows = db.prepare(`
    SELECT endpoint, status, COUNT(*) AS count
    FROM   webhook_queue
    GROUP  BY endpoint, status
    ORDER  BY endpoint, status
  `).all();

  const stats = {};
  for (const row of rows) {
    stats[row.endpoint] ??= {};
    stats[row.endpoint][row.status] = row.count;
  }

  return reply.send({ stats, ts: new Date().toISOString() });
});

// ------------------------------------------------------------
// Constant-Time String-Vergleich (Timing-Angriffe verhindern)
// ------------------------------------------------------------
function timingSafeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  if (a.length !== b.length) {
    let diff = 0;
    for (let i = 0; i < b.length; i++) diff |= (b.charCodeAt(i) ^ (b.charCodeAt(i) + 1));
    return false;
  }
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

// ------------------------------------------------------------
// Start
// ------------------------------------------------------------
try {
  await app.listen({ port: PORT, host: HOST });
  app.log.info(`Webhook receiver läuft auf http://${HOST}:${PORT}`);
  app.log.info(`Aktive Endpunkte: ${[...endpoints.keys()].join(', ')}`);
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
