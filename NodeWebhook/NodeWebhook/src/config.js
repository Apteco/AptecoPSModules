// src/config.js
// Lädt und validiert endpoints.yaml.
// Gibt eine Map<endpointName, EndpointConfig> zurück.

import { readFileSync } from 'fs';
import { resolve } from 'path';
import { parse } from 'yaml';

/**
 * @typedef {Object} EndpointConfig
 * @property {string}   key             – URL-Key (Pflicht)
 * @property {string}   [description]
 * @property {number}   bodyLimit       – max. Body-Größe in Bytes
 * @property {string[]} allowedIps      – leer = alle IPs erlaubt
 * @property {string[]} headers         – zusätzliche Header speichern
 *
 * Optionale Token-Absicherung (zusätzlich zum URL-Key):
 * @property {string}   [apiKey]        – Erwarteter Wert für X-Api-Key Header
 * @property {string}   [apiKeyHeader]  – Header-Name, default: "x-api-key"
 * @property {string}   [bearerToken]   – Erwarteter Bearer Token (Authorization: Bearer <token>)
 */

const DEFAULTS = {
  bodyLimit:    1_048_576,
  allowedIps:   [],
  headers:      [],
  apiKey:       null,
  apiKeyHeader: 'x-api-key',
  bearerToken:  null,
};

export function loadEndpoints(yamlPath) {
  const absPath = resolve(yamlPath);
  let raw;

  try {
    raw = readFileSync(absPath, 'utf8');
  } catch (err) {
    throw new Error(`endpoints.yaml nicht gefunden: ${absPath}\n${err.message}`);
  }

  const doc = parse(raw);

  if (!doc?.endpoints || typeof doc.endpoints !== 'object') {
    throw new Error('endpoints.yaml: Schlüssel "endpoints" fehlt oder ist leer.');
  }

  const map = new Map();

  for (const [name, cfg] of Object.entries(doc.endpoints)) {
    if (!cfg?.key || typeof cfg.key !== 'string' || cfg.key.trim() === '') {
      throw new Error(`endpoints.yaml: Endpunkt "${name}" hat kein gültiges "key"-Feld.`);
    }

    map.set(name, {
      ...DEFAULTS,
      ...cfg,
      key:          cfg.key.trim(),
      allowedIps:   Array.isArray(cfg.allowedIps) ? cfg.allowedIps : [],
      headers:      Array.isArray(cfg.headers)    ? cfg.headers    : [],
      apiKey:       cfg.apiKey       ? String(cfg.apiKey).trim()       : null,
      apiKeyHeader: cfg.apiKeyHeader ? String(cfg.apiKeyHeader).trim().toLowerCase() : 'x-api-key',
      bearerToken:  cfg.bearerToken  ? String(cfg.bearerToken).trim()  : null,
    });
  }

  if (map.size === 0) {
    throw new Error('endpoints.yaml: Keine Endpunkte definiert.');
  }

  return map;
}
