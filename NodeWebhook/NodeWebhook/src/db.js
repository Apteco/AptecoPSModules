// src/db.js
// SQLite queue database — verwendet das eingebaute node:sqlite Modul.
// Kein nativer Addon, kein Compiler erforderlich (Node.js >= 22.5).

import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'fs';
import { dirname } from 'path';

let _db = null;

/**
 * Gibt die SQLite-Instanz zurück (Singleton).
 * @param {string} dbPath  Pfad zur .db-Datei
 */
export function getDb(dbPath = './data/queue.db') {
  if (_db) return _db;

  mkdirSync(dirname(dbPath), { recursive: true });

  _db = new DatabaseSync(dbPath);

  // node:sqlite unterstützt kein .pragma() — PRAGMAs via exec() setzen
  _db.exec('PRAGMA journal_mode = WAL');
  _db.exec('PRAGMA synchronous = NORMAL');
  _db.exec('PRAGMA foreign_keys = ON');

  _db.exec(`
    CREATE TABLE IF NOT EXISTS webhook_queue (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,

      -- Endpunkt-Identifikation
      endpoint      TEXT    NOT NULL,

      -- Timestamps
      created_at    TEXT    NOT NULL
                    DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
      updated_at    TEXT    NOT NULL
                    DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),

      -- Herkunft
      source_ip     TEXT,
      headers       TEXT,

      -- Nutzdaten
      payload       TEXT    NOT NULL,

      -- Verarbeitungsstatus
      status        TEXT    NOT NULL DEFAULT 'pending'
                            CHECK(status IN ('pending', 'processing', 'done', 'failed')),
      attempts      INTEGER NOT NULL DEFAULT 0,
      last_error    TEXT,
      processed_at  TEXT
    );

    CREATE TRIGGER IF NOT EXISTS trg_webhook_queue_updated_at
      AFTER UPDATE ON webhook_queue
      FOR EACH ROW
      WHEN OLD.updated_at = NEW.updated_at
      BEGIN
        UPDATE webhook_queue
        SET    updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
        WHERE  id = NEW.id;
      END;

    CREATE INDEX IF NOT EXISTS idx_queue_status
      ON webhook_queue(status, created_at);

    CREATE INDEX IF NOT EXISTS idx_queue_endpoint
      ON webhook_queue(endpoint, status);
  `);

  return _db;
}

/**
 * Fügt einen neuen Webhook-Payload in die Queue ein.
 * Gibt die neue ID zurück.
 *
 * node:sqlite verwendet ausschließlich positionale Parameter (?),
 * keine Named Parameters (@name) wie better-sqlite3.
 *
 * @param {DatabaseSync} db
 * @param {{ endpoint: string, sourceIp?: string, headers?: object, payload: any }} opts
 * @returns {number|bigint}  lastInsertRowid
 */
export function enqueue(db, { endpoint, sourceIp, headers, payload }) {
  const stmt = db.prepare(`
    INSERT INTO webhook_queue (endpoint, source_ip, headers, payload)
    VALUES (?, ?, ?, ?)
  `);

  const result = stmt.run(
    endpoint,
    sourceIp ?? null,
    headers ? JSON.stringify(headers) : null,
    typeof payload === 'string' ? payload : JSON.stringify(payload),
  );

  return result.lastInsertRowid;
}
