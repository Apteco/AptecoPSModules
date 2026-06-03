// src/worker.js
// Asynchroner Worker — pollt die SQLite-Queue und schreibt in SQL Server.
// Läuft als separater Prozess: npm run worker

import 'dotenv/config';
import { getDb } from './db.js';
import { getPool, closePool } from './sqlserver.js';
import { handleEntry } from './handlers.js';

const SQLITE_PATH   = process.env.SQLITE_PATH          ?? './data/queue.db';
const POLL_INTERVAL = parseInt(process.env.WORKER_POLL_MS       ?? '3000', 10);
const BATCH_SIZE    = parseInt(process.env.WORKER_BATCH          ?? '10',  10);
const MAX_ATTEMPTS  = parseInt(process.env.WORKER_MAX_ATTEMPTS   ?? '3',   10);

const db = getDb(SQLITE_PATH);

// Vorbereitete Statements (einmalig kompiliert)
// node:sqlite verwendet nur positionale ? Parameter — keine Named Parameters.
const stmtClaim = db.prepare(`
  UPDATE webhook_queue
  SET    status = 'processing', attempts = attempts + 1
  WHERE  id = ?
`);

const stmtDone = db.prepare(`
  UPDATE webhook_queue
  SET    status = 'done',
         processed_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
         last_error = NULL
  WHERE  id = ?
`);

const stmtFail = db.prepare(`
  UPDATE webhook_queue
  SET    status = ?, last_error = ?
  WHERE  id = ?
`);

// Beim Start hängengebliebene 'processing'-Einträge zurücksetzen
db.prepare(`
  UPDATE webhook_queue
  SET    status = 'pending'
  WHERE  status = 'processing'
`).run();

const stmtFetch = db.prepare(`
  SELECT id, endpoint, payload, headers, source_ip, created_at, attempts
  FROM   webhook_queue
  WHERE  status = 'pending'
     OR (status = 'failed' AND attempts < ${MAX_ATTEMPTS})
  ORDER  BY created_at ASC
  LIMIT  ${BATCH_SIZE}
`);

// ------------------------------------------------------------
// Poll-Schleife
// ------------------------------------------------------------
async function pollOnce(pool) {
  const rows = stmtFetch.all();
  if (rows.length === 0) return;

  console.log(`[worker] ${rows.length} Einträge gefunden`);

  for (const entry of rows) {
    stmtClaim.run(entry.id);

    try {
      await handleEntry(pool, entry);
      stmtDone.run(entry.id);
      console.log(`[worker] ✓ ID=${entry.id} endpoint=${entry.endpoint}`);

    } catch (err) {
      const isFinal = entry.attempts + 1 >= MAX_ATTEMPTS;
      const nextStatus = isFinal ? 'failed' : 'pending';
      const msg = err.message ?? String(err);

      stmtFail.run(nextStatus, msg, entry.id);
      console.error(`[worker] ✗ ID=${entry.id} ${nextStatus} (Versuch ${entry.attempts + 1}/${MAX_ATTEMPTS}) — ${msg}`);
    }
  }
}

// ------------------------------------------------------------
// Start + Graceful Shutdown
// ------------------------------------------------------------
console.log(`[worker] Starte... Poll=${POLL_INTERVAL}ms Batch=${BATCH_SIZE} MaxAttempts=${MAX_ATTEMPTS}`);

let pool;
let running = true;

async function loop() {
  if (!running) return;

  try {
    // Pool bei Bedarf (neu) verbinden
    pool = await getPool();
    await pollOnce(pool);
  } catch (err) {
    console.error('[worker] Fehler in Poll-Schleife:', err.message);
    // Bei SQL-Server-Verbindungsfehler kurz länger warten
    await new Promise(r => setTimeout(r, 5_000));
  }

  if (running) setTimeout(loop, POLL_INTERVAL);
}

async function shutdown(signal) {
  console.log(`[worker] ${signal} empfangen — fahre herunter...`);
  running = false;
  await closePool();
  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

loop();
