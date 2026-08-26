'use strict';

const express = require('express');

// CSRF middleware is intentionally absent: this is a stateless JSON API with
// GET-only routes and no cookie/session auth, so CSRF — which abuses ambient
// browser cookies against state-changing requests — does not apply. Revisit if
// authenticated, state-changing endpoints are added.
// nosemgrep: javascript.express.security.audit.express-check-csurf-middleware-usage.express-check-csurf-middleware-usage
const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.get('/', (req, res) => {
  res.json({ service: 'sddp-__service__', status: 'ok' });
});

// Liveness/readiness endpoint for Kubernetes probes.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  // eslint-disable-next-line no-console
  console.log(`sddp-__service__ listening on :${PORT}`);
});

// Graceful shutdown so Kubernetes rolling updates drain cleanly.
process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});

module.exports = app;
