// ecosystem.config.cjs
// WICHTIG: .cjs-Endung erforderlich, weil package.json "type": "module" setzt —
// PM2-Configs müssen CommonJS sein (module.exports), die .cjs-Endung erzwingt das.
module.exports = {
  apps: [
    {
      name: 'webhook-receiver',
      script: 'C:\\FastStats\\Scripts\\node_webhook\\src\\server.js',
      cwd:    'C:\\FastStats\\Scripts\\node_webhook',
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10
      // env: { NODE_ENV: 'production', PORT: 3000 }   // falls nötig
    },
    {
      name: 'webhook-worker',
      script: 'C:\\FastStats\\Scripts\\node_webhook\\src\\worker.js',
      cwd:    'C:\\FastStats\\Scripts\\node_webhook',
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10
    }
  ]
};
