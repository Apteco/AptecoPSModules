// src/handlers.js
// Pro-Endpunkt SQL Server Handler.
//
// Jeder Endpunkt aus endpoints.yaml kann auf eine eigene Zieltabelle
// oder Stored Procedure geroutet werden.
// Nicht konfigurierte Endpunkte landen in der Fallback-Tabelle.

import { sql } from './sqlserver.js';

/**
 * Verarbeitet einen Queue-Eintrag und schreibt ihn in SQL Server.
 * Wird vom Worker für jeden Eintrag aufgerufen.
 *
 * @param {sql.ConnectionPool} pool
 * @param {object} entry  – Zeile aus webhook_queue
 * @param {number|bigint} entry.id
 * @param {string} entry.endpoint
 * @param {string} entry.payload     – JSON-String
 * @param {string} entry.headers     – JSON-String
 * @param {string} entry.source_ip
 * @param {string} entry.created_at  – ISO 8601 UTC
 */
export async function handleEntry(pool, entry) {
  const handler = ENDPOINT_HANDLERS[entry.endpoint] ?? defaultHandler;
  await handler(pool, entry);
}

// ------------------------------------------------------------
// Endpunkt-spezifische Handler
// Einen eigenen Handler pro Endpunkt anlegen oder defaultHandler nutzen.
// ------------------------------------------------------------

const ENDPOINT_HANDLERS = {

  /**
   * github → dbo.GithubEvents
   * Extrahiert das Event-Type-Feld aus dem Payload.
   */
  github: async (pool, entry) => {
    const payload = JSON.parse(entry.payload);
    const headers = entry.headers ? JSON.parse(entry.headers) : {};

    await pool.request()
      .input('event_type',  sql.NVarChar(100),      headers['x-github-event'] ?? null)
      .input('delivery_id', sql.NVarChar(100),      headers['x-github-delivery'] ?? null)
      .input('repository',  sql.NVarChar(255),      payload?.repository?.full_name ?? null)
      .input('action',      sql.NVarChar(100),      payload?.action ?? null)
      .input('payload',     sql.NVarChar(sql.MAX),  entry.payload)
      .input('source_ip',   sql.NVarChar(50),       entry.source_ip ?? null)
      .input('received_at', sql.DateTime2,           new Date(entry.created_at))
      .query(`
        INSERT INTO dbo.GithubEvents
          (EventType, DeliveryId, Repository, Action, Payload, SourceIp, ReceivedAt)
        VALUES
          (@event_type, @delivery_id, @repository, @action, @payload, @source_ip, @received_at)
      `);
  },

  /**
   * shopify → dbo.ShopifyEvents
   * Extrahiert Topic und Shop-Domain aus den Headern.
   */
  shopify: async (pool, entry) => {
    const payload = JSON.parse(entry.payload);
    const headers = entry.headers ? JSON.parse(entry.headers) : {};

    await pool.request()
      .input('topic',       sql.NVarChar(200),      headers['x-shopify-topic'] ?? null)
      .input('shop_domain', sql.NVarChar(255),      headers['x-shopify-shop-domain'] ?? null)
      .input('order_id',    sql.BigInt,             payload?.id ?? null)
      .input('payload',     sql.NVarChar(sql.MAX),  entry.payload)
      .input('source_ip',   sql.NVarChar(50),       entry.source_ip ?? null)
      .input('received_at', sql.DateTime2,           new Date(entry.created_at))
      .query(`
        INSERT INTO dbo.ShopifyEvents
          (Topic, ShopDomain, OrderId, Payload, SourceIp, ReceivedAt)
        VALUES
          (@topic, @shop_domain, @order_id, @payload, @source_ip, @received_at)
      `);
  },

  // Weitere Endpunkte hier ergänzen:
  // mein_system: async (pool, entry) => { ... },
};

// ------------------------------------------------------------
// Fallback: alle unbekannten/nicht konfigurierten Endpunkte
// → dbo.WebhookEvents (generische Tabelle)
// ------------------------------------------------------------
async function defaultHandler(pool, entry) {
  await pool.request()
    .input('endpoint',    sql.NVarChar(100),     entry.endpoint)
    .input('payload',     sql.NVarChar(sql.MAX), entry.payload)
    .input('headers',     sql.NVarChar(sql.MAX), entry.headers ?? null)
    .input('source_ip',   sql.NVarChar(50),      entry.source_ip ?? null)
    .input('received_at', sql.DateTime2,          new Date(entry.created_at))
    .query(`
      INSERT INTO dbo.WebhookEvents
        (Endpoint, Payload, Headers, SourceIp, ReceivedAt)
      VALUES
        (@endpoint, @payload, @headers, @source_ip, @received_at)
    `);
}
