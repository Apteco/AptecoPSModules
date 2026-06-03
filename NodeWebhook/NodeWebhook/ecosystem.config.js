// ecosystem.config.js
// Passe APP_DIR auf den tatsächlichen Installationspfad an.
const APP_DIR = __dirname;

module.exports = {
  apps: [
    {
      name:        'webhook-receiver',
      script:      `${APP_DIR}/src/server.js`,
      cwd:         APP_DIR,
      exec_mode:   'fork',
      autorestart: true,
      max_restarts: 10,
      // env: { NODE_ENV: 'production', PORT: 3000 }
    },
    {
      name:        'webhook-worker',
      script:      `${APP_DIR}/src/worker.js`,
      cwd:         APP_DIR,
      exec_mode:   'fork',
      autorestart: true,
      max_restarts: 10,
    },
  ],
};