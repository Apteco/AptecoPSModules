// src/sqlserver.js
// SQL Server Connection Pool — einmalig initialisiert, im Worker wiederverwendet.

import sql from 'mssql';

let _pool = null;

/**
 * Gibt den Connection Pool zurück (Singleton).
 * Bei SQLSERVER_WINDOWS_AUTH=true werden User/Pass nicht benötigt.
 *
 * @returns {Promise<sql.ConnectionPool>}
 */
export async function getPool() {
  if (_pool?.connected) return _pool;

  const windowsAuth = process.env.SQLSERVER_WINDOWS_AUTH === 'true';

  const config = {
    server:   requireEnv('SQLSERVER_HOST'),
    database: requireEnv('SQLSERVER_DB'),
    port:     parseInt(process.env.SQLSERVER_PORT ?? '1433', 10),
    options: {
      encrypt:                process.env.SQLSERVER_ENCRYPT !== 'false',
      trustServerCertificate: process.env.SQLSERVER_TRUST_CERT === 'true',
      enableArithAbort:       true,
      trustedConnection:      windowsAuth,
    },
    pool: {
      min:                  parseInt(process.env.SQLSERVER_POOL_MIN  ?? '2',   10),
      max:                  parseInt(process.env.SQLSERVER_POOL_MAX  ?? '10',  10),
      idleTimeoutMillis:    parseInt(process.env.SQLSERVER_POOL_IDLE ?? '30000', 10),
      acquireTimeoutMillis: 15_000,
    },
    connectionTimeout: 15_000,
    requestTimeout:    parseInt(process.env.SQLSERVER_REQUEST_TIMEOUT ?? '30000', 10),
  };

  // SQL-Login: User + Passwort hinzufügen
  // Windows Auth: beides weglassen, trustedConnection genügt
  if (!windowsAuth) {
    config.user     = requireEnv('SQLSERVER_USER');
    config.password = requireEnv('SQLSERVER_PASS');
  }

  _pool = await new sql.ConnectionPool(config).connect();

  _pool.on('error', err => {
    console.error('[sqlserver] Pool-Fehler:', err.message);
    _pool = null;
  });

  const authMode = windowsAuth ? 'Windows Auth' : `SQL Login (${config.user})`;
  console.log(`[sqlserver] Verbunden mit ${config.server}/${config.database} (${authMode})`);
  return _pool;
}

/**
 * Schließt den Pool (z.B. bei graceful shutdown).
 */
export async function closePool() {
  if (_pool) {
    await _pool.close();
    _pool = null;
    console.log('[sqlserver] Pool geschlossen');
  }
}

function requireEnv(key) {
  const val = process.env[key];
  if (!val) throw new Error(`Umgebungsvariable ${key} fehlt (wird für SQL Server benötigt).`);
  return val;
}

export { sql };
